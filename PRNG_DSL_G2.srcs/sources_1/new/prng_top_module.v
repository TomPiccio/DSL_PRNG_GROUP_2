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
    //output [1:0] led,
    //output [2:0] led_rgb,
    
    //Variables for RNG
    //input [31:0]A, //1 pos/neg bit, 7 round bits, no decimals
    //input [31:0]B, //total of 8 bits
    //input [0:0]sign,
    //input [7:0]int,
    //input [22:0]dec,
    output[31:0]x_1,
    output[31:0]x_2,
    output[31:0]y_1,
    output[31:0]y_2,
    output[31:0]RNG,
    
    //XADC
    input [1:0] xa_n,
    input [1:0] xa_p,
    input vp_in,
    input vn_in,
    
    //UART , ADC, Display
    input sysclk,
    input [1:0] btn,
    output pio37,
    output pio38,
    output pio39,
    output pio40,
    output pio41,
    output pio42,
    output pio43,
    output pio44,
    output pio45,
    output pio46,
    output pio47,
    output pio48,
    //output [1:0] led, already declared
    //External ADC MCP3202 1;
    output adc_din1,
    output adc_clk1,
    output adc_csn1,
    input  adc_dout1,
    //External ADC MCP3202 2;
    output adc_din2,
    output adc_clk2,
    output adc_csn2,
    input  adc_dout2,
    
    //UART
    input pio20, //UART - RX;
    output pio21 //UART - TX;    
    );
    
    wire rst, rstn;
    assign rst = btnR;
    assign rstn = ~btnR;
    //Clock
    wire CLK500Hz,CLK9600, CLK1Hz,CLK_ADC;

    clock_div clk_div_u0(rstn,sysclk,CLK9600);
    clock_div clk_div_u1(rstn,sysclk,CLK500Hz);
    clock_div clk_div_u2(rstn,CLK500Hz,CLK1Hz);
    clock_div clk_div_u3(rstn,sysclk,CLK_ADC);
    defparam clk_div_u0.FREQ_INPUT  = 12_000_000;
    defparam clk_div_u0.FREQ_OUTPUT = 9600;
    defparam clk_div_u1.FREQ_INPUT  = 12_000_000;
    defparam clk_div_u1.FREQ_OUTPUT = 500;
    defparam clk_div_u2.FREQ_INPUT  = 500;
    defparam clk_div_u2.FREQ_OUTPUT = 1;
    defparam clk_div_u3.FREQ_INPUT  = 12_000_000;
    defparam clk_div_u3.FREQ_OUTPUT = 2_000_000;
    
    //Magnet Sensor Variables
    wire [15:0] DXR, DZR, DYR;
    magnet_sensor mag(clk, rst, i2c_sda, i2c_scl, sensor_drdy, DXR, DZR, DYR);    
       
    //External ADC variables        
    reg [1:0] mode;
    wire [11:0] ext_adc_data;
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
    .daddr_in(PIN15_ADDR),        // Address bus for the dynamic reconfiguration port
    .dclk_in(sysclk),             // Clock input for the dynamic reconfiguration port
    .den_in(enable),              // Enable Signal for the dynamic reconfiguration port
    .di_in(0),                    // Input data bus for the dynamic reconfiguration port
    .dwe_in(0),                   // Write Enable for the dynamic reconfiguration port
    .vauxp12(xa_p[0]),
    .vauxn12(xa_n[0]),
    .vauxp4(xa_p[1]),
    .vauxn4(xa_n[1]),  
    .busy_out(),                 // ADC Busy signal
    .channel_out(),              // Channel Selection Outputs
    .do_out(ADC_data),           // Output data bus for dynamic reconfiguration port
    .drdy_out(ready),            // Data ready signal for the dynamic reconfiguration port
    .eoc_out(enable),            // End of Conversion Signal
    .vp_in(vp_in),               // Dedicated Analog Input Pair
    .vn_in(vn_in)
    );

//EXTERNAL ADC MCP3202 CONFIG;
// DRV FREQ : 2MHZ;
// CHANNEL : ONLY CHANNEL 0; 
localparam  SINGLE_CHAN0  = 2'b10;
localparam  SINGLE_CHAN1  = 2'b11;

reg adc_ready1;
reg adc_ready2;
wire adc_valid1;
wire adc_valid2;
wire [11:0] adc_data1;
wire [11:0] adc_data2;
reg [11:0] adc_data_mode0; //Use these for pRNG
reg [11:0] adc_data_mode1;
reg [11:0] adc_data_mode2;
reg [11:0] adc_data_mode3;

// Display mode toggles between 0 and 3 to cycle through sensor data
reg [1:0] current_display_mode = 0;  

always @(posedge CLK1Hz or negedge rstn) begin
    if (!rstn) begin
        current_display_mode <= 0;
    end else begin
        current_display_mode <= (current_display_mode + 1) % 4;  // Cycle through display modes every second
    end
end

drv_mcp3202 drv_mcp3202_u0(
    .rstn(rstn),
    .clk(CLK_ADC),
    .ap_ready(adc_ready1),
    .ap_valid(adc_valid1),
    .mode((current_display_mode < 2) ? SINGLE_CHAN0 : SINGLE_CHAN1),
    .data(adc_data),
    .port_din(adc_dout1),
    .port_dout(adc_din1), 
    .port_clk(adc_clk1),
    .port_cs(adc_csn1)
);

drv_mcp3202_2 drv_mcp3202_2_u0(
    .rstn(rstn),
    .clk(CLK_ADC),
    .ap_ready(adc_ready2),
    .ap_valid(adc_valid2),
    .mode((current_display_mode % 2) ? SINGLE_CHAN1 : SINGLE_CHAN0),
    .data(adc_data2),
    .port_din2(adc_dout2),
    .port_dout2(adc_din2), 
    .port_clk2(adc_clk2),
    .port_cs2(adc_csn2)
);

always @(posedge adc_valid1) begin
    if (current_display_mode < 2)
        adc_data_mode0 <= adc_data1;  // CH0 of ADC1
    else
        adc_data_mode1 <= adc_data1;  // CH1 of ADC1
end

always @(posedge adc_valid2) begin
    if (current_display_mode % 2 == 0)
        adc_data_mode2 <= adc_data2;  // CH0 of ADC2
    else
        adc_data_mode3 <= adc_data2;  // CH1 of ADC2
end

// Display logic
//always @(posedge CLK1Hz or negedge rstn) begin
//    if (!rstn) begin
//        adc_ready1 <= 1'b0;
//        adc_ready2 <= 1'b0;
//        Segment_data <= 12'h000;
//    end else begin
//        case (current_display_mode)
//            0: Segment_data <= adc_data_mode0;
//            1: Segment_data <= adc_data_mode1;
//            2: Segment_data <= adc_data_mode2;
//            3: Segment_data <= adc_data_mode3;
//        endcase
//        adc_ready1 <= 1'b1;
//        adc_ready2 <= 1'b1;
//    end
//end


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

    //num num_u0(sign,int,dec);
    Math MATH(A,B);
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
    
    always @ (posedge clk) begin
    //x0 = bin(1,8'd2,23'd17);
    x0 =bin(adc_data_mode3[11],adc_data_mode3[10:4],adc_data_mode3[3:0]); //location of center - X
    y0 =bin(adc_data_mode0[11],adc_data_mode0[10:4],adc_data_mode0[3:0]); //location of center - Y
    g = bin(0,ADC_data[15:8],ADC_data[7:0]); //gravity
    m1 =bin(DXR[15],DXR[14:7],DXR[6:0]); //mass 1 change this
    m2 =bin(adc_data_mode1[11],adc_data_mode1[10:4],adc_data_mode1[3:0]); //mass 2 change this
    l1 =bin(DYR[15],DYR[14:7],DYR[6:0]); //length 1 change this
    l2 =bin(adc_data_mode2[11],adc_data_mode2[10:4],adc_data_mode2[3:0]); //length 2 change this
    end
    DP dp(clk,x0,y0,g,m1,m2,l1,l2,RNG,x_1, x_2,y_1,y_2);
    //adc_data_mode0 1 2 3
    

//7SEGMENT DISPLAY CONFIG;
reg [11:0] Segment_data;
drv_segment segment_u0(rstn,CLK500Hz,{4'h0,Segment_data},{pio43,pio46,pio47,pio37},{pio40,pio38,pio45,pio42,pio41,pio39,pio48,pio44});

//UART START------------------------------------//

uart_tx uart_tx_u0(CLK9600,rstn,uart_ready,uart_vaild,pio21,1'b0,uart_tx_data);
reg uart_ready;
reg data_index;
reg uart_tx_data;
reg [31:0] data_array;

always@(posedge CLK500Hz,negedge rstn)begin
    if (!rstn)begin
        uart_ready <= 1'b0;
    end else begin
        if (uart_vaild) uart_ready <= 1'b0;
        else if(!uart_ready) uart_ready <= 1'b1;
    end
end

always @(posedge sysclk) begin
    if (~btn[1]) begin
        data_index <= 2'b00;
    end else begin
        if (data_index < 2'b10) begin
            data_index <= data_index + 1'b1;
        end else begin
            data_index <= 2'b00;
        end
        uart_tx_data <= data_array[data_index];
    end
end

always @(posedge CLK9600) begin
    data_array = RNG;
end
//UART END-------------------------------------------------------//
endmodule
