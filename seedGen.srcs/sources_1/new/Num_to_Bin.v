`timescale 1ns / 1ps

module num(
    input [0:0]sign, //1 pos/neg bit, 7 round bits, no decimals
    input [7:0]int,
    input [22:0]dec
    );
  
function [31:0] bin;
    input [0:0]sign;
    input [7:0]int;
    input [22:0]dec;
    reg [31:0] binary;
        begin
        binary[31] = sign;
        binary[30:23] = int;
        binary[22:0] = dec;
        bin = binary;
        end
endfunction

endmodule
