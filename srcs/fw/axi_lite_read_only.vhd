library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_lite_read_only is
  generic (
    C_S_AXI_LITE_DATA_WIDTH  : integer  := 32;
    C_S_AXI_LITE_ADDR_WIDTH  : integer  := 32;

    C_REG0_OFFSET : std_logic_vector(11 downto 0) := x"000";
    C_REG1_OFFSET : std_logic_vector(11 downto 0) := x"004";
    C_REG2_OFFSET : std_logic_vector(11 downto 0) := x"008";
    C_REG3_OFFSET : std_logic_vector(11 downto 0) := x"00C"
  );
  port (
    -- registers available from axi at specified offsets
    REG0            : in std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    REG1            : in std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    REG2            : in std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    REG3            : in std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    
    -- axi signals
    S_AXI_LITE_ACLK  : in std_logic;
    S_AXI_LITE_ARESETN  : in std_logic;

    S_AXI_LITE_AWADDR  : in std_logic_vector(C_S_AXI_LITE_ADDR_WIDTH-1 downto 0);
    S_AXI_LITE_AWPROT  : in std_logic_vector(2 downto 0) := "000";
    S_AXI_LITE_AWVALID  : in std_logic;
    S_AXI_LITE_AWREADY  : out std_logic;

    S_AXI_LITE_WDATA  : in std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    S_AXI_LITE_WSTRB  : in std_logic_vector((C_S_AXI_LITE_DATA_WIDTH/8)-1 downto 0);
    S_AXI_LITE_WVALID  : in std_logic;
    S_AXI_LITE_WREADY  : out std_logic;
                
    S_AXI_LITE_BRESP  : out std_logic_vector(1 downto 0);
    S_AXI_LITE_BVALID  : out std_logic;
    S_AXI_LITE_BREADY  : in std_logic;
    
    S_AXI_LITE_ARADDR  : in std_logic_vector(C_S_AXI_LITE_ADDR_WIDTH-1 downto 0);
    S_AXI_LITE_ARPROT  : in std_logic_vector(2 downto 0) := "000";
    S_AXI_LITE_ARVALID  : in std_logic;
    S_AXI_LITE_ARREADY  : out std_logic;

    S_AXI_LITE_RDATA  : out std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    S_AXI_LITE_RRESP  : out std_logic_vector(1 downto 0);
    S_AXI_LITE_RVALID  : out std_logic;
    S_AXI_LITE_RREADY  : in std_logic
  );
end axi_lite_read_only;

architecture arch_imp of axi_lite_read_only is

  -- AXI4LITE signals
  signal axi_awaddr  : std_logic_vector(C_S_AXI_LITE_ADDR_WIDTH-1 downto 0);
  signal axi_awready  : std_logic;
  signal axi_wready  : std_logic;
  signal axi_bresp  : std_logic_vector(1 downto 0);
  signal axi_bvalid  : std_logic;
  signal axi_araddr  : std_logic_vector(C_S_AXI_LITE_ADDR_WIDTH-1 downto 0);
  signal axi_arready  : std_logic;
  signal axi_rdata  : std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
  signal axi_rresp  : std_logic_vector(1 downto 0);
  signal axi_rvalid  : std_logic;

  ------------------------------------------------
  ---- Signals for user logic register space example
  --------------------------------------------------
  ---- Number of Slave Registers 4
  signal slv_reg0  :std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
  signal slv_reg1  :std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
  signal slv_reg2  :std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
  signal slv_reg3  :std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
  signal slv_reg_rden  : std_logic;
  signal slv_reg_wren  : std_logic;
  signal reg_data_out  :std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
  signal byte_index  : integer;
  signal aw_en  : std_logic;

begin
  -- I/O Connections assignments
  S_AXI_LITE_AWREADY  <= axi_awready;
  S_AXI_LITE_WREADY  <= axi_wready;
  S_AXI_LITE_BRESP  <= axi_bresp;
  S_AXI_LITE_BVALID  <= axi_bvalid;
  S_AXI_LITE_ARREADY  <= axi_arready;
  S_AXI_LITE_RDATA  <= axi_rdata;
  S_AXI_LITE_RRESP  <= axi_rresp;
  S_AXI_LITE_RVALID  <= axi_rvalid;

  -- Address write ready (AWREADY)
  process (S_AXI_LITE_ACLK)
  begin
    if rising_edge(S_AXI_LITE_ACLK) then 
      if S_AXI_LITE_ARESETN = '0' then
        axi_awready <= '0';
        aw_en <= '1';
      else
        if (axi_awready = '0' and S_AXI_LITE_AWVALID = '1' and S_AXI_LITE_WVALID = '1' and aw_en = '1') then
             axi_awready <= '1';
             aw_en <= '0';
          elsif (S_AXI_LITE_BREADY = '1' and axi_bvalid = '1') then
             aw_en <= '1';
             axi_awready <= '0';
        else
          axi_awready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Address latch (AWADDR)
  process (S_AXI_LITE_ACLK)
  begin
    if rising_edge(S_AXI_LITE_ACLK) then 
      if S_AXI_LITE_ARESETN = '0' then
        axi_awaddr <= (others => '0');
      else
        if (axi_awready = '0' and S_AXI_LITE_AWVALID = '1' and S_AXI_LITE_WVALID = '1' and aw_en = '1') then
          axi_awaddr <= S_AXI_LITE_AWADDR;
        end if;
      end if;
    end if;                   
  end process; 

  -- Data write ready (WREADY)
  process (S_AXI_LITE_ACLK)
  begin
    if rising_edge(S_AXI_LITE_ACLK) then 
      if S_AXI_LITE_ARESETN = '0' then
        axi_wready <= '0';
      else
        if (axi_wready = '0' and S_AXI_LITE_WVALID = '1' and S_AXI_LITE_AWVALID = '1' and aw_en = '1') then
          axi_wready <= '1';
        else
          axi_wready <= '0';
        end if;
      end if;
    end if;
  end process; 

  -- Data write latch (WDATA) (does nothing -> these are read only registers
  slv_reg_wren <= axi_wready and S_AXI_LITE_WVALID and axi_awready and S_AXI_LITE_AWVALID ;

  -- Register inputs
  process (S_AXI_LITE_ACLK)
  variable loc_addr : std_logic_vector(11 downto 0); 
  begin
    if rising_edge(S_AXI_LITE_ACLK) then 
      if S_AXI_LITE_ARESETN = '0' then

      else
        slv_reg0 <= REG0;
        slv_reg1 <= REG1;
        slv_reg2 <= REG2;
        slv_reg3 <= REG3;
      end if;
    end if;                   
  end process; 

  -- Write response (BRESP, BVALID) (always ok)
  process (S_AXI_LITE_ACLK)
  begin
    if rising_edge(S_AXI_LITE_ACLK) then 
      if S_AXI_LITE_ARESETN = '0' then
        axi_bvalid  <= '0';
        axi_bresp   <= "00";
      else
        if (axi_awready = '1' and S_AXI_LITE_AWVALID = '1' and axi_wready = '1' and S_AXI_LITE_WVALID = '1' and axi_bvalid = '0') then
          axi_bvalid <= '1';
          axi_bresp  <= "00"; 
        elsif (S_AXI_LITE_BREADY = '1' and axi_bvalid = '1') then
          axi_bvalid <= '0';
        end if;
      end if;
    end if;                   
  end process; 

  -- Address read ready and address latch (ARREADY, ARADDR)
  process (S_AXI_LITE_ACLK)
  begin
    if rising_edge(S_AXI_LITE_ACLK) then 
      if S_AXI_LITE_ARESETN = '0' then
        axi_arready <= '0';
        axi_araddr  <= (others => '1');
      else
        if (axi_arready = '0' and S_AXI_LITE_ARVALID = '1') then
          axi_arready <= '1';
          axi_araddr  <= S_AXI_LITE_ARADDR;           
        else
          axi_arready <= '0';
        end if;
      end if;
    end if;                   
  end process; 

  -- Read data latch (RDATA)
  slv_reg_rden <= axi_arready and S_AXI_LITE_ARVALID and (not axi_rvalid) ;
  process (slv_reg0, slv_reg1, slv_reg2, slv_reg3, axi_araddr, S_AXI_LITE_ARESETN, slv_reg_rden)
  variable loc_addr :std_logic_vector(11 downto 0);
  begin
      loc_addr := axi_araddr(11 downto 0);
      case loc_addr is
        when C_REG0_OFFSET =>
          reg_data_out <= slv_reg0;
        when C_REG1_OFFSET =>
          reg_data_out <= slv_reg1;
        when C_REG2_OFFSET =>
          reg_data_out <= slv_reg2;
        when C_REG3_OFFSET =>
          reg_data_out <= slv_reg3;
        when others =>
          reg_data_out  <= (others => '0');
      end case;
  end process;
        
  process( S_AXI_LITE_ACLK ) is
  begin
    if (rising_edge (S_AXI_LITE_ACLK)) then
      if ( S_AXI_LITE_ARESETN = '0' ) then
        axi_rdata  <= (others => '0');
      else
        if (slv_reg_rden = '1') then
                axi_rdata <= reg_data_out;
        end if;   
      end if;
    end if;
  end process;

  -- Read data ready and response (RRESP, RVALID)
  process (S_AXI_LITE_ACLK)
  begin
    if rising_edge(S_AXI_LITE_ACLK) then
      if S_AXI_LITE_ARESETN = '0' then
        axi_rvalid <= '0';
        axi_rresp  <= "00";
      else
        if (axi_arready = '1' and S_AXI_LITE_ARVALID = '1' and axi_rvalid = '0') then
          axi_rvalid <= '1';
          axi_rresp  <= "00";
        elsif (axi_rvalid = '1' and S_AXI_LITE_RREADY = '1') then
          axi_rvalid <= '0';
        end if;            
      end if;
    end if;
  end process;

end arch_imp;
