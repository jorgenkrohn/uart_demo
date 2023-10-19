library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_axistream;
use bitvis_vip_axistream.axistream_bfm_pkg.all;

library bitvis_vip_uart;
use bitvis_vip_uart.uart_bfm_pkg.all;

entity uart_bfm_tb is
  generic (
    runner_cfg  : string;
    GC_BAUDRATE : natural := 115200;
    GC_CLK_FREQ : natural := 100000000
  );
end entity uart_bfm_tb;

architecture sim of uart_bfm_tb is

  constant C_CLK_PERIOD   : time := 1 sec / GC_CLK_FREQ;
  constant C_BAUD_PERIOD  : time := 1 sec / GC_BAUDRATE;

  constant C_UART_BFM_CONFIG : t_uart_bfm_config := (
    bit_time                              => C_BAUD_PERIOD,
    num_data_bits                         => 8,
    idle_state                            => '1',
    num_stop_bits                         => STOP_BITS_ONE,
    parity                                => PARITY_NONE,
    timeout                               => 0 ns, -- will default never time out
    timeout_severity                      => error,
    num_bytes_to_log_before_expected_data => 10,
    match_strictness                      => MATCH_EXACT,
    id_for_bfm                            => ID_BFM,
    id_for_bfm_wait                       => ID_BFM_WAIT,
    id_for_bfm_poll                       => ID_BFM_POLL,
    id_for_bfm_poll_summary               => ID_BFM_POLL_SUMMARY,
    error_injection                       => C_BFM_ERROR_INJECTION_INACTIVE
  );

  -- Clock and reset
  signal clk                    : std_logic := '0';
  signal rst                    : std_logic := '1';
  -- UART interface
  signal uart_rxd               : std_logic := '1';
  signal uart_txd               : std_logic;
  -- Transmit interface
  signal s_axis_transmit_if     : t_axistream_if(tdata(7 downto 0), tkeep(0 downto 0), tuser(0 downto 0), tstrb(0 downto 0), tid(0 downto 0), tdest(0 downto 0)) := init_axistream_if_signals(true, 8, 1, 1, 1);
  -- Receive interface
  signal m_axis_receive_if      : t_axistream_if(tdata(7 downto 0), tkeep(0 downto 0), tuser(0 downto 0), tstrb(0 downto 0), tid(0 downto 0), tdest(0 downto 0)) := init_axistream_if_signals(false, 8, 1, 1, 1);

  signal uart_terminate : std_logic := '0';

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
      s_axis_transmit_tdata   => s_axis_transmit_if.tdata,
      s_axis_transmit_tvalid  => s_axis_transmit_if.tvalid,
      s_axis_transmit_tready  => s_axis_transmit_if.tready,
      -- Receive interface
      m_axis_receive_tdata    => m_axis_receive_if.tdata,
      m_axis_receive_tvalid   => m_axis_receive_if.tvalid,
      m_axis_receive_tready   => m_axis_receive_if.tready
    );

  ----------------------------------------------------------------------------------------
  -- Clock generator
  ----------------------------------------------------------------------------------------
  clock_generator(clk, C_CLK_PERIOD);


  m_axis_receive_if.tkeep <= (others=>'1');

  ----------------------------------------------------------------------------------------
  -- Test sequencer. Results are automatically checked
  ----------------------------------------------------------------------------------------
  p_sequencer : process

    procedure axistream_expect(
      constant exp_data_array : in std_logic_vector;
      constant msg            : in string
    ) is
    begin
      axistream_expect(exp_data_array, msg, clk, m_axis_receive_if);
    end procedure axistream_expect;

    procedure axistream_transmit(
      constant data_array   : in std_logic_vector(7 downto 0);
      constant msg          : in string                 := ""
    ) is
    begin
      axistream_transmit(data_array, msg, clk, s_axis_transmit_if);
    end procedure axistream_transmit;

    procedure uart_expect(
      constant data_exp       : in std_logic_vector(7 downto 0);
      constant msg            : in string
    ) is
    begin
      uart_expect(data_exp, msg, uart_txd, uart_terminate, 1, -1 ns, error, C_UART_BFM_CONFIG);
    end procedure uart_expect;

    procedure uart_transmit(
      constant data_value   : in std_logic_vector(7 downto 0);
      constant msg          : in string
    ) is
    begin
      uart_transmit(data_value, msg, uart_rxd, C_UART_BFM_CONFIG);
    end procedure uart_transmit;

  begin
    test_runner_setup(runner, runner_cfg);

    disable_log_msg(ID_PACKET_DATA);
    disable_log_msg(ID_PACKET_PAYLOAD);

    -- Print the configuration to the log
    report_global_ctrl(VOID);
    report_msg_id_panel(VOID);

    -- Reset design
    rst <= '1';
    wait for C_CLK_PERIOD*2;
    rst <= '0';
    wait for C_CLK_PERIOD*2;

    --------------------------------------------------------------------------------------
    -- Transmitting a data word
    --------------------------------------------------------------------------------------
    log(ID_LOG_HDR, "Transmitting a data word");
    axistream_transmit(x"AB", "Transmitting a data word on the AXI-Stream interface");
    uart_expect(x"AB", "Expecting the data word on the UART interface");

    --------------------------------------------------------------------------------------
    -- Receiving a data word
    --------------------------------------------------------------------------------------
    log(ID_LOG_HDR, "Receiving a data word");
    uart_transmit(x"CD", "Transmitting a word on the UART interface");
    axistream_expect(x"CD", "Expecting the data word on the AXI-Stream interface");

    report_alert_counters(FINAL);       -- Report final counters and print conclusion for simulation (Success/Fail)
    log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);

    test_runner_cleanup(runner);
  end process p_sequencer;

end architecture sim;
