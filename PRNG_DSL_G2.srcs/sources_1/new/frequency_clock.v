`timescale 1ns / 1ps
module clk_tree #(parameter COUNTER = 12000)(
    input in_clk,
    input rstn,
    input btnPauseN,
    input isPausable,
    output clk_out
);

reg [13:0]cnter;   // 12Mhz/(500Hz*2) =  12_000(14 bits);
reg internal_hz; 

assign clk_out = internal_hz;

reg pause = 0;

always@(posedge in_clk, negedge rstn)begin
    if(!rstn)begin              //Non-Sync Reset
        internal_hz <= 1'b0;    //Set 500hz clock as '0' to avoid any uncertain status;        
        cnter <= 14'd0; //Clear counter
    end
    else begin
        if(cnter == COUNTER-1'b1)begin   //When counter reach 12_000
            internal_hz <= ~internal_hz;        //Toggle 500Hz CLk reg;
            cnter <= 14'd0;             //Clear counter
        end
        else if(!pause)
            cnter <= cnter +1'b1; //Counter
    end
end

always@(negedge rstn, negedge btnPauseN)
begin
    if(!rstn)begin
        pause <= 0;
    end
    else
    begin
    if(isPausable == 1 && !btnPauseN) pause <= ~pause;
    else pause <= pause;
    end  
end

endmodule