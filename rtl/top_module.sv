
`timescale 1ns / 1ps

module i2c_top(
    input clk, rst, newd, op, stretch,
    input [6:0] addr,
    input [7:0] din,
    output [7:0] dout,
    output busy, ack_err,
    output done,
    inout sda, scl
);

wire ack_errm, ack_errs;

wire master_sda_low, master_scl_low;
wire slave_sda_low, slave_scl_low;

wire sda_low_bus, scl_low_bus;

// Master and Slave LOW requests
assign sda_low_bus = master_sda_low | slave_sda_low;
assign scl_low_bus = master_scl_low | slave_scl_low;

// Physical I2C bus resolution
assign sda = sda_low_bus ? 1'b0 : 1'bz;
assign scl = scl_low_bus ? 1'b0 : 1'bz;

i2c_master master (
    .clk(clk),
    .rst(rst),
    .newd(newd),
    .addr(addr),
    .op(op),
    .sda_in(sda),
    .scl_in(scl),
    .sda_low(master_sda_low),
    .scl_low(master_scl_low),
    .din(din),
    .dout(dout),
    .busy(busy),
    .ack_err(ack_errm),
    .done(done)
);
i2c_Slave slave (
    .clk(clk),
    .rst(rst),
    .stretch(stretch),
    .sda_in(sda),
    .scl_in(scl),
    .sda_low(slave_sda_low),
    .scl_low(slave_scl_low),
    .ack_err(ack_errs),
    .done()
);

assign ack_err = ack_errm | ack_errs;

endmodule