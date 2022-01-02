library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;	  
use work.fixed_generic_pkg_mod.all;

package pong_utilitaires_pkg is
	type matrix_points is array(0 to 7) of unsigned(7 downto 0); 
	type ball_info is record
		x_pos : unsigned(2 downto 0);
		y_pos : unsigned(2 downto 0);
		going_right : std_logic; 
		going_up : std_logic;
	end record;													 
	type paddle_info is record
		is_right_side : std_logic;
		y_pos : unsigned(2 downto 0);	
	end record;
	type GAME_STATE is (NEW_GAME, NEW_MATCH, MATCH_ONGOING, GAME_OVER);	  
	
	function generate_matrix(ball: ball_info; paddle_left : paddle_info; paddle_right : paddle_info) return matrix_points; 
	function is_ball_on_paddle(	ball: ball_info; paddle_left : paddle_info; paddle_right : paddle_info) return std_logic;
	
	constant H_RES : integer := 100;
	constant V_RES : integer := 100;
	-- black and white for now		   
	type row_info is array(0 to H_RES) of std_logic_vector(3 downto 0);
	type frame_info is array(0 to V_RES) of row_info;
	
 	type im_num is array(0 to 1) of ufixed(3 downto -20);
--	function getImFromPix(x_pix : integer range 0 to H_RES; y_pix : integer range 0 to V_RES) return im_num;
end package;	   

package body pong_utilitaires_pkg is  
	
	function generate_matrix(ball: ball_info; paddle_left :paddle_info; paddle_right : paddle_info) return matrix_points is
	variable matrix_to_return : matrix_points := (others => x"00");
    begin	
		-- Place ball in matrix
		for i in 0 to 7 loop
			if(ball.y_pos = i) then
				matrix_to_return(i) := x"00" or to_unsigned(2 ** to_integer (ball.x_pos), 8);
			else
				matrix_to_return(i) := x"00"; 
			end if;
		end loop;				
		
		for i in 0 to 3 loop 
			matrix_to_return(to_integer(paddle_left.y_pos + i)) := matrix_to_return(to_integer(paddle_left.y_pos + i)) or X"80";
			matrix_to_return(to_integer(paddle_right.y_pos + i)) := matrix_to_return(to_integer(paddle_right.y_pos + i)) or X"01";
		end loop;
        return matrix_to_return;
		
    end;								   
	
	function is_ball_on_paddle(	ball: ball_info; paddle_left : paddle_info; paddle_right : paddle_info) return std_logic is
	begin
		if(ball.x_pos = 6) then
			if (ball.y_pos >= paddle_left.y_pos) then
				if(paddle_left.y_pos = 4) then
					return '1';
				elsif ( ball.y_pos <= paddle_left.y_pos + 4) then
					return '1';	 
				end if;
			end if;
		elsif(ball.x_pos = 1) then
			if (ball.y_pos >= paddle_right.y_pos) then
				if(paddle_right.y_pos = 4) then
					return '1';
				elsif (ball.y_pos <= paddle_right.y_pos + 4) then
					return '1';
				end if;
			end if;
		end if;
		return '0';
	end;
	
end;