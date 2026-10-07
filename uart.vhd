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

-- TRANSMITTER TX MODULE

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


--TRANSMITTER FSM CONTROLLER

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
  
       
--RX LOGIC

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

-- RX FSM 


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_fsm is
    port(
        clk         : in  std_logic;
        reset       : in  std_logic;
        sample_tick : in  std_logic;
        tx_line     : in  std_logic;
        data_out    : out std_logic_vector(7 downto 0);
        rx_done     : out std_logic;
        busy        : out std_logic;
        error       : out std_logic
    );
end rx_fsm;

architecture rxfsm1 of rx_fsm is  
    type states is (IDLE, START, DATA, STOP);
    signal current_state, next_state : states;
    
    signal sample_count        : integer range 0 to 15 := 0;
    signal data_count          : integer range 0 to 7  := 0;
    signal data_sample_count   : integer range 0 to 15 := 0;
    signal stop_sample_count   : integer range 0 to 15 := 0;
    
    signal sample6, sample7, sample8 : std_logic := '0';
    signal r_data_out                : std_logic_vector(7 downto 0);
begin

    -- Synchronous Process: State transitions and counter updates
    process(clk)
    begin
        if rising_edge(clk) then
            if (reset = '1') then
                current_state       <= IDLE;
                sample_count        <= 0;
                data_count          <= 0;
                data_sample_count   <= 0;
                stop_sample_count   <= 0;
                r_data_out          <= (others => '0');
            else
                current_state <= next_state;
                end if;
                
                if current_state = IDLE and next_state = START then
                    r_data_out        <= (others => '0');
                    data_count        <= 0;
                    data_sample_count <= 0;
                    sample_count      <= 0;
                    stop_sample_count <= 0;
                end if;
                
                if current_state = START and next_state = DATA then
                    data_count        <= 0;  
                    data_sample_count <= 0;  
                end if;

                if sample_tick = '1' then
                    case current_state is
                        when START =>
                            if sample_count = 7 and tx_line /= '0' then
                                sample_count <= 0;
                            elsif sample_count = 15 then
                                sample_count      <= 0;
                                data_count        <= 0;        
                                data_sample_count <= 0; 
                            else
                                sample_count <= sample_count + 1;
                            end if;

                        when DATA =>
                            if data_sample_count = 6 then
                                sample6 <= tx_line;
                            elsif data_sample_count = 7 then
                                sample7 <= tx_line;
                            elsif data_sample_count = 8 then
                                sample8 <= tx_line;
                            end if;

                            if data_sample_count = 9 then
                                r_data_out(data_count) <= (sample6 and sample7) or (sample7 and sample8) or (sample8 and sample6);
                            end if;

                            if data_sample_count = 15 and data_count = 7 then
                                data_sample_count <= 0;
                                data_count        <= 0;
                            elsif data_sample_count = 15 then
                                data_count        <= data_count + 1;
                                data_sample_count <= 0;
                            else
                                data_sample_count <= data_sample_count + 1;
                            end if;

                        when STOP =>
                            if stop_sample_count = 7 and tx_line /= '1' then
                                stop_sample_count <= 0;
                            elsif stop_sample_count = 15 then
                                stop_sample_count <= 0;
                            else
                                stop_sample_count <= stop_sample_count + 1;
                            end if;

                        when others =>
                            null;
                    end case;
                end if;
            end if;
      
    end process;

    -- Combinational Process: Next state logic and outputs
    process(current_state, sample_tick, tx_line, sample_count, data_count, data_sample_count, stop_sample_count)  
    begin
        next_state <= current_state;
        rx_done    <= '0';
        error      <= '0';
        busy       <= '1';

        case current_state is
            when IDLE =>
                busy <= '0';
                if tx_line = '0' then
                    next_state <= START;
                else
                    next_state <= IDLE;
                end if;

            when START =>
                if sample_tick = '1' then
                    if sample_count = 7 and tx_line /= '0' then
                        next_state <= IDLE;
                    elsif sample_count = 15 then
                        next_state <= DATA;
                    end if;
                end if;

            when DATA =>
                if sample_tick = '1' then
                    if data_sample_count = 15 and data_count = 7 then
                        next_state <= STOP;
                    end if;
                end if;

            when STOP =>
                if sample_tick = '1' then
                    if stop_sample_count = 7 and tx_line /= '1' then
                        error      <= '1';
                        next_state <= IDLE;
                    elsif stop_sample_count = 15 then
                        rx_done    <= '1';
                        next_state <= IDLE;
                    end if;
                end if;
        end case;
    end process;

    data_out <= r_data_out;
end rxfsm1;