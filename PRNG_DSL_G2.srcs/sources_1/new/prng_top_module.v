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
    output [2:0] led_rgb
    );
    
    wire rst, rstn;
    assign rst = btnR;
    assign rstn = ~btnR;
    
    //Magnet Sensor Variables
    magnet_sensor mag(clk, rst, i2c_sda, i2c_scl, sensor_drdy, led, led_rgb);
       
    //External ADC variables        
    reg [1:0] mode;
    reg [11:0] ext_adc_data;
    wire port_dout;
    wire port_clk;
    wire port_cs;    
    drv_mcp3202 ext_adc(rstn, clk, ap_ready, ap_vaild, mode, ext_adc_data, port_din, port_dout, port_clk, port_cs);
endmodule
