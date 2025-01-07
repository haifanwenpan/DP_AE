`default_nettype none
module DEMUX_ONE_HOT #(
    parameter WORD_WIDTH  = 0,
    parameter WORD_COUNT  = 0,
    parameter TOTAL_WIDTH = WORD_COUNT * WORD_WIDTH  // Do not set at instantiation
) (
    input  wire [ WORD_COUNT-1:0] SEL,
    input  wire [ WORD_WIDTH-1:0] WORDS_IN,
    output wire [TOTAL_WIDTH-1:0] WORDS_OUT
);
  genvar i;
  for (i = 0; i < WORD_COUNT; i = i + 1) begin
    assign WORDS_OUT[WORD_WIDTH*i+:WORD_WIDTH] = WORDS_IN & {WORD_WIDTH{SEL[i]}};
  end
endmodule
