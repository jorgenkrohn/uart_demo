------------------------------------------------------------------------------------------
--
-- Single clock FIFO
--
-- Features:
--  -Configurable depth
--  -Configurable data width
--  -Empty and full status outputs
-- 
------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity single_clock_fifo is
  generic (
    GC_ADDR_WIDTH : natural;
    GC_DATA_WIDTH : natural
  );
  port (
    -- Clock and reset
    clk           : in  std_logic;
    rst           : in  std_logic;
    -- Write interface
    write_data    : in  std_logic_vector(GC_DATA_WIDTH-1 downto 0);
    write_enable  : in  std_logic;
    -- Read interface
    read_data     : out std_logic_vector(GC_DATA_WIDTH-1 downto 0);
    read_enable   : in  std_logic;
    -- Status outputs
    full          : out std_logic;
    empty         : out std_logic
  );
end entity single_clock_fifo;

architecture rtl of single_clock_fifo is

  -- Pointers have an extra bit to separate between full and empty
  signal read_pointer   : unsigned(GC_ADDR_WIDTH downto 0) := (others=>'0');
  signal write_pointer  : unsigned(GC_ADDR_WIDTH downto 0) := (others=>'0');

begin

  ----------------------------------------------------------------------------------------
  -- Dual port RAM
  ----------------------------------------------------------------------------------------
  i_dual_port_ram : entity work.dual_port_ram
    generic map (
      GC_ADDR_WIDTH => GC_ADDR_WIDTH,
      GC_DATA_WIDTH => GC_DATA_WIDTH
    )
    port map (
      -- Clock
      clk           => clk,
      -- Write port
      write_data    => write_data,
      write_enable  => write_enable,
      write_address => write_pointer(GC_ADDR_WIDTH-1 downto 0),
      -- Read port
      read_data     => read_data,
      read_enable   => read_enable,
      read_address  => read_pointer(GC_ADDR_WIDTH-1 downto 0)
    );

  ----------------------------------------------------------------------------------------
  -- Control logic
  ----------------------------------------------------------------------------------------
  p_control_logic : process(clk, rst)
  begin
    if rst = '1' then
      write_pointer       <= (others=>'0');
      read_pointer        <= (others=>'0');
    elsif rising_edge(clk) then
      -- Incrementing write pointer when data is written. Data is not written to the FIFO 
      -- if the FIFO is full
      if write_enable = '1' and full = '0' then
        write_pointer <= write_pointer + 1;
      end if;
      -- Incrementing read pointer when data is read. Data is not read if the FIFO is 
      -- empty
      if read_enable = '1' and empty = '0' then
        read_pointer <= read_pointer + 1;
      end if;
    end if;
  end process p_control_logic;

  -- FIFO is full if the pointers are equal. Separating between full and empty by adding another bit. This bit is unequal if the fifo is full
  full <= '1' when read_pointer(GC_ADDR_WIDTH) /= write_pointer(GC_ADDR_WIDTH) and 
                   read_pointer(GC_ADDR_WIDTH-1 downto 0) = write_pointer(GC_ADDR_WIDTH-1 downto 0) else
          '0';

  -- FIFO is empty if the pointers are equal, including the extra top bit
  empty <= '1' when write_pointer = read_pointer else
           '0';

end architecture rtl;
