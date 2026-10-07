library  ieee;
use ieee.std_logic_1164 .all;
use ieee.numeric_std .all;
entity tx is


port (
clk:in std_logic ;
reset:in std_logic ;
load:in std_logic ;
data_in: in std_logic_vector (7 downto 0);
baud_tick: in std_logic ;
tx_bit:out std_logic ;
done :out std_logic );
end tx;

architecture  tx1 of tx is
signal tx_reg:std_logic ;--DATA ASSIGNMENT TO TXLINE
signal bit_count:integer range 0 to 7;--TO COUNT NUMBER OF BITS
signal reg:std_logic_vector  (7 downto 0);-- 
signal done_reg:std_logic ;-- TO PREVENT DONE TO BE ASSERTED AT SAME CYCLE IN FSM 
begin
process(clk)
    begin
        if rising_edge (clk) then
            if(reset='1') then
                tx_reg<='0';
                bit_count<=0;
                done_reg<='0';
            elsif (load='1') then
                reg<=data_in;
                bit_count<=0;
                done_reg<='0';
            elsif(baud_tick='1') then
                tx_reg<=reg(bit_count);
                if(bit_count /= 7) then
                    bit_count<=(bit_count)+1;
                elsif(bit_count=7) then
                    done_reg<='1';
                end if;
            else
                tx_reg<=tx_reg;
                done_reg<=done_reg;
            end if;
--at the rising edge and baudtick the donereg will be set to 1 due to delta delay it doesnt apply in next posedge baud tick is 0 so itll  wait till next baud tick
    end if;

end process;
done<=done_reg;--ASSIGNMENT OF DONEREG TO DONE (ITLL DELAY ASSIGNNET TILL BEXT CYCLE WHICH ALLOWS FSM TO COMPLETE LAST BIT TRASNMISSION BEFORE IT ASSERTS DONE SIGNAL
tx_bit<=tx_reg;
end tx1;