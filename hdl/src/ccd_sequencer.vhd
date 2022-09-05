library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity ccd_sequencer is
  port (
    clk:            in std_logic; -- Master clock
    srst:           in std_logic; -- Synchronous reset

    trig:           in std_logic;

    ccd_sh:         out std_logic;
    ccd_ph1:        out std_logic;
    ccd_rs:         out std_logic;
    ccd_cp:         out std_logic
  );
end entity;

architecture impl1 of ccd_sequencer is

    -- There are two parts of the CCD capture waveform:
    -- SH goes high, and the clock signals go quiet
        -- -> "sample" state
    -- SH stays low, and the clock signals keep running
        -- -> "readout" state 

    type state_t is (SAMPLE, READOUT);
    signal state : state_t := READOUT;

    constant clock_ns : natural := 20;

    constant sh_post_delay : natural :=  500 / clock_ns;
    constant sh_start_at : natural   :=    0 / clock_ns;
    constant sh_width    : natural   := 1500 / clock_ns;

    constant ph_length   : natural := 1000 / clock_ns;   
    constant rscp_origin  : natural := ph_length/2 - (310 / clock_ns); --TODO

    constant rs_start_at : natural := rscp_origin;
    constant rs_width    : natural :=  100 / clock_ns;
    constant cp_start_at : natural := rscp_origin + (20 / clock_ns);
    constant cp_width    : natural :=  200 / clock_ns;

    signal sample_counter : unsigned (11 downto 0) := (others => '0');
    signal readout_counter : unsigned(10 downto 0) := (others => '0');

    signal trig_registered : std_logic := '0'; 

begin

    -- t1: should be 500ns, was ~1000ns
    -- t5: should be 500ns, was ~1000ns

    sync1: process(clk) is
    begin
        
        if rising_edge(clk) then
            ccd_sh <= '0';
            ccd_ph1 <= '1';
            ccd_rs <= '0';
            ccd_cp <= '0';  

            if srst = '1' then
                state <= READOUT;
                sample_counter <= (others => '0');
                readout_counter <= (others => '0');
            else      
                case state is
                    when SAMPLE => 
                        readout_counter <= (others => '0');
                        sample_counter <= sample_counter + 1;

                        if sample_counter >= sh_start_at and sample_counter < (sh_start_at + sh_width) then
                            ccd_sh <= '1';
                        end if;
                        if sample_counter >= (sh_start_at + sh_width + sh_post_delay) then
                            sample_counter <= (others => '0');
                            readout_counter <= (others => '0');
                            trig_registered <= '0';
                            state <= READOUT;
                        end if;

                    when READOUT => 
                        readout_counter <= readout_counter + 1;
                        sample_counter <= (others => '0');

                        if (trig = '1') then
                            trig_registered <= '1';
                        end if;

                        if readout_counter >= cp_start_at and readout_counter < (cp_start_at + cp_width) then
                            ccd_cp <= '1';
                        end if;

                        if readout_counter >= rs_start_at and readout_counter < (rs_start_at + rs_width) then
                            ccd_rs <= '1';
                        end if;

                        if readout_counter < ph_length / 2  then
                            ccd_ph1 <= '0';
                        end if;

                        if readout_counter >= ph_length then
                            readout_counter <= (others => '0');

                            if trig_registered = '1' or trig = '1' then
                                state <= SAMPLE;
                                sample_counter <= (others => '0');
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;


end architecture impl1;