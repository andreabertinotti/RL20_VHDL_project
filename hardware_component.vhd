-------------------------------------------------------------------------------- 
-- Company:  
-- Engineer:  
--  
-- Create Date: 24.08.2020 09:35:31 
-- Design Name:  
-- Module Name: project_reti_logiche - Behavioral 
-- Project Name:  
-- Target Devices:  
-- Tool Versions:  
-- Description:  
--  
-- Dependencies:  
--  
-- Revision: 
-- Revision 0.01 - File Created 
-- Additional Comments: 
--  
---------------------------------------------------------------------------------- 
 
 
library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL;  
use IEEE.STD_LOGIC_UNSIGNED.ALL;  
use ieee.numeric_std.all;  
 
 
entity project_reti_logiche is 
  Port ( 
           i_clk : in STD_LOGIC;  
           i_rst : in STD_LOGIC;              
           i_start : in STD_LOGIC;  
           i_data : in STD_LOGIC_VECTOR (7 downto 0);  
           o_done : out STD_LOGIC;  
           o_data : out STD_LOGIC_VECTOR (7 downto 0);  
           o_address : out STD_LOGIC_VECTOR (15 downto 0);  
           o_en : out STD_LOGIC;  
           o_we : out STD_LOGIC); 
end project_reti_logiche; 
 
architecture Behavioral of project_reti_logiche is 
 
signal addr, addr_next: STD_LOGIC_VECTOR (7 downto 0);  
signal wz, wz_next:  STD_LOGIC_VECTOR (7 downto 0);   
signal wz_num, wz_num_next:  STD_LOGIC_VECTOR (2 downto 0);  
signal offset, offset_next:  STD_LOGIC_VECTOR (3 downto 0);  
signal found, found_next: STD_LOGIC;  
signal sub, sub_next: STD_LOGIC_VECTOR (7 downto 0);  
signal result, result_next : STD_LOGIC_VECTOR (7 downto 0); 

signal holder, holder_next : Integer;


  

 
type S is (RESET, ADDR_READ, WZ_READ, SUBTRACTION, WZ_VERIFY, END_FOUND, END_NOT_FOUND, PRINT);  
signal cur_state, next_state : S;  
 
begin 
--consecutio degli stati  
    process(i_clk, i_rst, cur_state)  
    begin  
         
  
      if i_rst = '1' then    
          
         cur_state <= RESET; 
          
         addr <= "00000000";  
         wz <= "00000000";  
         wz_num <= "000";  
         offset <= "0000";  
         found <= '0';  
         sub <= "00000000"; 
         result <= "00000000"; 
         holder <= 0;
         
        
             
      elsif i_clk'event and i_clk = '1' then  
      
         cur_state <= next_state;  
          
         addr <= addr_next; 
         wz <= wz_next; 
         wz_num <= wz_num_next; 
         offset <= offset_next; 
         found <= found_next; 
         sub <= sub_next; 
         result <= result_next;
         holder <= holder_next;
         
 
         end if;  

    end process; 
 
  
process(cur_state, i_start, i_rst, i_data, addr, wz, wz_num, offset, found, sub, result) 
    variable sub_var : integer; 
    variable wz_num_var : integer; 
    variable stop :  STD_LOGIC;  
    begin 
     
    --inizializzo i valori  
     next_state <= cur_state;
     addr_next <= addr; 
     wz_next <= wz; 
     wz_num_next <= wz_num; 
     offset_next <= offset; 
     found_next <= found; 
     sub_next <= sub; 
     result_next <= result; 
     holder_next <= holder;
      
     o_we <= '0'; 
     o_en <= '1'; 
     o_done <= '0'; 
     o_address <= "0000000000000000";   
     o_data <= "00000000"; 
     
     

      
     case cur_state is 
      
        when RESET =>          
            if i_start='1' AND i_rst='0' then 
                o_address <= "0000000000001000"; -- cella 8 (leggo addr)
                o_en <= '1'; 
                o_we <= '0'; 
                wz_num_next <= "000"; 
                next_state <= ADDR_READ; 
            end if; 
         
        when ADDR_READ => 
            o_en <= '1'; 
            o_we <= '0'; 
            addr_next <= i_data; 
            o_address <= "0000000000000000"; -- cella 0 (leggo wz) 
            next_state <= WZ_READ; 
                 
        when WZ_READ =>  
            o_en <= '1'; 
            o_we <= '0'; 
            wz_next <= i_data;          
            wz_num_var := (to_integer(unsigned(wz_num)) + 1); 
            holder_next <= wz_num_var;          
            wz_num_next <= std_logic_vector(to_unsigned(wz_num_var, 3)); 
            next_state <= SUBTRACTION; 
             
        when SUBTRACTION => 
            o_en <= '0'; 
            o_we <= '0';             
            if (to_integer(unsigned(wz)) <= to_integer(unsigned(addr))) then 
                sub_var := (to_integer(unsigned(addr)) - to_integer(unsigned(wz))); 
                sub_next <= std_logic_vector(to_unsigned(sub_var, 8)); 
            else  
                sub_next <= "00011111"; 
            end if; 
            next_state <= WZ_VERIFY; 
             
        when WZ_VERIFY => 
         
        stop:= '0'; 
            wz_num_var := holder;
            if (to_integer(unsigned(sub)) >= 0 and to_integer(unsigned(sub)) <= 3 and (wz_num_var -1) < 8) then 
                found_next <= '1';  
                stop:= '1';  
                    if sub = "00000000" then  
                            offset_next <= "0001";  
                        elsif sub = "00000001" then  
                            offset_next <= "0010";  
                        elsif sub = "00000010" then  
                            offset_next <= "0100";  
                        else  
                            offset_next <= "1000";  
                    end if;  
                wz_num_var := (to_integer(unsigned(wz_num)) - 1); 
                wz_num_next <= std_logic_vector(to_unsigned(wz_num_var, 3)); 
                next_state <= END_FOUND;
           
            end if; 
            if (wz_num_var <= 7 and stop = '0') then 
                o_en <= '1'; 
                o_we <= '0'; 
                o_address <= std_logic_vector(to_unsigned(wz_num_var, 16)); 
                next_state <= WZ_READ; 
            elsif ( wz_num_var = 8 and stop = '0') then 
                o_we <= '1'; 
                o_en <= '1'; 
                next_state <= END_NOT_FOUND; 
            end if; 
             
        when END_FOUND => 
            o_en <= '1'; 
            o_we <= '1'; 
            result_next <= '1' & wz_num & offset; 
            o_address <= "0000000000001001"; 
            next_state <= PRINT; 
             
        when END_NOT_FOUND => 
            o_en <= '1'; 
            o_we <= '1'; 
            result_next <= addr; 
            o_address <= "0000000000001001"; 
            next_state <= PRINT; 
             
        when PRINT => 
            
            o_data <= result; 
            o_address <= "0000000000001001";  
            o_en <= '1'; 
            o_we <= '1'; 
            o_done <= '1';
            next_state <= RESET; 
            
         
             
             
        when others => 
         
     end case; 
      
  end process;             
 
end Behavioral;
