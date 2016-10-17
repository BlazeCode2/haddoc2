library ieee;
	use	ieee.std_logic_1164.all;
	use	ieee.numeric_std.all;

library work;
	use work.cnn_types.all;


entity firstLayer is
    generic(
        PIXEL_SIZE    :   integer;
        IMAGE_WIDTH   :   integer;
        KERNEL_SIZE   :   integer;
        NB_OUT_FLOWS  :   integer;
        W_CONV_PARAMS :   pixel_matrix;
        N_CONV_PARAMS :   pixel_array
    );

    port(
        clk	          :   in  std_logic;
        reset_n	      :   in  std_logic;
        enable        :   in  std_logic;

        in_data       :   in  std_logic_vector (0 to PIXEL_SIZE - 1);
        in_dv         :   in  std_logic;
        in_fv         :   in  std_logic;

        out_data      :   out pixel_array      (0 to NB_OUT_FLOWS - 1);
        out_dv        :   out std_logic_vector (0 to NB_OUT_FLOWS - 1);
        out_fv        :   out std_logic_vector (0 to NB_OUT_FLOWS - 1)
    );
end entity;

architecture STRUCTURAL of firstLayer is
    --------------------------------------------------------------------------------
    -- COMPONENTS
    --------------------------------------------------------------------------------
    component neighExtractor
    generic(
		PIXEL_SIZE      :   integer;
		IMAGE_WIDTH     :   integer;
		KERNEL_SIZE     :   integer
	);

    port(
		clk	            :	in 	std_logic;
        reset_n	        :	in	std_logic;
        enable	        :	in	std_logic;
        in_data         :	in 	std_logic_vector((PIXEL_SIZE-1) downto 0);
        in_dv	        :	in	std_logic;
        in_fv	        :	in	std_logic;
        out_data        :	out	pixel_array (0 to (KERNEL_SIZE * KERNEL_SIZE)- 1);
        out_dv			:	out std_logic;
        out_fv			:	out std_logic
    );
    end component;

    --------------------------------------------------------------------------------
    component convElement
    generic(
        KERNEL_SIZE :    integer;
        PIXEL_SIZE  :    integer
    );

    port(
        clk         :   in  std_logic;
        reset_n     :   in  std_logic;
        enable      :   in  std_logic;
        in_data     :   in  pixel_array (0 to KERNEL_SIZE * KERNEL_SIZE - 1);
        in_dv    	:   in  std_logic;
        in_fv    	:   in  std_logic;
        in_kernel   :   in  pixel_array (0 to KERNEL_SIZE * KERNEL_SIZE - 1);
        in_norm     :   in  std_logic_vector(PIXEL_SIZE-1 downto 0);
        out_data    :   out std_logic_vector(PIXEL_SIZE-1 downto 0);
        out_dv    	:   out std_logic;
        out_fv    	:   out std_logic

    );
    end component;

    --------------------------------------------------------------------------------
    -- SIGNALS
    --------------------------------------------------------------------------------
    -- Output of the neighborhood extractor
    signal s_ne_data : pixel_array (0 to KERNEL_SIZE * KERNEL_SIZE - 1);
    signal s_ne_dv   : std_logic;
    signal s_ne_fv   : std_logic;

    signal W_CONV_PARAMS_ARRAY : pixel_array (0 to KERNEL_SIZE * KERNEL_SIZE - 1);

    begin

        -- Extract neighborhood
        NE_INST : neighExtractor
        generic map(
            PIXEL_SIZE	 => PIXEL_SIZE,
            IMAGE_WIDTH  => IMAGE_WIDTH,
            KERNEL_SIZE	 => KERNEL_SIZE
        )
        port map(
            clk	         => clk,
            reset_n	     => reset_n,
            enable	     => enable,
            in_data      => in_data,
            in_dv	     => in_dv,
            in_fv	     => in_fv,
            out_data     => s_ne_data,
            out_dv	     => s_ne_dv,
            out_fv	     => s_ne_fv
        );

        -- Process Convolutions
        CEs_loop : for i in 0 to (NB_OUT_FLOWS - 1) generate

            -- Load kernels in array : matrix to tmp array
            tmp_loop : for j in 0 to (KERNEL_SIZE * KERNEL_SIZE - 1) generate
                W_CONV_PARAMS_ARRAY(j) <= W_CONV_PARAMS(i,j);
            end generate tmp_loop;

            -- Inst Conv Element
            CEs_inst : convElement
            generic map(
                KERNEL_SIZE => KERNEL_SIZE,
                PIXEL_SIZE  => PIXEL_SIZE
            )
            port map(
                clk         => clk,
                reset_n     => reset_n,
                enable      => enable,
                in_data     => s_ne_data,
                in_dv    	=> s_ne_dv,
                in_fv    	=> s_ne_fv,
                in_kernel   => W_CONV_PARAMS_ARRAY,
                in_norm     => N_CONV_PARAMS(i),
                out_data    => out_data,
                out_dv    	=> out_dv,
                out_fv    	=> out_fv
            );
        end generate CEs_loop;

end STRUCTURAL;