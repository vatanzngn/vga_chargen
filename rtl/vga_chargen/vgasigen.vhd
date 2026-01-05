library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vgasigen is
    port(
        PX_CLK_I        : in  std_logic;                    -- Pixel Clock
        RST_I           : in  std_logic;                    -- Active High Reset
        RES_SEL_I       : in  std_logic_vector(1 downto 0); -- 00:VGA, 01:SVGA, 10:WSXGA, 11:FHD
        FONT_SEL_I      : in  std_logic_vector(1 downto 0); -- 00:16px, 01:32px, 10:64px

        VISIBLE_O       : out std_logic;
        VGA_HSYNC_O     : out std_logic;
        VGA_VSYNC_O     : out std_logic;       
        CHAR_PTR_O      : out unsigned(13 downto 0); 
        
        PTR_PX_X_O      : out unsigned(5 downto 0); 
        PTR_PX_Y_O      : out unsigned(5 downto 0)  
    );
end entity;

architecture rtl of vgasigen is

    signal r_h_end_active : integer range 0 to 1920;
    signal r_h_beg_sync   : integer range 0 to 2008;
    signal r_h_end_sync   : integer range 0 to 2052;
    signal r_h_total      : integer range 0 to 2200;

    signal r_v_end_active : integer range 0 to 1080;
    signal r_v_beg_sync   : integer range 0 to 1084;
    signal r_v_end_sync   : integer range 0 to 1089;
    signal r_v_total      : integer range 0 to 1125;
    
    signal r_pol          : std_logic;

    signal r_shift_amt     : integer range 0 to 6;
    signal r_chars_per_row : integer range 0 to 255;

    signal cnt_h : integer range 0 to 2200 := 0;
    signal cnt_v : integer range 0 to 1125 := 0;

    signal s_hsync_s0, s_vsync_s0, s_visible_s0 : std_logic;

    signal s_hsync_s1, s_vsync_s1, s_visible_s1 : std_logic;
    signal s_ptr_px_x      : unsigned(5 downto 0); 
    signal s_ptr_px_y      : unsigned(5 downto 0);
    signal s_ptr_ch_x      : unsigned(7 downto 0); 
    signal s_ptr_ch_y      : unsigned(7 downto 0); 

    signal s_hsync_s2, s_vsync_s2, s_visible_s2 : std_logic;
    signal s_multvalue     : unsigned(15 downto 0);
    signal s_ptr_ch_x_d1   : unsigned(7 downto 0);
    signal s_ptr_px_x_d1   : unsigned(5 downto 0);
    signal s_ptr_px_y_d1   : unsigned(5 downto 0);

    signal s_hsync_s3, s_vsync_s3, s_visible_s3 : std_logic;
    signal s_charmem_ptr   : unsigned(13 downto 0);
    signal s_ptr_px_x_d2   : unsigned(5 downto 0);
    signal s_ptr_px_y_d2   : unsigned(5 downto 0);

begin

    process(RES_SEL_I, FONT_SEL_I)
    begin
        r_h_end_active  <= 640; 
        r_h_beg_sync    <= 656; 
        r_h_end_sync    <= 752; 
        r_h_total       <= 800;
        r_v_end_active  <= 480; 
        r_v_beg_sync    <= 490; 
        r_v_end_sync    <= 492; 
        r_v_total       <= 525;
        r_pol           <= '0';
        r_shift_amt     <= 4;
        r_chars_per_row <= 40;

        -- RESOLUTION MUX
        case RES_SEL_I is
            when "00" => -- VGA (640x480) @ 60Hz (25 MHz)
                r_h_end_active <= 640;
                r_h_beg_sync   <= 656;  -- 640+16
                r_h_end_sync   <= 752;  -- 656+96
                r_h_total      <= 800;  -- 752+48
                r_v_end_active <= 480;
                r_v_beg_sync   <= 490;  -- 480+10
                r_v_end_sync   <= 492;  -- 490+2
                r_v_total      <= 525;  -- 492+33
                r_pol          <= '0';  -- Negative Polarity

            when "01" => -- SVGA (800x600) @ 60Hz (40 MHz)
                r_h_end_active <= 800;
                r_h_beg_sync   <= 840;  -- 800+40
                r_h_end_sync   <= 968;  -- 840+128
                r_h_total      <= 1056; -- 968+88
                r_v_end_active <= 600;
                r_v_beg_sync   <= 601;  -- 600+1
                r_v_end_sync   <= 605;  -- 601+4
                r_v_total      <= 628;  -- 605+23
                r_pol          <= '1';  -- Positive Polarity

            when "10" => -- WSXGA (1600x900) @ 60Hz (108 MHz)
                r_h_end_active <= 1600;
                r_h_beg_sync   <= 1624; -- 1600+24
                r_h_end_sync   <= 1704; -- 1624+80
                r_h_total      <= 1800; -- 1704+96
                r_v_end_active <= 900;
                r_v_beg_sync   <= 901;  -- 900+1
                r_v_end_sync   <= 904;  -- 901+3
                r_v_total      <= 1000; -- 904+96
                r_pol          <= '1';

            when "11" => -- FHD (1920x1080) @ 60Hz (148.5 MHz)
                r_h_end_active <= 1920;
                r_h_beg_sync   <= 2008; -- 1920+88
                r_h_end_sync   <= 2052; -- 2008+44
                r_h_total      <= 2200; -- 2052+148
                r_v_end_active <= 1080;
                r_v_beg_sync   <= 1084; -- 1080+4
                r_v_end_sync   <= 1089; -- 1084+5
                r_v_total      <= 1125; -- 1089+36
                r_pol          <= '1';

            when others => null;
        end case;

        -- FONT SIZE MUX
        -- Calculates shift amount and chars per row based on selected resolution width
        if FONT_SEL_I = "01" then     -- 32px Font
            r_shift_amt <= 5; 
            case RES_SEL_I is
                when "00" => r_chars_per_row <= 20;  -- 640/32
                when "01" => r_chars_per_row <= 25;  -- 800/32
                when "10" => r_chars_per_row <= 50;  -- 1600/32
                when "11" => r_chars_per_row <= 60;  -- 1920/32
                when others => r_chars_per_row <= 20;
            end case;
        elsif FONT_SEL_I = "10" then  -- 64px Font
            r_shift_amt <= 6;
            case RES_SEL_I is
                when "00" => r_chars_per_row <= 10;  -- 640/64
                when "01" => r_chars_per_row <= 12;  -- 800/64
                when "10" => r_chars_per_row <= 25;  -- 1600/64
                when "11" => r_chars_per_row <= 30;  -- 1920/64
                when others => r_chars_per_row <= 10;
            end case;
        else                          -- 16px Font (Default)
            r_shift_amt <= 4;
            case RES_SEL_I is
                when "00" => r_chars_per_row <= 40;  -- 640/16
                when "01" => r_chars_per_row <= 50;  -- 800/16
                when "10" => r_chars_per_row <= 100; -- 1600/16
                when "11" => r_chars_per_row <= 120; -- 1920/16
                when others => r_chars_per_row <= 40;
            end case;
        end if;
    end process;

    P_SEQ_PROC : process (PX_CLK_I) 
        variable v_mask : unsigned(11 downto 0);
    begin
        if rising_edge(PX_CLK_I) then
            if RST_I = '1' then
                cnt_h <= 0; cnt_v <= 0;
                s_hsync_s0 <= '0'; s_vsync_s0 <= '0'; s_visible_s0 <= '0';
                s_hsync_s3 <= '0'; s_vsync_s3 <= '0'; s_visible_s3 <= '0';
                s_multvalue <= (others=>'0');
                s_charmem_ptr <= (others=>'0');
            else
                
                -- FF 1: Counters & Raw Syncs
                if cnt_h < r_h_total - 1 then
                    cnt_h <= cnt_h + 1;
                else
                    cnt_h <= 0;
                    if cnt_v < r_v_total - 1 then 
                        cnt_v <= cnt_v + 1; 
                    else 
                        cnt_v <= 0; 
                    end if;
                end if;

                -- Generate H-Sync
                if (cnt_h >= r_h_beg_sync) and (cnt_h < r_h_end_sync) then 
                    s_hsync_s0 <= r_pol; 
                else 
                    s_hsync_s0 <= not r_pol; 
                end if;

                -- Generate V-Sync
                if (cnt_v >= r_v_beg_sync) and (cnt_v < r_v_end_sync) then
                     s_vsync_s0 <= r_pol; 
                else
                    s_vsync_s0 <= not r_pol; 
                end if;

                -- Generate Active Video Flag
                if (cnt_h < r_h_end_active) and (cnt_v < r_v_end_active) then 
                    s_visible_s0 <= '1'; 
                else 
                    s_visible_s0 <= '0'; 
                end if;

                -- FF 2: Calculate Indices
                s_ptr_ch_x <= resize(shift_right(to_unsigned(cnt_h, 12), r_shift_amt), s_ptr_ch_x'length); -- Calculate Character Index (X) by Shifting (Division)
                s_ptr_ch_y <= resize(shift_right(to_unsigned(cnt_v, 12), r_shift_amt), s_ptr_ch_y'length); -- Calculate Character Index (Y) by Shifting (Division)
                
                v_mask := shift_left(to_unsigned(1, 12), r_shift_amt) - 1;         -- Calculate Pixel Offset (X/Y) by Masking (Modulo)
                s_ptr_px_x <= resize(to_unsigned(cnt_h, 12) and v_mask, s_ptr_px_x'length);
                s_ptr_px_y <= resize(to_unsigned(cnt_v, 12) and v_mask, s_ptr_px_y'length);


                -- FF 3: Base Address (Mult)
                s_multvalue   <= s_ptr_ch_y * to_unsigned(r_chars_per_row, 8);     -- Calculate Row Base Address: Row_Index * Chars_Per_Row
                s_ptr_ch_x_d1 <= s_ptr_ch_x;                                       -- Delay needed signals to align with Multiplication result


                -- FF 4: Final Address (Add)
                s_charmem_ptr <= resize(s_multvalue + s_ptr_ch_x_d1, s_charmem_ptr'length); -- Base_Addr + Col_Index

                
                -- Add Pipe Latency
                s_hsync_s1    <= s_hsync_s0;
                s_hsync_s2    <= s_hsync_s1; 
                s_hsync_s3    <= s_hsync_s2;

                s_vsync_s1    <= s_vsync_s0;
                s_vsync_s2    <= s_vsync_s1; 
                s_vsync_s3    <= s_vsync_s2;

                s_visible_s1  <= s_visible_s0;
                s_visible_s2  <= s_visible_s1;
                s_visible_s3  <= s_visible_s2;

                s_ptr_px_x_d1 <= s_ptr_px_x;
                s_ptr_px_x_d2 <= s_ptr_px_x_d1;

                s_ptr_px_y_d1 <= s_ptr_px_y;
                s_ptr_px_y_d2 <= s_ptr_px_y_d1;

            end if;
        end if;
    end process;

    CHAR_PTR_O  <= s_charmem_ptr;
    PTR_PX_X_O  <= s_ptr_px_x_d2;
    PTR_PX_Y_O  <= s_ptr_px_y_d2;
    
    VGA_HSYNC_O <= s_hsync_s3;
    VGA_VSYNC_O <= s_vsync_s3;
    VISIBLE_O   <= s_visible_s3;

end architecture;