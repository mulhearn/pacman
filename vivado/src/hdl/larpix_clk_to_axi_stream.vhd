library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity larpix_clk_to_axi_stream is
  generic(
    C_M_AXIS_TDATA_WIDTH : integer := 128; -- width of AXIS bus
    C_M_AXIS_TDATA_TYPE : std_logic_vector(7 downto 0) := x"53"; -- ASCII S
    C_SYNC_FLAG : std_logic_vector(7 downto 0) := x"53"; -- ASCII S
    C_HB_FLAG : std_logic_vector(7 downto 0) := x"48"; -- ASCII H
    C_CLK_SRC_FLAG : std_logic_vector(7 downto 0) := x"43" -- ASCII C
    );
  port (
    -- mclk'd timestamps
    TIMESTAMP : in unsigned(31 downto 0) := (others => '0');
    TIMESTAMP_PREV : in unsigned(31 downto 0) := (others => '0');
    TIMESTAMP_SYNC : in std_logic;
    CLK_SRC : in std_logic;

    -- heartbeat config
    HB_EN : in std_logic;
    HB_CYCLES : in unsigned(31 downto 0);

    -- axi-stream master
    M_AXIS_ACLK	        : in std_logic;
    M_AXIS_ARESETN	: in std_logic;
		
    M_AXIS_TVALID	: out std_logic;
    M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    M_AXIS_TKEEP        : out std_logic_vector(C_M_AXIS_TDATA_WIDTH/8-1 downto 0);
    M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
    M_AXIS_TLAST	: out std_logic;
    M_AXIS_TREADY	: in std_logic
    );
end larpix_clk_to_axi_stream;

architecture implementation of larpix_clk_to_axi_stream is                     

  attribute ASYNC_REG : string;
  type state is ( IDLE,
                  TX );                                                            
  signal  mst_exec_state : state;

  signal data_out       : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
  signal axis_tvalid	: std_logic;


  signal mclk_prev : std_logic;
  signal timestamp_meta : unsigned(31 downto 0) := (others => '0');
  signal timestamp_aclk : unsigned(31 downto 0) := (others => '0');
  
  signal timestamp_prev_meta : unsigned(31 downto 0) := (others => '0');
  signal timestamp_prev_aclk : unsigned(31 downto 0) := (others => '0');
  signal timestamp_sync_meta : std_logic;
  signal timestamp_sync_aclk : std_logic;
  signal timestamp_sync_prev : std_logic;
  
  signal clk_src_meta : std_logic;
  signal clk_src_aclk : std_logic;
  signal clk_src_prev : std_logic;

  signal hb_counter : unsigned(HB_CYCLES'length-1 downto 0);

  attribute ASYNC_REG of timestamp_meta: signal is "TRUE";
  attribute ASYNC_REG of timestamp_aclk: signal is "TRUE";
  attribute ASYNC_REG of timestamp_prev_meta: signal is "TRUE";
  attribute ASYNC_REG of timestamp_prev_aclk: signal is "TRUE";
  attribute ASYNC_REG of timestamp_sync_meta: signal is "TRUE";
  attribute ASYNC_REG of timestamp_sync_aclk: signal is "TRUE";
  attribute ASYNC_REG of clk_src_meta: signal is "TRUE";
  attribute ASYNC_REG of clk_src_prev: signal is "TRUE";

begin
  -- I/O Connections assignments
  M_AXIS_TVALID	<= axis_tvalid;
  M_AXIS_TDATA	<= data_out;
  M_AXIS_TLAST	<= '1';
  M_AXIS_TKEEP  <= (others => '1');
  M_AXIS_TSTRB	<= (others => '1');

  -- Timestamp sync (clock crossing)
  timestamp_sync_proc : process (M_AXIS_ACLK) is
  begin
    if (rising_edge (M_AXIS_ACLK)) then
      timestamp_meta <= TIMESTAMP;
      timestamp_aclk <= timestamp_meta;
      timestamp_prev_meta <= TIMESTAMP_PREV;
      timestamp_prev_aclk <= timestamp_prev_meta;
      timestamp_sync_meta <= TIMESTAMP_SYNC;
      timestamp_sync_aclk <= timestamp_sync_meta;
      timestamp_sync_prev <= timestamp_sync_aclk;
    end if;
  end process timestamp_sync_proc;

  -- Heartbeat generation
  heartbeat_gen : process(M_AXIS_ACLK) is
  begin
    if (rising_edge(M_AXIS_ACLK)) then
      -- synchronous reset
      if (M_AXIS_ARESETN = '0') then
        hb_counter <= (others => '0');

      -- update counter
      elsif (hb_counter > 0) then
        hb_counter <= hb_counter - 1;
      elsif (hb_counter = 0 and HB_EN = '1') then
        hb_counter <= HB_CYCLES;
      end if;
    end if;
  end process heartbeat_gen;

  -- Clock source switch (clock crossing)
  clk_src_sync_proc : process (M_AXIS_ACLK)
  begin
    if (rising_edge(M_AXIS_ACLK)) then
      clk_src_meta <= CLK_SRC;
      clk_src_aclk <= clk_src_meta;
      clk_src_prev <= clk_src_aclk;
    end if;
  end process clk_src_sync_proc;
  
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
            
            -- falling edge of timestamp_sync
            if (timestamp_sync_aclk = '0' and timestamp_sync_prev = '1') then
              axis_tvalid <= '1';
              data_out <= x"0000000000000000" & std_logic_vector(timestamp_prev_aclk) & x"0000" & C_SYNC_FLAG & C_M_AXIS_TDATA_TYPE;
              mst_exec_state <= TX;

            -- heart beat
            elsif (hb_counter = 0 and HB_EN = '1') then
              axis_tvalid <= '1';
              data_out <= x"0000000000000000" & std_logic_vector(timestamp_aclk) & x"0000" & C_HB_FLAG & C_M_AXIS_TDATA_TYPE;
              mst_exec_state <= TX;

            -- clock source switch
            elsif (not (clk_src_prev = clk_src_aclk)) then
              axis_tvalid <= '1';
              data_out <= x"0000000000000000" & std_logic_vector(timestamp_aclk) & x"000" & "000" & clk_src_aclk & C_CLK_SRC_FLAG & C_M_AXIS_TDATA_TYPE;
            end if;

          when TX =>
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
