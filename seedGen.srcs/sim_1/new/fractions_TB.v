`timescale 1ns / 1ps

module top_module_tb();
    reg clk;
    reg [31:0]x0;
    reg [31:0]y0;
    reg [31:0]g;
    reg [31:0]m1;
    reg [31:0]m2;
    reg [31:0]l1;
    reg [31:0]l2;
    wire[31:0]x_1;
    wire[31:0]x_2;
    wire[31:0]y_1;
    wire[31:0]y_2;
    wire[31:0]RNG;
    
Math MATH( //math takes 9 bit variables, 1st bit is signed, next 8 store values
    A,//Math.plus(A,B), Math.minus(A,B), Math.times(A,B), Math.divide(A,B)
    B //Math.mod(A), Math.neg(A) 
); //

num NUM( //num takes in a signed bit, 8bin integer and 23bit decimal place
    sign, //num.bin(0, 8'd20, 23'd3)
    int,
    dec //only accepts 1dp
); //

DP dp_a3( //num takes in a signed bit, 8bin integer and 23bit decimal place
    .clk(clk), //num.bin(0, 8'd20, 23'd3)
    .x0(x0[31:0]),
    .y0(y0[31:0]),
    .g(g[31:0]),
    .m1(m1[31:0]),
    .m2(m2[31:0]),
    .l1(l1[31:0]),
    .l2(l2[31:0]),
    .RNG(RNG[31:0]),
    .x_1(x_1[31:0]),
    .x_2(x_2[31:0]),
    .y_1(y_1[31:0]),
    .y_2(y_2[31:0]) //only accepts 1dp
); //

reg [31:0] counter = 0;
initial begin
x0 =NUM.bin(1,8'd9,23'd02); //location of center - X
y0 =NUM.bin(0,8'd2,23'd37); //location of center - Y
g = NUM.bin(0,8'd5,23'd00); //gravity
m1 =NUM.bin(0,8'd8,23'd95); //mass 1 change this
m2 =NUM.bin(0,8'd3,23'd44); //mass 2 change this
l1 =NUM.bin(0,8'd69,23'd96); //length 1 change this
l2 =NUM.bin(0,8'd33,23'd33); //length 2 change this
end

always begin
        #0 clk = 0;
        while(counter <= 32'd100000)begin
            #1
            clk = ~clk;
            counter = counter + 8'd1;
        end                 
        #10 $stop;
        #10 $finish;
    end

endmodule
