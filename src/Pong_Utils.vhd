library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;	  

package pong_utils_pkg is
    constant game_pixel_width : integer := 16;
	type matrix_points is array(0 to game_pixel_width -1) of unsigned(game_pixel_width - 1 downto 0); 
	type ball_info is record
		x_pos : unsigned(3 downto 0);
		y_pos : unsigned(3 downto 0);
		going_right : std_logic; 
		going_up : std_logic;
	end record;				
	
	constant paddle_size : integer := 4;									 
	type paddle_info is record
		is_right_side : std_logic;
		y_pos : unsigned(3 downto 0);	
	end record;
	type GAME_STATE is (NEW_GAME, NEW_MATCH, MATCH_ONGOING);
	
	subtype segments is std_logic_vector(7 downto 0);
	type four_nums is array(0 to 3) of segments;
	
	function generate_matrix(ball: ball_info; paddle_bottom : paddle_info; paddle_top : paddle_info) return matrix_points; 
	function is_ball_on_paddle(	ball: ball_info; paddle_bottom : paddle_info; paddle_top : paddle_info) return std_logic;
	function score_to_four_nums( score_right : unsigned(6 downto 0); score_left : unsigned(6 downto 0)) return four_nums;
	function int_to_segments(num : integer range 0 to 9) return segments;
	
	constant H_RES : integer := 100;
	constant V_RES : integer := 100;
	-- black and white for now		   
	type row_info is array(0 to H_RES) of std_logic_vector(3 downto 0);
	type frame_info is array(0 to V_RES) of row_info;
	
	

--	function getImFromPix(x_pix : integer range 0 to H_RES; y_pix : integer range 0 to V_RES) return im_num;
end package;	   

package body pong_utils_pkg is  
	
	function generate_matrix(ball: ball_info; paddle_bottom :paddle_info; paddle_top : paddle_info) return matrix_points is
	variable matrix_to_return : matrix_points := (others => to_unsigned(0, game_pixel_width));
    begin	
		-- Place ball in matrix
		for i in 0 to (game_pixel_width - 1) loop
			if(ball.y_pos = i) then
				matrix_to_return(i) := to_unsigned(0, game_pixel_width) or to_unsigned(2 ** to_integer (ball.x_pos), game_pixel_width);
			else
				matrix_to_return(i) := to_unsigned(0, game_pixel_width); 
			end if;
		end loop;				
		
		for i in 0 to 3 loop 
			matrix_to_return(to_integer(paddle_bottom.y_pos + i)) := matrix_to_return(to_integer(paddle_bottom.y_pos + i)) or to_unsigned(2 ** (game_pixel_width - 1), game_pixel_width);
			matrix_to_return(to_integer(paddle_top.y_pos + i)) := matrix_to_return(to_integer(paddle_top.y_pos + i)) or to_unsigned(1, game_pixel_width);
		end loop;
       return matrix_to_return;
		
    end;								   
	
	function is_ball_on_paddle(	ball: ball_info; paddle_bottom : paddle_info; paddle_top : paddle_info) return std_logic is
	begin
		if(ball.x_pos = game_pixel_width - 2) then
			if (ball.y_pos >= paddle_bottom.y_pos) then
				if(paddle_bottom.y_pos =  game_pixel_width - paddle_size) then
					return '1';
				elsif ( ball.y_pos <= paddle_bottom.y_pos + paddle_size - 1) then
					return '1';	 
				end if;
			end if;
		elsif(ball.x_pos = 1) then
			if (ball.y_pos >= paddle_top.y_pos) then
				if(paddle_top.y_pos = game_pixel_width - paddle_size) then
					return '1';
				elsif (ball.y_pos <= paddle_top.y_pos + paddle_size - 1) then
					return '1';
				end if;
			end if;
		end if;
		return '0';
	end;
	
	function int_to_segments(num : integer range 0 to 9) return segments is
	begin
	   case num is
            when 0 => return "11000000";
            when 1 => return "11111001";
            when 2 => return "10100100";
            when 3 => return "10110000";
            when 4 => return "10011001";
            when 5 => return "10010010";
            when 6 => return "10000010";
            when 7 => return "11111000";
            when 8 => return "10000000";
            when 9 => return "10010000";
        end case;
	end;
	
	-- Based on code from INF3500 class given by Pierre Langlois
	function score_to_four_nums( score_right : unsigned(6 downto 0); score_left : unsigned(6 downto 0)) return four_nums is
	
	variable to_return : four_nums;
	begin
       for tenths in 9 downto 0 loop
            if score_right >= tenths * 10 then
                to_return(1) := int_to_segments(tenths);
                to_return(0) := int_to_segments(to_integer(score_right) - (tenths * 10));
                exit;
            end if; 
	   end loop;
	   
      for tenths in 9 downto 0 loop
            if score_left >= tenths * 10 then
                to_return(3) := int_to_segments(tenths);
                to_return(2) := int_to_segments(to_integer(score_left) - (tenths * 10));
                exit;
            end if; 
	   end loop;
	   
	   return to_return;
	end;
	
end;