`timescale 1ns / 1ps

module DP(
    input clk,
    input [31:0]x0,
    input [31:0]y0,
    input [31:0]g,
    input [31:0]m1,
    input [31:0]m2,
    input [31:0]l1,
    input [31:0]l2,
    output [31:0]RNG,
    output [31:0]x_1,
    output [31:0]x_2,
    output [31:0]y_1,
    output [31:0]y_2
    );

Math MATH( //math takes 9 bit variables, 1st bit is signed, next 8 store values
    A,//Math.plus(A,B), Math.minus(A,B), Math.times(A,B), Math.divide(A,B)
    B //Math.mod(A), Math.neg(A) 
); //

num NUM( //num takes in a signed bit, 8bin integer and 23bit decimal place
    sign, //num.bin(0, 8'd20, 23'd3)
    int,
    dec //only accepts 1dp
); //
integer testfile;
initial begin
    testfile=$fopen("test6.txt","w");
end
//to get the random numbers, modify the below 7 variables and run for a random amount of time
//the random numbers will appear as x1 x2, y1 y2 values
//these position values correspond to the position of the masses for the chaotic pendulum during operation

//https://www.myphysicslab.com/pendulum/double-pendulum-en.html
//https://www.youtube.com/watch?v=ySvU8oQLtHY
    
//reg [31:0]x0 =NUM.bin(1,8'd2,23'd17); //location of center - X
//reg [31:0]y0 =NUM.bin(0,8'd7,23'd33); //location of center - Y
//reg [31:0]g = NUM.bin(0,8'd2,23'd05); //gravity
//reg [31:0]m1 =NUM.bin(0,8'd3,23'd50); //mass 1 change this
//reg [31:0]m2 =NUM.bin(0,8'd5,23'd50); //mass 2 change this
//reg [31:0]l1 =NUM.bin(0,8'd30,23'd03); //length 1 change this
//reg [31:0]l2 =NUM.bin(0,8'd69,23'd96); //length 2 change this
reg [31:0]TAU=NUM.bin(0,8'd6,23'd28); //constant
reg [31:0]a1 = MATH.divide(TAU,NUM.bin(0,8'd2,23'd00));                                    //angle
reg [31:0]a2 = MATH.times(TAU,MATH.divide(NUM.bin(0,8'd3,23'd00),NUM.bin(0,8'd8,23'd00))); //angle
reg [31:0]x1, y1, x2, y2;
reg [31:0]a1_v, a1_a, a2_v, a2_a; //first and second derivative
reg [31:0]var1,var2,var3,var4,var5,var6,var7;
reg [8:0] symbol [1:0];

assign x_1 = x1;
assign x_2 = x2;
assign y_1 = y1;
assign y_2 = y2;
assign RNG[7:0]  =y_2[7:0];
assign RNG[15:8] =x_2[7:0];
assign RNG[23:16]=y_1[7:0];
assign RNG[31:24]=x_1[7:0];

always @(negedge clk) begin
//a1_a = (-g*(2*m1*m2)*sin(a1) - m2*g*sin(a1-2*a2) - 2*sin(a1-a2)*m2*(a2_v*a2_v*l2 + a1_v*a1_v*l1*cos(a1-a2))) / (l1*(2*m1 + m2 - m2*cos(2*a1-2*a2)));
//              var1                   var2                var3                         var4                                    var5        
var1 = MATH.times(MATH.times(MATH.times(m1,m2),NUM.bin(0,8'd2,23'd00)),MATH.times(MATH.sin(a1),MATH.neg(g)));
var2 = MATH.times(MATH.sin(MATH.minus(a1,MATH.times(a2,NUM.bin(0,8'd2,23'd00)))),MATH.times(m2,g));
var3 = MATH.times(MATH.times(m2,NUM.bin(0,8'd2,23'd00)),MATH.sin(MATH.minus(a1,a2)));
var4 = MATH.plus(MATH.times(l2,MATH.times(a2_v,a2_v)),MATH.times(MATH.times(l1,MATH.times(a1_v,a1_v)),MATH.cos(MATH.minus(a1,a2))));
var5 = MATH.times(l1,MATH.plus(MATH.times(NUM.bin(0,8'd2,23'd00),m1),MATH.minus(m2,MATH.times(m2,MATH.cos(MATH.minus(MATH.times(a1,NUM.bin(0,8'd2,23'd00)),MATH.times(a2,NUM.bin(0,8'd2,23'd00))))))));
a1_a = MATH.divide(MATH.minus(MATH.minus(var1,var2),MATH.times(var3,var4)),var5);


//a2_a = 2*sin(a1-a2) * (a1_v*a1_v*l1*(m1+m2) + g*(m1+m2)*cos(a1) + a2_v*a2_v*l2*m2*cos(a1-a2)) / (l2*(2*m1 + m2 - m2*cos(2*a1-2*a2)));
//           var1               var2                  var3                    var4                                var6                                
var1 = MATH.times(NUM.bin(0,8'd2,23'd00),MATH.sin(MATH.minus(a1,a2)));
var2 = MATH.times(MATH.times(MATH.times(a1_v,a1_v),l2),MATH.plus(m1,m1));
var3 = MATH.times(MATH.times(g,MATH.plus(m1,m2)),MATH.cos(a1));
var4 = MATH.times(MATH.times(MATH.times(MATH.times(a2_v,a2_v),l2),m2),MATH.cos(MATH.minus(a1,a2)));
var5 = MATH.times(m2,MATH.cos(MATH.minus(MATH.times(NUM.bin(0,8'd2,23'd00),a1),MATH.times(NUM.bin(0,8'd2,23'd00),a2))));
var6 = MATH.times(l2,MATH.minus(MATH.plus(MATH.times(NUM.bin(0,8'd2,23'd00),m1),m2),var5));
a2_a = MATH.plus(MATH.plus(MATH.times(var1,var2),var3),MATH.divide(var4,var6));

a1_v = MATH.plus(a1_v,a1_a); //a1_v = a1_v + a1_a;
a2_v = MATH.plus(a2_v,a2_a); //a2_v = a2_v + a2_a;
a1 = MATH.plus(a1,a1_v);     //a1 = a1 + a1_v;
a2 = MATH.plus(a2,a2_v);     //a2 = a2 + a2_v;

x1 = MATH.plus(x0,MATH.times(l1,MATH.sin(a1))); //x1 = x0 + l1*sin(a1);
x2 = MATH.plus(x1,MATH.times(l2,MATH.sin(a2))); //x2 = x1 + l2*sin(a2);
y1 = MATH.plus(y0,MATH.times(l1,MATH.cos(a1))); //y1 = y0 + l1*cos(a1);
y2 = MATH.plus(y1,MATH.times(l2,MATH.cos(a2))); //y2 = y1 + l2*cos(a2);
            
symbol[1] = "-";
symbol[0] = "+";

//$display("x1 = %c%d.%d y1 = %c%d.%d       x2 = %c%d.%d y2 = %c%d.%d", 
//symbol[x1[31]], x1[30:23], x1[7:0], symbol[y1[31]], y1[30:23], y1[7:0],

//symbol[x2[31]], x2[30:23], x2[7:0],  symbol[y2[31]], y2[30:23], y2[7:0]);
$display("RNG = %d", RNG);
$fwrite(testfile,"%d\n",RNG);
end

endmodule
