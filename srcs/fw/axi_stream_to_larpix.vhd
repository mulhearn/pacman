library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_stream_to_larpix is
  generic (
    C_S_AXIS_TDATA_WIDTH        : integer := 128;
    C_LARPIX_DATA_WIDTH         : integer := 64;
    C_CHANNEL                   : std_logic_vector(7 downto 0) := x"FF";
    C_DATA_TYPE                 : std_logic_vector(7 downto 0) := x"44"
    );
  port (
    data_LArPix         : out std_logic_vector(C_LARPIX_DATA_WIDTH-1 downto 0);
    data_update_LArPix  : out std_logic;
    busy_LArPix         : in std_logic;
    
    S_AXIS_ACLK	        : in std_logic;
    S_AXIS_ARESETN	: in std_logic;

    S_AXIS_TREADY	: out std_logic;
    S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
    S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
    S_AXIS_TKEEP    : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
    S_AXIS_TLAST	: in std_logic;
    S_AXIS_TVALID	: in std_logic
    );
end axi_stream_to_larpix;

architecture arch_imp of axi_stream_to_larpix is
  type state is ( IDLE,
                  RX,
                  RX_DONE,
                  TX,
                  TX_DONE );
  signal mst_exec_state : state;

  signal axis_tready : std_logic;

  signal data_out : std_logic_vector(C_LARPIX_DATA_WIDTH-1 downto 0);
  signal update : std_logic;

  signal buf : std_logic_vector(2*C_S_AXIS_TDATA_WIDTH-1 downto 0);
  signal buf_bytes : integer range 2*C_S_AXIS_TDATA_WIDTH/8 downto 0;
  
  -- Function to determine number of data bytes in data beat
  function valid_bytes (condition : std_logic_vector) return integer is
    variable bytes : integer := 0;
  begin
    for i in condition'range loop
      if condition(i) = '1' then
        bytes := bytes + 1;
      end if;
    end loop;
    return bytes;
  end valid_bytes;
  
  -- Function to shift data to LSB, ommitting null bytes
  function squash_data(
    data : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0); 
    condition : std_logic_vector (C_S_AXIS_TDATA_WIDTH/8-1 downto 0)
    ) return std_logic_vector is
    variable rv: std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
    variable byte_idx: integer range C_S_AXIS_TDATA_WIDTH/8-1 downto 0;
  begin
    byte_idx := 0;
    rv := (others => '0');
    for i in condition'reverse_range loop
      if (condition(i) = '1') then
        rv((byte_idx*8)+7 downto byte_idx*8) := data((i*8)+7 downto i*8);
        byte_idx := byte_idx + 1;
      end if;
    end loop;
    return rv;
  end function squash_data;

begin
  -- I/O Connections assigments
  S_AXIS_TREADY	<= axis_tready;

  data_LArPix <= data_out;
  data_update_LArPix <= update;

  -- Control state machine implementation
  process (S_AXIS_ACLK) is
    variable new_bytes: integer range C_S_AXIS_TDATA_WIDTH/8 downto 0;
    variable squashed_data: std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
  begin
    if (rising_edge(S_AXIS_ACLK)) then
      if (S_AXIS_ARESETN = '0') then
        -- synchronous reset
        mst_exec_state <= IDLE;
        buf_bytes <= 0;
        
      else
        case mst_exec_state is
          when IDLE =>
            -- wait for new data
            axis_tready <= '0';
            update <= '0';
            if (S_AXIS_TVALID = '1') then
              mst_exec_state <= RX;
              new_bytes := valid_bytes(S_AXIS_TSTRB and S_AXIS_TKEEP);
            end if;

          when RX =>
            axis_tready <= '1';
            squashed_data := squash_data(S_AXIS_TDATA, S_AXIS_TSTRB and S_AXIS_TKEEP);
            -- shift valid data
            if (buf_bytes = 0) then
              buf(new_bytes*8-1 downto 0) <= squashed_data(new_bytes*8-1 downto 0);
            else
              buf((buf_bytes + new_bytes)*8 - 1 downto 0) <= squashed_data(new_bytes*8-1 downto 0) & buf(buf_bytes*8-1 downto 0);
            end if;
            buf_bytes <= buf_bytes + new_bytes;
            mst_exec_state <= RX_DONE;

          when RX_DONE =>
            axis_tready <= '0';
            -- don't transmit partial messages
            if (buf_bytes < C_S_AXIS_TDATA_WIDTH/8) then
              mst_exec_state <= IDLE;
            else
              -- latch next word
              data_out <= buf(C_S_AXIS_TDATA_WIDTH-1 downto C_S_AXIS_TDATA_WIDTH - C_LARPIX_DATA_WIDTH);
              -- shift buffer bytes
              buf_bytes <= buf_bytes - C_S_AXIS_TDATA_WIDTH/8;
              if (buf_bytes - C_S_AXIS_TDATA_WIDTH/8 > 0) then
                buf(buf_bytes*8 - C_S_AXIS_TDATA_WIDTH - 1 downto 0) <= buf(buf_bytes*8 - 1 downto C_S_AXIS_TDATA_WIDTH);
              end if;
              -- check that data is destined for this channel
              if (C_DATA_TYPE = buf(7 downto 0) and C_CHANNEL = buf(15 downto 8)) then
                mst_exec_state <= TX;
              -- skip word if not
              else
                mst_exec_state <= IDLE;
              end if;
            end if;
            
          when TX =>
            -- update larpix data
            update <= '1';
            if (busy_LArPix = '1') then
              mst_exec_state <= TX_DONE;
            end if;

          when TX_DONE =>
            -- wait for complete transmission
            update <= '0';
            if (busy_LArPix = '0') then
              mst_exec_state <= IDLE;
            end if;

          when others =>
            mst_exec_state <= IDLE;
        end case;
      end if;
    end if;
  end process larpix_tx_fsm;

end arch_imp;
