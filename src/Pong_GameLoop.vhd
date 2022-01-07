library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;  	
use work.all;
use work.pong_utils_pkg.all;

entity Pong_GameLoop is 
    
   	generic (clock_speed : integer
   	);
    port (
	clk, reset : in std_logic;
	matrix : out matrix_points;
	score_left, score_right : out unsigned(6 downto 0);
	joystick_input : in std_logic_vector(11 downto 0)
	);
end Pong_GameLoop;

architecture arch of Pong_GameLoop is	
signal done : std_logic;  
signal curr_matrix : matrix_points;	 
signal game_state : GAME_STATE := NEW_GAME;

signal score_right_s, score_left_s : integer range 0 to 99;

begin									    
	
	process(all)
    constant paddle_start_pos : integer := (game_pixel_width / 2) - 2;
	constant screen_border_pixel : integer := game_pixel_width - 1;
	
	variable ball : ball_info := (x_pos => to_unsigned(6, ball_info.x_pos'length),
							y_pos => to_unsigned(2, ball_info.y_pos'length),
							going_right => '1',
							going_up => '1');
	variable paddle_left : paddle_info := (is_right_side => '0', y_pos => to_unsigned(paddle_start_pos, paddle_info.y_pos'length));
	variable paddle_right : paddle_info := (is_right_side => '1', y_pos => to_unsigned(paddle_start_pos, paddle_info.y_pos'length));
	variable clock_count : integer range 0 to clock_speed * 3;

	begin		
        if rising_edge(clk) then
			
			if (reset = '1' or game_state = NEW_MATCH) then 	
			    
				-- init signals
				ball := (   x_pos => to_unsigned(4, ball_info.x_pos'length),
							y_pos => to_unsigned(2, ball_info.y_pos'length),
							going_right => '1',
							going_up => '1'); 
				paddle_left.y_pos := to_unsigned(paddle_start_pos, paddle_left.y_pos'length);	  
				paddle_right.y_pos := to_unsigned(paddle_start_pos, paddle_right.y_pos'length);

				
				-- call function to get matrix from ball and paddles
				curr_matrix <= generate_matrix(ball, paddle_left, paddle_right);
				
				if ( reset = '1') then
                    score_left_s <= 0;
                    score_right_s <= 0;
                    clock_count := 0;
                    game_state <= NEW_MATCH;	

				elsif(clock_count >= clock_speed * 3) then
				    game_state <= MATCH_ONGOING;
				    
				else 
				    clock_count := clock_count + 1;
				end if;
			
			elsif (game_state = MATCH_ONGOING) then
			
				
				-- If one second has passed, go to the next frame
				if (clock_count = clock_speed / 3) then	
					-- Check if one side scored
					if(ball.x_pos = 0) then
						score_left_s <= score_left_s + 1;
						game_state <= NEW_MATCH;
						clock_count := 0;
					elsif(ball.x_pos = screen_border_pixel) then
						score_right_s <= score_right_s +1;
						game_state <= NEW_MATCH;
						clock_count := 0;
					else	 
						-- Collision logic
						if(ball.y_pos = 0 or ball.y_pos = screen_border_pixel) then
							ball.going_up := not ball.going_up;
						end if;													  
						if(is_ball_on_paddle(ball, paddle_left, paddle_right)) then
							ball.going_right := not ball.going_right;	
						end if;
						-- X movement
						with ball.going_right select ball.x_pos :=
							ball.x_pos + 1 when '1',
							ball.x_pos -1 when others;	
						-- Y movement
						with ball.going_up select ball.y_pos :=
							ball.y_pos + 1 when '1',
							ball.y_pos -1 when others;	   
						
						-- Paddle Movement
						if ( (unsigned(joystick_input) > (x"FFF" * 2/3)) and not (paddle_left.y_pos = 0) ) then
							paddle_left.y_pos := paddle_left.y_pos - 1;
							paddle_right.y_pos := paddle_right.y_pos - 1;
						elsif ( (unsigned(joystick_input) < (x"FFF" * 1/3)) and not (paddle_left.y_pos = (screen_border_pixel - paddle_size + 1)) ) then
							paddle_left.y_pos := paddle_left.y_pos + 1;
							paddle_right.y_pos := paddle_right.y_pos + 1;
						else
							paddle_left.y_pos := paddle_left.y_pos;
							paddle_right.y_pos := paddle_right.y_pos;
						end if;
							
						-- Generate new matrix with ball and paddles	   
						curr_matrix <= generate_matrix(ball, paddle_left, paddle_right);
					end if;
					
					clock_count := 0;
				else
					clock_count := clock_count + 1;
				end if;	 
			end if;
		end if;					
    end process;
   
    matrix <= curr_matrix;	
    score_right <= to_unsigned(score_right_s, score_right);
    score_left <= to_unsigned(score_left_s, score_left;
end arch;