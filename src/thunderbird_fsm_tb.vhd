--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;
 
architecture test_bench of thunderbird_fsm_tb is 
	component thunderbird_fsm is 
	  port(  
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
		);
	end component thunderbird_fsm;
 
	-- test I/O signals
	signal w_clk : std_logic := '0';
	signal w_reset: std_logic :='0';
	signal w_sw: std_logic_vector (1 downto 0) := "00"; 
	signal w_lights: std_logic_vector (5 downto 0):= "000000"; 
	-- constants
	constant k_clk_period : time := 10 ns;
begin
	-- PORT MAPS ----------------------------------------
	uut: thunderbird_fsm port map(
	   i_clk       => w_clk,
	   i_reset     => w_reset,
	   i_left      => w_sw(1),
	   i_right     => w_sw(0),
	   o_lights_L  => w_lights(5 downto 3),
	   o_lights_R  => w_lights(2 downto 0) 
	   );
	-----------------------------------------------------
	-- PROCESSES ----------------------------------------	
    	clk_proc : process
	begin
		w_clk <= '0';
        wait for k_clk_period/2;
		w_clk <= '1';
		wait for k_clk_period/2;
	end process;
	-----------------------------------------------------
	sim_proc: process
	begin
	--Reset
	w_reset <= '1';
	wait for k_clk_period*1;
		  assert w_lights = "000000" report "bad reset" severity failure;
	w_reset <= '0'; 
	wait for k_clk_period*1; 
	
	--OFF State
	w_sw <= "00";
	wait for k_clk_period*1;
	     assert w_lights = "000000" report "bad on start" severity failure;
	--Hazards
	w_sw <="11";
	wait for k_clk_period*1;
        assert w_lights = "111111" report "bad ON hazard" severity failure;
    wait for k_clk_period*1;
        assert w_lights = "000000" report "bad OFF hazard" severity failure;
    wait for k_clk_period*1;
    --reset and left transition
    w_reset <='1';
    wait for k_clk_period*1;
    w_reset<='0';
    wait for k_clk_period*1;
    w_sw <= "10";
    wait for k_clk_period*1;
    wait for k_clk_period*1;
        assert w_lights = "001000" report "bad on L1" severity failure;
    wait for k_clk_period*1;
        assert w_lights = "011000" report "bad on L2 / bad transition" severity failure;
    wait for k_clk_period*1;
        assert w_lights = "111000" report "bad on L3 / bad transition" severity failure;
    wait for k_clk_period*1;
        assert w_lights = "000000" report "bad OFF on left cycle" severity failure;
    w_sw <= "00"; --switch off
    wait for k_clk_period*1;
        assert w_lights = "000000" report "bad OFF post left cycle" severity failure;
    --reset and  right transition
    w_reset <='1';
    wait for k_clk_period*1;
    w_reset<='0';
    wait for k_clk_period*1;
    w_sw <= "01";
    wait for k_clk_period*1;
        assert w_lights = "000001" report "bad on R1" severity failure;
    wait for k_clk_period*1;
        assert w_lights = "000011" report "bad on R2 / bad transition" severity failure;
    wait for k_clk_period*1;
        assert w_lights = "000111" report "bad on R3 / bad transition" severity failure;
    wait for k_clk_period*1;
        assert w_lights = "000000" report "bad OFF on right cycle" severity failure;
    -- check left cycle with right input in the middle
    w_sw <= "10";
    wait for k_clk_period*1;
        assert w_lights = "001000" report "bad left start cycle" severity failure;
    wait for k_clk_period*1;
        assert w_lights = "011000" report "bad left mid cycle" severity failure;
    w_sw <= "01";
    wait for k_clk_period*1;
        assert w_lights = "111000" report "right input, left cycle" severity failure;
    wait for k_clk_period*1;
        assert w_lights = "000000" report "failed to exit left cycle with right input" severity failure;
    -- check right cycle with left input in the middle
    w_sw <= "01";
    wait for k_clk_period*1;
        assert w_lights = "000001" report "bad right start cycle" severity failure;
    wait for k_clk_period*1;
        assert w_lights = "000011" report "bad right mid cycle" severity failure;
    w_sw <= "10";
    wait for k_clk_period*1;
        assert w_lights = "000111" report "takes left input mid right cycle" severity failure;
    wait for k_clk_period*1;
        assert w_lights = "000000" report "failed to exit right cycle with left input" severity failure;
    -- check for reset input in the middle of the right cycle
    w_sw <="01";
    wait for k_clk_period*1;
        assert w_lights = "000001" report "bad right start cycle" severity failure;
    w_reset <='1';
    wait for k_clk_period*1;
        assert w_lights = "000000" report "bad right reset in the cycle" severity failure;
    w_reset <= '0';
    -- check for reset input in the middle of the left cycle
    w_sw <="10";
    wait for k_clk_period*1;
        assert w_lights = "001000" report "bad left start cycle" severity failure;
    w_reset <='1';
    wait for k_clk_period*1;
        assert w_lights = "000000" report "bad left reset in the cycle" severity failure;
    w_reset <= '0';
    w_sw <= "00";
    wait;
    end process;
	-----------------------------------------------------	
end test_bench;
	-----------------------------------------------------		