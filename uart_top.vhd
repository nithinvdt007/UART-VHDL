-------------------------------------------------------------------------------
-- Title      : uart
-- Project    : 
-------------------------------------------------------------------------------
-- File       : uart_top.vhd
-- Author     :   <Admin@WORKPC>
-- Company    : 
-- Created    : 2026-10-07
-- Last update: 2026-10-07
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2026 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2026-10-07  1.0      Admin	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity uart_top is

  generic (

    -- global generics
    BAUD_RX           : integer := 9600;
    CLK_FREQ          : integer := 50000000;
    OVERSAMPLING_FACT : integer := 16;

    -- generics for "baud_tick_1"
    FREQ     : integer := 50000000;
    BAUDRATE : integer := 9600);

  port (

    -- global ports
    clk         : in  std_logic;
    reset       : in  std_logic;
    baud_tick   : in  std_logic;
    sample_tick : out std_logic;

    -- ports to "baud_tick_1"
    baud  : out std_logic;
    start : in  std_logic;

    -- ports to "tx_1"
    data_in : in std_logic_vector (7 downto 0);

    -- ports to "tx_fsm_1"
    start_tx : in  std_logic;
    tx_out   : out std_logic;
    busy     : out std_logic;
    tx_done  : out std_logic);

end entity uart_top;

-------------------------------------------------------------------------------

architecture str of uart_top is

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------

  -- outputs of "tx_1"
  signal tx_bit : std_logic;
  signal done   : std_logic;

  -- outputs of "tx_fsm_1"
  signal load : std_logic;

begin  -- architecture str

  -----------------------------------------------------------------------------
  -- Component instantiations
  -----------------------------------------------------------------------------

  -- instance "baud_tick_1"
  baud_tick_1: entity example3_lib.baud_tick
    generic map (
      FREQ     => FREQ,
      BAUDRATE => BAUDRATE)
    port map (
      clk   => clk,
      reset => reset,
      baud  => baud,
      start => start);

  -- instance "tx_1"
  tx_1: entity example3_lib.tx
    port map (
      clk       => clk,
      reset     => reset,
      load      => load,
      data_in   => data_in,
      baud_tick => baud_tick,
      tx_bit    => tx_bit,
      done      => done);

  -- instance "tx_fsm_1"
  tx_fsm_1: entity example3_lib.tx_fsm
    port map (
      clk       => clk,
      reset     => reset,
      start_tx  => start_tx,
      baud_tick => baud_tick,
      tx_bit    => tx_bit,
      done      => done,
      tx_out    => tx_out,
      load      => load,
      busy      => busy,
      tx_done   => tx_done);

  -- instance "baud_rx_1"
  baud_rx_1: entity example3_lib.baud_rx
    generic map (
      BAUD_RX           => BAUD_RX,
      CLK_FREQ          => CLK_FREQ,
      OVERSAMPLING_FACT => OVERSAMPLING_FACT)
    port map (
      clk         => clk,
      reset       => reset,
      sample_tick => sample_tick);

  -- instance "baud_rx_2"
  baud_rx_2: entity example3_lib.baud_rx
    generic map (
      BAUD_RX           => BAUD_RX,
      CLK_FREQ          => CLK_FREQ,
      OVERSAMPLING_FACT => OVERSAMPLING_FACT)
    port map (
      clk         => clk,
      reset       => reset,
      sample_tick => sample_tick);

end architecture str;

-------------------------------------------------------------------------------
