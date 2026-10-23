--Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2021.1 (lin64) Build 3247384 Thu Jun 10 19:36:07 MDT 2021
--Date        : Fri Oct 23 02:18:21 2026
--Host        : ls-260186-phy running 64-bit Ubuntu 24.04.4 LTS
--Command     : generate_target zsys_wrapper.bd
--Design      : zsys_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity zsys_wrapper is
  port (
    ANALOG_PWR_EN : out STD_LOGIC_VECTOR ( 0 to 0 );
    CLK : out STD_LOGIC;
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    HW_SYNC_TRIG : in STD_LOGIC;
    I2C_1_SCL : inout STD_LOGIC;
    I2C_1_SDA : inout STD_LOGIC;
    MISO_0 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    MOSI_0 : out STD_LOGIC_VECTOR ( 31 downto 0 );
    RESETN : out STD_LOGIC;
    TILE_EN : out STD_LOGIC_VECTOR ( 7 downto 0 );
    TRIG : out STD_LOGIC_VECTOR ( 7 downto 0 );
    TRIG1_IN : in STD_LOGIC;
    UART_RX_BUSY : out STD_LOGIC;
    UART_TX_BUSY : out STD_LOGIC;
    usr_t : out STD_LOGIC_VECTOR ( 5 downto 0 )
  );
end zsys_wrapper;

architecture STRUCTURE of zsys_wrapper is
  component zsys is
  port (
    ANALOG_PWR_EN : out STD_LOGIC_VECTOR ( 0 to 0 );
    CLK : out STD_LOGIC;
    HW_SYNC_TRIG : in STD_LOGIC;
    I2C_1_SCL : inout STD_LOGIC;
    I2C_1_SDA : inout STD_LOGIC;
    MISO_0 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    MOSI_0 : out STD_LOGIC_VECTOR ( 31 downto 0 );
    RESETN : out STD_LOGIC;
    TILE_EN : out STD_LOGIC_VECTOR ( 7 downto 0 );
    TRIG : out STD_LOGIC_VECTOR ( 7 downto 0 );
    TRIG1_IN : in STD_LOGIC;
    UART_RX_BUSY : out STD_LOGIC;
    UART_TX_BUSY : out STD_LOGIC;
    usr_t : out STD_LOGIC_VECTOR ( 5 downto 0 );
    DDR_cas_n : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC
  );
  end component zsys;
begin
zsys_i: component zsys
     port map (
      ANALOG_PWR_EN(0) => ANALOG_PWR_EN(0),
      CLK => CLK,
      DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
      DDR_cas_n => DDR_cas_n,
      DDR_ck_n => DDR_ck_n,
      DDR_ck_p => DDR_ck_p,
      DDR_cke => DDR_cke,
      DDR_cs_n => DDR_cs_n,
      DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
      DDR_odt => DDR_odt,
      DDR_ras_n => DDR_ras_n,
      DDR_reset_n => DDR_reset_n,
      DDR_we_n => DDR_we_n,
      FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
      HW_SYNC_TRIG => HW_SYNC_TRIG,
      I2C_1_SCL => I2C_1_SCL,
      I2C_1_SDA => I2C_1_SDA,
      MISO_0(31 downto 0) => MISO_0(31 downto 0),
      MOSI_0(31 downto 0) => MOSI_0(31 downto 0),
      RESETN => RESETN,
      TILE_EN(7 downto 0) => TILE_EN(7 downto 0),
      TRIG(7 downto 0) => TRIG(7 downto 0),
      TRIG1_IN => TRIG1_IN,
      UART_RX_BUSY => UART_RX_BUSY,
      UART_TX_BUSY => UART_TX_BUSY,
      usr_t(5 downto 0) => usr_t(5 downto 0)
    );
end STRUCTURE;
