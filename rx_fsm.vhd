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