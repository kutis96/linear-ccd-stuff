library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity periodic_trigger is
  generic (
    period : natural;
    offset : natural
  );
  port (
    clk:            in std_logic; -- Master clock
    srst:           in std_logic; -- Synchronous reset
    q:              out std_logic
  );
end entity;

architecture impl1 of periodic_trigger is
    signal counter : integer := offset;
begin

sync1: process(clk) is

begin
    if rising_edge(clk) then
        q <= '0';
        if srst = '1' then
            counter <= -offset;
        else
            if counter >= (period - 1) then
                counter <= 0;
                q <= '1';
            else
                counter <= counter + 1;
            end if;            
        end if;
    end if;
end process;

end architecture impl1;