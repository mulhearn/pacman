library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity larpix_trig_to_axi_stream is
  generic(
    C_M_AXIS_TDATA_WIDTH : integer := 128; -- width of AXIS bus
    C_M_AXIS_TDATA_TYPE : std_logic_vector(7 downto 0) := x"54" -- ASCII T
    );
  port (
    TRIG_TYPE : in std_logic_vector(7 downto 0);
    TRIG_TIMESTAMP : in unsigned(31 downto 0) := (others => '0');

    -- axi-stream master
    M_AXIS_ACLK	        : in std_logic;
    M_AXIS_ARESETN	: in std_logic;
		
    M_AXIS_TVALID	: out std_logic;
    M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    M_AXIS_TKEEP    : out std_logic_vector(C_M_AXIS_TDATA_WIDTH/8-1 downto 0);
    M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
    M_AXIS_TLAST	: out std_logic;
    M_AXIS_TREADY	: in std_logic
    );
end larpix_trig_to_axi_stream;

architecture implementation of larpix_trig_to_axi_stream is                     

  type state is ( IDLE,
                  TX,
                  TX_WT );                                                            
  signal  mst_exec_state : state;

  signal trig_meta : std_logic;
  signal trig_aclk : std_logic;
  signal trig_prev : std_logic;
  signal trig_type_meta : std_logic_vector(7 downto 0);
  signal trig_type_aclk : std_logic_vector(7 downto 0);
  signal trig_type_prev : std_logic_vector(7 downto 0);
  signal trig_type_latched : std_logic_vector(7 downto 0);
  signal trig_timestamp_meta : unsigned(31 downto 0);
  signal trig_timestamp_aclk : unsigned(31 downto 0);
  signal trig_timestamp_latched : unsigned(31 downto 0);
  
  signal data_out       : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
  signal axis_tvalid	: std_logic;

begin
  -- I/O Connections assignments
  M_AXIS_TVALID	<= axis_tvalid;
  M_AXIS_TDATA	<= data_out;
  M_AXIS_TLAST	<= '1';
  M_AXIS_TKEEP  <= (others => '1');
  M_AXIS_TSTRB	<= (others => '1');

  -- Clock domain crossing
  sync_proc : process (M_AXIS_ACLK) is
  begin
    if (rising_edge(M_AXIS_ACLK)) then
      trig_type_meta <= TRIG_TYPE;
      trig_type_aclk <= trig_type_meta;
      trig_type_prev <= trig_type_aclk;
      trig_timestamp_meta <= TRIG_TIMESTAMP;
      trig_timestamp_aclk <= trig_timestamp_meta;
    end if;
  end process;
  
  -- Control state machine implementation
  master_axis_fsm : process(M_AXIS_ACLK)
  begin
    if (rising_edge(M_AXIS_ACLK)) then
      -- synchronous reset
      if(M_AXIS_ARESETN = '0') then
        mst_exec_state <= IDLE;
        axis_tvalid <= '0';
        
      else
        -- axi-stream fsm
        case (mst_exec_state) is
          when IDLE =>
            axis_tvalid <= '0';
            
            -- rising edge of any trigger bit
            if (((trig_type_aclk xor trig_type_prev) and trig_type_aclk) /= x"00") then
              trig_timestamp_latched <= trig_timestamp_aclk;
              trig_type_latched <= (trig_type_aclk xor trig_type_prev) and trig_type_aclk;
              mst_exec_state <= TX;
            end if;

          when TX =>
            axis_tvalid <= '1';
            data_out <= x"0000000000000000" & std_logic_vector(trig_timestamp_latched) & x"0000" & trig_type_latched & C_M_AXIS_TDATA_TYPE;
            mst_exec_state <= TX_WT;
            
          when TX_WT =>
            axis_tvalid <= '1';
            if (M_AXIS_TREADY = '1') then
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
