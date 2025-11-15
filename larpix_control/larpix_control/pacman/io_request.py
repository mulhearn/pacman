# larpix_control/pacman/io_request.py
"""
Manager for PACMAN UART REQ/REP traffic.

This module provides a single io_request manager class that:
  - loads fixed_network.yaml
  - builds a routing table mapping io_channel -> route_info
  - creates one REQ socket per pacman (io_group)
  - routes send_packets/send_string calls by io_channel to the correct socket

Usage:
    io = io_request()                       # uses package-relative config path
    io.send_string(0x101, "hello")
    io.send_packets(0x101, [pkt1, pkt2])
    io.set_timeout(0x101, 3000)             # update timeout for that channel's socket
    io.close()
"""

from __future__ import annotations

import os
import time
import yaml
from typing import Dict, Any, Optional

import zmq

from larpix_control.pacman.zmq_req import get_req_socket, send_and_receive, request_timeout
from larpix_control import pacman_message as pm
from larpix_control.common.interfaces import io_request_iface

_default_yaml = os.path.join(os.path.dirname(__file__), "..", "..", "config", "network", "single_local.yaml")
_default_yaml = os.path.normpath(_default_yaml)

class io_request(io_request_iface):
    """
    Manager for UART REQ/REP access by io_channel.

    The manager builds:
      - self.routes: mapping io_channel -> dict(io_group, endpoint, timeout_ms)
      - self.sockets: mapping io_group -> zmq REQ socket

    Caller-facing API:
      - send_packets(io_chan, packets) -> list[bytes | None]
      - send_string(io_chan, s) -> bytes | None
      - set_timeout(io_chan, timeout_ms)
      - close()
    """

    def __init__(self, config_path: Optional[str] = None, debug_fn: Optional[callable] = None):
        """
        If config_path is None, load the package-default config.
        debug_fn, if provided, will be called with debug strings.
        """
        if config_path is None:
            config_path = _default_yaml

        self._debug_fn = debug_fn
        self.config_path = config_path
        self.routes: Dict[int, Dict[str, Any]] = {}
        self.sockets: Dict[int, zmq.Socket] = {}
        self._load_config_and_build_routes(config_path)
        self._init_sockets()

    # -------------------------
    # config / routing
    # -------------------------
    def _log(self, *args):
        if self._debug_fn:
            try:
                self._debug_fn(" ".join(str(a) for a in args))
            except Exception:
                # don't let logger break operation
                pass

    def _to_int_if_hex(self, v):
        if isinstance(v, str):
            # accepts "0x..." or decimal string
            if v.startswith("0x") or v.startswith("0X"):
                return int(v, 16)
            return int(v)
        return int(v)

    def _load_config_and_build_routes(self, path: str):
        """Load the YAML and build self.routes: io_chan -> route_info."""
        with open(path) as f:
            cfg = yaml.safe_load(f)

        if not isinstance(cfg, dict) or "network" not in cfg:
            raise ValueError(f"invalid config file: {path}")

        # temporary mapping to hold info per io_group so we can check consistency
        group_endpoints: Dict[int, Dict[str, Any]] = {}

        for entry in cfg["network"]:
            # required fields
            try:
                io_group = int(entry["io_group"])
                hostname = str(entry["hostname"])
                port = int(entry["port"])
                timeout_ms = int(entry["timeout_ms"])
                first_io_chan = self._to_int_if_hex(entry["first_io_chan"])
                uart_mask = self._to_int_if_hex(entry["uart_mask"])
            except KeyError as e:
                raise ValueError(f"missing required field in config: {e}")
            except Exception as e:
                raise ValueError(f"invalid value in config entry {entry}: {e}")

            endpoint = f"tcp://{hostname}:{port}"

            # validate that the same io_group does not map to multiple endpoints
            prev = group_endpoints.get(io_group)
            if prev is None:
                group_endpoints[io_group] = {"endpoint": endpoint, "timeout_ms": timeout_ms}
            else:
                if prev["endpoint"] != endpoint:
                    raise ValueError(
                        f"inconsistent endpoints for io_group {io_group}: {prev['endpoint']} vs {endpoint}"
                    )
                # if timeout differs, keep the first one and warn (but not fatal)
                if prev["timeout_ms"] != timeout_ms:
                    self._log(
                        f"warning: differing timeout_ms for io_group {io_group}; "
                        f"using {prev['timeout_ms']} (found {timeout_ms})"
                    )

            # walk bits in uart_mask; any set bit means the channel (first_io_chan + bit) is active
            if uart_mask < 0:
                raise ValueError(f"negative uart_mask in entry {entry}")

            # iterate bits up to bit_length
            bit = 0
            limit = max(1, uart_mask.bit_length())
            while bit < limit:
                if uart_mask & (1 << bit):
                    io_chan = first_io_chan + bit
                    if io_chan in self.routes:
                        raise ValueError(f"overlapping io_channel {hex(io_chan)} in config")
                    self.routes[io_chan] = {
                        "io_group": io_group,
                        "endpoint": endpoint,
                        "timeout_ms": group_endpoints[io_group]["timeout_ms"],
                    }
                bit += 1

        if not self.routes:
            raise ValueError("no active channels found in network config")

        self._log(f"loaded {len(self.routes)} active channels from {path}")

    # -------------------------
    # sockets
    # -------------------------
    def _init_sockets(self):
        """Create one REQ socket per io_group (pacman)."""
        for io_chan, info in self.routes.items():
            grp = info["io_group"]
            if grp in self.sockets:
                continue
            endpoint = info["endpoint"]
            timeout_ms = info["timeout_ms"]
            sock = get_req_socket(endpoint, timeout_ms=timeout_ms)
            self.sockets[grp] = sock
            self._log(f"created socket for io_group {grp} -> {endpoint}")

    # -------------------------
    # public API: send / string
    # -------------------------
    def _get_route(self, io_chan: int) -> Dict[str, Any]:
        if io_chan not in self.routes:
            raise ValueError(f"unknown io_channel: {hex(io_chan)}")
        return self.routes[io_chan]

    def send_packets(self, io_chan: int, packets):
        """
        Send a list of raw packet bytes to the channel io_chan.
        Returns list of replies (bytes) or None for timeouts.
        """
        route = self._get_route(io_chan)
        grp = route["io_group"]
        sock = self.sockets.get(grp)
        if sock is None:
            raise RuntimeError(f"socket for io_group {grp} not initialized")

        replies = []
        for pkt in packets:
            msg = pm.pack_msg(
                "REQ",
                [pm.content_data(channel=io_chan, timestamp=int(time.time()), payload=pkt, pacman=grp)],
                timestamp=int(time.time()),
            )
            if self._debug_fn:
                self._debug_fn(f"route send: io_chan={hex(io_chan)} -> io_group={grp} endpoint={route['endpoint']}")
            try:
                rep = send_and_receive(sock, msg)
            except request_timeout:
                replies.append(None)
                continue
            replies.append(rep)
        return replies

    def send_string(self, io_chan: int, s: str):
        """
        Send a string message to the channel identified by io_chan.
        Returns reply bytes or None on timeout.
        """
        route = self._get_route(io_chan)
        grp = route["io_group"]
        sock = self.sockets.get(grp)
        if sock is None:
            raise RuntimeError(f"socket for io_group {grp} not initialized")

        msg = pm.pack_string_msg(s, timestamp=int(time.time()), pacman=grp)
        if self._debug_fn:
            self._debug_fn(f"route send_string: io_chan={hex(io_chan)} -> io_group={grp} endpoint={route['endpoint']}")
        try:
            rep = send_and_receive(sock, msg)
        except request_timeout:
            return None
        return rep

    # -------------------------
    # timeout / socket control
    # -------------------------
    def set_timeout(self, io_chan: int, timeout_ms: int):
        """
        Update the timeout for the socket handling the given io_chan.
        This updates the socket options in-place (RCVTIMEO, SNDTIMEO).
        """
        route = self._get_route(io_chan)
        grp = route["io_group"]
        sock = self.sockets.get(grp)
        if sock is None:
            raise RuntimeError(f"socket for io_group {grp} not initialized")

        sock.setsockopt(zmq.RCVTIMEO, int(timeout_ms))
        sock.setsockopt(zmq.SNDTIMEO, int(timeout_ms))
        # record in routes so new sockets (recreated) would know, and for callers
        for r in self.routes.values():
            if r["io_group"] == grp:
                r["timeout_ms"] = int(timeout_ms)
        self._log(f"set timeout for io_group {grp} -> {timeout_ms} ms")

    def set_timeout_all(self, timeout_ms: int):
        """Update all sockets' timeouts."""
        for grp, sock in self.sockets.items():
            sock.setsockopt(zmq.RCVTIMEO, int(timeout_ms))
            sock.setsockopt(zmq.SNDTIMEO, int(timeout_ms))
            for r in self.routes.values():
                if r["io_group"] == grp:
                    r["timeout_ms"] = int(timeout_ms)
        self._log(f"set timeout for all sockets -> {timeout_ms} ms")

    # -------------------------
    # cleanup
    # -------------------------
    def close(self):
        """Close all underlying sockets."""
        for grp, sock in list(self.sockets.items()):
            try:
                sock.close()
                self._log(f"closed socket for io_group {grp}")
            except Exception:
                pass
        self.sockets.clear()

    # convenience: context manager
    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        self.close()
