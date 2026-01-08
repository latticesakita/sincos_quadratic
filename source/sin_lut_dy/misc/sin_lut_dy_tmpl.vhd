component sin_lut_dy is
    port(
        rd_clk_i: in std_logic;
        rst_i: in std_logic;
        rd_en_i: in std_logic;
        rd_clk_en_i: in std_logic;
        rd_addr_i: in std_logic_vector(9 downto 0);
        rd_data_o: out std_logic_vector(35 downto 0)
    );
end component;

__: sin_lut_dy port map(
    rd_clk_i=>,
    rst_i=>,
    rd_en_i=>,
    rd_clk_en_i=>,
    rd_addr_i=>,
    rd_data_o=>
);
