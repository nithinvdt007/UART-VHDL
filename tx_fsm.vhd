library ieee;
use ieee.std_logic_1164 .all;
use ieee.numeric_std .all;

entity tx_fsm is

port(
clk:in std_logic ;
reset:in std_logic ;
start_tx:in std_logic ;
baud_tick:in std_logic ;
tx_bit:in std_logic ;
done:in std_logic ;
tx_out:out std_logic ;
load:out std_logic ;
busy:out std_logic ;
tx_done:out std_logic );
end tx_fsm;


architecture tx_fsm1 of tx_fsm is
signal startreg:std_logic:='0' ;

type states is(IDLE,START,DATA,STOP);
signal current_state,next_state:states;
begin

process(clk)
    begin
        if rising_edge (clk) then
            if(reset='1') then
                current_state<=IDLE;
                startreg<='0';

            else
                current_state<=next_state;
                if(start_tx='1') then
                startreg<='1';
              elsif current_state = IDLE and startreg = '1' then
              startreg<='0';
              else
              startreg<=startreg;
                end if;
                end if;
                end if;
                
                
end process;

process(current_state,baud_tick,start_tx,tx_bit,done,startreg) 
begin
    tx_out     <= '1';--INITIAL STATE OF TX LINE IS 1
    load       <= '0';
    busy       <= '0';
    tx_done    <= '0';
    next_state <= current_state;
case current_state is
 when IDLE => 
         tx_done<= '0';
         tx_out<='1';
         busy<='0';
         load<='0';
       
         
        if(start_tx='1' or startreg='1') then
         load<='1';
         next_state<=START;
         else 
         next_state<=IDLE;
         end if;
  when START => 
         busy<='1';
        tx_out<='0';
        if(baud_tick='1') then-- we were not waiting for complete baud _tick  the internal counter of baud can be anything(0=434) 
            next_state<=DATA;
        else 
            next_state<=START;
        end if;
        
  when DATA=> 
       busy<='1';
       tx_out<=tx_bit;-- SEND THE BIT FROM THE DATA PATH MODULE INTO FSM OUT LINE
       if(done='1') and baud_tick='1' then-- wait cause in data path done is scheduled to update and the clck edge its still zero so it can wor
            next_state<=STOP;
       else
            next_state<=DATA;
       end if;
  when STOP=>
       busy<='1';
       tx_out<= '1';
       if(baud_tick='1') then
             next_state<=IDLE;
             tx_done<='1';
       else
             next_state<=STOP;
       end if;
  end case;
  end process;
  end tx_fsm1;