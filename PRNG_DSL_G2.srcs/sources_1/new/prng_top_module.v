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
    output[31:0]RNG,
    
    //XADC
    input [1:0] xa_n,
    input [1:0] xa_p,
    input vp_in,
    input vn_in
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
   
    //XADC
    localparam PIN15_ADDR = 8'h14;  //VAUX4;
    localparam PIN16_ADDR = 8'h1C;  //VAUX12;
    reg Sel_ADDR = PIN15_ADDR;
    
    wire enable;                    //enable into the xadc to continuosly get data out
    reg [6:0] Address_in = 7'h14;    //Adress of register in XADC drp corresponding to data
    wire ready;                      //XADC port that declares when data is ready to be taken
    wire [15:0] ADC_data;                //XADC data  
    xadc_wiz_0 ADC1
    (
    .daddr_in(PIN16_ADDR),        // Address bus for the dynamic reconfiguration port
    .dclk_in(sysclk),             // Clock input for the dynamic reconfiguration port
    .den_in(enable),              // Enable Signal for the dynamic reconfiguration port
    .di_in(0),                    // Input data bus for the dynamic reconfiguration port
    .dwe_in(0),                   // Write Enable for the dynamic reconfiguration port
    .vauxp12(xa_p[1]),
    .vauxn12(xa_n[1]),
    .vauxp4(xa_p[0]),
    .vauxn4(xa_n[0]),  
    .busy_out(),                 // ADC Busy signal
    .channel_out(),              // Channel Selection Outputs
    .do_out(ADC_data),           // Output data bus for dynamic reconfiguration port
    .drdy_out(ready),            // Data ready signal for the dynamic reconfiguration port
    .eoc_out(enable),            // End of Conversion Signal
    .vp_in(vp_in),               // Dedicated Analog Input Pair
    .vn_in(vn_in)
    );
    
    //Creating pRNG
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
    x0 =num0.bin(DZR[15],DZR[14:7],DZR[6:0]); //location of center - X
    y0 =num0.bin(0,8'd2,23'd37); //location of center - Y
    g = num0.bin(0,ADC_data[15:8],ADC_data[7:0]); //gravity
    m1 =num0.bin(DXR[15],DXR[14:7],DXR[6:0]); //mass 1 change this
    m2 =num0.bin(0,8'd3,23'd44); //mass 2 change this
    l1 =num0.bin(DYR[15],DYR[14:7],DYR[6:0]); //length 1 change this
    l2 =num0.bin(0,8'd33,23'd33); //length 2 change this
    end
    DP dp(clk,x0,y0,g,m1,m2,l1,l2,RNG,x_1, x_2,y_1,y_2);
    
endmodule
