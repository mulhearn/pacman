"""
Lightweight utilities for ZMQ REQ/REP communication.

Centralizes:
  - global ZMQ context
  - REQ socket creation
  - adjustable timeouts
  - safe send/receive helpers
  - standard exception types
"""

import zmq


# ---------------------------------------------------------------------------
# Exception hierarchy
# ---------------------------------------------------------------------------

class comm_error(Exception):
    """Base class for ZMQ request/response errors."""


class request_timeout(comm_error):
    """Raised when no reply is received within the configured timeout."""


class disconnected(comm_error):
    """Raised when the socket is no longer connected / handshake failed."""


class protocol_error(comm_error):
    """Raised when the server reply is missing or malformed."""


# ---------------------------------------------------------------------------
# Module-level state
# ---------------------------------------------------------------------------

_context = zmq.Context.instance()
_debug_fn = None


def set_debug(fn):
    """Optional: set a log function, e.g., print, to monitor traffic."""
    global _debug_fn
    _debug_fn = fn


# ---------------------------------------------------------------------------
# Socket helpers
# ---------------------------------------------------------------------------

def get_req_socket(endpoint, timeout_ms=2000, linger_ms=0):
    """
    Create and return a REQ socket connected to the given endpoint.

    Parameters
    ----------
    endpoint : str
        ZMQ endpoint string, e.g. "tcp://localhost:5555"
    timeout_ms : int
        Timeout for send/recv operations, in milliseconds.
    linger_ms : int
        Linger time on close. 0 = drop unsent messages.
    """
    sock = _context.socket(zmq.REQ)

    # Set linger before connect.
    sock.setsockopt(zmq.LINGER, linger_ms)

    # Set timeouts.
    sock.setsockopt(zmq.RCVTIMEO, timeout_ms)
    sock.setsockopt(zmq.SNDTIMEO, timeout_ms)

    sock.connect(endpoint)
    return sock


def set_timeouts(sock, timeout_ms):
    """Adjust send/receive timeouts on the fly."""
    sock.setsockopt(zmq.RCVTIMEO, timeout_ms)
    sock.setsockopt(zmq.SNDTIMEO, timeout_ms)


# ---------------------------------------------------------------------------
# Request helpers
# ---------------------------------------------------------------------------

def send_and_receive(sock, msg):
    """
    Perform a single REQ/REP exchange.

    Parameters
    ----------
    sock : zmq.Socket
        REQ socket.
    msg : bytes
        Outgoing message.

    Returns
    -------
    bytes
        Reply from server.

    Raises
    ------
    request_timeout
    disconnected
    protocol_error
    """

    if _debug_fn:
        _debug_fn(f"REQ → {msg.hex()} ({len(msg)} bytes)")

    try:
        sock.send(msg)
    except zmq.error.Again:
        raise request_timeout("send timed out")
    except zmq.error.ZMQError as e:
        raise disconnected(f"failed to send: {e}")

    try:
        reply = sock.recv()
    except zmq.error.Again:
        raise request_timeout("no reply from server")
    except zmq.error.ZMQError as e:
        raise disconnected(f"failed to receive: {e}")

    if reply is None:
        raise protocol_error("empty reply")

    if _debug_fn:
        _debug_fn(f"REP ← {reply.hex()} ({len(reply)} bytes)")

    return reply


def safe_request(sock, msg, retries=1):
    """
    Wrap send_and_receive() with retry logic.

    retries == number of *additional* attempts on failure.

    Raises the final exception if all attempts fail.
    """

    attempt = 0
    last_exc = None

    while attempt <= retries:
        try:
            return send_and_receive(sock, msg)
        except comm_error as e:
            last_exc = e
            attempt += 1

    # If we got here, all attempts failed.
    raise last_exc
