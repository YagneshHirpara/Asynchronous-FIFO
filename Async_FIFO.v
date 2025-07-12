module Async_FIFO #(parameter WIDTH=8, DEPTH=16)(
  input  wire                   i_w_clk,
  input  wire                   i_r_clk,
  input  wire                   i_wresetn,
  input  wire                   i_rresetn,
  input  wire                   i_we,
  input  wire                   i_re,
  input  wire [WIDTH-1:0]       i_wdata,
  output wire                   o_full,
  output wire                   o_empty,
  output reg [WIDTH-1:0]        o_rdata
);

  localparam ADDR_WIDTH = $clog2(DEPTH);

  // Binary and Gray pointers
  reg [ADDR_WIDTH:0] wptr_bin, wptr_gray;
  reg [ADDR_WIDTH:0] rptr_bin, rptr_gray;

  // Synchronized pointers
  reg [ADDR_WIDTH:0] rq1_wptr, rq2_wptr;
  reg [ADDR_WIDTH:0] wq1_rptr, wq2_rptr;

  // Memory
  reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [$clog2(DEPTH)-1:0]count=0;
  // Write logic
  wire [ADDR_WIDTH-1:0] waddr = wptr_bin[ADDR_WIDTH-1:0];
 wire wclken = i_we & ~o_full;

  always @(posedge i_w_clk or negedge i_wresetn) begin
    if (!i_wresetn) begin
      wptr_bin  <= 0;
      wptr_gray <= 0;
    end else if (wclken) begin
      wptr_bin  <= wptr_bin + 1;
      wptr_gray <= (wptr_bin + 1) ^ ((wptr_bin + 1) >> 1);      
    end
  end

  always @(posedge i_w_clk or negedge i_wresetn) begin
     if (i_we & ~o_full)begin
      mem[waddr] <= i_wdata;
      end
    end
  
  // Read logic
  wire [ADDR_WIDTH-1:0] raddr = rptr_bin[ADDR_WIDTH-1:0];
  always @(posedge i_r_clk or negedge i_rresetn) begin
      if (i_re & !o_empty)begin
      o_rdata <= mem[raddr];
      end
  end
  always @(posedge i_r_clk or negedge i_rresetn) begin
    if (!i_rresetn) begin
      rptr_bin  <= 0;
      rptr_gray <= 0;
    end else if (i_re & !o_empty) begin
      rptr_bin  <= rptr_bin + 1;
      rptr_gray <= (rptr_bin + 1) ^ ((rptr_bin + 1) >> 1);
     end
  end

  // Synchronize pointers across domains
  always @(posedge i_w_clk or negedge i_wresetn) begin
    if (!i_wresetn) begin
      wq1_rptr <= 0;
      wq2_rptr <= 0;
    end else begin
      wq1_rptr <= rptr_gray;
      wq2_rptr <= wq1_rptr;
    end
  end

  always @(posedge i_r_clk or negedge i_rresetn) begin
    if (!i_rresetn) begin
      rq1_wptr <= 0;
      rq2_wptr <= 0;
    end else begin
      rq1_wptr <= wptr_gray;
      rq2_wptr <= rq1_wptr;
    end
  end

  // Full condition
  assign o_full = (wptr_gray[ADDR_WIDTH]   != wq2_rptr[ADDR_WIDTH]) &&
                  (wptr_gray[ADDR_WIDTH-1] != wq2_rptr[ADDR_WIDTH-1]) &&
                  (wptr_gray[ADDR_WIDTH-2:0] == wq2_rptr[ADDR_WIDTH-2:0]);

  // Empty condition
  assign o_empty = (rptr_gray == rq2_wptr);
   
endmodule

