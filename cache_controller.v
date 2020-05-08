module cache_controller(clk, reset, i_addr, i_data, o_data, i_data_is_valid, o_data_is_valid, full, empty);

`ifdef FORMAL
	parameter C_DATA_WIDTH = 8; 
	parameter C_SIZE_OF_CACHE = 4;
`else
	parameter C_DATA_WIDTH = 128; 
	parameter C_SIZE_OF_CACHE = 64;
`endif

input clk, reset;
input i_data_is_valid; // input data is valid
input [C_DATA_WIDTH-1:0] i_data;
input [$clog2(C_SIZE_OF_CACHE)-1:0] i_addr; // address for reading cache content
output full;
output empty;
output reg o_data_is_valid; // output data is valid
output reg [C_DATA_WIDTH-1:0] o_data;

reg [C_DATA_WIDTH-1:0] cache [C_SIZE_OF_CACHE-1:0]; // in Xilinx vivado, this infers BRAM
reg [$clog2(C_SIZE_OF_CACHE)-1:0] cache_index;

localparam INTEGER_BITWIDTH = 32;
localparam BITWIDTH_DIFFERENCE_DATA_AND_INTEGER = (C_DATA_WIDTH > INTEGER_BITWIDTH) ? 
			C_DATA_WIDTH-INTEGER_BITWIDTH : INTEGER_BITWIDTH-C_DATA_WIDTH;

integer cache_entry_index; // address for writing cache content

always @(posedge clk)
begin
	if(reset) 
	begin
		cache_index <= 0;

		for(cache_entry_index = 0; cache_entry_index < C_SIZE_OF_CACHE; 
			cache_entry_index = cache_entry_index + 1)
		begin
			`ifdef FORMAL
				cache[cache_entry_index] <= cache_entry_index[C_DATA_WIDTH-1:0]; // acts as random initialization
			`else
				cache[cache_entry_index] <= {{(BITWIDTH_DIFFERENCE_DATA_AND_INTEGER){1'b0}}, cache_entry_index}; // acts as random initialization
			`endif
		end
	end

	else if(i_data_is_valid && !full) 
	begin
		cache[cache_index] <= i_data;
		cache_index <= cache_index + 1;
	end
end


always @(posedge clk)
begin
	if(reset) 
	begin
		o_data <= 0;
		o_data_is_valid <= 0;
	end

	else if(!empty) 
	begin
		o_data <= cache[i_addr];
		o_data_is_valid <= 1;
	end
end

localparam SKID_BUFFER_BACKPRESSURE_SPACE = 1;

assign empty = (reset) ? 1 : (cache_index == 0);
assign full = (reset) ? 0 : (cache_index == (C_SIZE_OF_CACHE[$clog2(C_SIZE_OF_CACHE)-1:0]-1));

endmodule
