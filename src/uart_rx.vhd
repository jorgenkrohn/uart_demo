library ieee;
use ieee.std_logic_1164.all;

entity uart_rx is
  generic (
    GC_BAUDRATE : natural;
    GC_CLK_FREQ : natural
  );
  port (
    -- Clock and reset
    clk                     : in  std_logic;
    rst                     : in  std_logic;
    -- UART interface
    uart_rxd                : in  std_logic;
    -- Receive interface
    m_axis_receive_tdata    : out std_logic_vector(7 downto 0);
    m_axis_receive_tvalid   : out std_logic;
    m_axis_receive_tready   : in  std_logic
  );
end entity uart_rx;

architecture rtl of uart_rx is

  type t_fifo_read_state is (IDLE, VALID_DATA);
  type t_state           is (IDLE, START_BIT, DATA, STOP_BIT);

  signal state                  : t_state;
  signal uart_rxd_synced        : std_logic;
  signal uart_rxd_synced_d1     : std_logic;
  signal received_data          : std_logic_vector(7 downto 0);
  signal fifo_full              : std_logic;
  signal fifo_empty             : std_logic;
  signal fifo_write             : std_logic;
  signal fifo_read              : std_logic;
  signal baud_generator_enable  : std_logic;
  signal baud_pulse             : std_logic;
  signal data_index             : natural range 0 to 7;
  signal fifo_read_state        : t_fifo_read_state;

begin

  ----------------------------------------------------------------------------------------
  -- Sychronizing the uart_rxd input
  ----------------------------------------------------------------------------------------
  i_sync_uart_rxd : entity work.sync_sl
    port map (
      clk     => clk,
      rst     => rst,
      sl_in   => uart_rxd,
      sl_out  => uart_rxd_synced
    );

  ----------------------------------------------------------------------------------------
  -- FIFO for buffering receive data
  ----------------------------------------------------------------------------------------
  i_single_clock_fifo : entity work.single_clock_fifo
    generic map (
      GC_ADDR_WIDTH => 3,
      GC_DATA_WIDTH => 8
    )
    port map (
      -- Clock and reset
      clk           => clk,
      rst           => rst,
      -- Write interface
      write_data    => received_data,
      write_enable  => fifo_write,
      -- Read interface
      read_data     => m_axis_receive_tdata,
      read_enable   => fifo_read,
      -- Status outputs
      full          => fifo_full,
      empty         => fifo_empty
    );

  ----------------------------------------------------------------------------------------
  -- Reading out data from the FIFO and provide it to the AXI-Stream interface
  ----------------------------------------------------------------------------------------
  p_fifo_read : process(clk, rst)
  begin
    if rst = '1' then
      fifo_read_state       <= IDLE;
      fifo_read             <= '0';
      m_axis_receive_tvalid <= '0';
    elsif rising_edge(clk) then
      fifo_read <= '0';
      case fifo_read_state is
        when IDLE =>
          if fifo_empty = '0' then
            fifo_read <= '1';
            fifo_read_state <= VALID_DATA;
          end if;
        when VALID_DATA =>
          m_axis_receive_tvalid <= '1';
          if m_axis_receive_tvalid = '1' and m_axis_receive_tready = '1' then
            m_axis_receive_tvalid <= '0';
            fifo_read_state <= IDLE;
          end if;
      end case;
    end if;
  end process p_fifo_read;

  ----------------------------------------------------------------------------------------
  -- Baud rate generator
  ----------------------------------------------------------------------------------------
  i_baud_generator : entity work.baud_generator
    generic map (
      GC_BAUDRATE => GC_BAUDRATE,
      GC_CLK_FREQ => GC_CLK_FREQ,
      GC_BAUD_RX  => true
    )
    port map (
      -- Clock and reset
      clk         => clk,
      rst         => rst,
      -- Baud generator interface
      enable      => baud_generator_enable,
      baud_pulse  => baud_pulse
    );

  ----------------------------------------------------------------------------------------
  -- UART RX
  ----------------------------------------------------------------------------------------
  p_uart_rx : process(clk, rst)
  begin
    if rst = '1' then
      fifo_write            <= '0';
      state                 <= IDLE;
      uart_rxd_synced_d1    <= '0';
      baud_generator_enable <= '0';
      data_index            <= 0;
    elsif rising_edge(clk) then
      -- Default value
      fifo_write <= '0';
      -- Delayed version of the synchronized uart_rxd input
      uart_rxd_synced_d1 <= uart_rxd_synced;
      -- State machine
      case state is
        when IDLE =>
          -- Detecting start bit
          if uart_rxd_synced = '0' and uart_rxd_synced_d1 = '1' then
            baud_generator_enable <= '1';
            state                 <= START_BIT;
          end if;
        when START_BIT =>
          if baud_pulse = '1' then
            if uart_rxd_synced = '0' then
              data_index <= 7;
              state <= DATA;
            else
              -- Unexpected value on uart_rxd. Going back to IDLE
              state <= IDLE;
            end if;
          end if;
        when DATA =>
          if baud_pulse = '1' then
            received_data(data_index) <= uart_rxd_synced;
            if data_index > 0 then
              data_index <= data_index - 1;
            else
              state <= STOP_BIT;
            end if;
          end if;
        when STOP_BIT =>
          if baud_pulse = '1' then
            -- Writing the received data to the FIFO unless the FIFO is full
            if fifo_full = '0' then
              fifo_write <= '1';
            end if;
            -- Disabling baud counter and go back to IDLE
            baud_generator_enable <= '0';
            state <= IDLE;
          end if;
      end case;
    end if;
  end process p_uart_rx;

end architecture rtl;
