`default_nettype none
module CRC_32_PARALLEL #(
    parameter integer PARALLEL_DEPTH = 4
) (
    input wire [31:0] CRC_IN,
    input wire [PARALLEL_DEPTH-1:0] VALID,
    input wire [PARALLEL_DEPTH*48-1:0] DATA,
    output wire [31:0] CRC_OUT
);
  wire [31:0] STAGE_IN[PARALLEL_DEPTH];
  wire [31:0] STAGE_OUT[PARALLEL_DEPTH];
  wire [31:0] CRC_OUT_PRE[PARALLEL_DEPTH];

  assign STAGE_IN[0] = CRC_IN;
  assign CRC_OUT_PRE[0] = STAGE_OUT[0];

  CRC_32 INPUT_STAGE (
      .CRC_IN(STAGE_IN[0]),
      .DATA(DATA[0+:48]),
      .CRC_OUT(STAGE_OUT[0])
  );

  genvar i;
  generate
    for (i = 1; i < PARALLEL_DEPTH; i = i + 1) begin : g_PARALLEL_STAGES
      assign STAGE_IN[i] = VALID[i-1] ? STAGE_OUT[i-1] : CRC_IN;
      assign CRC_OUT_PRE[i] = VALID[i] ? STAGE_OUT[i] : CRC_OUT_PRE[i-1];
      CRC_32 PARALLEL_STAGE (
          .CRC_IN(STAGE_IN[i-1]),
          .DATA(DATA[i*48+:48]),
          .CRC_OUT(STAGE_OUT[i])
      );
    end
  endgenerate

  assign CRC_OUT = CRC_OUT_PRE[PARALLEL_DEPTH-1];
endmodule
