//`define AXI_PROTOCOL_CHECKER 1
`define LOOPBACK 1

module axi_demo(clk, reset, done, error);

input clk, reset;
output reg done;
output reg error;


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

parameter SIZE_OF_SLAVE_MEMORY = (1 << C_AXI_ADDR_WIDTH);

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


// AXI write address channel signals
	wire			axi_awready; // Slave is ready to accept
	wire	[C_AXI_ID_WIDTH-1:0]	axi_awid;	// Write ID
	wire	[C_AXI_ADDR_WIDTH-1:0]	axi_awaddr;	// Write address
	wire	[$clog2(MAX_BURST_LENGTH)-1:0]		axi_awlen;	// Write Burst Length
	wire	[BURST_SIZE_ENCODING_WIDTH-1:0]		axi_awsize;	// Write Burst size
	wire	[1:0]		axi_awburst;	// Write Burst type
	wire	[0:0]		axi_awlock;	// Write lock type
	wire	[CACHE_BITWIDTH-1:0]		axi_awcache;	// Write Cache type
	wire	[PROT_BITWIDTH-1:0]		axi_awprot;	// Write Protection type
/* verilator lint_off UNUSED */
	wire	[QOS_BITWIDTH-1:0]		axi_awqos;	// Write Quality of Svc
/* verilator lint_on UNUSED */
	wire			axi_awvalid;	// Write address valid

// AXI write data channel signals
	wire			axi_wready;  // Write data ready
	wire	[C_AXI_DATA_WIDTH-1:0]	axi_wdata;	// Write data
	wire	[C_AXI_DATA_WIDTH/SUBWORD_SMALLEST_UNIT-1:0] axi_wstrb;	// Write strobes
	wire			axi_wlast;	// Last write transaction
	wire			axi_wvalid;	// Write valid

// AXI write response channel signals
 	wire 	[C_AXI_ID_WIDTH-1:0]	axi_bid;	// Response ID
	wire 	[1:0]		axi_bresp;	// Write response
	wire			axi_bvalid;  // Write reponse valid
	wire			axi_bready;  // Response ready

// AXI read address channel signals
	wire			axi_arready;	// Read address ready
	wire	[C_AXI_ID_WIDTH-1:0]	axi_arid;	// Read ID
	wire 	[C_AXI_ADDR_WIDTH-1:0]	axi_araddr;	// Read address
	wire	[$clog2(MAX_BURST_LENGTH)-1:0]		axi_arlen;	// Read Burst Length
	wire	[BURST_SIZE_ENCODING_WIDTH-1:0]		axi_arsize;	// Read Burst size
	wire	[1:0]		axi_arburst;	// Read Burst type
	wire	[0:0]		axi_arlock;	// Read lock type
	wire	[CACHE_BITWIDTH-1:0]		axi_arcache;	// Read Cache type
	wire	[PROT_BITWIDTH-1:0]		axi_arprot;	// Read Protection type
/* verilator lint_off UNUSED */
	wire	[QOS_BITWIDTH-1:0]		axi_arqos;	// Read Quality of Svc
/* verilator lint_on UNUSED */
	wire			axi_arvalid;	// Read address valid

// AXI read data channel signals
 	wire 	[C_AXI_ID_WIDTH-1:0]	axi_rid;     // Response ID
	wire	[1:0]		axi_rresp;   // Read response
	wire			axi_rvalid;  // Read reponse valid
 	wire 	[C_AXI_DATA_WIDTH-1:0] axi_rdata;    // Read data
	wire			axi_rlast;    // Read last
	wire			axi_rready;  // Read Response ready

`ifdef AXI_PROTOCOL_CHECKER

// https://www.xilinx.com/products/intellectual-property/axi_protocol_checker.html

localparam PC_STATUS_BITWIDTH = 160;
wire [PC_STATUS_BITWIDTH-1:0] pc_status ;
wire pc_asserted;

axi_protocol_checker_0 axi_pc0(
    .pc_status(pc_status),
    .pc_asserted(pc_asserted), 
    .aclk(clk), 
    .aresetn(!reset), 
    .pc_axi_awid(axi_awid),       .pc_axi_awaddr(axi_awaddr),   .pc_axi_awlen(axi_awlen),     
    .pc_axi_awsize(axi_awsize),   .pc_axi_awburst(axi_awburst), .pc_axi_awlock(axi_awlock),   
    .pc_axi_awcache(axi_awcache), .pc_axi_awprot(axi_awprot),   .pc_axi_awqos(axi_awqos),     
    .pc_axi_awregion(0),		  .pc_axi_awvalid(axi_awvalid), .pc_axi_awready(axi_awready), 
    .pc_axi_wlast(axi_wlast),     .pc_axi_wdata(axi_wdata),     .pc_axi_wstrb(axi_wstrb), 
    .pc_axi_wvalid(axi_wvalid),   .pc_axi_wready(axi_wready),   .pc_axi_bid(axi_bid),         
    .pc_axi_bresp(axi_bresp),     .pc_axi_bvalid(axi_bvalid),   .pc_axi_bready(axi_bready),   
    .pc_axi_arid(axi_arid),       .pc_axi_araddr(axi_araddr),   .pc_axi_arlen(axi_arlen), 
    .pc_axi_arsize(axi_arsize),   .pc_axi_arburst(axi_arburst), .pc_axi_arlock(axi_arlock), 
    .pc_axi_arcache(axi_arcache), .pc_axi_arprot(axi_arprot),   .pc_axi_arqos(axi_arqos), 
    .pc_axi_arregion(0),          .pc_axi_arvalid(axi_arvalid), .pc_axi_arready(axi_arready), 
    .pc_axi_rid(axi_rid),         .pc_axi_rlast(axi_rlast),     .pc_axi_rdata(axi_rdata),     
    .pc_axi_rresp(axi_rresp),     .pc_axi_rvalid(axi_rvalid),   .pc_axi_rready(axi_rready)
);
`endif

// there is no need of address generator logic for hard-coded instructions 

axi_master #(.C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH)) master
(
    .clk(clk), .reset(reset),
    .i_axi_awready(axi_awready), .o_axi_awid(axi_awid),       .o_axi_awaddr(axi_awaddr), 
    .o_axi_awlen(axi_awlen),     .o_axi_awsize(axi_awsize),   .o_axi_awburst(axi_awburst),
    .o_axi_awlock(axi_awlock),   .o_axi_awcache(axi_awcache), .o_axi_awprot(axi_awprot), 
    .o_axi_awqos(axi_awqos),     .o_axi_awvalid(axi_awvalid), .i_axi_wready(axi_wready), 
    .o_axi_wdata(axi_wdata),     .o_axi_wstrb(axi_wstrb),     .o_axi_wlast(axi_wlast), 
    .o_axi_wvalid(axi_wvalid),   .i_axi_bid(axi_bid),         .i_axi_bresp(axi_bresp), 
    .i_axi_bvalid(axi_bvalid),   .o_axi_bready(axi_bready),   .i_axi_arready(axi_arready), 
    .o_axi_arid(axi_arid),       .o_axi_araddr(axi_araddr),   .o_axi_arlen(axi_arlen), 
    .o_axi_arsize(axi_arsize),   .o_axi_arburst(axi_arburst), .o_axi_arlock(axi_arlock), 
    .o_axi_arcache(axi_arcache), .o_axi_arprot(axi_arprot),   .o_axi_arqos(axi_arqos), 
    .o_axi_arvalid(axi_arvalid), .i_axi_rid(axi_rid),         .i_axi_rresp(axi_rresp), 
    .i_axi_rvalid(axi_rvalid),   .i_axi_rdata(axi_rdata),     .i_axi_rlast(axi_rlast), 
    .o_axi_rready(axi_rready)
);


// for storing NN params at source side 
// (the source is a slave memory device which is accessible using AXI)

axi_slave_ram slave(
	.clk(clk), .rst(reset), 
    .s_axi_awready(axi_awready), .s_axi_awid(axi_awid),       .s_axi_awaddr(axi_awaddr), 
    .s_axi_awlen(axi_awlen),     .s_axi_awsize(axi_awsize),   .s_axi_awburst(axi_awburst),
    .s_axi_awlock(axi_awlock),   .s_axi_awcache(axi_awcache), .s_axi_awprot(axi_awprot), 
    .s_axi_awvalid(axi_awvalid), .s_axi_wready(axi_wready),   .s_axi_wdata(axi_wdata),     
    .s_axi_wstrb(axi_wstrb),     .s_axi_wlast(axi_wlast),     .s_axi_wvalid(axi_wvalid),   
    .s_axi_bid(axi_bid),         .s_axi_bresp(axi_bresp),     .s_axi_bvalid(axi_bvalid),   
    .s_axi_bready(axi_bready),   .s_axi_arready(axi_arready), .s_axi_arid(axi_arid),       
    .s_axi_araddr(axi_araddr),   .s_axi_arlen(axi_arlen),     .s_axi_arsize(axi_arsize),   
    .s_axi_arburst(axi_arburst), .s_axi_arlock(axi_arlock),   .s_axi_arcache(axi_arcache), 
    .s_axi_arprot(axi_arprot),   .s_axi_arvalid(axi_arvalid), .s_axi_rid(axi_rid),         
    .s_axi_rresp(axi_rresp),     .s_axi_rvalid(axi_rvalid),   .s_axi_rdata(axi_rdata),     
    .s_axi_rlast(axi_rlast),     .s_axi_rready(axi_rready)
);


// each read transaction only read one particular piece of data at one unique, non-consecutive address
reg [$clog2(SIZE_OF_SLAVE_MEMORY)-1:0] num_of_memory_data_read_transaction ;
wire valid_read_response_contains_error_messages ;

assign valid_read_response_contains_error_messages = (axi_rvalid && (axi_rresp != 0));


always @(posedge clk)
begin
	if(reset) num_of_memory_data_read_transaction <= 0;

	else if(axi_rready && axi_rvalid && (axi_rresp == 0)) 
		num_of_memory_data_read_transaction <=
		num_of_memory_data_read_transaction + 1;
end
	
always @(posedge clk)
begin
	if(reset) error <= 0;

	else error <= 
			((valid_read_response_contains_error_messages) 
			`ifdef AXI_PROTOCOL_CHECKER 
							| (pc_asserted) 
			`endif
			);
end

always @(posedge clk)
begin
	if(reset) done <= 0;

	else if(num_of_memory_data_read_transaction == SIZE_OF_SLAVE_MEMORY-1) 
			done <= 1;
end

endmodule
