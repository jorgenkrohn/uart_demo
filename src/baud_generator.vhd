library ieee;
use ieee.std_logic_1164.all;

entity baud_generator is
  generic (
    GC_BAUDRATE : natural;
    GC_CLK_FREQ : natural;
    GC_BAUD_RX  : boolean  -- True: Baud pulse is in the midpoint
  );
  port (
    -- Clock and reset
    clk         : in  std_logic;
    rst         : in  std_logic;
    -- Baud generator interface
    enable      : in  std_logic;
    baud_pulse  : out std_logic
  );
end entity baud_generator;

architecture rtl of baud_generator is

  constant C_COUNT_VALUE : natural := GC_CLK_FREQ/GC_BAUDRATE;

  type t_state is (IDLE, ENABLED);
  signal state : t_state;

  signal baud_counter : natural range 0 to C_COUNT_VALUE-1;

begin

  p_baud_generator : process(clk, rst)
  begin
    if rst = '1' then
      state         <= IDLE;
      baud_counter  <= 0;
      baud_pulse    <= '0';
    elsif rising_edge(clk) then
      -- Default value
      baud_pulse <= '0';
      -- FSM
      case state is
        when IDLE =>
          if enable = '1' then
            state <= ENABLED;
            if GC_BAUD_RX then 
              baud_counter <= C_COUNT_VALUE/2;
            else
              baud_counter <= 0;
            end if;
          end if;
        when ENABLED =>
          if baud_counter = C_COUNT_VALUE-1 then
            baud_counter  <= 0;
            baud_pulse    <= '1';
          else
            baud_counter  <= baud_counter + 1;
          end if;
          if enable = '0' then
            state <= IDLE;
          end if;
      end case;
    end if;
  end process p_baud_generator;

end architecture rtl;
