library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.math_real.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity whack_a_mole is
    Port ( clock : in  STD_LOGIC;
           start : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           whack : in  STD_LOGIC_VECTOR (3 downto 0);
           mole : out  STD_LOGIC_VECTOR (3 downto 0);
	   led_score : out STD_LOGIC_VECTOR (3 downto 0);
           LCD_E : out  STD_LOGIC;
           LCD_RS : out  STD_LOGIC;
           LCD_RW : out  STD_LOGIC;
           SF_D : out  STD_LOGIC_VECTOR (3 downto 0);
           SF_CE0 : out  STD_LOGIC;
end whack_a_mole;

architecture Behavioral of whack_a_mole is
	--WHACK A MOLE
	type state_type is (idle, game_play, game_over);
	signal state_reg : state_type;
	signal state_next : state_type;
	signal clock2 : STD_LOGIC;
	signal counter : integer;
	signal score : integer range 0 to 12 := 0;
	signal whack_prev : STD_LOGIC_VECTOR (3 downto 0) := "0000";
	
	--LCD
	type tx_sequence is (high_setup, high_hold, oneus, low_setup, low_hold, fortyus, done);
	signal tx_state : tx_sequence := done;
	signal tx_byte : STD_LOGIC_VECTOR(7 downto 0);
	signal tx_init : STD_LOGIC := '0';
	
	type init_sequence is (idle, fifteenms, one, two, three, four, five, six, seven, eight, done);
	signal init_state : init_sequence := idle;
	signal init_init, init_done : STD_LOGIC := '0';
	signal i : integer range 0 to 750000 := 0;
	signal i2 : integer range 0 to 2000 := 0;
	signal i3 : integer range 0 to 82000 := 0;
	signal SF_D0, SF_D1 : STD_LOGIC_VECTOR(3 downto 0);
	signal LCD_E0, LCD_E1 : STD_LOGIC;
	signal mux : STD_LOGIC;
	
	type display_state is (init, function_set, entry_set, set_display, clr_display, pause, set_addr, num_0, num_1, done);
	signal cur_state : display_state := init;

begin

	--CLOCK DIVIDER (SETTING SPEED OF LED)
	process(clock)
		variable counter_clock : integer range 0 to 50000000;	
	begin
		if rising_edge(clock) then
			if counter_clock < 50000000 then
				counter_clock := counter_clock + 1;
			else
				counter_clock := 0;
				clock2 <= not clock2;
			end if;
		end if;
	end process;
	
	--CLOCK PROCESS
	process(clock2, reset)
	begin
		if reset = '1' then
			state_reg <= idle;
		elsif rising_edge(clock2) then
			state_reg <= state_next;
		end if;
	end process;

	--NEXT STATE LOGIC
	process(state_reg, start, reset, counter)
	begin
		case state_reg is
			when idle =>
				if start = '1' then
					state_next <= game_play;
				else
					state_next <= idle;
				end if;
                
			when game_play =>
				if reset = '1' then
					state_next <= idle;
				elsif counter = 8 then
					state_next <= game_over;
				else
					state_next <= game_play;
				end if;
            
			when game_over =>
				if reset = '1' then
					state_next <= idle;
				else
					state_next <= game_over;
				end if;
		end case;
	end process;

	--MEALY OUTPUT LOGIC 
	process(clock2, state_reg, counter, whack, score)
		variable local_mole : std_logic_vector(3 downto 0);
	begin
		if rising_edge(clock2) then
			case state_reg is
				when idle =>
					mole <= "0000";
					counter <= 0;
					score <= 0;
					led_score <= "0000";
						
				when game_play =>
					counter <= counter + 1;
					
					case counter is
						when 0 =>
							mole <= "0001";
							
							if local_mole = "0001" then
								if whack(0) /= whack_prev(0) then
									score <= score + 1;
								else
									score <= score;
								end if;
							else
								score <= score;
							end if;
							
						when 1 =>
							mole <= "0010";
							
							if local_mole = "0010" then
								if whack(1) /= whack_prev(1) then
									score <= score + 1;
								else
									score <= score;
								end if;
							else
								score <= score;
							end if;
							
						when 2 =>
							mole <= "0100";
							
							if local_mole = "0100" then
								if whack(2) /= whack_prev(2) then
									score <= score + 1;
								else
									score <= score;
								end if;
							else
								score <= score;
							end if;
							
						when 3 =>
							mole <= "1000";
							
							if local_mole = "1000" then
								if whack(3) /= whack_prev(3) then
									score <= score + 1;
								else
									score <= score;
								end if;
							else
								score <= score;
							end if;
							
						when 4 =>
							mole <= "1010";
							
							if local_mole = "1010" then
								if whack(1) /= whack_prev(1) and whack(3) /= whack_prev(3) then
									score <= score + 2;
								elsif whack(1) /= whack_prev(1) or whack(3) /= whack_prev(3) then
									score <= score + 1;
								else
									score <= score;
								end if;
							else
								score <= score;
							end if;
							
						when 5 =>
							mole <= "0110";
							
							if local_mole = "0110" then
								if whack(1) /= whack_prev(1) and whack(2) /= whack_prev(2) then
									score <= score + 2;
								elsif whack(1) /= whack_prev(1) or whack(2) /= whack_prev(2) then
									score <= score + 1;
								else
									score <= score;
								end if;
							else
								score <= score;
							end if;
							
						when 6 =>
							mole <= "0011";
							
							if local_mole = "0011" then
								if whack(0) /= whack_prev(0) and whack(1) /= whack_prev(1) then
									score <= score + 2;
								elsif whack(0) /= whack_prev(0) or whack(1) /= whack_prev(1) then
									score <= score + 1;
								else
									score <= score;
								end if;
							else
								score <= score;
							end if;
							
						when 7 =>
							mole <= "0101";
							
							if local_mole = "0101" then
								if whack(0) /= whack_prev(0) and whack(2) /= whack_prev(2) then
									score <= score + 2;
								elsif whack(0) /= whack_prev(0) or whack(2) /= whack_prev(2) then
									score <= score + 1;
								else
									score <= score;
								end if;
							else
								score <= score;
							end if;
						when others =>
							mole <= "0000";
					end case;
					
					whack_prev <= whack;
					
				when game_over =>
					mole <= "1111";
					led_score <= std_logic_vector(to_unsigned(score, 4));
					counter <= 0;
			end case;
		end if;
	end process;

	--LCD
	SF_CE0 <= '1';
	LCD_RW <= '0';
	
	with cur_state select
		tx_init <= '0' when init | pause | done,
		'1' when others;

	with cur_state select
		mux <= '1' when init,
		'0' when others;

	with cur_state select
		init_init <= '1' when init,
		'0' when others;

	with cur_state select
		LCD_RS <= '0' when function_set|entry_set|set_display|clr_display|set_addr,
		'1' when others;

	process (cur_state, score)
	begin
		case cur_state is
			when function_set =>
				tx_byte <= "00101000";
			when entry_set =>
				tx_byte <= "00000110";
			when set_display =>
				tx_byte <= "00001100";
			when clr_display =>
				tx_byte <= "00000001";
			when set_addr =>
				tx_byte <= "10000000";
			when num_0 =>
				case score is
					when 0 =>
						tx_byte <= "00110000";
					when 1 =>
						tx_byte <= "00110000";
					when 2 =>
						tx_byte <= "00110000";
					when 3 =>
						tx_byte <= "00110000";
					when 4 =>
						tx_byte <= "00110000";
					when 5 =>
						tx_byte <= "00110000";
					when 6 =>
						tx_byte <= "00110000";
					when 7 =>
						tx_byte <= "00110000";
					when 8 =>
						tx_byte <= "00110000";
					when 9 =>
						tx_byte <= "00110000";
					when 10 =>
						tx_byte <= "00110001";
					when 11 =>
						tx_byte <= "00110001";
					when 12 =>
						tx_byte <= "00110001";
					when others =>
						tx_byte <= "00000000";
				end case;
			when num_1 =>
				case score is
					when 0 =>
						tx_byte <= "00110000";
					when 1 =>
						tx_byte <= "00110001";
					when 2 =>
						tx_byte <= "00110010";
					when 3 =>
						tx_byte <= "00110011";
					when 4 =>
						tx_byte <= "00110100";
					when 5 =>
						tx_byte <= "00110101";
					when 6 =>
						tx_byte <= "00110110";
					when 7 =>
						tx_byte <= "00110111";
					when 8 =>
						tx_byte <= "00111000";
					when 9 =>
						tx_byte <= "00111001";
					when 10 =>
						tx_byte <= "00110000";
					when 11 =>
						tx_byte <= "00110001";
					when 12 =>
						tx_byte <= "00110011";
					when others =>
						tx_byte <= "00000000";
				end case;
			when others =>
				tx_byte <= "00000000";
		end case;
	end process;

	--main state machine
	display: process(clock, reset, score)
	begin
		if(reset='1') then
			cur_state <= function_set;
		elsif rising_edge(clock) then
			case cur_state is
				when init =>
					if(init_done = '1') then
						cur_state <= function_set;
					else
						cur_state <= init;
					end if;

				when function_set =>
					if(i2 = 2000) then
						cur_state <= entry_set;
					else
						cur_state <= function_set;
					end if;
					
				when entry_set =>
					if(i2 = 2000) then
						cur_state <= set_display;
					else
						cur_state <= entry_set;
					end if;
					
				when set_display =>
					if(i2 = 2000) then
						cur_state <= clr_display;
					else
						cur_state <= set_display;
					end if;
					
				when clr_display =>
					i3 <= 0;
					if(i2 = 2000) then
						cur_state <= pause;
					else
						cur_state <= clr_display;
					end if;
					
				when pause =>
					if(i3 = 82000) then
						cur_state <= set_addr;
						i3 <= 0;
					else
						cur_state <= pause;
						i3 <= i3 + 1;
					end if;
					
				when set_addr =>
					if(i2 = 2000) then
						cur_state <= num_0;
					else
						cur_state <= set_addr;
					end if;
					
				when num_0 =>
					if(i2 = 2000) then
						cur_state <= num_1;
					else
						cur_state <= num_0;
					end if;
					
				when num_1 =>
					if(i2 = 2000) then
						cur_state <= done;
					else
						cur_state <= num_1;
					end if;
						
				when done =>
					cur_state <= done;
			end case;
		end if;
	end process;
	
	with mux select
		SF_D <= SF_D0 when '0',
		SF_D1 when others;
	with mux select
		LCD_E <= LCD_E0 when '0',
		LCD_E1 when others;

	transmit : process(clock, reset, tx_init)
	begin
		if(reset='1') then
			tx_state <= done;
		elsif rising_edge(clock) then
			case tx_state is
				when high_setup =>
					LCD_E0 <= '0';
					SF_D0 <= tx_byte(7 downto 4);
					if(i2 = 2) then
						tx_state <= high_hold;
						i2 <= 0;
					else
						tx_state <= high_setup;
						i2 <= i2 + 1;
					end if;
					
				when high_hold =>
					LCD_E0 <= '1';
					SF_D0 <= tx_byte(7 downto 4);
					if(i2 = 12) then
						tx_state <= oneus;
						i2 <= 0;
					else
						tx_state <= high_hold;
						i2 <= i2 + 1;
					end if;	
					
				when oneus =>
					LCD_E0 <= '0';
					if(i2 = 50) then
						tx_state <= low_setup;
						i2 <= 0;
					else
						tx_state <= oneus;
						i2 <= i2 + 1;
					end if;
					
				when low_setup =>
					LCD_E0 <= '0';
					SF_D0 <= tx_byte(3 downto 0);
					if(i2 = 2) then
						tx_state <= low_hold;
						i2 <= 0;
					else
						tx_state <= low_setup;
						i2 <= i2 + 1;
					end if;
					
				when low_hold =>
					LCD_E0 <= '1';
					SF_D0 <= tx_byte(3 downto 0);
					if(i2 = 12) then
						tx_state <= fortyus;
						i2 <= 0;
					else
						tx_state <= low_hold;
						i2 <= i2 + 1;
					end if;
					
				when fortyus =>
					LCD_E0 <= '0';
					if(i2 = 2000) then
						tx_state <= done;
						i2 <= 0;
					else
						tx_state <= fortyus;
						i2 <= i2 + 1;
					end if;
					
				when done =>
					LCD_E0 <= '0';
					if(tx_init = '1') then
						tx_state <= high_setup;
						i2 <= 0;
					else
						tx_state <= done;
						i2 <= 0;
					end if;
			end case;
		end if;
	end process transmit;

	power_on_initialize: process(clock, reset, init_init)
	begin
		if(reset='1') then
			init_state <= idle;
			init_done <= '0';
		elsif rising_edge(clock) then
			case init_state is
				when idle =>
					init_done <= '0';
					if(init_init = '1') then
						init_state <= fifteenms;
						i <= 0;
					else
						init_state <= idle;
						i <= i + 1;
					end if;
					
				when fifteenms =>
					init_done <= '0';
					if(i = 750000) then
						init_state <= one;
						i <= 0;
					else
						init_state <= fifteenms;
						i <= i + 1;
					end if;
					
				when one =>
					SF_D1 <= "0011";
					LCD_E1 <= '1';
					init_done <= '0';
					if(i = 11) then
						init_state<=two;
						i <= 0;
					else
						init_state<=one;
						i <= i + 1;
					end if;
					
				when two =>
					LCD_E1 <= '0';
					init_done <= '0';
					if(i = 205000) then
						init_state<=three;
						i <= 0;
					else
						init_state<=two;
						i <= i + 1;
					end if;
					
				when three =>
					SF_D1 <= "0011";
					LCD_E1 <= '1';
					init_done <= '0';
					if(i = 11) then
						init_state<=four;
						i <= 0;
					else
						init_state<=three;
						i <= i + 1;
					end if;
					
				when four =>
					LCD_E1 <= '0';
					init_done <= '0';
					if(i = 5000) then
						init_state<=five;
						i <= 0;
					else
						init_state<=four;
						i <= i + 1;
					end if;
					
				when five =>
					SF_D1 <= "0011";
					LCD_E1 <= '1';
					init_done <= '0';
					if(i = 11) then
						init_state<=six;
						i <= 0;
					else
						init_state<=five;
						i <= i + 1;
					end if;
					
				when six =>
					LCD_E1 <= '0';
					init_done <= '0';
					if(i = 2000) then
						init_state<=seven;
						i <= 0;
					else
						init_state<=six;
						i <= i + 1;
					end if;
					
				when seven =>
					SF_D1 <= "0010";
					LCD_E1 <= '1';
					init_done <= '0';
					if(i = 11) then
						init_state<=eight;
						i <= 0;
					else
						init_state<=seven;
						i <= i + 1;
					end if;
					
				when eight =>
					LCD_E1 <= '0';
					init_done <= '0';
					if(i = 2000) then
						init_state<=done;
						i <= 0;
					else
						init_state<=eight;
						i <= i + 1;
					end if;
					
				when done =>
					init_state <= done;
					init_done <= '1';
			end case;
		end if;
	end process power_on_initialize;

end Behavioral;