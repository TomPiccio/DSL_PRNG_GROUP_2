module i2c_manager(input clk, input rst, inout i2c_sda, inout wire i2c_scl, input enable, input rw, input [7:0] data_in, output reg [7:0] data_out, output wire ready, input [7:0] reg_in, input bool_init, output reg [2:0] data_num);
     
    localparam ADDR = 6'b011110; //ADDRESS: 011110X read: 0111101 or 0x3D, write 0111100 or 0x3C
    
    //States
    reg [3:0] state;
	localparam [3:0]
	IDLE = 4'h0,
	START = 4'h1,
	ADDRESS = 4'h2,
	READ_ACK = 4'h3,
	WRITE_DATA = 4'h4,
	WRITE_ACK = 4'h5,
	READ_DATA = 4'h6,
	READ_ACK2 = 4'h7,
	STOP = 4'h8,
	WRITE_REG = 4'h9,
	READ_ACK_INIT = 4'hA;
	
	localparam DIVIDE_BY = 120; //12MHz to 100kHz

	
	reg [7:0] saved_addr;
	reg [7:0] saved_data;
	reg [7:0] counter;
	reg [7:0] counter2 = 0;
	reg write_enable;
	reg sda_out;
	reg i2c_scl_enable = 0;
	reg i2c_clk = 1;

	assign ready = ((rst == 0) && (state == IDLE)) ? 1 : 0;
	assign i2c_scl = (i2c_scl_enable == 0 ) ? 1 : i2c_clk;
	assign i2c_sda = (write_enable == 1) ? sda_out : 'bz;
	
	//I2C 100Hz clock
	always @(posedge clk) begin
		if (counter2 == (DIVIDE_BY/2) - 1) begin
			i2c_clk <= ~i2c_clk;
			counter2 <= 0;
		end
		else counter2 <= counter2 + 1;
	end 
	
	//I2C SCL Output
	always @(negedge i2c_clk, posedge rst) begin
		if(rst == 1) begin
			i2c_scl_enable <= 0;
		end else begin
			if ((state == IDLE) || (state == START) || (state == STOP)) begin
				i2c_scl_enable <= 0;
			end else begin
				i2c_scl_enable <= 1;
			end
		end
	end

    //I2C States
	always @(posedge i2c_clk, posedge rst) begin
		if(rst == 1) begin
			state <= IDLE;
			counter <= 7;
			data_num <= 0;
			data_out <= 8'b0;
		end		
		else begin
			case(state)
			
				IDLE: begin
					if (enable) begin
						state <= START;
						saved_addr <= {ADDR, rw};
						saved_data <= data_in;
					end
					else state <= IDLE;
				end

				START: begin
					counter <= 7;
					state <= ADDRESS;
				end

				ADDRESS: begin
					if (counter == 0) begin 
						state <= READ_ACK;
						data_num <= 0;
					end else counter <= counter - 1;
				end

				READ_ACK: begin
					if (i2c_sda == 0) begin
						counter <= 7;
						state <= saved_addr[0] ? READ_DATA : bool_init ? WRITE_REG : WRITE_DATA;
					end else state <= STOP;
				end
				
				WRITE_REG: begin
					if(counter == 0) begin
						state <= READ_ACK_INIT;
					end else counter <= counter - 1;
				end
				
				READ_ACK_INIT: begin
					state <=  ((i2c_sda == 0) && (enable == 1))  ? WRITE_DATA : STOP;
				end

				WRITE_DATA: begin
					if(counter == 0) begin
						state <= READ_ACK2;
					end else counter <= counter - 1;
				end
				
				READ_ACK2: begin
					state <=  ((i2c_sda == 0) && (enable == 1))  ? IDLE : STOP;
				end

				READ_DATA: begin
					data_out[counter] <= i2c_sda;
					if (counter == 0) state <= WRITE_ACK;
					else counter <= counter - 1;
				end
				
				WRITE_ACK: begin
				    if(data_num < 3'd6) begin
                        state <= READ_DATA;
                        data_num <= data_num + 1;
                        counter <= 7;
				    end else state <= STOP;
				end

				STOP: begin
					state <= IDLE;
				end
			endcase
		end
	end
	
	//SDA
	always @(negedge i2c_clk, posedge rst) begin
		if(rst == 1) begin
			write_enable <= 1;
			sda_out <= 1;
		end else begin
			case(state)
				
				START: begin
					write_enable <= 1;
					sda_out <= 0;
				end
				
				ADDRESS: begin
					sda_out <= saved_addr[counter];
				end
				
				READ_ACK: begin
					write_enable <= 0;
				end
				
				READ_ACK2: begin
					write_enable <= 0;
				end
				
				READ_ACK_INIT: begin
					write_enable <= 0;
				end
				
				WRITE_DATA: begin 
					write_enable <= 1;
					sda_out <= saved_data[counter];
				end
				
				WRITE_REG: begin 
					write_enable <= 1;
					sda_out <= reg_in[counter];
				end
				
				WRITE_ACK: begin
					write_enable <= 1;
					sda_out <= 0;
				end
				
				READ_DATA: begin
					write_enable <= 0;				
				end
				
				STOP: begin
					write_enable <= 1;
					sda_out <= 1;
				end
			endcase
		end
	end

endmodule