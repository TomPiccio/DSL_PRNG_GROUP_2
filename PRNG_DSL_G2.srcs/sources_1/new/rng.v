module Math(
    input [31:0]A, //1 pos/neg bit, 7 round bits, no decimals
    input [31:0]B //total of 8 bits
    );
    
function [31:0] plus;
    input [31:0] A; //bit 1 sign
    input [31:0] B; //bits 2 - 9 real
    reg [31:0]a, b; // bits 10 - 16 decimals
    reg [31:0]var; //local variable
    reg [8:0] symbol [1:0];
        begin
            symbol[1] = "-";
            symbol[0] = "+";
            a = A;
            b = B;
            case({a[31],b[31],~(a[30:23] >= b[30:23]), ~(a[22:0] >= b[22:0])})
                4'b0000, 4'b0001, 4'b0010, 4'b0011: begin //both positive
                    var[31] = 0;
                    var[30:23] = a[30:23] + b[30:23];
                    var[22:0] = a[22:0] + b[22:0];
                    while (var[22:0] >= 23'd100)begin
                        var[30:23] = var[30:23] + 8'd1;
                        var[22:0] = var[22:0] - 23'd100; 
                        end
                    end
                    //------------------------------------------//
                4'b0100:begin //A positive, B negative, both of A larger than B 
                        var[31] = 0;
                        var[30:23] = a[30:23] - b[30:23];
                        var[22:0] = a[22:0] - b[22:0];
                        end
                4'b0101:begin //A > B, a < b
                        var[31] = 0;
                        if(a[30:23] == b[30:23])begin
                            var[31] = 1;
                            a[30:23] = a[30:23]+ 8'd1; 
                            var[22:0] = b[22:0] - a[22:0];end
                        var[30:23] = a[30:23] - b[30:23] - 8'd1;
                        var[22:0] = (a[22:0] + 23'd100) - b[22:0];      
                        end
                4'b0110:begin //A < B, a > b
                        var[31] = 1;
                        if(a[30:23] == b[30:23])begin
                            b[30:23] = b[30:23]+ 8'd1; end                        
                        var[30:23] = b[30:23] - a[30:23] - 8'd1;
                        var[22:0] = (23'd100 + b[22:0]) - a[22:0];  
                        end
                4'b0111:begin //A < B, a < b
                        var[31] = 1;
                        var[30:23] = b[30:23] - a[30:23];
                        var[22:0] = b[22:0] - a[22:0];
                        end
                        //----------------------------------------//
                4'b1000:begin //A negative, B positiv, both of A larger than B 
                        var[31] = 1;
                        var[30:23] = a[30:23] - b[30:23];
                        var[22:0] = a[22:0] - b[22:0];
                        end
                4'b1001:begin //A > B, a < b
                        var[31] = 1;
                        if(a[30:23] == b[30:23])begin
                            a[30:23] = a[30:23]+ 8'd1; end                        
                        var[30:23] = a[30:23] - b[30:23] - 8'd1;
                        var[22:0] = (23'd100 + a[22:0]) - b[22:0];      
                        end
                4'b1010:begin //A < B, a > b
                        var[31] = 0;
                        if(a[30:23] == b[30:23])begin
                            b[30:23] = b[30:23]+ 8'd1; end                        
                        var[30:23] = b[30:23] - a[30:23] - 8'd1;
                        var[22:0] = (23'd100 + b[22:0]) - a[22:0];  
                        end
                4'b1011:begin //A < B, a < b
                        var[31] = 0;
                        var[30:23] = b[30:23] - a[30:23];
                        var[22:0] = b[22:0] - a[22:0];
                        end                        
                4'b1100, 4'b1101, 4'b1110, 4'b1111: begin
                    var[31] = 1;
                    var[30:23] = a[30:23] + b[30:23];
                    var[22:0] = a[22:0] + b[22:0];
                    while (var[22:0] >= 23'd100)begin
                        var[30:23] = var[30:23] + 8'd1;
                        var[22:0] = var[22:0] - 23'd100; 
                        end
                    end
                default: var = 32'd100;
            endcase
            //$display("A = %c%d.%d, and , B = %c%d.%d", symbol[A[31]],A[30:23],A[22:0],symbol[B[31]],B[30:23],B[22:0]);
            plus = var;
            //$display("A + B = %c%d.%d", symbol[plus[31]],plus[30:23],plus[22:0]);
//            $display("%c%d.%d + %c%d.%d = %c%d.%d"
//            ,symbol[a[31]],a[30:23],a[22:0]
//            ,symbol[b[31]],b[30:23],b[22:0]
//            ,symbol[plus[31]],plus[30:23],plus[22:0]);
        end
endfunction
//==========================================================================//
function [31:0] minus;
    input [31:0] A; //bit 1 sign
    input [31:0] B; //bits 2 - 9 real
    reg [31:0]var; //local variable
    reg [8:0] symbol [1:0];
    reg [31:0]a, b; // bits 10 - 16 decimals
        begin
            symbol[1] = "-";
            symbol[0] = "+";
            a = A;
            b = B;
            b[31] = ~B[31];
            var = plus(a,b);         
            //$display("A = %c%d.%d, and , B = %c%d.%d", symbol[A[31]],A[30:23],A[22:0],symbol[B[31]],B[30:23],B[22:0]);
            minus = var;
            //$display("A - B = %c%d.%d", symbol[minus[31]],minus[30:23],minus[22:0]);
        end
endfunction
//==========================================================================//
function [31:0] times;
    input [31:0] A; //bit 1 sign
    input [31:0] B; //bits 2 - 9 real
    reg [31:0]a, b; // bits 10 - 16 decimals
    reg [31:0]var, var1, var2, var3, var4, var5, dec;
    reg [8:0] symbol [1:0]; //(A.a)(B.b) = (A + .a)(B + .b) = (A*B + A*.b + B*.a + .a*.b)
        begin
            symbol[1] = "-";
            symbol[0] = "+";
            a = A;
            b = B;
            var1[30:23] = a[30:23] + b[30:23]; //A*B
            var2[22:0] = a[30:23] * b[22:0];   //A * .b
            var3[22:0] = b[30:23] * a[22:0];   //B * .a
            var4[22:0] = a[22:0] * b[22:0];    //.a * .b
            //first add the decimals together
            //Add first 2 DIGITS of var4 into var2 + var3, store in var5
            //extract first 2 digits of var4
            var5[7:0] = var4[22:0]/23'd100;
            dec[22:0] = var2[22:0] + var3[22:0] + var5[7:0];
            //next overflow the decimals into the integers
            var5[22:0] = dec[22:0]/23'd100;
            var[30:23] = (a[30:23] * b[30:23]) + var5[7:0];
            //store remaining decimals
            var[22:0] = dec[22:0] - (dec[22:0]/23'd100)*23'd100; //purposely truncated
            case({a[31],b[31] })
                2'b00, 2'b11: var[31] = 0; //both positive
                2'b01, 2'b10: var[31] = 1;
                default: var = 32'd100;
            endcase
            //$display("dec[22:0] = %d, dec[22:0]/100 = %d", dec[22:0], dec[22:0]/23'd100);
            //$display("A = %c%d.%d, and , B = %c%d.%d", symbol[A[31]],A[30:23],A[22:0],symbol[B[31]],B[30:23],B[22:0]);
            times = var;
            //$display("A + B = %c%d.%d", symbol[times[31]],times[30:23],times[22:0]);
//            $display("%c%d.%d * %c%d.%d = %c%d.%d"
//            ,symbol[a[31]],a[30:23],a[22:0]
//            ,symbol[b[31]],b[30:23],b[22:0]
//            ,symbol[times[31]],times[30:23],times[22:0]);            
        end
endfunction
//==========================================================================//
function [31:0] divide;
    input [31:0] A; //bit 1 sign
    input [31:0] B; //bits 2 - 9 real
    reg [31:0]a, b; // bits 10 - 16 decimals
    reg [31:0]var, int, quo, dec;
    reg [8:0] symbol [1:0]; //(A.a)/(B.b) ==> (Aa)(Bb) remove decimals and do division, keeping quotients
        begin
            symbol[1] = "-";
            symbol[0] = "+";
            a = A;
            b = B;           
            //move decimal place and combine
            a[30:0] = A[30:23] * 8'd100;
            a[30:0] = a[30:0] + A[7:0];
            b[30:0] = B[30:23] * 8'd100;
            b[30:0] = b[30:0] + B[7:0];
//            $display("A = %c%d.%d, a = %c%d"
//            ,symbol[A[31]],A[30:23],A[22:0]
//            ,symbol[a[31]],a[30:0]);             
            case({a[31],b[31],~(a[30:0] >= b[30:0])})
                3'b000, 3'b110: begin
                    var[31] = 0;
                    int[30:23] = a[30:0] / b[30:0];
                    quo[30:0] = a[30:0] - (int[30:23] * b[30:0]); //quotient
                    dec[22:0] = (quo[30:0]*100) / b[30:0]; //2dp is enough
                    var[30:23] = int[30:23];
                    var[22:0] = dec[22:0];end
                3'b001, 3'b111: begin
                    var[31] = 0;
                    var[30:23] = 0;
                    var[22:0] = (a[30:0] * 100) / b[30:0];end
                3'b011, 3'b101: begin
                    var[31] = 1;
                    var[30:23] = 0;
                    var[22:0] = (a[30:0] * 100) / b[30:0];end
                3'b010, 3'b100: begin
                    var[31] = 1;
                    int[30:23] = a[30:0] / b[30:0];
                    quo[30:0] = a[30:0] - (int[30:23] * b[30:0]); //quotient
                    dec[22:0] = (quo[30:0]*100) / b[30:0]; //2dp is enough
                    var[30:23] = int[30:23];
                    var[22:0] = dec[22:0];end
                default: var = 32'd100;
            endcase
            //$display("a = %d.%d divide by b = %d.%d", A[30:23],A[22:0], B[30:23],B[22:0]);
            //$display("Ans = %d.%d", var[30:23], var[22:0]);
            //$display("A = %c%d.%d, and , B = %c%d.%d", symbol[A[31]],A[30:23],A[22:0],symbol[B[31]],B[30:23],B[22:0]);
            divide = var;
//            $display("%c%d.%d / %c%d.%d = %c%d.%d"
//            ,symbol[a[31]],a[30:23],a[22:0]
//            ,symbol[b[31]],b[30:23],b[22:0]
//            ,symbol[divide[31]],divide[30:23],divide[22:0]);
        end
endfunction
//==========================================================================//
function [31:0] mod;
    input [31:0] A;
    reg [31:0]a;
    reg [31:0]var; //local variable
    reg [8:0] symbol [1:0];
        begin
            symbol[1] = "-";
            symbol[0] = "+";
            a = A;
            var[31] = 0;
            var[30:0] = a[30:0];          
//            $display("A = %c%d.%d", symbol[A[31]],A[30:23],A[22:0]);
            mod = var;
//            $display("|A| = %c%d.%d", symbol[var[31]],mod[30:23],mod[22:0]);
        end
endfunction
//==========================================================================//
function [31:0] neg;
    input [31:0] A;
    reg [31:0]a;
    reg [31:0]var; //local variable
    reg [8:0] symbol [1:0];
        begin
            symbol[1] = "-";
            symbol[0] = "+";
            a = A;
            var[31] = ~a[31];
            var[30:0] = a[30:0];          
//            $display("A = %c%d.%d", symbol[A[31]],A[30:23],A[22:0]);
            neg = var;
//            $display("neg A = %c%d.%d", symbol[var[31]],neg[30:23],neg[22:0]);
        end
endfunction
//==========================================================================//
reg [31:0]pi, pi_2;
reg [31:0]const16, const5, const4, const2, const1;
initial begin
const16 = 0; const5 = 0; const4 = 0; const2 = 0; const1 = 0;
const16[30:23] = 8'd16;
const5[30:23] = 8'd5;
const4[30:23] = 8'd4;
const2[30:23] = 8'd2;
const1[30:23] = 8'd1;

pi[31] = 0;
pi[30:23] = 8'd3;
pi[22:0] = 23'd14;
pi_2 = Math.times(pi,const2);
end

function [31:0] sin;
//https://en.wikipedia.org/wiki/Bh%C4%81skara_I%27s_sine_approximation_formula
    input [31:0]theta;
    reg [31:0] var, store, var1, var2, var3, var4, var5, var6, var7;
    reg [8:0] symbol [1:0];
    begin
    symbol[1] = "-";
    symbol[0] = "+";
    //Check what is theta
    store = divide(theta,pi_2);
    case({theta[31],store[30:23] >= 1})
        2'b00:begin//positive number less than 2 pi
        theta = theta;end
        2'b01:begin//positive numver greater than 2 pi
        store = divide(theta,pi_2);
        store[31] = 0; store[22:0] = 0;
        theta = minus(theta,times(store,pi_2));end
        2'b10:begin//negative number less than 2pi
        theta = mod(theta);
        theta = minus(pi_2,theta);end       
        2'b11:begin//negatiev number greater than 2pi
        //$display("theta before = %c%d.%d", symbol[theta[31]],theta[30:23],theta[22:0]);
        store = 0; store = divide(theta,pi_2); store[31] = 0; store[22:0] = 23'd0;//1.11
        theta = plus(theta,times(plus(const1,store),pi_2)); //7-2pi
        //$display("theta after= %c%d.%d", symbol[theta[31]],theta[30:23],theta[22:0]);
        end
    endcase
    if(theta >= 0 && theta <= pi)begin //first 2 quadrants
        //sine function for 0 to pi:   y = 16x(pi-x) / (5pi^2 - 4x(pi-x))
        var = times(times(const16,theta),minus(pi,theta));
        var = divide(var,times(times(pi,pi),const5) - times(times(const4,theta),minus(pi,theta)));
        //$display("i went here");
        end
    if(theta > pi && theta <= pi_2)begin //last 2 quadrants ///ERROR HERE
        //sine function for pi to 2pi: y = -16(x-2pi)(pi-x) / (5pi^2 - 4(x-2pi)(pi-x))
        var = times(times(neg(const16), minus(theta,pi_2)),minus(pi,theta));
        //$display("var part 1 = %c%d.%d", symbol[var[31]],var[30:23],var[22:0]);
        var = divide(var,minus(times(times(pi,pi),const5),times(times(const4,minus(theta,pi_2)),minus(pi,theta))));
        //$display("var part 2 = %c%d.%d", symbol[var[31]],var[30:23],var[22:0]);
        end
    sin = var;
    //$display("pi = %c%d.%d", symbol[pi[31]],pi[30:23],pi[22:0]);
    //$display("theta = %c%d.%d", symbol[theta[31]],theta[30:23],theta[22:0]);
    //$display("sin(theta) = %c%d.%d", symbol[sin[31]],sin[30:23],sin[22:0]);
    end
endfunction
//==========================================================================//
function [31:0] cos;
//https://en.wikipedia.org/wiki/Bh%C4%81skara_I%27s_sine_approximation_formula
    input [31:0]theta;
    reg [31:0] var, store;
    reg [8:0] symbol [1:0];
    begin
    symbol[1] = "-";
    symbol[0] = "+";
    //cos(x) = sin(x - pi/2)
    cos = sin(minus(divide(pi,const2),theta));
    //$display("pi = %c%d.%d", symbol[pi[31]],pi[30:23],pi[22:0]);
    //$display("theta = %c%d.%d", symbol[theta[31]],theta[30:23],theta[22:0]);
    //$display("cos(theta) = %c%d.%d", symbol[cos[31]],cos[30:23],cos[22:0]);
    end
endfunction
//==========================================================================//
endmodule