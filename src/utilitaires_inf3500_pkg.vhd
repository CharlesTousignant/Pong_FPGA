---------------------------------------------------------------------------------------------------
-- 
-- utilitaires_inf3500_pkg.vhd
--
-- Pierre Langlois
-- v. 1.0, 2020-07-12
-- v. 1.1, 2020-10-21 correction assert dans la fonction unsigned_to_BCD(nombre : unsigned(9 downto 0)), erreur trouvée par Félix Boucher
-- v. 1.2, 2020-10-24 changement de nom pour utilitaires_inf3500_pkg.vhd
-- v. 1.3, 2020-10-31 ajout de fonctions pour les caractères encodés en Base64
--                    _2_ devient _to_
-- v. 1.4, 2021-01-23 ajout de la fonction bool2stdl()
--                    modifications mineures au texte, fonction unsigned_to_BCD
--
-- Déclarations et fonctions utilitaires pour le cours INF3500
-- 
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;  

package utilitaires_inf3500_pkg is

    subtype quartet is std_logic_vector(3 downto 0);
    subtype quartet_signed is signed(3 downto 0);
    subtype quartet_unsigned is unsigned(3 downto 0);
    subtype segments is std_logic_vector(7 downto 0);
    
    subtype BCD is quartet;

    subtype BCD1 is unsigned(3 downto 0); -- un chiffre décimal BCD
    subtype BCD2 is unsigned(7 downto 0); -- deux chiffres décimaux BCD, ex. 58 : 0101_1000
    subtype BCD3 is unsigned(11 downto 0); -- trois chiffres décimaux BCD, ex. 907 : 1001_0000_0111
    
    type quatre_symboles is array(3 downto 0) of segments; 
    
    function hex_to_7seg(chiffre_hex: quartet) return segments;
    function hex_to_7seg(chiffre_hex: quartet_signed) return segments;
    function hex_to_7seg(chiffre_hex: quartet_unsigned) return segments;
    function BCD_to_7seg(chiffre_bcd: BCD) return segments;
    
    function unsigned_to_BCD(nombre : unsigned(9 downto 0)) return BCD3;
    
    function character_to_7seg(caractere: character) return segments;
    
    function indiceBase64_to_character(indice: natural range 0 to 63) return character;
    
    function hex_to_character(chiffre_hex: natural range 0 to 15) return character;
    function hex_to_character(chiffre_hex: quartet_unsigned) return character;
    
    function bool2stdl(b : boolean) return std_logic;
    
end package;

package body utilitaires_inf3500_pkg is

    ------------------------------------------------------------------------------------------------
    --
    -- décodeur pour caractères hexadécimaux vers affichage à 7 segments (8 bits incluant le point)
    -- correspondances entre bits et segments:
    --      0
    --     ---  
    --  5 |   | 1
    --     ---   <- 6
    --  4 |   | 2
    --     ---
    --      3     
    --  point: bit 7
    --
    function hex_to_7seg(chiffre_hex: quartet) return segments is
    variable lessegments : segments;
    begin
        case chiffre_hex is
            when x"0" => lessegments := "11000000";
            when x"1" => lessegments := "11111001";
            when x"2" => lessegments := "10100100";
            when x"3" => lessegments := "10110000";
            when x"4" => lessegments := "10011001";
            when x"5" => lessegments := "10010010";
            when x"6" => lessegments := "10000010";
            when x"7" => lessegments := "11111000";
            when x"8" => lessegments := "10000000";
            when x"9" => lessegments := "10010000";
            when x"A" => lessegments := "10001000"; -- A
            when x"B" => lessegments := "10000011"; -- b
            when x"C" => lessegments := "11000110"; -- C
            when x"D" => lessegments := "10100001"; -- d
            when x"E" => lessegments := "10000110"; -- E
            when x"F" => lessegments := "10001110"; -- F
            when others => lessegments := "01111111"; -- erreur, affichage éteint sauf le point (ne devrait pas se produire)
        end case;
        
        return lessegments;
    
    end;
    
    -- fonction surchargée pour accepter une entrée de type signed
    function hex_to_7seg(chiffre_hex: quartet_signed) return segments is
    begin
        return hex_to_7seg(quartet(chiffre_hex));
    end;
    
    -- fonction surchargée pour accepter une entrée de type unsigned
    function hex_to_7seg(chiffre_hex: quartet_unsigned) return segments is
    begin
        return hex_to_7seg(quartet(chiffre_hex));
    end;
    
    -- fonction surchargée pour accepter une entrée de type BCD
    function BCD_to_7seg(chiffre_bcd: BCD) return segments is
    begin
        return hex_to_7seg(chiffre_bcd);
    end;

    ------------------------------------------------------------------------------------------------
    --
    -- décodeur pour caractères ASCII vers affichage à 7 segments (8 bits incluant le point)
    -- correspondances entre bits et segments:
    --      0
    --     ---  
    --  5 |   | 1
    --     ---   <- 6
    --  4 |   | 2
    --     ---
    --      3     
    --  point: bit 7
    --
    function character_to_7seg(caractere: character) return segments is
    variable lessegments : segments;
    begin
        case caractere is
            when ' ' => lessegments := "11111111";
            when '!' => lessegments := "01111001";
            when '"' => lessegments := "11011101";
            when '#' => lessegments := "00100011";
            when '$' => lessegments := "00010010";
            when '%' => lessegments := "00011100";
            when '&' => lessegments := "00001100";
            when ''' => lessegments := "11111101";
            when '(' => lessegments := "11000110";
            when ')' => lessegments := "11110000";
            when '*' => lessegments := "00111001";
            when '+' => lessegments := "10111001";
            when ',' => lessegments := "11110011";
            when '-' => lessegments := "10111111";
            when '.' => lessegments := "01111111";
            when '/' => lessegments := "10101101";
            when '0' => lessegments := "11000000";
            when '1' => lessegments := "11111001";
            when '2' => lessegments := "10100100";
            when '3' => lessegments := "10110000";
            when '4' => lessegments := "10011001";
            when '5' => lessegments := "10010010";
            when '6' => lessegments := "10000010";
            when '7' => lessegments := "11111000";
            when '8' => lessegments := "10000000";
            when '9' => lessegments := "10010000";
            when ':' => lessegments := "01111001";
            when ';' => lessegments := "01111001";
            when '<' => lessegments := "10100111";
            when '=' => lessegments := "10110111";
            when '>' => lessegments := "10110011";
            when '?' => lessegments := "00100100";
            when '@' => lessegments := "00100011";
            when 'A' => lessegments := "10001000";
            when 'B' => lessegments := "10000011";
            when 'C' => lessegments := "11000110";
            when 'D' => lessegments := "10100001";
            when 'E' => lessegments := "10000110";
            when 'F' => lessegments := "10001110";
            when 'G' => lessegments := "10010000";
            when 'H' => lessegments := "10001001";
            when 'I' => lessegments := "11111001";
            when 'J' => lessegments := "11100001";
            when 'K' => lessegments := "10001001";
            when 'L' => lessegments := "11000111";
            when 'M' => lessegments := "11001000";
            when 'N' => lessegments := "10101011";
            when 'O' => lessegments := "10100011";
            when 'P' => lessegments := "10001100";
            when 'Q' => lessegments := "01000000";
            when 'R' => lessegments := "10101111";
            when 'S' => lessegments := "10010010";
            when 'T' => lessegments := "11001110";
            when 'U' => lessegments := "11000001";
            when 'V' => lessegments := "11100011";
            when 'W' => lessegments := "11100011";
            when 'X' => lessegments := "11001001";
            when 'Y' => lessegments := "10011001";
            when 'Z' => lessegments := "10100100";
            when '[' => lessegments := "11000110";
            when '\' => lessegments := "10011011";
            when ']' => lessegments := "11110000";
            when '^' => lessegments := "11011100";
            when '_' => lessegments := "11110111";
            when '`' => lessegments := "11011111";
            when 'a' => lessegments := "00100011";
            when 'b' => lessegments := "10000011";
            when 'c' => lessegments := "10100111";
            when 'd' => lessegments := "10100001";
            when 'e' => lessegments := "10000110";
            when 'f' => lessegments := "10001110";
            when 'g' => lessegments := "10010000";
            when 'h' => lessegments := "10001011";
            when 'i' => lessegments := "11111011";
            when 'j' => lessegments := "11100001";
            when 'k' => lessegments := "10001001";
            when 'l' => lessegments := "11001111";
            when 'm' => lessegments := "10101011";
            when 'n' => lessegments := "10101011";
            when 'o' => lessegments := "10100011";
            when 'p' => lessegments := "10001100";
            when 'q' => lessegments := "10011000";
            when 'r' => lessegments := "10101111";
            when 's' => lessegments := "10010010";
            when 't' => lessegments := "11001110";
            when 'u' => lessegments := "11100011";
            when 'v' => lessegments := "11100011";
            when 'w' => lessegments := "11100011";
            when 'x' => lessegments := "10001001";
            when 'y' => lessegments := "10010001";
            when 'z' => lessegments := "10100100";
            when '{' => lessegments := "11000110";
            when '|' => lessegments := "11001111";
            when '}' => lessegments := "11110000";
            when '~' => lessegments := "10111111";
            when others => lessegments := "01111111"; -- erreur, affichage éteint sauf le point (ne devrait pas se produire)
        end case;
        
        return lessegments;
    
    end;
    

    ------------------------------------------------------------------------------------------------
    --
    -- Conversion d'un nombre binaire type unsigned vers décimal sur 3 chiffres (centaines, dizaines, unités) encodé en BCD.
    -- AVERTISSEMENT : ne fonctionne que pour des valeurs inférieures à 1000
    --
    -- Description combinatoire par encodeurs à priorité.
    --
    function unsigned_to_BCD(nombre : unsigned(9 downto 0)) return BCD3 is
    variable n, c, d, u : natural := 0;
    begin
        
        assert nombre < 1000 report "fonction unsigned_to_BCD, les nombres >= 1000 ne sont pas pris en charge" severity failure;

        n := to_integer(nombre);
        
        c := 0;
        for centaines in 9 downto 1 loop
            if n >= centaines * 100 then
                c := centaines;
                exit;
            end if;
        end loop;

        n := n - c * 100;

        d := 0;
        for dizaines in 9 downto 1 loop
            if n >= dizaines * 10 then
                d := dizaines;
                exit;
            end if;
        end loop;
        
        u := n - d * 10;
        
        return to_unsigned(c, 4) & to_unsigned(d, 4) & to_unsigned(u, 4);

    end;    
    
    
    ------------------------------------------------------------------------------------------------
    --
    -- obtenir le caractère ASCII correspondant à l'indice en encodage Base64
    -- référence : https://en.wikipedia.org/wiki/Base64
    -- L'encodage Base64 inclut les lettres majuscules, les lettres minuscules, les chiffres '0' à '9' et les caractères '+' et '/'
    --
    function indiceBase64_to_character(indice: natural range 0 to 63) return character is
    begin
        if indice <= 25 then
            -- lettres majuscules, 'A' = x"41" = 65
            return character'val(65 + indice);
        elsif indice <= 51 then           
            -- lettres minuscules, 'a' = x"61" = 97
            return character'val(97 + indice - 26);
        elsif indice <= 61 then
            -- chiffres 0 à 9, '0' = x"30" = 48
            return character'val(48 + indice- 52);
        elsif indice = 62 then
            return '+';
        else
            return '/';
        end if;
    end;

    
    ------------------------------------------------------------------------------------------------
    --
    -- obtenir le caractère ASCII correspondant au quartet en entrée : {'0' à '9', 'a' à 'f'}
    -- on choisit arbitrairement de prendre les lettres minuscules 'a' à 'f'
    --
    function hex_to_character(chiffre_hex: natural range 0 to 15) return character is
    begin
        if chiffre_hex <= 9 then
            -- les chiffres 0 à 9
            return character'val(48 + chiffre_hex);
        else
            -- lettres minuscules, 'a' = x"61" = 97
            return character'val(97 + chiffre_hex - 10);
        end if;
    end;

    ------------------------------------------------------------------------------------------------
    --
    -- obtenir le caractère ASCII correspondant au quartet en entrée : {'0' à '9', 'a' à 'f'}
    --
    function hex_to_character(chiffre_hex: quartet_unsigned) return character is
    begin
        return hex_to_character(to_integer(chiffre_hex));
    end;

    
    ------------------------------------------------------------------------------------------------
    --
    -- convertir un boolean en std_logic
    -- cette fonction est utile pour rendre le code plus compact
    -- remplace {si vrai alors F <= '1' sinon F <= '0'}
    --
    function bool2stdl(b : boolean) return std_logic is
    begin
        if b then
            return '1';
        else
            return '0';
        end if;
    end;
    
end;
