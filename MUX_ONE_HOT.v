`default_nettype none
module MUX_ONE_HOT #(
    parameter WORD_WIDTH  = 0,
    parameter WORD_COUNT  = 0,
    parameter TOTAL_WIDTH = WORD_COUNT * WORD_WIDTH  // Do not set at instantiation
) (
    input  wire [ WORD_COUNT-1:0] SEL,
    input  wire [TOTAL_WIDTH-1:0] WORDS_IN,
    output wire [ WORD_WIDTH-1:0] WORDS_OUT
);
  genvar i;
  wire [TOTAL_WIDTH-1:0] WORDS_IN_SELECTED;
  wire [ WORD_WIDTH-1:0] PARTIAL_REDUCTION [WORD_COUNT];

  for (i = 0; i < WORD_COUNT; i = i + 1) begin
    assign WORDS_IN_SELECTED [WORD_WIDTH*i +: WORD_WIDTH] = WORDS_IN[WORD_WIDTH*i +: WORD_WIDTH] & {WORD_WIDTH{SEL[i]}};
  end

  assign PARTIAL_REDUCTION[0] = WORDS_IN_SELECTED[0+:WORD_WIDTH];
  for (i = 1; i < WORD_COUNT; i = i + 1) begin
    assign PARTIAL_REDUCTION[i] = PARTIAL_REDUCTION[i-1] | WORDS_IN_SELECTED[WORD_WIDTH*i +: WORD_WIDTH];
  end
  assign WORDS_OUT = PARTIAL_REDUCTION[WORD_COUNT-1];
endmodule
