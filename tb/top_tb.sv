


`timescale 1ns / 1ps

module i2c_top_tb;

    reg clk = 0, rst = 0, newd = 0, op;
    reg stretch = 0;
    reg [6:0] addr;
    reg [7:0] din;
    reg [7:0] din_wr2;

    wire [7:0] dout;
    wire busy, ack_err;
    wire done;
    tri1 sda, scl;

    i2c_top dut (
        .clk(clk),
        .rst(rst),
        .newd(newd),
        .op(op),
        .stretch(stretch),
        .addr(addr),
        .din(din),
        .dout(dout),
        .busy(busy),
        .ack_err(ack_err),
        .done(done),
        .sda(sda),
        .scl(scl)
    );

    always #12.5 clk = ~clk;

    initial begin
        rst = 1;
        repeat(5) @(posedge clk);
        @(negedge clk);
        rst = 0;

        
        // Transaction 1: Write without stretching
  
        @(negedge clk);
        newd    = 1'b1;
        stretch = 1'b0;
        op      = 1'b0;
        addr    = 7'd100;
        din     = $urandom_range(1,5);

        @(negedge clk);
        newd = 1'b0;

        @(posedge done);
        $display("[WR1] din : %0d addr : %0d", din, addr);

      
        // Transaction 2: Write with stretching
   
        @(negedge clk);
        newd    = 1'b1;
        stretch = 1'b1;
        op      = 1'b0;
        addr    = 7'd100;
        din     = $urandom_range(1,5);
        din_wr2 = din;

        wait(dut.master.state == 3);

        repeat(1200) @(posedge clk);

        @(negedge clk);
        stretch = 1'b0;

        @(negedge clk);
        newd = 1'b0;

        @(posedge done);
        $display("[WR2] din : %0d addr : %0d", din, addr);

        // Transaction 3: Read without stretching
        @(negedge clk);
        newd    = 1'b1;
        stretch = 1'b0;
        op      = 1'b1;
        addr    = 7'd100;
        din     = 8'h00;

        @(negedge clk);
        newd = 1'b0;

        @(posedge done);

        if (dout == din_wr2)
            $display("[RD] PASS: dout = %h", dout);
        else
            $display("[RD] FAIL: expected = %h, got = %h",
                     din_wr2, dout);
        // Transaction 4: Read with clock stretching
   
        @(negedge clk);
        newd    = 1'b1;
        stretch = 1'b1;
        op      = 1'b1;
        addr    = 7'd100;
        din     = 8'h00;

        // Wait until master reaches ACK phase
        wait(dut.master.state == 3);

        // Hold clock stretching
        repeat(1200) @(posedge clk);

        // Release clock stretching
        @(negedge clk);
        stretch = 1'b0;

        @(negedge clk);
        newd = 1'b0;

        @(posedge done);

        if (dout == din_wr2)
            $display("[RD-STRETCH] PASS: dout = %h", dout);
        else
            $display("[RD-STRETCH] FAIL: expected = %h, got = %h",
                     din_wr2, dout);
        // Transaction 5: Incorrect slave address (NACK)
        @(negedge clk);
        newd    = 1'b1;
        stretch = 1'b0;
        op      = 1'b0;
        addr    = 7'd99;
        din     = 8'hA5;

        @(negedge clk);
        newd = 1'b0;

        @(posedge done);

        if (ack_err == 1'b1)
            $display("[NACK] PASS: incorrect address rejected, ack_err = 1");
        else
            $display("[NACK] FAIL: expected ack_err = 1, got = %b",
                     ack_err);
        $stop;

    end

endmodule
