`default_nettype none
module CRC_32_MULTI_REQ #(
    parameter SIMPLE = 0,
    parameter REQ_COUNT = 16,
    parameter INST_COUNT = 4,  // Meaningless when simple is 1
    parameter PARALLEL_DEPTH = 4,
    parameter CRC_WIDTH = REQ_COUNT * 32,  // Do not set at instantiation
    parameter VALID_WIDTH = REQ_COUNT * PARALLEL_DEPTH,  // Do not set at instantiation
    parameter DATA_WIDTH = REQ_COUNT * PARALLEL_DEPTH * 48  // Do not set at instantiation
) (
    input  wire [  CRC_WIDTH-1:0] CRC_IN,
    input  wire [VALID_WIDTH-1:0] VALID,
    input  wire [ DATA_WIDTH-1:0] DATA,
    output wire [  CRC_WIDTH-1:0] CRC_OUT
);
  genvar i;
  generate
    if (SIMPLE == 0) begin
      wire [REQ_COUNT-1:0] REQ_DE;
      wire [REQ_COUNT-1:0] ONE_HOT_REQ[INST_COUNT];
      wire [REQ_COUNT-1:0] TURN_OFF_R1[INST_COUNT];
      wire [32-1:0] MUX_CRC_OUT[INST_COUNT];
      wire [PARALLEL_DEPTH-1:0] MUX_VALID_OUT[INST_COUNT];
      wire [PARALLEL_DEPTH*48-1:0] MUX_DATA_OUT[INST_COUNT];
      wire [32-1:0] PARALLEL_CRC_OUT[INST_COUNT];
      wire [CRC_WIDTH-1:0] DEMUX_CRC_OUT[INST_COUNT];
      wire [CRC_WIDTH-1:0] PARTIAL_REDUCTION[INST_COUNT];
      assign CRC_OUT = PARTIAL_REDUCTION[INST_COUNT-1];
      for (i = 0; i < REQ_COUNT; i = i + 1) begin
        assign REQ_DE[i] = |VALID[i*PARALLEL_DEPTH+:PARALLEL_DEPTH];
      end
      assign PARTIAL_REDUCTION[0] = DEMUX_CRC_OUT[0];
      assign TURN_OFF_R1[0] = REQ_DE;
      assign ONE_HOT_REQ[0] = TURN_OFF_R1[0] & (-TURN_OFF_R1[0]);  // Isolate Rightmost 1 Bit
      for (i = 1; i < INST_COUNT; i = i + 1) begin
        assign TURN_OFF_R1[i] = TURN_OFF_R1[i-1] & (~ONE_HOT_REQ[i-1]);  //Turn Off Rightmost 1 Bit
        assign ONE_HOT_REQ[i] = TURN_OFF_R1[i] & (-TURN_OFF_R1[i]);  // Isolate Rightmost 1 Bit
        assign PARTIAL_REDUCTION[i] = PARTIAL_REDUCTION[i-1] | DEMUX_CRC_OUT[i];
      end
      for (i = 0; i < INST_COUNT; i = i + 1) begin
        MUX_ONE_HOT #(
            .WORD_WIDTH(32),
            .WORD_COUNT(REQ_COUNT)
        ) MUX_ONE_HOT_CRC_INST (
            .SEL(ONE_HOT_REQ[i]),
            .WORDS_IN(CRC_IN),
            .WORDS_OUT(MUX_CRC_OUT[i])
        );
        MUX_ONE_HOT #(
            .WORD_WIDTH(PARALLEL_DEPTH),
            .WORD_COUNT(REQ_COUNT)
        ) MUX_ONE_HOT_VALID_INST (
            .SEL(ONE_HOT_REQ[i]),
            .WORDS_IN(VALID),
            .WORDS_OUT(MUX_VALID_OUT[i])
        );
        MUX_ONE_HOT #(
            .WORD_WIDTH(PARALLEL_DEPTH * 48),
            .WORD_COUNT(REQ_COUNT)
        ) MUX_ONE_HOT_DATA_INST (
            .SEL(ONE_HOT_REQ[i]),
            .WORDS_IN(DATA),
            .WORDS_OUT(MUX_DATA_OUT[i])
        );
        CRC_32_PARALLEL #(
            .PARALLEL_DEPTH(PARALLEL_DEPTH)
        ) CRC_32_PARALLEL_INST (
            .CRC_IN(MUX_CRC_OUT[i]),
            .VALID(MUX_VALID_OUT[i]),
            .DATA(MUX_DATA_OUT[i]),
            .CRC_OUT(PARALLEL_CRC_OUT[i])
        );
        DEMUX_ONE_HOT #(
            .WORD_WIDTH(32),
            .WORD_COUNT(REQ_COUNT)
        ) DEMUX_ONE_HOT_inst (
            .SEL(ONE_HOT_REQ[i]),
            .WORDS_IN(PARALLEL_CRC_OUT[i]),
            .WORDS_OUT(DEMUX_CRC_OUT[i])
        );
      end
    end else if (SIMPLE > 0) begin
      for (i = 0; i < REQ_COUNT; i = i + 1) begin
        CRC_32_PARALLEL #(
            .PARALLEL_DEPTH(PARALLEL_DEPTH)
        ) CRC_32_PARALLEL_INST (
            .CRC_IN(CRC_IN[i*32+:32]),
            .VALID(VALID[i*PARALLEL_DEPTH+:PARALLEL_DEPTH]),
            .DATA(DATA[i*PARALLEL_DEPTH*48+:PARALLEL_DEPTH*48]),
            .CRC_OUT(CRC_OUT[i*32+:32])
        );
      end
    end
  endgenerate
endmodule
