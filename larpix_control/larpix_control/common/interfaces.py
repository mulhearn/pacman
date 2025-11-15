# larpix/common/interfaces.py
"""Common interfaces for the LArPix control software.

This module defines abstract base classes (ABCs) for software
interfaces, which have concrete implementations elsewhere.
"""

from abc import ABC, abstractmethod


class asic_config_iface(ABC):
    """Abstract interface for configuring an ASIC.

    Concrete subclasses implement the version-specific details for
    configuring an ASIC’s registers and applying the settings.
    """

    @abstractmethod
    def set_chip_id(self, chip_id) -> None:
        """Set the chip_id"""
        pass

    @abstractmethod
    def init_root_chip_io(self, chip_id: int, fpga_port: str) -> None:
        """Initialize the root chip for I/O"""
        pass

    @abstractmethod
    def init_io(self, chip_id: int) -> None:
        """Initialize a non-root chip for I/O"""
        pass

    @abstractmethod
    def set_input_enables(self, chip_id: int, ports: list[str]) -> None:
        """Set enables for receiving (either direction)"""
        pass

    @abstractmethod
    def set_downstream_output_enables(self, chip_id: int, ports: list[str]) -> None:
        """Set enables for transmitting downstream (toward FPGA)"""
        pass

    @abstractmethod
    def set_upstream_output_enables(self, chip_id: int, ports: list[str]) -> None:
        """Set enables for transmitting upstream (from FPGA)"""
        pass

class io_request_iface(ABC):
    """
    Abstract base class for PACMAN communication interfaces.
    """

    @abstractmethod
    def send_packets(self, io_chan, packets):
        """
        Send a list of integer/word packets to io_chan.
        Returns a list of reply bytes (or None if timeout).
        """
        pass

    @abstractmethod
    def send_string(self, s):
        """
        Send a high-level string message.
        Returns reply bytes (or None if timeout).
        """
        pass

    @abstractmethod
    def set_timeout(self, timeout_ms: int):
        """
        Adjust timeout on the fly (milliseconds).
        """
        pass
