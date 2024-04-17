`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/17/2024 01:25:12 PM
// Design Name: 
// Module Name: top_module
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


module top_module(
    input sysclk, 
    input btnR,
    input btnL,
    input pio9, //external button
    input pio20, //RX
    output pio21, //TX 
    output [1:0]led,
    
    //Magnet Sensor I2C Inputs
    inout i2c_sda,
    inout wire i2c_scl,
    input sensor_drdy,
    
    //XADC
    input [1:0] xa_n,
    input [1:0] xa_p,
    input vp_in,
    input vn_in
    );
    
    //Magnet Sensor Variables
    wire [15:0] DXR, DZR, DYR;
    wire rst, rstn;
    wire [31:0] mag_data;
    assign rst = btnR;
    //assign rstn = ~btnR;
    magnet_sensor mag(sysclk, rst, i2c_sda, i2c_scl, sensor_drdy, DXR, DZR, DYR);
    assign mag_data[31:16] = DXR;
    assign mag_data[15:0] = DZR;
    
    //XADC
    localparam PIN15_ADDR = 8'h14;  //VAUX4;
    localparam PIN16_ADDR = 8'h1C;  //VAUX12;
    
    wire enable;                    //enable into the xadc to continuosly get data out
    reg [6:0] Address_in = 7'h14;    //Adress of register in XADC drp corresponding to data
    wire ready;                      //XADC port that declares when data is ready to be taken
    wire [15:0] ADC_data;                //XADC data  
    
    
    //Clock
    wire CLK500Hz,CLK9600,CLK1Hz;
    clock_div clk_div_u0(rstn,sysclk,CLK9600);
    clock_div clk_div_u1(rstn,sysclk,CLK500Hz);
    clock_div clk_div_u2(rstn,CLK500Hz,CLK1Hz);
    defparam clk_div_u0.FREQ_INPUT  = 12_000_000;
    defparam clk_div_u0.FREQ_OUTPUT = 9600;
    defparam clk_div_u1.FREQ_INPUT  = 12_000_000;
    defparam clk_div_u1.FREQ_OUTPUT = 500;
    defparam clk_div_u2.FREQ_INPUT  = 500;
    defparam clk_div_u2.FREQ_OUTPUT = 1;
    
    //XADC Code here
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
    
    //External ADC
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
    
    //UART
    wire rstn, extbtn;
    //assign rstn = ~btnR;
    assign rstn = ~pio9;
    
    wire [7:0] uart_rx_data;
    
    reg uart_ready;
    wire uart_valid;
    
//    reg [31:0] data_array [0:2]; // Array with 3 elements (0 to 2)
//    initial begin
//        data_array[0] = ADC_data;
//        data_array[1][31:16] = DZR;
//        data_array[1][15:0] = DYR;
//        data_array[2] = 32'b11111110110111001011101010011000;
//    end
    
    reg [1:0] data_index = 2'b00;
    
    reg [63:0] uart_tx_data;
    //uart_rx uart_rx_u0(CLK9600,rstn,uart_ready,uart_valid,pio20,1'b0,uart_rx_data);
    uart_tx uart_tx_u0(CLK9600,rstn,uart_ready,uart_valid,pio21,1'b0,uart_tx_data);
    
    

    reg [13:0] out_counter;
    reg [3:0] byte_counter;
    always @(posedge CLK9600, posedge pio9)begin
    if (pio9)begin
        uart_ready <= 1'b0;
        out_counter <= 6'b0;
        byte_counter <= 3'd0;
    end else begin
        if (byte_counter >= 4'd8) begin 
            uart_ready <= 1'b0;
        end
        else begin
            if (uart_valid && uart_ready) begin
                uart_ready <= 1'b0;
                byte_counter <= byte_counter + 6'b1;
            end
            else if(!uart_ready) uart_ready <= 1'b1;
        end
    end
    end
    assign led[1] = uart_ready;
    
    wire [63:0]combined_data;
    assign combined_data[63:48] = mag_data;
    assign combined_data[47:32] = adc_data_mode0 * adc_data_mode1;
    assign combined_data[31:16] = adc_data_mode2 * adc_data_mode3; //ADC_data
    assign combined_data[15:0] = ADC_data; //ADC_data

    always @(posedge CLK9600) begin
        //uart_tx_data <= ADC_data;
        uart_tx_data <= combined_data;
    end
    assign led[0] = pio9;
endmodule
