library ieee;
use ieee.std_logic_1164.all;

entity uart_tx is
  generic (
    GC_BAUDRATE : natural;
    GC_CLK_FREQ : natural
  );
  port (
    -- Clock and reset
    clk                     : in  std_logic;
    rst                     : in  std_logic;
    -- UART interface
    uart_txd                : out std_logic;
    -- Transmit interface
    s_axis_transmit_tdata   : in  std_logic_vector(7 downto 0);
    s_axis_transmit_tvalid  : in  std_logic;
    s_axis_transmit_tready  : out std_logic
  );
end entity uart_tx;

architecture rtl of uart_tx is

  type t_state is (IDLE, START_BIT, DATA, STOP_BIT);

  signal state                  : t_state;
  signal fifo_full              : std_logic;
  signal fifo_empty             : std_logic;
  signal fifo_write             : std_logic;
  signal fifo_read              : std_logic;
  signal fifo_read_data         : std_logic_vector(7 downto 0);
  signal baud_generator_enable  : std_logic;
  signal baud_pulse             : std_logic;
  signal read_data_index        : natural range 0 to 7;

begin

  ----------------------------------------------------------------------------------------
  -- FIFO for buffering transmit data
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
      write_data    => s_axis_transmit_tdata,
      write_enable  => fifo_write,
      -- Read interface
      read_data     => fifo_read_data,
      read_enable   => fifo_read,
      -- Status outputs
      full          => fifo_full,
      empty         => fifo_empty
    );

  s_axis_transmit_tready <= '1';

  fifo_write <= s_axis_transmit_tvalid and s_axis_transmit_tready;


  ----------------------------------------------------------------------------------------
  -- Baud rate generator
  ----------------------------------------------------------------------------------------
  i_baud_generator : entity work.baud_generator
    generic map (
      GC_BAUDRATE => GC_BAUDRATE,
      GC_CLK_FREQ => GC_CLK_FREQ,
      GC_BAUD_RX  => false
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
  -- UART TX
  ----------------------------------------------------------------------------------------
  p_uart_tx : process(clk, rst)
  begin
    if rst = '1' then
      state                 <= IDLE;
      uart_txd              <= '1';
      fifo_read             <= '0';
      baud_generator_enable <= '0';
      read_data_index       <= 0;
    elsif rising_edge(clk) then
      -- Default value
      fifo_read <= '0';
      -- State machine
      case state is
        when IDLE =>
          uart_txd  <= '1';
          if fifo_empty = '0' then
            -- Reading the word to be transmitted
            fifo_read <= '1';
            -- Starting the baud counter
            baud_generator_enable <= '1';
            -- Setting the START bit
            state <= START_BIT;
          end if;
        when START_BIT =>
          uart_txd  <= '0';
          if baud_pulse = '1' then
            read_data_index <= 0;
            state <= DATA;
          end if;
        when DATA =>
          uart_txd <= fifo_read_data(read_data_index);
          if baud_pulse = '1' then
            if read_data_index < 7 then
              read_data_index <= read_data_index + 1;
            else
              state <= STOP_BIT;
            end if;
          end if;
        when STOP_BIT =>
          uart_txd  <= '0';
          if baud_pulse = '1' then
            -- Disabling baud counter and go back to IDLE
            baud_generator_enable <= '0';
            state <= IDLE;
          end if;
      end case;
    end if;
  end process p_uart_tx;

end architecture rtl;
