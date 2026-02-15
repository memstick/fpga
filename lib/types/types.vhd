
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

package generic_types is
  type addr_out is array (natural range <>) of std_logic_vector(31 downto 0);
  type data_out is array (natural range <>) of std_logic_vector(31 downto 0);
  type rreq_out is array (natural range <>) of std_logic;
  type rw_out   is array (natural range <>) of std_logic;
  type rack_out is array (natural range <>) of std_logic;
  type port_match is array (natural range <>) of std_logic_vector(3 downto 0);
end package generic_types;
