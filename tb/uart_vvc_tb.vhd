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
    variable v_data_array : t_slv_array(0 to 15)(7 downto 0);
  begin
    test_runner_setup(runner, runner_cfg);

    disable_log_msg(ID_UVVM_CMD_ACK);
    disable_log_msg(ID_UVVM_SEND_CMD);
    disable_log_msg(ID_AWAIT_COMPLETION_LIST);
    disable_log_msg(ID_AWAIT_COMPLETION_WAIT);
    disable_log_msg(ID_AWAIT_COMPLETION_END);
    disable_log_msg(AXISTREAM_VVCT, C_TX_IDX, ID_CMD_INTERPRETER);
    disable_log_msg(AXISTREAM_VVCT, C_TX_IDX, ID_CMD_INTERPRETER_WAIT);
    disable_log_msg(AXISTREAM_VVCT, C_TX_IDX, ID_CMD_EXECUTOR_WAIT);
    disable_log_msg(AXISTREAM_VVCT, C_TX_IDX, ID_BFM_WAIT);
    disable_log_msg(AXISTREAM_VVCT, C_TX_IDX, ID_PACKET_INITIATE);
    disable_log_msg(AXISTREAM_VVCT, C_TX_IDX, ID_PACKET_COMPLETE);
    disable_log_msg(AXISTREAM_VVCT, C_RX_IDX, ID_CMD_INTERPRETER);
    disable_log_msg(AXISTREAM_VVCT, C_RX_IDX, ID_CMD_INTERPRETER_WAIT);
    disable_log_msg(AXISTREAM_VVCT, C_RX_IDX, ID_CMD_EXECUTOR_WAIT);
    disable_log_msg(AXISTREAM_VVCT, C_RX_IDX, ID_BFM_WAIT);
    disable_log_msg(AXISTREAM_VVCT, C_RX_IDX, ID_PACKET_INITIATE);
    disable_log_msg(AXISTREAM_VVCT, C_RX_IDX, ID_PACKET_COMPLETE);
    disable_log_msg(AXISTREAM_VVCT, C_RX_IDX, ID_PACKET_PAYLOAD);
    disable_log_msg(UART_VVCT, C_UART_IDX, TX, ID_CMD_INTERPRETER);
    disable_log_msg(UART_VVCT, C_UART_IDX, TX, ID_CMD_INTERPRETER_WAIT);
    disable_log_msg(UART_VVCT, C_UART_IDX, TX, ID_CMD_EXECUTOR_WAIT);
    disable_log_msg(UART_VVCT, C_UART_IDX, TX, ID_BFM_WAIT);
    disable_log_msg(UART_VVCT, C_UART_IDX, RX, ID_CMD_INTERPRETER);
    disable_log_msg(UART_VVCT, C_UART_IDX, RX, ID_CMD_INTERPRETER_WAIT);
    disable_log_msg(UART_VVCT, C_UART_IDX, RX, ID_CMD_EXECUTOR_WAIT);
    disable_log_msg(UART_VVCT, C_UART_IDX, RX, ID_BFM_WAIT);

    -- Wait for UVVM to finish initialization
    await_uvvm_initialization(VOID);

    -- Print the configuration to the log
    report_global_ctrl(VOID);
    report_msg_id_panel(VOID);

    -- Wait for reset to be released
    wait for C_CLK_PERIOD*10;

    if run("single_word_transmission") then

      log(ID_LOG_HDR, "Transmitting a data word on the UART TX interface of the DUT");
      axistream_transmit(AXISTREAM_VVCT, C_TX_IDX, x"AB", "Transmitting a data word on the AXI-Stream interface");
      uart_expect(UART_VVCT, C_UART_IDX, RX, x"AB", "Expecting the data word on the UART interface");
      await_completion(UART_VVCT, C_UART_IDX, RX, 1 ms);

      log(ID_LOG_HDR, "Receiving a data word on the UART RX interface of the DUT");
      uart_transmit(UART_VVCT, C_UART_IDX, TX, x"CD", "Transmitting a word on the UART interface");
      axistream_expect(AXISTREAM_VVCT, C_RX_IDX, x"CD", "Expecting the data word on the AXI-Stream interface");
      await_completion(AXISTREAM_VVCT, C_RX_IDX, 1 ms);

    elsif run("multi_word_transmission") then

      -- This test case will fill the FIFO. The FIFO has room for 8 words at a time, but the test sends 16 words as fast
      -- as possible

      -- Storing random data in the data array
      for i in 0 to 15 loop
        v_data_array(i) := random(8);
      end loop;

      log(ID_LOG_HDR, "Transmitting multiple data words on the UART TX interface of the DUT");
      axistream_transmit(AXISTREAM_VVCT, C_TX_IDX, v_data_array, "Transmitting a data word on the AXI-Stream interface");
      for i in 0 to 15 loop
        uart_expect(UART_VVCT, C_UART_IDX, RX, v_data_array(i), "Expecting the data word on the UART interface");
      end loop;
      await_completion(UART_VVCT, C_UART_IDX, RX, 10 ms);

      -- Storing random data in the data array
      for i in 0 to 15 loop
        v_data_array(i) := random(8);
      end loop;

      log(ID_LOG_HDR, "Receiving multiple data words on the UART RX interface of the DUT");
      for i in 0 to 15 loop
        uart_transmit(UART_VVCT, C_UART_IDX, TX, v_data_array(i), "Transmitting a word on the UART interface");
      end loop;
      axistream_expect(AXISTREAM_VVCT, C_RX_IDX, v_data_array, "Expecting the data word on the AXI-Stream interface");
      await_completion(AXISTREAM_VVCT, C_RX_IDX, 10 ms);

    elsif run("simultaneous_transmission") then

      -- This test case transmits and receives at the same time.

      -- Storing random data in the data array
      for i in 0 to 15 loop
        v_data_array(i) := random(8);
      end loop;

      log(ID_LOG_HDR, "Transmitting multiple data words on the UART TX interface of the DUT");
      axistream_transmit(AXISTREAM_VVCT, C_TX_IDX, v_data_array, "Transmitting a data word on the AXI-Stream interface");
      for i in 0 to 15 loop
        uart_expect(UART_VVCT, C_UART_IDX, RX, v_data_array(i), "Expecting the data word on the UART interface");
      end loop;

      -- Storing random data in the data array
      for i in 0 to 15 loop
        v_data_array(i) := random(8);
      end loop;

      log(ID_LOG_HDR, "Receiving multiple data words on the UART RX interface of the DUT");
      for i in 0 to 15 loop
        uart_transmit(UART_VVCT, C_UART_IDX, TX, v_data_array(i), "Transmitting a word on the UART interface");
      end loop;
      axistream_expect(AXISTREAM_VVCT, C_RX_IDX, v_data_array, "Expecting the data word on the AXI-Stream interface");

      await_completion(AXISTREAM_VVCT, C_RX_IDX, 10 ms);
      await_completion(UART_VVCT, C_UART_IDX, RX, 10 ms);

    end if;

    report_alert_counters(FINAL);       -- Report final counters and print conclusion for simulation (Success/Fail)
    log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);

    test_runner_cleanup(runner);
  end process p_sequencer;

end architecture sim;
