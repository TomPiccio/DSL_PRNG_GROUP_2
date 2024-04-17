`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.04.2024 02:14:39
// Design Name: 
// Module Name: drv_mcp3202_2
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


module drv_mcp3202_2(
    input rstn,
    input clk,
    input   ap_ready,
    output  reg ap_valid,
    input   [3:0] mode,
    output  [11:0] data,

    //MC3202 2
    input   port_din2,
    output  reg port_dout2,
    output  port_clk2,
    output  reg port_cs2
);

wire    [3:0]      Data_Transmit; // 4 bits CONTROL;
reg     [12:0]     Data_Receive;  // 1 bit NULL + 12 bits DATA;

assign Data_Transmit[3]    = 1'b1;
assign Data_Transmit[0]    = 1'b1;
assign Data_Transmit[2:1] = mode;

reg [1:0]   fsm_statu,fsm_next;
localparam FSM_IDLE = 2'b00;
localparam FSM_WRIT = 2'b10;
localparam FSM_READ = 2'b11;
localparam FSM_STOP = 2'b01;

reg [1:0] cnter_writ;
reg [3:0] cnter_read;

//FSM statu transfer;
always @(posedge clk, negedge rstn) begin
    if (!rstn)  fsm_statu <= FSM_IDLE;
    else        fsm_statu <= fsm_next;
end

//FSM Transfer Condition;
always @(*)begin
    if(!rstn) fsm_next <= FSM_IDLE;
    else begin
        case (fsm_statu)
            FSM_IDLE : fsm_next <= (ap_ready)? FSM_WRIT : FSM_IDLE;
            FSM_WRIT : fsm_next <= (2'd0 == cnter_writ)? FSM_READ : FSM_WRIT;
            FSM_READ : fsm_next <= (2'd0 == cnter_read)? FSM_STOP : FSM_READ;
            FSM_STOP : fsm_next <= (!ap_ready)? FSM_STOP : FSM_IDLE;
            default  : fsm_next <= FSM_IDLE;
        endcase
    end
end

//FSM Output - SPI Write Data
always @(negedge rstn,negedge clk)begin
    if (!rstn) begin
        cnter_writ  <= 2'd3;
        port_dout2   <= 1'b1;
        port_cs2     <= 1'b1;
    end else begin
        case (fsm_statu)
            FSM_IDLE : begin 
                cnter_writ  <= 2'd3;
                port_dout2   <= 1'b1;
                port_cs2     <= 1'b1;
            end
            FSM_WRIT : begin 
                port_cs2     <= 1'b0;
                port_dout2   <= Data_Transmit[cnter_writ];
                cnter_writ  <= cnter_writ - 1'b1;
            end
            FSM_READ : begin 
                port_cs2     <= 1'b0;
                port_dout2   <= 1'b1;
            end
            FSM_STOP : port_cs2     <= 1'b1;
            default  : ;
        endcase
    end
end

//FSM Output - SPI Read  Data
always @(negedge rstn,posedge clk)begin
    if (!rstn) begin
        cnter_read  <= 4'd13;
        Data_Receive <= 13'h00;
        ap_valid = 1'b0;
    end else begin
        case (fsm_statu)
            FSM_IDLE : begin
                ap_valid = 1'b0; 
                cnter_read  <= 4'd13;
            end
            FSM_WRIT : begin 
                Data_Receive <= 13'h00;
            end
            FSM_READ : begin 
                cnter_read <= cnter_read - 1'b1;
                Data_Receive[cnter_read] <= port_din2;
            end
            FSM_STOP : ap_valid = 1'b1;
            default  : ;
        endcase
    end
end

assign port_clk2 = clk | port_cs2;
assign data = Data_Receive[11:0];

endmodule