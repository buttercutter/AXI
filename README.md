# AXI
A simple AXI demo example

This is AXI memory controller with _WDATA_ and _AWADDR_ re-transmission feature in the case of consecutive NACKs (bad _BRESP_ from AXI slave)

![waveform](./waveform.png)

TODO :
1. Solve [Xilinx AXI protocol checker issue](https://github.com/alexforencich/verilog-axi/issues/8)
2. Replace [AXI slave code](https://github.com/alexforencich/verilog-axi/blob/master/rtl/axi_ram.v) with my own AXI slave code
3. Add [skid buffer](https://www.eevblog.com/forum/fpga/some-thoughts-on-axi-pipe-handshake-protocol-and-timing-closure/msg2530332/?PHPSESSID=26ailf4l5pvur8ma3isff0g8g5#msg2530332) for better STA performance
4. Formally verify the entire AXI protocol transactions

Credit : @alexforencich 
