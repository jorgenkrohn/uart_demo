------------------------------------------------------------------------------------------------------------------------
-- Synchronization module for std_logic values. 
--
-- Features:
--  -Generic number of synchronization flip-flops
--  -Generic choice of reset value
--
-- Notes: 
--  -This module assumes that the value of the std_logic input changes slowly compared to the clock period. When 
--   synchronizing a pulse from one clock domain to another, a different method should be used.
------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity sync_sl is
  generic(
    GC_NUMBER_OF_SYNC_FFS : positive  := 2;
    GC_RESET_VALUE        : std_logic := '0'
  );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    sl_in   : in  std_logic;
    sl_out  : out std_logic
  );
end entity sync_sl;

architecture rtl of sync_sl is

  signal sl_ff : std_logic_vector(GC_NUMBER_OF_SYNC_FFS-1 downto 0) := (others=>GC_RESET_VALUE);

begin

  p_sync : process(clk, rst) is
  begin
    if rst = '1' then
      sl_ff <= (others=>GC_RESET_VALUE);
    elsif rising_edge(clk) then
      sl_ff <= sl_ff(GC_NUMBER_OF_SYNC_FFS-2 downto 0) & sl_in;
    end if;
  end process p_sync;

  sl_out <= sl_ff(GC_NUMBER_OF_SYNC_FFS-1);

end architecture rtl;
