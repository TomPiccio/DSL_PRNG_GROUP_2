`timescale 1ns / 1ps

module uart_manager(
        input clk,
        input rst,
        input [31:0] data_in,
        input pio20, //UART - RX;
        output pio21, //UART - TX;
        output [1:0] led,
        output [2:0] ledrgb
);

wire CLK500Hz,CLK9600,CLK50Hz;

clock_div clk_div_u0(rstn,sysclk,CLK9600);
clock_div clk_div_u1(rstn,sysclk,CLK500Hz);
clock_div clk_div_u2(rstn,CLK500Hz,CLK50Hz);
defparam clk_div_u0.FREQ_INPUT  = 12_000_000;
defparam clk_div_u0.FREQ_OUTPUT = 9600;
defparam clk_div_u1.FREQ_INPUT  = 12_000_000;
defparam clk_div_u1.FREQ_OUTPUT = 500;
defparam clk_div_u2.FREQ_INPUT  = 500;
defparam clk_div_u2.FREQ_OUTPUT = 50;

reg uart_ready;
wire uart_valid;

wire [2:0] rgb_led;
assign ledrgb = ~rgb_led;
//uart_rx uart_rx_u0(CLK9600,rstn,uart_ready,uart_valid,pio20,1'b0,uart_rx_data);
uart_tx uart_tx_u0(CLK9600,rstn,uart_ready,uart_valid,pio21,1'b0,data_in,rgb_led);

reg [5:0] out_counter;
reg [2:0] byte_counter;


//debug
assign led = {uart_ready,~uart_valid};


always @(posedge CLK50Hz, posedge rst)begin
    if (rst)begin
        uart_ready <= 1'b0;
        out_counter <= 6'b0;
        byte_counter <= 3'd0;
    end else begin
        if(out_counter == 6'd50 ) begin //same count with frequency meaning output every 1s
            out_counter <= 6'b0;
            byte_counter <= 3'd0;
        end
        else if (byte_counter >= 3'd4) begin 
            out_counter <= out_counter + 6'b1;
            uart_ready <= 1'b0;
        end
        else begin
            if (uart_valid && uart_ready) begin
                uart_ready <= 1'b0;
                byte_counter <= byte_counter + 6'b1;
            end
            else if(!uart_ready) uart_ready <= 1'b1;
            out_counter <= out_counter + 6'b1;
        end
    end
end

endmodule

