library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity larpix_to_axi_stream is
  generic(
    C_M_AXIS_TDATA_WIDTH    : integer := 128; -- width of AXIS bus
    C_LARPIX_DATA_WIDTH     : integer := 64;
    C_M_AXIS_TDATA_TYPE     : std_logic_vector(7 downto 0) := x"44"; -- ASCII D
    C_M_AXIS_TDATA_CHANNEL  : std_logic_vector(7 downto 0) := x"FF"
    );
  port (
    --C_M_AXIS_TDATA_CHANNEL  : in std_logic_vector(7 downto 0) := x"FF";
    
    timestamp           : in unsigned(31 downto 0) := (others => '0');

    data_LArPix         : in std_logic_vector(C_LARPIX_DATA_WIDTH-1 downto 0);
    data_update_LArPix  : in std_logic;
    busy_LArPix         : out std_logic;
    
    M_AXIS_ACLK	        : in std_logic;
    M_AXIS_ARESETN	: in std_logic;
		
    M_AXIS_TVALID	: out std_logic;
    M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    M_AXIS_TKEEP     : out std_logic_vector(C_M_AXIS_TDATA_WIDTH/8-1 downto 0);
    M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
    M_AXIS_TLAST	: out std_logic;
    M_AXIS_TREADY	: in std_logic
    );
end larpix_to_axi_stream;

architecture implementation of larpix_to_axi_stream is                     

  type state is ( IDLE,
                  TX,
                  TX_DONE );                                                            
  signal  mst_exec_state : state;

  signal data_out       : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
  signal axis_tvalid	: std_logic;
	
  signal busy : std_logic;

begin
  -- I/O Connections assignments
  M_AXIS_TVALID	<= axis_tvalid;
  M_AXIS_TDATA	<= data_out;
  M_AXIS_TLAST	<= '1';
  M_AXIS_TKEEP  <= (others => '1');
  M_AXIS_TSTRB	<= (others => '1');

  busy_LArPix <= busy;

  -- Control state machine implementation                                               
  process(M_AXIS_ACLK)
  begin
    if (rising_edge (M_AXIS_ACLK)) then
      -- synchronous reset
      if(M_AXIS_ARESETN = '0') then
        mst_exec_state <= IDLE;
        axis_tvalid <= '0';
        busy <= '1';
      else
        -- axi-stream fsm
        case (mst_exec_state) is
          when IDLE =>
            busy <= '0';
            axis_tvalid <= '0';
            if (data_update_LArPix = '1') then
              busy <= '1';
              axis_tvalid <= '1';
              data_out <= data_LArPix & x"0000" & std_logic_vector(timestamp) & C_M_AXIS_TDATA_CHANNEL & C_M_AXIS_TDATA_TYPE;
              mst_exec_state <= TX;
            end if;

          when TX =>
            busy <= '1';
            axis_tvalid <= '1';
            if (M_AXIS_TREADY = '1') then
              busy <= '1';
              axis_tvalid <= '0';
              mst_exec_state <= TX_DONE;
            end if;
            
          when TX_DONE =>
            busy <= '1';
            axis_tvalid <= '0';
            if (data_update_LArPix = '0') then
              busy <= '0';
              axis_tvalid <= '0';
              mst_exec_state <= IDLE;
            end if;
            
          when others =>
            mst_exec_state <= IDLE;
        end case;  
      end if;
    end if;
  end process;
        
end implementation;
