library ieee;
use ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library bitvis_vip_axistream;
context bitvis_vip_axistream.vvc_context;

library bitvis_vip_uart;
context bitvis_vip_uart.vvc_context;

library work;
use work.uart_vvc_tb_pkg.all;

entity uart_vvc_th is
  generic (
    GC_BAUDRATE : natural := 115200;
    GC_CLK_FREQ : natural := 100000000
  );
end entity uart_vvc_th;

architecture sim of uart_vvc_th is

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

  constant C_AXISTREAM_BFM_CONFIG : t_axistream_bfm_config := (
    max_wait_cycles                => 100000,
    max_wait_cycles_severity       => ERROR,
    clock_period                   => -1 ns,
    clock_period_margin            => 0 ns,
    clock_margin_severity          => TB_ERROR,
    setup_time                     => -1 ns,
    hold_time                      => -1 ns,
    bfm_sync                       => SYNC_ON_CLOCK_ONLY,
    match_strictness               => MATCH_EXACT,
    byte_endianness                => LOWER_BYTE_LEFT,
    valid_low_at_word_num          => 0,
    valid_low_multiple_random_prob => 0.5,
    valid_low_duration             => 0,
    valid_low_max_random_duration  => 5,
    check_packet_length            => false,
    protocol_error_severity        => ERROR,
    ready_low_at_word_num          => 0,
    ready_low_multiple_random_prob => 0.5,
    ready_low_duration             => 0,
    ready_low_max_random_duration  => 5,
    ready_default_value            => '0',
    id_for_bfm                     => ID_BFM
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

  -----------------------------------------------------------------------------
  -- Instantiate the concurrent procedure that initializes UVVM
  -----------------------------------------------------------------------------
  i_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;

  ----------------------------------------------------------------------------------------
  -- AXI-Stream TX VVC
  ----------------------------------------------------------------------------------------
  i_axistream_tx_vvc : entity bitvis_vip_axistream.axistream_vvc
    generic map (
      GC_VVC_IS_MASTER        => true,
      GC_DATA_WIDTH           => 8,
      GC_USER_WIDTH           => 0,
      GC_ID_WIDTH             => 0,
      GC_DEST_WIDTH           => 0,
      GC_INSTANCE_IDX         => C_TX_IDX,
      GC_AXISTREAM_BFM_CONFIG => C_AXISTREAM_BFM_CONFIG
    )
    port map (
      clk                     => clk,
      axistream_vvc_if        => s_axis_transmit_if
    );

  ----------------------------------------------------------------------------------------
  -- AXI-Stream RX VVC
  ----------------------------------------------------------------------------------------
  i_axistream_rx_vvc : entity bitvis_vip_axistream.axistream_vvc
    generic map (
      GC_VVC_IS_MASTER        => false,
      GC_DATA_WIDTH           => 8,
      GC_USER_WIDTH           => 0,
      GC_ID_WIDTH             => 0,
      GC_DEST_WIDTH           => 0,
      GC_INSTANCE_IDX         => C_RX_IDX,
      GC_AXISTREAM_BFM_CONFIG => C_AXISTREAM_BFM_CONFIG
    )
    port map (
      clk                     => clk,
      axistream_vvc_if        => m_axis_receive_if
    );

  ----------------------------------------------------------------------------------------
  -- UART VVC
  ----------------------------------------------------------------------------------------
  i_uart_vvc : entity bitvis_vip_uart.uart_vvc
    generic map (
      GC_DATA_WIDTH   => 8,
      GC_INSTANCE_IDX => C_UART_IDX,
      GC_UART_CONFIG  => C_UART_BFM_CONFIG
    )
    port map (
      uart_vvc_rx => uart_txd,
      uart_vvc_tx => uart_rxd
    );

  ----------------------------------------------------------------------------------------
  -- Clock generator
  ----------------------------------------------------------------------------------------
  clock_generator(clk, C_CLK_PERIOD);

  ----------------------------------------------------------------------------------------
  -- Reset generator
  ----------------------------------------------------------------------------------------
  rst <= '0' after C_CLK_PERIOD*4;

  m_axis_receive_if.tkeep <= (others=>'1');


end architecture sim;
