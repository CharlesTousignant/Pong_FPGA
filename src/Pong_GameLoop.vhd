library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;  	
use work.all;
use work.pong_utilitaires_pkg.all;



entity Pong_GameLoop is 
   	generic (clock_speed : integer);
    port (
	clk, reset : in std_logic;
	cols, rows : out unsigned(7 downto 0);
	matrix : out matrix_points;
	score_left, score_right : inout unsigned(2 downto 0);
	joystick_input : out std_logic_vector(11 downto 0)
	);
end Pong_GameLoop;

architecture arch of Pong_GameLoop is	
signal done : std_logic;  
signal curr_matrix : matrix_points;	 
signal game_state : GAME_STATE := NEW_GAME;

begin									    
	
	module_pong : entity Pong_8x8Matrix(arch)
    port map (
	    clk => clk,
		matrix => curr_matrix, 
		cols => cols,
		rows => rows
    );	  	
	matrix <= curr_matrix;

	process(all)
	variable ball : ball_info := (x_pos => to_unsigned(6, 3),
							y_pos => to_unsigned(2, 3),
							going_right => '1',
							going_up => '1');
	variable paddle_left : paddle_info := (is_right_side => '0', y_pos => to_unsigned(2, paddle_info.y_pos'length));
	variable paddle_right : paddle_info := (is_right_side => '1', y_pos => to_unsigned(2, paddle_info.y_pos'length));
	variable clock_count : integer;
	begin
			

			
        if rising_edge(clk) then
			
			if (reset = '1') then 	
				-- init all positions
				ball := (x_pos => to_unsigned(4, 3),
							y_pos => to_unsigned(2, 3),
							going_right => '1',
							going_up => '1'); 
				paddle_left.y_pos := to_unsigned(2, paddle_left.y_pos'length);	  
				paddle_right.y_pos := to_unsigned(2, paddle_right.y_pos'length);
				
				-- call function to get matrix from ball and paddles
				curr_matrix <= generate_matrix(ball, paddle_left, paddle_right);

				clock_count := 0;
				game_state <= NEW_MATCH;	
				
			elsif (game_state = NEW_MATCH ) then	
				if (clock_count >= clock_speed) then
					ball := (x_pos => to_unsigned(4, 3),
								y_pos => to_unsigned(2, 3),
								going_right => '1',
								going_up => '1'); 
					paddle_left.y_pos := to_unsigned(2, paddle_left.y_pos'length);	  
					paddle_right.y_pos := to_unsigned(2, paddle_right.y_pos'length);	
					curr_matrix <= generate_matrix(ball, paddle_left, paddle_right);
					
					game_state <= MATCH_ONGOING;
					clock_count := 0;			   
				else
					clock_count := clock_count + 1;
				end if;
			
			elsif (game_state = MATCH_ONGOING) then
			
				
				-- If one second has passed, go to the next frame
				if (clock_count = clock_speed) then	
					-- Check if one side scored
					if(ball.x_pos = 0) then
						score_left <= score_left + 1;
						game_state <= NEW_MATCH;
						clock_count := 0;
					elsif(ball.x_pos = 7) then
						score_right <= score_right +1;
						game_state <= NEW_MATCH;
						clock_count := 0;
					else	 
						-- Collision logic
						if(ball.y_pos = 0 or ball.y_pos = 7) then
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
						if (unsigned(joystick_input) > x"FFF" * 2/3) then
							paddle_left.y_pos := paddle_left.y_pos - 1;
						elsif (unsigned(joystick_input) < x"FFF" * 1/3) then
							paddle_left.y_pos := paddle_left.y_pos + 1;
						else
							paddle_left.y_pos := paddle_left.y_pos;
						end if;
							
						-- Generate new matrix with ball and paddles	   
						curr_matrix <= generate_matrix(ball, paddle_left, paddle_right);

					end if;

					clock_count := 0;
				
				else
					clock_count := clock_count + 1;
				end if;	 
				
			elsif (game_state = GAME_OVER) then
 				 clock_count := 0;
			end if;
		end if;
		

							
   end process;
end arch;