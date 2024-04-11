`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.04.2024 13:47:35
// Design Name: 
// Module Name: prng_top_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module prng_top_module(
    input clk, 
    input btnR, 
    
    //Magnet Sensor I2C Inputs
    inout i2c_sda,
    inout wire i2c_scl,
    input sensor_drdy,
    
    //External ADC Pin
    input port_din,
    
    //Debug Outputs
    output [1:0] led,
    output [2:0] led_rgb,
    
    //Variables for RNG
    input [31:0]A, //1 pos/neg bit, 7 round bits, no decimals
    input [31:0]B, //total of 8 bits
    input [0:0]sign,
    input [7:0]int,
    input [22:0]dec,
    output[31:0]x_1,
    output[31:0]x_2,
    output[31:0]y_1,
    output[31:0]y_2,
    output[31:0]RNG
    );
    
    wire rst, rstn;
    assign rst = btnR;
    assign rstn = ~btnR;
    
    //Magnet Sensor Variables
    wire [15:0] DXR, DZR, DYR;
    magnet_sensor mag(clk, rst, i2c_sda, i2c_scl, sensor_drdy, DXR, DZR, DYR);    
       
    //External ADC variables        
    reg [1:0] mode;
    reg [11:0] ext_adc_data;
    wire port_dout;
    wire port_clk;
    wire port_cs;    
    drv_mcp3202 ext_adc(rstn, clk, ap_ready, ap_vaild, mode, ext_adc_data, port_din, port_dout, port_clk, port_cs);
    
    //Creating pRNG
    //reg clk;
    reg [31:0]x0;
    reg [31:0]y0;
    reg [31:0]g;
    reg [31:0]m1;
    reg [31:0]m2;
    reg [31:0]l1;
    reg [31:0]l2;
//    wire[31:0]x_1;
//    wire[31:0]x_2;
//    wire[31:0]y_1;
//    wire[31:0]y_2;
//    wire[31:0]RNG;
    num num0(sign,int,dec);
    Math MATH(A,B);
    always @ (posedge clk) begin
    x0 =num0.bin(1,8'd9,23'd02); //location of center - X
    y0 =num0.bin(0,8'd2,23'd37); //location of center - Y
    g = num0.bin(DZR[15],DZR[14:7],DZR[6:0]); //gravity
    m1 =num0.bin(DXR[15],DXR[14:7],DXR[6:0]); //mass 1 change this
    m2 =num0.bin(0,8'd3,23'd44); //mass 2 change this
    l1 =num0.bin(DYR[15],DYR[14:7],DYR[6:0]); //length 1 change this
    l2 =num0.bin(0,8'd33,23'd33); //length 2 change this
    end
    DP dp(clk,x0,y0,g,m1,m2,l1,l2,RNG,x_1, x_2,y_1,y_2);
    
endmodule
