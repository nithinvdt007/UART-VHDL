library ieee;
use ieee.std_logic_1164 .all;
use ieee.numeric_std .all;
entity baud_tick is
generic(
 FREQ:integer:=50000000;--CLK FREQ PARAMTERIZED
 BAUDRATE:integer := 9600);  --BAUD RATE PARAMETERIZED                 
port(
clk:in std_logic ;
reset:in std_logic ;
baud:out std_logic;
start: in std_logic ) ;-- BAUD TICK FOR TX
end baud_tick;
architecture baud1 of baud_tick is
constant COUNT:integer:=(FREQ/BAUDRATE);-- CALCULATION OF COUNTS FOR BAUD RATE
signal COUNTER:integer;
begin
process(clk)
    begin
        if rising_edge (clk) then
            if(reset)='1' or start='1'  then
                   COUNTER<=0;
                   baud<='0';
            elsif(COUNTER=COUNT-1) then
                    baud<='1';
                    COUNTER<=0;
            else 
                    baud<='0';
                    COUNTER<=COUNTER+1;
             end if;
         end if;
end process;
end baud1;