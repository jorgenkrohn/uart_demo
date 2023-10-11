------------------------------------------------------------------------------------------
--
-- Dual-port RAM
--
-- Features:
--  -Independent write and read ports
--  -Common clock between ports
-- 
------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dual_port_ram is
  generic (
    GC_ADDR_WIDTH : natural;
    GC_DATA_WIDTH : natural
  );
  port (
    -- Clock
    clk           : in  std_logic;
    -- Write port
    write_data    : in  std_logic_vector(GC_DATA_WIDTH-1 downto 0);
    write_enable  : in  std_logic;
    write_address : in  unsigned(GC_ADDR_WIDTH-1 downto 0);
    -- Read port
    read_data     : out std_logic_vector(GC_DATA_WIDTH-1 downto 0);
    read_enable   : in  std_logic;
    read_address  : in  unsigned(GC_ADDR_WIDTH-1 downto 0)
  );
end entity dual_port_ram;

architecture rtl of dual_port_ram is

  type t_ram is array ((2**GC_ADDR_WIDTH)-1 downto 0) of std_logic_vector(GC_DATA_WIDTH-1 downto 0);

  signal ram : t_ram;

begin

  p_ram : process (clk)
  begin
    if rising_edge(clk) then
      if write_enable = '1' then
        ram(to_integer(write_address)) <= write_data;
      end if;
      if read_enable = '1' then
        read_data <= ram(to_integer(read_address));
      end if;
    end if;
  end process p_ram;

end architecture rtl;
