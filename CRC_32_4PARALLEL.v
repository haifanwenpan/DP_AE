`default_nettype none
module CRC_32_4PARALLEL #(
    parameter FAST = 0
) (
    input  wire [ 31:0] CRC_IN,
    input  wire [  3:0] VALID,
    input  wire [191:0] DATA,
    output wire [ 31:0] CRC_OUT
);
  generate
    if (FAST == 0) begin
      CRC_32_PARALLEL #(
          .PARALLEL_DEPTH(4)
      ) PARALLEL_INST (
          .CRC_IN(CRC_IN),
          .VALID(VALID),
          .DATA(DATA),
          .CRC_OUT(CRC_OUT)
      );
    end else begin
      wire [  2:0] CNT;
      wire [191:0] DATA_SEL;
      wire [  3:0] TURN_OFF_R1[4];
      wire [  3:0] ONE_HOT_REQ[4];
      wire CNT_IS_1, CNT_IS_2, CNT_IS_3, CNT_IS_4;
      wire [ 47:0] DATA48;
      wire [ 95:0] DATA96;
      wire [143:0] DATA144;
      wire [191:0] DATA192;
      wire [31:0] CRC_OUT48, CRC_OUT96, CRC_OUT144, CRC_OUT192;
      genvar i;
      assign TURN_OFF_R1[0] = VALID;
      assign ONE_HOT_REQ[0] = TURN_OFF_R1[0] & (-TURN_OFF_R1[0]);  // Isolate Rightmost 1 Bit
      for (i = 1; i < 4; i = i + 1) begin
        assign TURN_OFF_R1[i] = TURN_OFF_R1[i-1] & (~ONE_HOT_REQ[i-1]);  //Turn Off Rightmost 1 Bit
        assign ONE_HOT_REQ[i] = TURN_OFF_R1[i] & (-TURN_OFF_R1[i]);  // Isolate Rightmost 1 Bit
      end
      for (i = 0; i < 4; i = i + 1) begin
        MUX_ONE_HOT #(
            .WORD_WIDTH(48),
            .WORD_COUNT(4)
        ) MUX_ONE_HOT_CRC_INST (
            .SEL(ONE_HOT_REQ[i]),
            .WORDS_IN(DATA),
            .WORDS_OUT(DATA_SEL[i*48+:48])
        );
      end
      assign CNT = VALID[3] + VALID[2] + VALID[1] + VALID[0];
      assign CNT_IS_1 = CNT == 3'd1;
      assign CNT_IS_2 = CNT == 3'd2;
      assign CNT_IS_3 = CNT == 3'd3;
      assign CNT_IS_4 = CNT == 3'd4;
      assign DATA48 = DATA_SEL[0+:48];
      assign DATA96 = DATA_SEL[0+:96];
      assign DATA144 = DATA_SEL[0+:144];
      assign DATA192 = DATA;
      CRC_32_DAT_48 CRC_32_DAT_48_INST (
          .CRC_IN(CRC_IN),
          .DATA(DATA48),
          .CRC_OUT(CRC_OUT48)
      );
      CRC_32_DAT_96 CRC_32_DAT_96_INST (
          .CRC_IN(CRC_IN),
          .DATA(DATA96),
          .CRC_OUT(CRC_OUT96)
      );
      CRC_32_DAT_144 CRC_32_DAT_144_INST (
          .CRC_IN(CRC_IN),
          .DATA(DATA144),
          .CRC_OUT(CRC_OUT144)
      );
      CRC_32_DAT_192 CRC_32_DAT_192_INST (
          .CRC_IN(CRC_IN),
          .DATA(DATA192),
          .CRC_OUT(CRC_OUT192)
      );
      MUX_ONE_HOT #(
          .WORD_WIDTH(32),
          .WORD_COUNT(4)
      ) MUX_ONE_HOT_CRC_INST (
          .SEL({CNT_IS_4, CNT_IS_3, CNT_IS_2, CNT_IS_1}),
          .WORDS_IN({CRC_OUT192, CRC_OUT144, CRC_OUT96, CRC_OUT48}),
          .WORDS_OUT(CRC_OUT)
      );
    end
  endgenerate
endmodule
