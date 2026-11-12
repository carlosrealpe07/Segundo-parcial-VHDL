library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity display_decoder is
    Port (
        distance_in1 : in  STD_LOGIC_VECTOR (8 downto 0);
        display_sal  : out STD_LOGIC_VECTOR (6 downto 0); -- Unidades (HEX0)
        display_sal2 : out STD_LOGIC_VECTOR (6 downto 0)  -- Decenas  (HEX1)
    );
end display_decoder;

architecture Behavioral of display_decoder is
begin
    -- Displays de anodo comun de la Altera DE0 ('0' enciende segmento, indice 6 downto 0)
    process(distance_in1)
    begin
        case distance_in1 is
            when "000001000" => -- Cubo de 8 cm -> Muestra "08"
                display_sal2 <= "1000000"; -- '0'
                display_sal  <= "0000000"; -- '8'

            when "000000100" => -- Cubo de 4 cm -> Muestra "04"
                display_sal2 <= "1000000"; -- '0'
                display_sal  <= "0011001"; -- '4'

            when "000000000" => -- Banda vacia (~12 cm) -> Apagados
                display_sal2 <= "1111111";
                display_sal  <= "1111111";

            when others =>      -- Medida fuera de rango -> Muestra "Er"
                display_sal2 <= "0000110"; -- 'E'
                display_sal  <= "0101111"; -- 'r'
        end case;
    end process;
end Behavioral;