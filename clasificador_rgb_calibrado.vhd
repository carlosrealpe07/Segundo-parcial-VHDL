library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clasificador_rgb_calibrado is
    port (
        clk          : in  std_logic;
        rst_n        : in  std_logic;
        listo        : in  std_logic;
        val_r        : in  integer range 0 to 999;
        val_g        : in  integer range 0 to 999;
        val_b        : in  integer range 0 to 999;
        color_out    : out std_logic_vector(1 downto 0); -- "01"=Rojo, "10"=Verde, "11"=Azul, "00"=Vacio
        color_valido : out std_logic
    );
end clasificador_rgb_calibrado;

architecture arch_clasificador of clasificador_rgb_calibrado is
begin

    process(clk, rst_n)
    begin
        if (rst_n = '0') then
            color_out    <= "00";
            color_valido <= '0';
        elsif rising_edge(clk) then
            if (listo = '1') then
                -- 1. Descarte de banda negra / vacio (cuando los 3 canales son bajos <= 28)
                if (val_r <= 28 and val_g <= 32 and val_b <= 30) then
                    color_out    <= "00";
                    color_valido <= '0';

                -- 2. Deteccion de ROJO: R supera a G y a B
                elsif (val_r > val_g and val_r > val_b) then
                    color_out    <= "01";
                    color_valido <= '1';

                -- 3. Deteccion de AZUL: B es el mayor, o B supera ampliamente a R mientras R es bajo
                elsif (val_b >= val_g and val_b > val_r) or (val_b > (val_r + 15) and (val_r * 2) < val_g and val_b * 4 > val_g * 3) then
                    color_out    <= "11";
                    color_valido <= '1';

                -- 4. Deteccion de VERDE: G es el mayor
                elsif (val_g >= val_r and val_g >= val_b) then
                    color_out    <= "10";
                    color_valido <= '1';

                else
                    color_out    <= "00";
                    color_valido <= '0';
                end if;
            end if;
        end if;
    end process;

end arch_clasificador;