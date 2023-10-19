library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;

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

entity uart_vvc_tb is
  generic (
    runner_cfg  : string;
    GC_BAUDRATE : natural := 115200;
    GC_CLK_FREQ : natural := 100000000
  );
end entity uart_vvc_tb;

architecture sim of uart_vvc_tb is

  constant C_CLK_PERIOD   : time := 1 sec / GC_CLK_FREQ;

  impure function get_random_byte_array (
    size : integer
  ) return t_slv_array is
    variable v_data_array : t_slv_array(0 to size-1)(7 downto 0);
  begin
    for i in 0 to size-1 loop
      v_data_array(i) := random(8);
    end loop;
    return v_data_array;
  end function get_random_byte_array;

begin

  ----------------------------------------------------------------------------------------
  -- Test harness
  ----------------------------------------------------------------------------------------
  i_uart_vvc_th : entity work.uart_vvc_th
    generic map (
      GC_BAUDRATE => GC_BAUDRATE,
      GC_CLK_FREQ => GC_CLK_FREQ
    );

  ----------------------------------------------------------------------------------------
  -- Test sequencer. Results are automatically checked
  ----------------------------------------------------------------------------------------
  p_sequencer : process
    variable v_data_array_8   : t_slv_array(0 to 7)(7 downto 0);
    variable v_data_array_16  : t_slv_array(0 to 15)(7 downto 0);
  begin
    test_runner_setup(runner, runner_cfg);

    disable_log_msg(ALL_MESSAGES);
    enable_log_msg(ID_LOG_HDR);
    enable_log_msg(ID_SEQUENCER);
    enable_log_msg(ID_AWAIT_COMPLETION_END);
    disable_log_msg(AXISTREAM_VVCT, C_TX_IDX, ALL_MESSAGES);
    enable_log_msg(AXISTREAM_VVCT, C_TX_IDX, ID_CMD_EXECUTOR);
    enable_log_msg(AXISTREAM_VVCT, C_TX_IDX, ID_IMMEDIATE_CMD);
    enable_log_msg(AXISTREAM_VVCT, C_TX_IDX, ID_PACKET_DATA);
    disable_log_msg(AXISTREAM_VVCT, C_RX_IDX, ALL_MESSAGES);
    enable_log_msg(AXISTREAM_VVCT, C_RX_IDX, ID_CMD_EXECUTOR);
    enable_log_msg(AXISTREAM_VVCT, C_RX_IDX, ID_IMMEDIATE_CMD);
    enable_log_msg(AXISTREAM_VVCT, C_RX_IDX, ID_PACKET_DATA);
    disable_log_msg(UART_VVCT, C_UART_IDX, TX, ALL_MESSAGES);
    enable_log_msg(UART_VVCT, C_UART_IDX, TX, ID_CMD_EXECUTOR);
    enable_log_msg(UART_VVCT, C_UART_IDX, TX, ID_IMMEDIATE_CMD);
    disable_log_msg(UART_VVCT, C_UART_IDX, RX, ALL_MESSAGES);
    enable_log_msg(UART_VVCT, C_UART_IDX, RX, ID_CMD_EXECUTOR);
    enable_log_msg(UART_VVCT, C_UART_IDX, RX, ID_IMMEDIATE_CMD);

    -- Wait for UVVM to finish initialization
    await_uvvm_initialization(VOID);

    -- Print the configuration to the log
    report_global_ctrl(VOID);
    report_msg_id_panel(VOID);

    -- Wait for reset to be released
    wait for C_CLK_PERIOD*10;

    if run("single_word_transmission") then
      -- This test case transmits 1 word at the same time in each direction

      log(ID_LOG_HDR, "Transmitting a data word on the UART TX interface of the DUT and receiving a data word on the UART RX interface");
      axistream_transmit(AXISTREAM_VVCT, C_TX_IDX, x"AB", "Transmitting a data word on the AXI-Stream interface");
      uart_expect(UART_VVCT, C_UART_IDX, RX, x"AB", "Expecting the data word on the UART interface");
      uart_transmit(UART_VVCT, C_UART_IDX, TX, x"CD", "Transmitting a word on the UART interface");
      axistream_expect(AXISTREAM_VVCT, C_RX_IDX, x"CD", "Expecting the data word on the AXI-Stream interface");

      await_completion(VVC_BROADCAST, 1 ms);

    elsif run("multi_word_transmission") then
      -- This test case transmits and receives 8 words at the same time.

      log(ID_LOG_HDR, "Transmitting 8 data words on the UART TX while receiving 8 words on the UART RX interface");
      -- Transmitting 8 words
      v_data_array_8 := get_random_byte_array(8);
      axistream_transmit(AXISTREAM_VVCT, C_TX_IDX, v_data_array_8, "Transmitting a data word on the AXI-Stream interface");
      for i in 0 to 7 loop
        uart_expect(UART_VVCT, C_UART_IDX, RX, v_data_array_8(i), "Expecting the data word on the UART interface");
      end loop;
      -- Receiving 8 words
      v_data_array_8 := get_random_byte_array(8);
      for i in 0 to 7 loop
        uart_transmit(UART_VVCT, C_UART_IDX, TX, v_data_array_8(i), "Transmitting a word on the UART interface");
      end loop;
      axistream_expect(AXISTREAM_VVCT, C_RX_IDX, v_data_array_8, "Expecting 8 data words on the AXI-Stream interface");

      await_completion(VVC_BROADCAST, 10 ms);

    elsif run("fill_tx_fifo") then
      -- This test case will fill the TX FIFO. The FIFO has room for 8 words at a time, but the test sends 16 words as fast
      -- as possible to fill the FIFO. This should make the UART module stop accepting data by disable the ready signal as
      -- long as the FIFO is full.

      -- Storing random data in the data array
      v_data_array_16 := get_random_byte_array(16);

      log(ID_LOG_HDR, "Transmitting multiple data words on the UART TX interface to fill the TX FIFO");
      axistream_transmit(AXISTREAM_VVCT, C_TX_IDX, v_data_array_16, "Transmitting 16 data words on the AXI-Stream interface");
      for i in 0 to 15 loop
        uart_expect(UART_VVCT, C_UART_IDX, RX, v_data_array_16(i), "Expecting the data word on the UART interface");
      end loop;
      await_completion(UART_VVCT, C_UART_IDX, RX, 10 ms);

    elsif run("fill_rx_fifo") then
      -- This test case will fill the RX FIFO. The FIFO has room for 8 words at a time + 1 words that are immediately 
      -- read out from the FIFO. If a word is received while the FIFO is full, the word is discarded.

      log(ID_LOG_HDR, "Receiving 16 data words on the UART RX interface of the DUT where the 7 last words are discarded");
      v_data_array_16 := get_random_byte_array(16);
      for i in 0 to 15 loop
        uart_transmit(UART_VVCT, C_UART_IDX, TX, v_data_array_16(i), "Transmitting a word on the UART interface");
      end loop;
      await_completion(UART_VVCT, C_UART_IDX, TX, 10 ms);

      log(ID_LOG_HDR, "Receiving 9 data words on the AXI-Stream interface");
      axistream_expect(AXISTREAM_VVCT, C_RX_IDX, v_data_array_16(0 to 8), "Expecting 9 data words on the AXI-Stream interface");
      await_completion(AXISTREAM_VVCT, C_RX_IDX, 10 ms);

      log(ID_LOG_HDR, "The FIFO should now be empty. We transmit 8 more words to check that the previous 7 words were discarded");
      v_data_array_8 := get_random_byte_array(8);
      for i in 0 to 7 loop
        uart_transmit(UART_VVCT, C_UART_IDX, TX, v_data_array_8(i), "Transmitting a word on the UART interface");
      end loop;
      axistream_expect(AXISTREAM_VVCT, C_RX_IDX, v_data_array_8, "Expecting 8 data words on the AXI-Stream interface");
      await_completion(AXISTREAM_VVCT, C_RX_IDX, 10 ms);

    end if;

    report_alert_counters(FINAL);       -- Report final counters and print conclusion for simulation (Success/Fail)
    log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);

    test_runner_cleanup(runner);
  end process p_sequencer;

end architecture sim;
