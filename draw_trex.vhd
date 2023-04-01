library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.STD_LOGIC_UNSIGNED.all;
--use ieee.numeric_std.ALL;
use ieee.std_logic_arith.ALL;

entity draw_trex is
	generic(
		H_counter_size: natural:= 10;
		V_counter_size: natural:= 10
	);
	port(
		clk: in std_logic;
		jump: in std_logic;
		agachar: in std_logic;
		pixel_x: in integer;
		pixel_y: in integer;
		rgbDrawColor: out std_logic_vector(11 downto 0) := (others => '0')
	);
end draw_trex;

architecture arch of draw_trex is
	constant PIX : integer := 16;
	constant COLS : integer := 40;
	constant T_FAC : integer := 100000;
	constant cactusSpeed : integer := 40;
	constant pteroSpeed : integer := 60;
	
	signal cloudX_1: integer := 40;
	signal cloudY_1: integer := 8;
	
	-- VGA Sigs
	signal hCount: integer := 640;
	signal vCount: integer := 480;
	signal nextHCount: integer := 641;
	signal nextVCount: integer := 480;
	
	-- T-Rex
	signal trexX: integer := 8;
	signal trexY: integer := 24;
	signal saltando: std_logic := '0';
	signal abajo : std_logic := '0';

	-- Pterodactyl
	signal pteroX: integer := COLS;
	signal pteroY: integer := 21;
	
	-- Cactus	
	signal resetGame : std_logic := '0';
	signal cactusX_1: integer := COLS;
	signal cactusY: integer := 24;
	
	signal cactusX_2: integer := (COLS/2);
	
	-- Game
	signal gameOver : std_logic := '0';
	

	
	signal gameSpeed: integer := 0;
	
	-- COMPONENT SIGNALS
	signal sclock, cleanJump : std_logic;
	signal d0, d10, d100 : std_logic_vector (3 downto 0);
	signal disp1, disp2, disp3 : std_logic_vector (6 downto 0);
	
	
	
-- Sprites
type sprite_block is array(0 to 15, 0 to 15) of integer range 0 to 1;
type sprite_block_2 is array(0 to 15, 0 to 25) of integer range 0 to 1;
constant cloud: sprite_block:=(  (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 0 
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 1 
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 2
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 3
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 4
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 5
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 6
											 (0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0), -- 7
											 (0,0,0,0,0,1,1,0,0,0,1,1,1,1,0,0), -- 8
											 (0,1,1,1,1,1,0,0,0,0,0,0,0,1,1,1), -- 9
											 (1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1), -- 10
											 (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1), -- 11
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 12
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 13
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 14
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));-- 15
									 
constant cloud_2: sprite_block:=(  (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 0 
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 1 
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 2
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 3
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 4
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 5
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 6
											 (0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0), -- 7
											 (0,0,0,0,0,1,1,0,0,0,1,1,1,1,0,0), -- 8
											 (0,1,1,1,1,1,0,0,0,0,0,0,0,1,1,1), -- 9
											 (1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1), -- 10
											 (1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1), -- 11
											 (0,0,1,1,0,1,1,1,0,1,1,1,1,0,0,0), -- 12
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 13
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 14
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));-- 15
									 
constant cloud_3: sprite_block:=(  (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 0 
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 1 
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 2
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 3
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 4
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 5
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 6
											 (0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0), -- 7
											 (0,0,0,0,0,1,1,0,0,0,1,1,1,1,0,0), -- 8
											 (0,1,1,1,1,1,0,0,0,0,0,0,0,1,1,1), -- 9
											 (1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1), -- 10
											 (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1), -- 11
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 12
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 13
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 14
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));-- 15
									 
constant moon: sprite_block:=(  (0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0), -- 0 
										 (0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0), -- 1 
										 (0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0), -- 2
										 (0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0), -- 3
										 (0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0), -- 4
										 (0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0), -- 5
										 (0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0), -- 6
										 (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1), -- 7
										 (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1), -- 8
										 (0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0), -- 9
										 (0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0), -- 10
										 (0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0), -- 11
										 (0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0), -- 12
										 (0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0), -- 13
										 (0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0), -- 14
										 (0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0));-- 15

constant star: sprite_block:=(  (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 0 
										 (0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0), -- 1 
										 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 2
										 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 3
										 (0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0), -- 4
										 (0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0), -- 5
										 (0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0), -- 6
										 (0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0), -- 7
										 (0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0), -- 8
										 (0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0), -- 9
										 (0,0,0,0,0,1,1,1,1,1,1,1,0,0,0,0), -- 10
										 (0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0), -- 11
										 (0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0), -- 12
										 (0,0,0,1,1,1,1,1,0,1,1,1,1,1,0,0), -- 13
										 (0,0,0,1,1,1,1,0,0,0,1,1,1,1,0,0), -- 14
										 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));-- 15
									 
constant trex_2: sprite_block:=((0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0), -- 0 
											(0,0,0,0,0,0,0,1,1,0,1,1,1,1,1,1), -- 1 
											(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1), -- 2
											(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1), -- 3
											(0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0), -- 4
											(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0), -- 5
											(0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0), -- 6
											(1,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0), -- 7
											(1,1,0,0,1,1,1,1,1,1,1,0,0,1,0,0), -- 8
											(1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0), -- 9
											(0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 10
											(0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 11
											(0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0), -- 12
											(0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0), -- 13
											(0,0,0,0,0,1,1,0,1,0,0,0,0,0,0,0), -- 14
											(0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0));-- 15	

constant trex_dead: sprite_block:=( (0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0), -- 0 
												(0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1), -- 1 
												(0,0,0,0,0,0,0,1,0,1,0,1,1,1,1,1), -- 2
												(0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1), -- 3
												(0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1), -- 4
												(0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0), -- 5
												(0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0), -- 6
												(1,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0), -- 7
												(1,1,0,0,1,1,1,1,1,1,1,0,0,1,0,0), -- 8
												(1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0), -- 9
												(0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 10
												(0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0), -- 11
												(0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0), -- 12
												(0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0), -- 13
												(0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0), -- 14
												(0,0,0,0,0,1,1,0,1,1,0,0,0,0,0,0));-- 15

constant trex_1: sprite_block_2:=(  (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 0 
												(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 1 
												(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 2
												(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 3
												(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 4
												(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 5
												(1,0,0,0,0,0,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,0,0,0,0), -- 6
												(1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,0,0,0), -- 7
												(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0), -- 8
												(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0), -- 9
												(0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0), -- 10
												(0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,0,0,0,0), -- 11
												(0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 12
												(0,0,0,0,0,1,0,0,1,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0), -- 13
												(0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 14
												(0,0,0,0,0,1,1,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));-- 15

constant cactus: sprite_block :=((0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0), -- 0 
										 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 1 
										 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 2
										 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 3
										 (0,0,0,0,0,1,0,1,1,1,0,1,0,0,0,0), -- 4
										 (0,0,0,0,1,1,0,1,1,1,0,1,0,0,0,0), -- 5
										 (0,0,0,0,1,1,0,1,1,1,0,1,0,0,0,0), -- 6
										 (0,0,0,0,1,1,0,1,1,1,0,1,0,0,0,0), -- 7
										 (0,0,0,0,1,1,0,1,1,1,0,1,0,0,0,0), -- 8
										 (0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0), -- 9
										 (0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0), -- 10
										 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 11
										 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 12
										 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 13
										 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 14
										 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0));-- 15			

constant cactus_2: sprite_block_2 :=((0,0,0,1,1,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0), -- 0 
												 (0,0,0,1,1,1,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0), -- 1 
												 (0,0,0,1,1,1,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0), -- 2
												 (0,0,0,1,1,1,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0), -- 3
												 (0,1,0,1,1,1,0,1,0,1,0,1,1,1,0,0,1,0,1,0,0,1,1,1,0,0), -- 4
												 (1,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,1,0,1,1,0,1,1,1,0,1), -- 5
												 (1,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,1,0,1,1,0,1,1,1,0,1), -- 6
												 (1,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,1,0,1,1,0,1,1,1,0,1), -- 7
												 (1,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,1,0,1,1,0,1,1,1,0,1), -- 8
												 (1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1), -- 9
												 (0,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1,0,0,0,1,1,1,1,1,0,0), -- 10
												 (0,0,0,1,1,1,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,1,1,1,0,0), -- 11
												 (0,0,0,1,1,1,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0), -- 12
												 (0,0,0,1,1,1,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0), -- 13
												 (0,0,0,1,1,1,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0), -- 14
												 (0,0,0,1,1,1,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0));-- 15	

	constant ptero_1: sprite_block:=((0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0), -- 0 
											 (0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0), -- 1 
											 (0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0), -- 2
											 (0,0,0,1,1,0,0,1,1,1,1,0,0,0,0,0), -- 3
											 (0,0,1,1,1,0,0,1,1,1,1,1,0,0,0,0), -- 4
											 (0,1,1,1,1,0,0,1,1,1,1,1,1,0,0,0), -- 5
											 (1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0), -- 6
											 (0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1), -- 7
											 (0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0), -- 8
											 (0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0), -- 9
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 11
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 10
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 12
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 13
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 14
											 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));-- 15

	constant ptero_2: sprite_block:=((0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 0 
												 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 1 
												 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 2
												 (0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0), -- 3
												 (0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0), -- 4
												 (0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0), -- 5
												 (1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0), -- 6
												 (0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1), -- 7
												 (0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0), -- 8
												 (0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0), -- 9
												 (0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0), -- 10
												 (0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0), -- 11
												 (0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0), -- 12
												 (0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0), -- 13
												 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), -- 14
												 (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));-- 15							 
									 
type color_arr is array(0 to 1) of std_logic_vector(11 downto 0);									 
constant sprite_color : color_arr := ("000000000000", "111100000000");
constant sprite_color_cloud : color_arr := ("000000000000", "111111111111");
constant sprite_color_cactus : color_arr := ("000000000000", "000011110000");
constant sprite_color_trex : color_arr := ("000000000000", "110011100010");
begin
	draw_objects: process(clk, pixel_x, pixel_y)	
	
	variable sprite_x : integer := 0;
	variable sprite_y : integer := 0;
	variable prescalerCount: integer := 0;
	variable prescaler: integer := 5000000;
	
	begin			
		if(clk'event and clk='1') then		
			-- Dibuja el fondo
			rgbDrawColor <= "0000" & "0000" & "0000";
					
			-- Dibuja el suelo
			if(pixel_y = 400 or pixel_y = 404) then
				rgbDrawColor <= "1100" & "1111" & "1100";		
			end if;
			
			sprite_x := pixel_x mod PIX;
			sprite_y := pixel_y mod PIX;
							
			-- Nube 1
			if ((pixel_x / PIX = 0) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud(sprite_y, sprite_x));
			end if;			
			
			-- Nube 2
			if ((pixel_x / PIX = 3) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;	
	
			-- Nube 3
			if ((pixel_x / PIX = 6) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;
			
			-- Nube 4
			if ((pixel_x / PIX = 10) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- Nube 5
			if ((pixel_x / PIX = 12) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;	

			-- Nube 6
			if ((pixel_x / PIX = 14) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;	

			-- Nube 7
			if ((pixel_x / PIX = 16) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;
		
			-- Nube 8
			if ((pixel_x / PIX = 18) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- Nube 9
			if ((pixel_x / PIX = 20) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;	
			
			-- Nube 10
			if ((pixel_x / PIX = 22) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- Nube 11
			if ((pixel_x / PIX = 24) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- Nube 12
			if ((pixel_x / PIX = 26) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;
			
			-- Nube 13
			if ((pixel_x / PIX = 28) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- Nube 14
			if ((pixel_x / PIX = 30) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- Nube 15
			if ((pixel_x / PIX = 32) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- Nube 16
			if ((pixel_x / PIX = 34) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;
			
			-- Nube 17
			if ((pixel_x / PIX = 36) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- Nube 18
			if ((pixel_x / PIX = 38) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- Nube 19
			if ((pixel_x / PIX = 40) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;								

			-- luna 1
			if ((pixel_x / PIX = 8) and (pixel_y / PIX = 0)) then 
				rgbDrawColor <= sprite_color_cloud(moon(sprite_y, sprite_x));
			end if;

			-- nube 1
			if ((pixel_x / PIX = 1) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;			
			
			-- nube 2
			if ((pixel_x / PIX = 2) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;	
	
			-- nube 3
			if ((pixel_x / PIX = 5) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;
			
			-- nube 4
			if ((pixel_x / PIX = 7) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- nube 5
			if ((pixel_x / PIX = 9) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;	

			-- nube 6
			if ((pixel_x / PIX = 11) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;	

			-- nube 7
			if ((pixel_x / PIX = 13) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;
		
			-- nube 8
			if ((pixel_x / PIX = 15) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- nube 9
			if ((pixel_x / PIX = 17) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;	
			
			-- nube 10
			if ((pixel_x / PIX = 19) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- nube 11
			if ((pixel_x / PIX = 21) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- nube 12
			if ((pixel_x / PIX = 23) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;
			
			-- nube 13
			if ((pixel_x / PIX = 25) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- nube 14
			if ((pixel_x / PIX = 27) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- nube 15
			if ((pixel_x / PIX = 29) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- nube 16
			if ((pixel_x / PIX = 31) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;
			
			-- nube 17
			if ((pixel_x / PIX = 33) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- nube 18
			if ((pixel_x / PIX = 35) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;

			-- nube 19
			if ((pixel_x / PIX = 37) and (pixel_y / PIX = 2)) then 
				rgbDrawColor <= sprite_color_cloud(cloud_2(sprite_y, sprite_x));
			end if;
			
			-- Cactus1
			if ((pixel_x / PIX = cactusX_1) and (pixel_y / PIX = cactusY)) then 
				rgbDrawColor <= sprite_color_cactus(cactus(sprite_y, sprite_x));
			end if;

			-- Cactus2
			if ((pixel_x / PIX = cactusX_2) and (pixel_y / PIX = cactusY)) then 
				rgbDrawColor <= sprite_color_cactus(cactus_2(sprite_y, sprite_x));
			end if;	

			-- pterodactyl

			if ((pixel_x / PIX) = pteroX) and ((pixel_y / PIX) = pteroY) then
				if (gameOver = '1') then
					rgbDrawColor <= sprite_color_cloud(ptero_1(sprite_y, sprite_x));
				else
					rgbDrawColor <= sprite_color_cloud(ptero_2(sprite_y, sprite_x));
				end if;
			end if;
		
			-- T-Rex
			if (gameOver = '1') then
				if	((pixel_x / PIX = trexX) and (pixel_y / PIX = trexY)) then
					rgbDrawColor <= sprite_color_trex(trex_dead(sprite_y, sprite_x));
				end if;
			else
				if (saltando = '1') then
					if	((pixel_x / PIX = trexX) and (pixel_y / PIX = trexY)) then
						rgbDrawColor <= sprite_color_trex(trex_2(sprite_y, sprite_x));			
					end if;
				else
					if	((pixel_x / PIX = trexX) and (pixel_y / PIX = trexY)) then
						rgbDrawColor <= sprite_color(trex_2(sprite_y, sprite_x));			
					end if;
				if (abajo = '1') then
						if	((pixel_x / PIX = trexX) and (pixel_y / PIX = trexY)) then
							rgbDrawColor <= sprite_color_trex(trex_1(sprite_y, sprite_x));			
						end if;
					else
						if	((pixel_x / PIX = trexX) and (pixel_y / PIX = trexY)) then
							rgbDrawColor <= sprite_color(trex_2(sprite_y, sprite_x));			
						end if;
					end if;
			end if;
		end if;
		end if;
	end process;
	
	actions: process(clk, jump,agachar)	
	variable cactusCount: integer := 0;
	variable cactusCount_2: integer := 0;
	variable trexCount: integer := 0;
	
	variable pteroCount: integer := 0;
	variable cloudCount: integer := 0;
	variable endGame: std_logic := '0';
	variable waitCount: integer := 0;
	variable waitTime: integer := T_FAC*40;
	
	begin		
	
			    -- Adjust game speed
		    -- if gameSpeed < 20 and d0 = "0101" then
		    	-- gameSpeed <= gameSpeed + 5;
		    -- end if;
			 
			if(clk'event and clk = '1') then
			
			-- Salto
			if(jump = '1') then
				saltando <= '1';
				if (trexY > 20) then
					trexY <= trexY - 1;
				else
					saltando <= '0';
				end if;
			else
			   saltando <= '0';
				if (trexY < 24) then
					trexY <= trexY + 1;
				end if;
			end if;		
			
-- Salto
			if(agachar = '1') then
			  abajo <= '1';
				
			else
			   abajo <= '0';
			end if;	
			
			-- Detectar golpe con Cactus
			if (trexY = cactusY) and ((trexX = cactusX_1)) then
				endGame := '1';
			end if;
			
			if (trexY = cactusY) and ((trexX = cactusX_2))then
				endgame := '1';
			end if;

			-- Detectar golpe con Pterodactyl
			if (trexY = pteroY) and (trexX = pteroX) then
				endGame := '1';
			end if;
			gameOver <= endGame;

			-- Game Over
			if endGame = '1' then
				if waitCount >= waitTime then
					trexX <= 8;
					trexY <= 24;
					endGame := '0';
					waitCount := 0;
					resetGame <= '1';
				end if;
				waitCount := waitCount + 1;
			end if;


			if resetGame = '1' then
				cactusX_1 <= COLS;
				cactusX_2 <= (COLS/2);
				cloudX_1 <= COLS;
				pteroX <= COLS ;
				gameSpeed <= 0;
				resetGame <= '0';
			else
			
			-- Movimiento del Cactus
			-- Cactus Movement
			if (cactusCount >= T_FAC * cactusSpeed) then
				if (cactusX_1 <= 0) then
					cactusX_1 <= COLS;				
				else
					cactusX_1 <= cactusX_1 - 1;					
				end if;
				cactusCount := 0;
			end if;
			cactusCount := cactusCount + 1;
			

			
			-- Movimiento del Cactus 2
			-- Cactus Movement
			
			if (cactusCount_2 >= T_FAC * cactusSpeed) then
				if (cactusX_2 <= 0) then
					cactusX_2 <= (COLS/2);				
				else
					cactusX_2 <= cactusX_2 - 1;					
				end if;
				cactusCount_2 := 0;
			end if;
			cactusCount_2 := cactusCount_2 + 1;
			
			end if;
			
			-- Pterodactyl Movement
				if(pteroCount >= T_FAC * pteroSpeed - gameSpeed) then
					if pteroX <= 0 then
						pteroX <= COLS  ;
					else
						pteroX <= pteroX - 1;
					end if;
					pteroCount := 0;
				end if;
				pteroCount := pteroCount + 1;
		end if;
		
	end process;
	
end arch;