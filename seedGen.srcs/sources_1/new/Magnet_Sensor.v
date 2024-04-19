module magnet_sensor(input clk, input rst, inout i2c_sda, inout wire i2c_scl, input sensor_drdy, output reg [15:0] DXR, output reg [15:0] DZR, output reg [15:0] DYR);
     
    //I2C Variables
    reg enable;
    reg rw; //0 = write, 1 = read
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire i2c_ready;
    reg [7:0] reg_in;
    reg bool_init;
    wire [2:0] data_num;
    
    i2c_manager(clk, rst, i2c_sda, i2c_scl, enable, rw, data_in, data_out, i2c_ready, reg_in, bool_init, data_num);
    
    localparam [2:0]
    STATE_IDLE = 4'h0,
    STATE_INIT = 4'h1,
    STATE_CRA = 4'h2,
    STATE_CRB = 4'h3,
    STATE_SINGLE_QUERY = 4'h4,
    STATE_WAIT_DRDY = 4'h5,
    STATE_READ_DATA = 4'h6;
    
    reg [2:0] state_num = STATE_INIT;
    localparam INIT_DATA_LEN = 7;
    reg [8:0] init_data [INIT_DATA_LEN-1:0];
    localparam HMC5883L_ADDR = 7'h3C;
    
    localparam [7:0] CRA_VAL = 8'h10;  // Data: 0x10 0 00 100 00 - 1 sample at 15 Hz at normal configuration
    localparam [7:0] CRB_VAL = 8'h60;  // Data: 0x60 011 00000 Set gain to +-2.5
    localparam [7:0] MODE_VAL = 8'h01;  // Data: 0x01 means Single Mode
    localparam [7:0] READ_VAL = 8'h06; //Data: Read all 6 data points
    reg [23:0] ctr; //to output data every 1s
    
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state_num <= STATE_INIT;
            ctr <= 0;
        end
        else
        begin
            case (state_num)
                STATE_INIT:
                begin
                    enable <= 0;
                    bool_init <= 1;
                    //SETUP for CRA
                    reg_in <= 8'b0;
                    data_in <= CRA_VAL;
                    state_num <= STATE_CRA;
                    rw <= 0;
                end
                STATE_CRA:
                begin
                    enable <= 1;
                    //SETUP for CRB
                    reg_in <= 8'b1;
                    data_in <= CRB_VAL;
                    state_num <= STATE_CRB;
                end
                
                STATE_CRB:
                begin
                    state_num <= i2c_ready ? STATE_IDLE : STATE_CRB;
                end
                
                STATE_IDLE:
                begin
                    enable <= 0;
                    if(ctr >= 24'd12000000)
                    begin
                        //SETUP for STATE_SINGLE_QUERY
                        reg_in <= 8'b10;
                        data_in <= MODE_VAL;
                        bool_init <= 0;
                        state_num <= STATE_SINGLE_QUERY;
                        rw <= 0;
                    end
                    else ctr <= ctr + 1;
                end
                
                STATE_SINGLE_QUERY:
                begin
                    ctr <= 0;
                    enable <= 1;
                    data_in <= READ_VAL;
                    state_num <= i2c_ready ? STATE_WAIT_DRDY : STATE_SINGLE_QUERY;
                end
                
                STATE_WAIT_DRDY:
                begin
                    if (sensor_drdy)
                    begin
                        state_num <= STATE_READ_DATA;
                        enable<=1;
                        rw <= 1;
                    end
                    else begin
                        state_num <= STATE_WAIT_DRDY;
                        enable <= 0;
                    end
                end
                STATE_READ_DATA:
                begin
                    enable <= 1;
                    case(data_num)
                        3'd0: DXR[15:8] <= data_out;
                        3'd1: DXR[7:0] <= data_out;
                        3'd2: DZR[15:8] <= data_out;
                        3'd3: DZR[7:0] <= data_out;
                        3'd4: DYR[15:8] <= data_out;
                        3'd5: DYR[7:0] <= data_out;
                        default: state_num <= STATE_IDLE;
                    endcase
                end
                default:
                    state_num <= STATE_INIT;
            endcase
        end
    end    
endmodule