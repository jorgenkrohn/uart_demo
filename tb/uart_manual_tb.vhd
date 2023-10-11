library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity uart_manual_tb is
  generic (
    runner_cfg  : string;
    GC_BAUDRATE : natural := 115200;
    GC_CLK_FREQ : natural := 100000000
  );
end entity uart_manual_tb;

architecture sim of uart_manual_tb is

  constant C_CLK_PERIOD   : time := 1 sec / GC_CLK_FREQ;
  constant C_BAUD_PERIOD  : time := 1 sec / GC_BAUDRATE;

  -- Clock and reset
  signal clk                    : std_logic := '0';
  signal rst                    : std_logic := '1';
  -- UART interface
  signal uart_rxd               : std_logic := '1';
  signal uart_txd               : std_logic;
  -- Transmit interface
  signal s_axis_transmit_tdata  : std_logic_vector(7 downto 0) := (others=>'0');
  signal s_axis_transmit_tvalid : std_logic := '0';
  signal s_axis_transmit_tready : std_logic;
  -- Receive interface
  signal m_axis_receive_tdata   : std_logic_vector(7 downto 0);
  signal m_axis_receive_tvalid  : std_logic;
  signal m_axis_receive_tready  : std_logic := '0';

  signal received_data          : std_logic_vector(7 downto 0) := (others=>'0');
  signal transmit_data          : std_logic_vector(7 downto 0) := (others=>'0');

begin

  ----------------------------------------------------------------------------------------
  -- DUT
  ----------------------------------------------------------------------------------------
  i_uart : entity work.uart
    generic map (
      GC_BAUDRATE => GC_BAUDRATE,
      GC_CLK_FREQ => GC_CLK_FREQ
    )
    port map (
      -- Clock and reset
      clk                     => clk,
      rst                     => rst,
      -- UART interface
      uart_rxd                => uart_rxd,
      uart_txd                => uart_txd,
      -- Transmit interface
      s_axis_transmit_tdata   => s_axis_transmit_tdata,
      s_axis_transmit_tvalid  => s_axis_transmit_tvalid,
      s_axis_transmit_tready  => s_axis_transmit_tready,
      -- Receive interface
      m_axis_receive_tdata    => m_axis_receive_tdata,
      m_axis_receive_tvalid   => m_axis_receive_tvalid,
      m_axis_receive_tready   => m_axis_receive_tready
    );

  ----------------------------------------------------------------------------------------
  -- Clock generator
  ----------------------------------------------------------------------------------------
  p_clk_generator : process
  begin
    wait for C_CLK_PERIOD/2;
    clk <= not clk;
  end process p_clk_generator;

  ----------------------------------------------------------------------------------------
  -- Test sequencer. Results must be manually checked
  ----------------------------------------------------------------------------------------
  p_sequencer : process
  begin
    test_runner_setup(runner, runner_cfg);

    -- Reset design
    rst <= '1';
    wait for C_CLK_PERIOD*2;
    rst <= '0';
    wait for C_CLK_PERIOD*2;

    --------------------------------------------------------------------------------------
    -- Transmitting a data word
    --------------------------------------------------------------------------------------
    -- Transmitting a word on the AXI-Stream interface
    wait until rising_edge(clk);
    s_axis_transmit_tdata   <= x"AB";
    s_axis_transmit_tvalid  <= '1';
    -- Wait until data is accepted
    loop
      wait until rising_edge(clk);
      if s_axis_transmit_tready = '1' then
        s_axis_transmit_tvalid  <= '0';
        exit;
      end if;
    end loop;
    -- Receiving the word on the UART interface
    -- Detecting start bit
    wait until uart_txd = '0';
    -- Waiting half a baud period to sample at the correct time
    wait for C_BAUD_PERIOD/2;
    -- Wait for the 8 data bits
    for i in 0 to 7 loop
      wait for C_BAUD_PERIOD;
      received_data(i) <= uart_txd;
    end loop;

    --------------------------------------------------------------------------------------
    -- Receiving a data word
    --------------------------------------------------------------------------------------
    -- Transmitting a word on the UART interface
    -- Start bit
    uart_rxd <= '0';
    -- 8 data bits
    transmit_data <= x"CD";
    for i in 0 to 7 loop
      wait for C_BAUD_PERIOD;
      uart_rxd <= transmit_data(i);
    end loop;
    -- Stop bit
    wait for C_BAUD_PERIOD;
    uart_rxd <= '1';

    -- Receiving the data word on the AXI-Stream interface
    wait on clk until m_axis_receive_tvalid = '1';
    m_axis_receive_tready <= '1';
    wait until rising_edge(clk);
    m_axis_receive_tready <= '0';

    wait for 10 us;

    test_runner_cleanup(runner);
  end process p_sequencer;

end architecture sim;
