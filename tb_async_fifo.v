`timescale 1ns / 1ns
module tb_async_fifo;
  
  parameter  WIDTH = 8;
  parameter  DEPTH = 32;
  localparam WCLK_PER = 8;  // 125 MHz
  localparam RCLK_PER = 4;  // 250 MHz

  reg               wclk = 0;
  reg               rclk = 0;
  reg               wresetn = 0;
  reg               rresetn = 0;
  reg               we = 0;
  reg               re = 0;
  reg  [WIDTH-1:0]  wdata = 0;
  wire [WIDTH-1:0]  rdata;
  wire              full;
  wire              empty;

  Async_FIFO #(WIDTH, DEPTH) dut (
    .i_w_clk(wclk), .i_r_clk(rclk),
    .i_wresetn(wresetn), .i_rresetn(rresetn),
    .i_we(we), .i_re(re),
    .i_wdata(wdata),
    .o_rdata(rdata), .o_full(full), .o_empty(empty)
  );

  always #(WCLK_PER/2) wclk = ~wclk;
  always #(RCLK_PER/2) rclk = ~rclk;

  initial begin
    $dumpfile("fifo_async.vcd");
    $dumpvars();
    #1000; $finish;
  end

  task reset_fifo; begin
    wresetn = 0; rresetn = 0;
    repeat (2) @(posedge wclk);
    wresetn = 1;
    @(posedge rclk); rresetn = 1; 
  end endtask

  // 1. Basic write followed by read
  task test_basic; integer i;
    $display("\n-- Test: BASIC WRITE/READ");
    reset_fifo();
    for (i = 0; i < 16; i++) begin we = 1; wdata = i; @(posedge wclk); we = 0; @(posedge wclk); end
    for (i = 0; i < 16; i++) begin @(posedge rclk); re = 1; @(posedge rclk); re = 0; end
  endtask

  // 2. Write until FULL is asserted
  task test_write_full; integer i;
    $display("\n-- Test: WRITE UNTIL FULL");
    reset_fifo();
    i = 0;
    while (!full) begin @(posedge wclk); we = 1; wdata = i; i = i + 1; end
    @(posedge wclk); we = 0;
  endtask

  // 3. Read until EMPTY is asserted
  task test_read_empty;
    $display("\n-- Test: READ UNTIL EMPTY");
    while (!empty) @(posedge rclk) re = 1;
    @(posedge rclk); re = 0;
  endtask

  // 4. Simultaneous continuous R/W
  task test_simultaneous; integer i;
    $display("\n-- Test: SIMULTANEOUS R/W");
    reset_fifo();
    for (i = 0; i < 32; i++) begin @(posedge wclk); we = 1; wdata = $random; end
    @(posedge wclk); we = 0;
    repeat (64) begin
      @(posedge wclk) if (!full) begin we = 1; wdata = $random; end else we = 0;
      @(posedge rclk) if (!empty) begin re = 1; end else re = 0;
      @(posedge rclk); re = 0;
    end
    @(posedge wclk); we = 0;
  endtask

  // 5. Overflow and Underflow detection
  task test_overflow_underflow;
    $display("\n-- Test: OVERFLOW & UNDERFLOW");
    reset_fifo();
    
    // Fill FIFO
    while (!full) @(posedge wclk) begin we = 1; wdata = $random; end
    @(posedge wclk); we = 1; wdata = $random; @(posedge wclk); we = 0;
    
    // Drain FIFO
    while (!empty) @(posedge rclk) begin re = 1; end
    @(posedge rclk); re = 1; @(posedge rclk); re = 0;
  endtask

  // 6. Reset during operation
  task test_mid_reset;
    integer i;
    $display("\n-- Test: RESET DURING OPERATION");
    reset_fifo();
    for (i = 0; i < 16; i++) begin @(posedge wclk); we = 1; wdata = i; end
    we = 0;
    
    // Now assert reset mid-way
    wresetn = 0; rresetn = 0;
    repeat (2) @(posedge wclk);
    @(posedge rclk); rresetn = 1;
    @(posedge wclk); wresetn = 1;
    
    // Continue writing and reading to ensure pointers cleared
    for (i = 0; i < 8; i++) begin @(posedge wclk); we = 1; wdata = i+100; end
    we = 0;
    for (i = 0; i < 8; i++) begin @(posedge rclk); re = 1; @(posedge rclk); re = 0; end
  endtask

  // 7. Back-to-Back full-empty toggles
  task test_toggle; integer cycle;
    $display("\n-- Test: BACK-TO-BACK FULL/EMPTY TOGGLES");
    reset_fifo();
    for (cycle = 0; cycle < 5; cycle++) begin
      test_write_full(); test_read_empty();
    end
  endtask

 
  initial $monitor("%0t WE=%b RE=%b WDATA=%0h RDATA=%0h FULL=%b EMPTY=%b",
                  $time, we, re, wdata, rdata, full, empty);

 
  initial begin
    if ($test$plusargs("sanitary"))          test_basic();
    if ($test$plusargs("write_full"))        test_write_full();
    if ($test$plusargs("read_empty"))        test_read_empty();
    if ($test$plusargs("simultaneous"))      test_simultaneous();
    if ($test$plusargs("overflow_underflow"))test_overflow_underflow();
    if ($test$plusargs("mid_reset"))         test_mid_reset();
    if ($test$plusargs("toggle"))            test_toggle();
  end

endmodule
