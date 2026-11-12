library ieee;
use ieee.std_logic_1164.all;

entity deco_7seg_color is
    port (
        a : in  std_logic_vector(3 downto 0);
        d : out std_logic_vector(6 downto 0)
    );
end deco_7seg_color;

architecture arch_deco of deco_7seg_color is
begin
    with a select
        d <= "1000000" when "0000", -- 0
             "1111001" when "0001", -- 1
             "0100100" when "0010", -- 2
             "0110000" when "0011", -- 3
             "0011001" when "0100", -- 4
             "0010010" when "0101", -- 5
             "0000010" when "0110", -- 6
             "1111000" when "0111", -- 7
             "0000000" when "1000", -- 8
             "0010000" when "1001", -- 9
             "0001000" when "1010", -- 'A' (Azul)
             "0101111" when "1011", -- 'r' (Rojo)
             "1000010" when "1100", -- 'G' (Verde)
             "0111111" when "1101", -- '-' (Guion / Vacio)
             "1111111" when others; -- Apagado
end arch_deco;