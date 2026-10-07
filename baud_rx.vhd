library ieee;
use ieee.std_logic_1164 .all;
use ieee.numeric_std .all;
entity baud_rx is
generic( BAUD_RX: integer:=9600;
CLK_FREQ:integer := 50000000;
OVERSAMPLING_FACT:integer:=16);
port(
clk:in std_logic ;
reset:in std_logic ;
sample_tick:out std_logic );
end baud_rx;
architecture baud_tick_rx of baud_rx is
constant RX_COUNT:integer:=((CLK_FREQ)/(OVERSAMPLING_FACT*BAUD_RX));
signal counter:integer range 0 to RX_COUNT-1;
begin
process(clk)
begin
        if rising_edge (clk) then
            if(reset='1')then
                sample_tick<='0';
                counter<=0;
            elsif(counter=RX_COUNT-1) then
                sample_tick<='1';
                counter<=0;
            else
                counter<=counter+1;
                sample_tick<='0';
            end if;
        end if;
end process;
end baud_tick_rx;