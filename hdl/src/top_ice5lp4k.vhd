library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

-- Library provided by the iCECube 2 software package
library sb_ice40_components_syn;
use sb_ice40_components_syn.components.all;

entity top_ice5lp4k is
  generic (
    -- Optional signal inversion - actual CCD drivers are often inverting, but may not be!
    invert_ccd_sh   : std_logic := '1';
    invert_ccd_clk  : std_logic := '1';
    invert_ccd_rs   : std_logic := '1';
    invert_ccd_cp   : std_logic := '1'
  );
  port (
    ccd_sh      : out std_logic;    -- CCD sample & hold
    ccd_clk1    : out std_logic;    -- CCD main clock
    ccd_rs      : out std_logic;    -- CCD 
    ccd_cp      : out std_logic     -- CCD clamp gate
  );
end entity;

architecture impl1 of top_ice5lp4k is
  
    signal clk_48M : std_logic; -- Master clock

    -- "Raw" CCD signals before optional inversion to the output
    signal ccd_sh_raw   : std_logic;
    signal ccd_clk1_raw : std_logic;
    signal ccd_rs_raw   : std_logic;
    signal ccd_cp_raw   : std_logic;

    signal srst         : std_logic; -- Synchronous reset

    signal ccd_integration_trig : std_logic;

begin

-- Invert signals as configured
    ccd_sh <= ccd_sh_raw xor invert_ccd_sh;
    ccd_clk1 <= ccd_clk1_raw xor invert_ccd_clk;
    ccd_rs <= ccd_rs_raw xor invert_ccd_rs;
    ccd_cp <= ccd_cp_raw xor invert_ccd_cp;

-- Internal high frequency oscillator
main_osc: SB_HFOSC
    generic map (
        CLKHF_DIV => "0b00" -- 00 = 48 MHz, 01 = 24 MHz, 10 = 12 MHZ, 11 = 6 MHz
    )
    port map (
        CLKHFEN => '1',
        CLKHFPU => '1',
        CLKHF => clk_48M
    );

-- Power-on reset?
  srst <= '0'; --TODO: implement

-- CCD integration time timer
inttimer: entity work.periodic_trigger
    generic map (
      period => 10_000_000 / 20,
      offset => 0
    )
    port map (
      clk => clk_48M,
      srst => srst,
      q => ccd_integration_trig
    );

-- Actual raw CCD timings generator
ccdtimer: entity work.ccd_sequencer 
    port map (
      clk => clk_48M,
      srst => srst,

      trig => ccd_integration_trig,

      ccd_sh => ccd_sh_raw,
      ccd_ph1 => ccd_clk1_raw,
      ccd_rs => ccd_rs_raw,
      ccd_cp => ccd_cp_raw
  );

end architecture;