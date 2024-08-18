library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity larpix_trig_gen is
  port (
    MCLK : in std_logic;
    RSTN : in std_logic;
    
    -- configurables
    TRIG_LEN : in unsigned(7 downto 0);
    TRIG0_MASK : in std_logic_vector(7 downto 0);
    TRIG1_MASK : in std_logic_vector(7 downto 0);
    TRIG2_MASK : in std_logic_vector(7 downto 0);
    TRIG3_MASK : in std_logic_vector(7 downto 0);        

    -- trigger inputs
    TRIG0_IN : in std_logic;
    TRIG1_IN : in std_logic;
    TRIG2_IN : in std_logic;
    TRIG3_IN : in std_logic;    

    -- trigger outputs
    TRIG: out std_logic;
    TRIG_TYPE : out std_logic_vector(3 downto 0);
    TRIG_MASKED : out std_logic_vector(7 downto 0)
    );
end larpix_trig_gen;

architecture arch_imp of larpix_trig_gen is

  signal trig0_srg : std_logic_vector(1 downto 0);
  signal trig1_srg : std_logic_vector(1 downto 0);
  signal trig2_srg : std_logic_vector(1 downto 0);
  signal trig3_srg : std_logic_vector(1 downto 0);  
  signal trig0_rx : std_logic;
  signal trig1_rx : std_logic;
  signal trig2_rx : std_logic;
  signal trig3_rx : std_logic;
  
  signal trig_len_meta : unsigned(7 downto 0);
  signal trig_len_mclk : unsigned(7 downto 0);
  signal trig0_mask_meta : std_logic_vector(7 downto 0);
  signal trig0_mask_mclk : std_logic_vector(7 downto 0);
  signal trig1_mask_meta : std_logic_vector(7 downto 0);
  signal trig1_mask_mclk : std_logic_vector(7 downto 0);
  signal trig2_mask_meta : std_logic_vector(7 downto 0);
  signal trig2_mask_mclk : std_logic_vector(7 downto 0);
  signal trig3_mask_meta : std_logic_vector(7 downto 0);
  signal trig3_mask_mclk : std_logic_vector(7 downto 0);
  
  signal trig0_counter : unsigned(7 downto 0);
  signal trig1_counter : unsigned(7 downto 0);
  signal trig2_counter : unsigned(7 downto 0);
  signal trig3_counter : unsigned(7 downto 0);
  
  signal trig0_masked : std_logic_vector(7 downto 0);
  signal trig1_masked : std_logic_vector(7 downto 0);
  signal trig2_masked : std_logic_vector(7 downto 0);
  signal trig3_masked : std_logic_vector(7 downto 0);
  
  signal trig0 : std_logic;
  signal trig1 : std_logic;
  signal trig2 : std_logic;
  signal trig3 : std_logic;
  signal trig_out : std_logic;
  signal trig_type_out : std_logic_vector(3 downto 0);  
  signal trig_masked_out : std_logic_vector(7 downto 0);

begin
  TRIG <= trig0 or trig1 or trig2 or trig3;
  TRIG_TYPE <= trig3 & trig2 & trig1 & trig0;
  TRIG_MASKED <= trig_masked_out;
  trig_masked_out <= trig0_masked or trig1_masked or trig2_masked or trig3_masked;

  glitch_rej : process (MCLK) is
  begin
    if (rising_edge(MCLK)) then
      trig0_srg <= TRIG0_IN & trig0_srg(trig0_srg'length-1 downto 1);
      trig1_srg <= TRIG1_IN & trig1_srg(trig1_srg'length-1 downto 1);
      trig2_srg <= TRIG2_IN & trig2_srg(trig2_srg'length-1 downto 1);
      trig3_srg <= TRIG3_IN & trig3_srg(trig3_srg'length-1 downto 1);      

      if (trig0_srg = "11") then
        trig0_rx <= '1';
      elsif (trig0_srg = "00") then
        trig0_rx <= '0';
      end if;

      if (trig1_srg = "11") then
        trig1_rx <= '1';
      elsif (trig1_srg = "00") then
        trig1_rx <= '0';
      end if;

      if (trig2_srg = "11") then
        trig2_rx <= '1';
      elsif (trig2_srg = "00") then
        trig2_rx <= '0';
      end if;

      if (trig3_srg = "11") then
        trig3_rx <= '1';
      elsif (trig3_srg = "00") then
        trig3_rx <= '0';
      end if;
    end if;
  end process;

  -- sync configurables to mclk
  sync_to_mclk : process (MCLK) is
  begin
    if (rising_edge(MCLK)) then
      trig_len_meta <= TRIG_LEN;
      trig_len_mclk <= trig_len_meta;
      trig0_mask_meta <= TRIG0_MASK;
      trig0_mask_mclk <= trig0_mask_meta;
      trig1_mask_meta <= TRIG1_MASK;
      trig1_mask_mclk <= trig1_mask_meta;
      trig2_mask_meta <= TRIG2_MASK;
      trig2_mask_mclk <= trig2_mask_meta;
      trig3_mask_meta <= TRIG3_MASK;
      trig3_mask_mclk <= trig3_mask_meta;            
    end if;
  end process;  
  
  -- trigger generator
  larpix_trig_fsm : process (MCLK, RSTN) is
  begin
    if (RSTN = '0') then
      trig0 <= '0';
      trig1 <= '0';
      trig2 <= '0';
      trig3 <= '0';
      trig0_masked <= (others => '0');
      trig1_masked <= (others => '0');
      trig2_masked <= (others => '0');
      trig3_masked <= (others => '0');
      trig0_counter <= (others => '0');
      trig1_counter <= (others => '0');
      trig2_counter <= (others => '0');
      trig3_counter <= (others => '0');
      
    elsif (rising_edge(MCLK)) then
      -- update counters
      if (trig0_counter > 0) then
        trig0_counter <= trig0_counter - 1;
      elsif (trig0_rx = '1') then
        trig0_counter <= trig_len_mclk;
      end if;
      
      if (trig1_counter > 0) then
        trig1_counter <= trig1_counter - 1;
      elsif (trig1_rx = '1') then
        trig1_counter <= trig_len_mclk;
      end if;
      
      if (trig2_counter > 0) then
        trig2_counter <= trig2_counter - 1;
      elsif (trig2_rx = '1') then
        trig2_counter <= trig_len_mclk;
      end if;
      
      if (trig3_counter > 0) then
        trig3_counter <= trig3_counter - 1;
      elsif (trig3_rx = '1') then
        trig3_counter <= trig_len_mclk;
      end if;
      
      -- update trigger signals
      if (trig0_counter > 0) then
        trig0 <= '1';
        trig0_masked <= (not trig0_mask_mclk);
      else
        trig0 <= '0';
        trig0_masked <= (others => '0');
      end if;
      
      if (trig1_counter > 0) then
        trig1 <= '1';
        trig1_masked <= (not trig1_mask_mclk);
      else
        trig1 <= '0';
        trig1_masked <= (others => '0');
      end if;
      
      if (trig2_counter > 0) then
        trig2 <= '1';
        trig2_masked <= (not trig2_mask_mclk);
      else
        trig2 <= '0';
        trig2_masked <= (others => '0');
      end if;
      
      if (trig3_counter > 0) then
        trig3 <= '1';
        trig3_masked <= (not trig3_mask_mclk);
      else
        trig3 <= '0';
        trig3_masked <= (others => '0');
      end if;
      
    end if;
  end process;

end arch_imp;
