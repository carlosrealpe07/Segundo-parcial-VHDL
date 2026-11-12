library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity distance_calculation is
    port(
        echo_count : in  STD_LOGIC_VECTOR (19 downto 0);
        distance   : out STD_LOGIC_VECTOR (8 downto 0)
    );
end distance_calculation;

architecture Behavioral of distance_calculation is
begin
    -- Escala a 50 MHz: 1 cm = 2900 ciclos
    --   * Eco entre 2.5 cm y 5.5 cm (7250 a 15950 ciclos)  -> Cubo Grande 8 cm ("000001000")
    --   * Eco entre 6.0 cm y 9.8 cm (17400 a 28420 ciclos) -> Cubo Pequeno 4 cm ("000000100")
    --   * Eco >= 10.0 cm            (>= 29000 ciclos)      -> Banda vacia       ("000000000")
    --   * Resto de distancias                              -> Error/Invalido    ("000011111")

    distance <= "000001000" when (echo_count >= 7250  and echo_count <= 15950) else
                "000000100" when (echo_count >= 17400 and echo_count <= 28420) else
                "000000000" when (echo_count >= 29000) else
                "000011111";
end Behavioral;