`define LOOPBACK 1

module axi_master(clk, reset,
			i_axi_awready, o_axi_awid, o_axi_awaddr, o_axi_awlen, o_axi_awsize, o_axi_awburst,
		 	o_axi_awlock, o_axi_awcache, o_axi_awprot, o_axi_awqos, o_axi_awvalid,
			i_axi_wready, o_axi_wdata, o_axi_wstrb, o_axi_wlast, o_axi_wvalid,
			i_axi_bid, i_axi_bresp, i_axi_bvalid, o_axi_bready, 
			i_axi_arready, o_axi_arid, o_axi_araddr, o_axi_arlen, o_axi_arsize, o_axi_arburst,
			o_axi_arlock, o_axi_arcache, o_axi_arprot, o_axi_arqos, o_axi_arvalid,
			i_axi_rid, i_axi_rresp, i_axi_rvalid, i_axi_rdata, i_axi_rlast, o_axi_rready);


`ifdef FORMAL
	// AXI Address width (log wordsize) for slave
	parameter C_AXI_ADDR_WIDTH = 12; 
	parameter C_AXI_DATA_WIDTH = 8; // related to AxSIZE
	parameter C_SIZE_OF_CACHE = 4; // for storing weights and biases parameters of neural network
`else
	// AXI Address width (log wordsize) for slave
	parameter C_AXI_ADDR_WIDTH = 12; // just for random test
	parameter C_AXI_DATA_WIDTH = 128; // related to AxSIZE
	parameter C_SIZE_OF_CACHE = 64; // for storing weights and biases parameters of neural network
`endif

parameter C_AXI_ID_WIDTH	=   1;

localparam NUM_OF_BITS_PER_BYTES = 8;
localparam INCR_BURST_TYPE = 2'b01; // AxBURST[2:0] , see 'burst type' section in AXI spec

// AXI4 extends burst length support for the INCR burst type to 1 to 256 transfers. 
// Support for all other burst types in AXI4 remains at 1 to 16 transfers.
// for wrapping bursts, the burst length must be 2, 4, 8, or 16
// a burst must not cross a 4KB address boundary
// early termination of bursts is not supported
localparam MAX_BURST_LENGTH = 256; 

localparam BURST_SIZE_ENCODING_WIDTH = 3; // AxSIZE[2:0] , see 'burst size' section in AXI spec
localparam SUBWORD_SMALLEST_UNIT = 8; // smallest granularity in AXI protocol : 8 bit
localparam PROT_BITWIDTH = 3;
localparam QOS_BITWIDTH = 4;
localparam CACHE_BITWIDTH = 4;

localparam BITWIDTH_DIFFERENCE_ADDR_AND_BURST_LENGTH = 
			 (C_AXI_ADDR_WIDTH > $clog2(MAX_BURST_LENGTH)) ?
		C_AXI_ADDR_WIDTH-$clog2(MAX_BURST_LENGTH) : $clog2(MAX_BURST_LENGTH)-C_AXI_ADDR_WIDTH ;

input clk, reset;

// AXI write address channel signals
	input	wire			i_axi_awready; // Slave is ready to accept
	output	wire	[C_AXI_ID_WIDTH-1:0]	o_axi_awid;	// Write ID
	output	reg		[C_AXI_ADDR_WIDTH-1:0]	o_axi_awaddr;	// Write address
	output	wire	[$clog2(MAX_BURST_LENGTH)-1:0]		o_axi_awlen;	// Write Burst Length
	output	wire	[BURST_SIZE_ENCODING_WIDTH-1:0]		o_axi_awsize;	// Write Burst size
	output	wire	[1:0]		o_axi_awburst;	// Write Burst type
	output	wire	[0:0]		o_axi_awlock;	// Write lock type
	output	wire	[CACHE_BITWIDTH-1:0]		o_axi_awcache;	// Write Cache type
	output	wire	[PROT_BITWIDTH-1:0]		o_axi_awprot;	// Write Protection type
/* verilator lint_off UNUSED */
	output	wire	[QOS_BITWIDTH-1:0]		o_axi_awqos;	// Write Quality of Svc
/* verilator lint_on UNUSED */
	output	reg			o_axi_awvalid;	// Write address valid

// AXI write data channel signals
	input	wire			i_axi_wready;  // Write data ready
	output	reg	[C_AXI_DATA_WIDTH-1:0]	o_axi_wdata;	// Write data
	output	reg	[C_AXI_DATA_WIDTH/SUBWORD_SMALLEST_UNIT-1:0] o_axi_wstrb;	// Write strobes
	output	reg			o_axi_wlast;	// Last write transaction
	output	reg			o_axi_wvalid;	// Write valid

// AXI write response channel signals
/* verilator lint_off UNUSED */
	input 	wire [C_AXI_ID_WIDTH-1:0]	i_axi_bid;	// Response ID
/* verilator lint_on UNUSED */
	input	wire [1:0]		i_axi_bresp;	// Write response
	input	wire			i_axi_bvalid;  // Write reponse valid
	output	wire			o_axi_bready;  // Response ready

// AXI read address channel signals
	input	wire			i_axi_arready;	// Read address ready
	output	wire	[C_AXI_ID_WIDTH-1:0]	o_axi_arid;	// Read ID
	output	reg 	[C_AXI_ADDR_WIDTH-1:0]	o_axi_araddr;	// Read address
	output	wire	[$clog2(MAX_BURST_LENGTH)-1:0]		o_axi_arlen;	// Read Burst Length
	output	wire	[BURST_SIZE_ENCODING_WIDTH-1:0]		o_axi_arsize;	// Read Burst size
	output	wire	[1:0]		o_axi_arburst;	// Read Burst type
	output	wire	[0:0]		o_axi_arlock;	// Read lock type
	output	wire	[CACHE_BITWIDTH-1:0]		o_axi_arcache;	// Read Cache type
	output	wire	[PROT_BITWIDTH-1:0]		o_axi_arprot;	// Read Protection type
/* verilator lint_off UNUSED */
	output	wire	[QOS_BITWIDTH-1:0]		o_axi_arqos;	// Read Quality of Svc
/* verilator lint_on UNUSED */
	output	reg			o_axi_arvalid;	// Read address valid

/* verilator lint_off UNUSED */
// AXI read data channel signals
	input wire 		[C_AXI_ID_WIDTH-1:0]	i_axi_rid;     // Response ID
/* verilator lint_on UNUSED */
	input	wire	[1:0]		i_axi_rresp;   // Read response
	input	wire			i_axi_rvalid;  // Read reponse valid
	input 	wire 	[C_AXI_DATA_WIDTH-1:0] i_axi_rdata;    // Read data
	input	wire			i_axi_rlast;    // Read last
	output	wire			o_axi_rready;  // Read Response ready




always @(posedge clk) 
begin
	if(reset) o_axi_wstrb <= 0;

	// burst alignment mechanism, see https://i.imgur.com/jKbzfFo.png
	// o_axi_wstrb <= (~0) << (o_axi_awaddr % (o_axi_awlen+1));
	// all the bracket variables are for removing verilator width warnings

	else o_axi_wstrb <= (C_AXI_DATA_WIDTH == SUBWORD_SMALLEST_UNIT) ? 1'b1 : 
								((~0) << (o_axi_awaddr % 
						   		  {{(BITWIDTH_DIFFERENCE_ADDR_AND_BURST_LENGTH){1'b0}},
								    (o_axi_awlen+1'b1)}));
end

wire write_response_is_ok = i_axi_bvalid && ((i_axi_bresp == 'b00) || (i_axi_bresp == 'b01));

// need to implement data re-transmission
wire write_response_is_not_ok = i_axi_bvalid && !((i_axi_bresp == 'b00) || (i_axi_bresp == 'b01));


always @(posedge clk) 
begin
	if(reset) 
	begin 
		o_axi_wvalid <= 0;
	end

	else if(!(o_axi_wvalid && !i_axi_wready))
	begin
		// since this is for testing, WDATA just uses some values within the write data space
		// Note: a master must not wait for AWREADY to be asserted before driving WVALID
		o_axi_wvalid <= (o_axi_wlast) ? 0 : 
						(o_axi_wdata < {C_AXI_DATA_WIDTH{1'b1}}); 
	end
end

wire slave_write_address_range_is_valid = (o_axi_awaddr < (1 << C_AXI_ADDR_WIDTH));

always @(posedge clk) 
begin	
	if(reset) o_axi_awvalid <= 0;

	// AXI specification: A3.3.1 Dependencies between channel handshake signal
	// the VALID signal of the AXI interface sending information must not be dependent on 
	// the READY signal of the AXI interface receiving that information
	// this is to prevent deadlock 
	// since AXI slave could wait for i_axi_awvalid to be true before setting o_axi_awready true.
	// Note: For same interface, VALID cannot depend upon READY, but READY can depends upon VALID
	// Note: Once VALID is asserted, it MUST be kept asserted until READY is asserted.
	// 		 VALID signal needs to be set (initially) independent of READY signal, 
	// 		 and then only ever adjusted if !(VALID && !READY)
	// Note: the master must not wait for the slave to assert AWREADY before asserting AWVALID
	// Note: (!(o_axi_awvalid && !i_axi_awready)) == (!awvalid || awready) 
	//       == (!awvalid || (awvalid && awready)). 
	//		 it means "no transaction in progress or transaction accepted"
	else if(!(o_axi_awvalid && !i_axi_awready))
			o_axi_awvalid <= /*i_axi_awready &&*/ (slave_write_address_range_is_valid);
end

reg [C_AXI_ADDR_WIDTH-1:0] axi_awaddr_previous;
always @(posedge clk)
begin
	if(reset) axi_awaddr_previous <= 0;

	else if(address_write_transaction_is_accepted) axi_awaddr_previous <= o_axi_awaddr;
end

wire write_transaction_is_accepted = (o_axi_wvalid) && (i_axi_wready);
wire address_write_transaction_is_accepted = (o_axi_awvalid) && (i_axi_awready);

wire bad_bresp_just_arrived = (!axi_bvalid_previous) && write_response_is_not_ok;

always @(posedge clk)
begin
	if(reset) o_axi_awaddr <= 0;

	else if(address_write_transaction_is_accepted) 
	begin
		if(write_response_is_not_ok) o_axi_awaddr <= axi_awaddr_previous;
		
		else o_axi_awaddr <= ((retransmit_wdata_now) ? axi_awaddr_previous : o_axi_awaddr) + 
							{{(BITWIDTH_DIFFERENCE_ADDR_AND_BURST_LENGTH){1'b0}}, 
								(o_axi_awlen+1'b1)} * (1 << o_axi_awsize);
	end
end

reg axi_bvalid_previous;
always @(posedge clk) axi_bvalid_previous <= i_axi_bvalid;

reg needs_to_retransmit_wdata; // a signal to prepare for asserting 'retransmit_wdata_now' in the next burst
reg retransmit_wdata_now;
// needs to store the entire write burst of data in the case of bad BRESP from AXI slave,
// let the next pair of AWADDR and WDATA to proceed before retransmitting the previous pair of AWADDR and WDATA
// because AWADDR is clocked-reg and can only transitions after (AWVALID && AWREADY) is true,
// and AWREADY as well as BVALID from AXI slave can be asserted at same clock edge
reg [C_AXI_DATA_WIDTH-1:0]  wdata_to_be_retransmitted [AxLEN:0];

always @(posedge clk)
begin
	if(reset || (retransmission_index == AxLEN)) retransmit_wdata_now <= 0;
	
	else if(needs_to_retransmit_wdata && o_axi_wlast && (retransmission_index != o_axi_awlen+1))
		retransmit_wdata_now <= 1;
end

`ifdef LOOPBACK

generate

genvar wdata_index;

	for(wdata_index=0; wdata_index<=AxLEN; wdata_index=wdata_index+1)
	begin
		always @(posedge clk) 
			if(bad_bresp_just_arrived && !retransmit_wdata_now) 
				wdata_to_be_retransmitted[wdata_index] <= o_axi_wdata - AxLEN + wdata_index;
	end

endgenerate

`endif

always @(*)
begin
	if(reset || write_response_is_ok) needs_to_retransmit_wdata = 0;
	
	else if(write_response_is_not_ok) needs_to_retransmit_wdata = 1;
end

reg [$clog2(AxLEN):0] retransmission_index;
reg [$clog2(AxLEN):0] retransmission_index_previous;

always @(posedge clk)
begin
	if(reset) retransmission_index <= 0;
	
	else if(retransmit_wdata_now) retransmission_index <= retransmission_index + 1;
	
	else retransmission_index <= 0;
end

always @(posedge clk) 
begin
	if(reset) retransmission_index_previous <= 0;

	else retransmission_index_previous <= retransmission_index;
end

wire wdata_retransmission_just_finished
	= (retransmission_index == 0) && (retransmission_index_previous == AxLEN+1);

reg [C_AXI_DATA_WIDTH-1:0] axi_wdata_next;

always @(posedge clk) 
	if(o_axi_wlast && needs_to_retransmit_wdata) axi_wdata_next <= o_axi_wdata;

always @(posedge clk)
begin
	if(reset) o_axi_wdata <= 0;

	else if(!(o_axi_wvalid && !i_axi_wready)) 
	begin
		if(retransmit_wdata_now) 
			o_axi_wdata <= wdata_to_be_retransmitted[retransmission_index];
		
		else o_axi_wdata <= ((wdata_retransmission_just_finished) ? axi_wdata_next : o_axi_wdata) 
								+ (!o_axi_wlast);
	end
end

`ifdef LOOPBACK

wire data_had_been_written_successfully = write_response_is_ok && o_axi_bready;

wire read_address_contains_loopback_data = data_had_been_written_successfully &&
(o_axi_awaddr >= (o_axi_araddr + {{(BITWIDTH_DIFFERENCE_ADDR_AND_BURST_LENGTH){1'b0}}, o_axi_awlen}));

`endif

wire slave_read_address_range_is_valid = (o_axi_araddr < (1 << C_AXI_ADDR_WIDTH));


always @(posedge clk) 
begin	
	if(reset) o_axi_arvalid <= 0;

	// AXI specification: A3.3.1 Dependencies between channel handshake signal
	// the VALID signal of the AXI interface sending information must not be dependent on 
	// the READY signal of the AXI interface receiving that information
	// this is to prevent deadlock 
	// since AXI slave could wait for i_axi_arvalid to be true before setting o_axi_arready true.
	// Note: For same interface, VALID cannot depend upon READY, but READY can depends upon VALID
	// Note: Once VALID is asserted, it MUST be kept asserted until READY is asserted.
	// 		 VALID signal needs to be set (initially) independent of READY signal, 
	// 		 and then only ever adjusted if !(VALID && !READY)
	// Note: the master must not wait for the slave to assert ARREADY before asserting ARVALID
	// Note: (!(o_axi_arvalid && !i_axi_arready)) == (!arvalid || arready) 
	//       == (!arvalid || (arvalid && arready)). 
	//		 it means "no transaction in progress or transaction accepted"
	else if(!(o_axi_arvalid && !i_axi_arready))
		`ifdef LOOPBACK
			o_axi_arvalid <= /*i_axi_arready &&*/ (slave_read_address_range_is_valid) && 
							//(read_address_contains_loopback_data) && 
							(o_axi_bready && i_axi_bvalid && write_response_is_ok);
		`else
			o_axi_arvalid <= /*i_axi_arready &&*/ (slave_read_address_range_is_valid);
		`endif
end


reg [$clog2(MAX_BURST_LENGTH)-1:0] num_of_write_transactions;

always @(posedge clk) 
begin	
	if(reset) num_of_write_transactions <= 0;

	else if(o_axi_wvalid && i_axi_wready)
			num_of_write_transactions <= (o_axi_wlast) ? 0 : num_of_write_transactions + 1;
end

always @(posedge clk) 
begin	
	if(reset) o_axi_wlast <= 0;

	else o_axi_wlast <= (num_of_write_transactions == (o_axi_awlen - 1));
end

localparam AxLEN = 15;

assign o_axi_awid = 0;
assign o_axi_awlen = AxLEN; // each burst has (Burst_Length = AxLEN[7:0] + 1) data transfers

/* verilator lint_off WIDTH */

// 128 bits (16 bytes) of data when AxSIZE[2:0] = 3'b100
// Burst_Length = AxLEN[7:0] + 1, to accommodate the extended burst length of the INCR burst type

assign o_axi_awsize = $clog2(C_AXI_DATA_WIDTH/NUM_OF_BITS_PER_BYTES); 
assign o_axi_arsize = $clog2(C_AXI_DATA_WIDTH/NUM_OF_BITS_PER_BYTES);

/* verilator lint_on WIDTH */

assign o_axi_awburst = INCR_BURST_TYPE;
assign o_axi_awlock = 0;
assign o_axi_awcache = 0;
assign o_axi_awprot = 0;

/* verilator lint_off UNUSED */
assign o_axi_awqos = 0; // no priority or QoS concept
assign o_axi_arqos = 0; // no priority or QoS concept
/* verilator lint_on UNUSED */

assign o_axi_arburst = INCR_BURST_TYPE;

assign o_axi_arlen = AxLEN; // each burst has (Burst_Length = AxLEN[7:0] + 1) data transfers
assign o_axi_arprot = 3'b010; // {data access, non-secure access, unprivileged access}
assign o_axi_arlock = 0; // AXI4 does not support locked transactions. 
assign o_axi_arcache = 0; // mostly used for HPS (hard processor system) such as ARM hard CPU IP

assign o_axi_arid = 0; // for this demo, there is only one AXI slave

// what situations will render data requester (AXI master) busy to receive read response ??
// such as AXI interconnect where arbitration will fail to acquire the data transfer priority
// such as the internal cache storage to store the data from external slave memory is now full
// So, let's use a random value that is $anyseq in formal verification
assign o_axi_rready = (reset) ? 1 : `ifdef FORMAL $anyseq `else (!cache_is_full) `endif; 

// The master can wait for BVALID before asserting BREADY.
// The master can assert BREADY before BVALID is asserted.
assign o_axi_bready = (reset) ? 1 : `ifdef FORMAL $anyseq `else (i_axi_bvalid) `endif; 

wire address_read_transaction_is_accepted = (o_axi_arvalid) && (i_axi_arready);

reg [C_AXI_ADDR_WIDTH-1:0] araddr; // introduces another clock cycles of delay

always @(posedge clk)
begin
	if(reset) araddr <= {{(BITWIDTH_DIFFERENCE_ADDR_AND_BURST_LENGTH){1'b0}},
						 (o_axi_arlen+1'b1)} * (1 << o_axi_arsize);

	else if(address_read_transaction_is_accepted) 
		araddr <= araddr + {{(BITWIDTH_DIFFERENCE_ADDR_AND_BURST_LENGTH){1'b0}},
							(o_axi_arlen+1'b1)} * (1 << o_axi_arsize);
end

always @(posedge clk)
begin
	if(reset) o_axi_araddr <= 0;

	// When ARVALID & ARREADY are both high the next ARADDR can be generated 
	// because the current address for the current transfer is now complete (ARVALID & ARREADY).
	else if(address_read_transaction_is_accepted) 
		o_axi_araddr <= araddr; // increments slave address to read instructions from
end


/* verilator lint_off UNUSED */
wire arm_write_param_enable; // neural network layers to start another intermediate computations
wire [C_AXI_DATA_WIDTH-1:0] arm_write_param_data; // NN params going to neural network layers

wire cache_is_empty; // no NN params to feed into the neural network layers

wire [$clog2(C_SIZE_OF_CACHE)-1:0] cache_address_for_reading;
assign cache_address_for_reading = 0; // for testing only
/* verilator lint_on UNUSED */


wire valid_read_response_does_not_contain_error_messages = i_axi_rvalid && (i_axi_rresp == 0);

wire cache_is_full; // needed since C_SIZE_OF_CACHE is always smaller than SIZE_OF_SLAVE_MEMORY


// this acts as intermediate cache (much smaller size than slave memory)
cache_controller #(.C_DATA_WIDTH(C_AXI_DATA_WIDTH), .C_SIZE_OF_CACHE(C_SIZE_OF_CACHE)) cache_mem
(
	.clk(clk), .reset(reset),
  	.i_data(i_axi_rdata),   // data coming from slave memory
  	.i_data_is_valid   		// slave data is valid
	 ((o_axi_rready && valid_read_response_does_not_contain_error_messages)),
	.i_addr(cache_address_for_reading),
	.full(cache_is_full), 
	.o_data(arm_write_param_data), 
	.o_data_is_valid(arm_write_param_enable), 
	.empty(cache_is_empty) 
);

`ifdef FORMAL

localparam ADDR_INDEX = 1;

wire [C_AXI_ADDR_WIDTH-1:0] ADDRESS_IN_REQUEST 
							= ADDR_INDEX * (o_axi_arlen+1'b1) * (1 << o_axi_arsize);

wire retry_transaction_after_nack = o_axi_bready && i_axi_bvalid && write_response_is_not_ok;

initial assume(reset);

reg first_clock_had_passed = 0;

always @(posedge clk) first_clock_had_passed <= 1;

/*
always @(posedge clk)
begin
	if(first_clock_had_passed)
	begin
		cover(o_axi_araddr >= SECOND_ADDRESS_IN_REQUEST);
		cover(!o_axi_rready);
		cover(address_read_transaction_is_accepted);
	end
end
*/

always @(posedge clk) 
begin
	if(first_clock_had_passed) 
	begin
		cover((o_axi_araddr >= ADDRESS_IN_REQUEST) 
				&& $past(retry_transaction_after_nack, (AxLEN+1)));
		//cover((o_axi_araddr >= ADDRESS_IN_REQUEST) && address_read_transaction_is_accepted);
	end
end
`endif

endmodule
