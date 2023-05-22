module i2c (
  input        clk,
  input        reset,
  input  [6:0] addr,
  input  [7:0] data,
  output reg   i2c_sda,
  output wire  i2c_scl,
  output reg   [7:0] state
);

  localparam STATE_IDLE   = 0; // Different states
  localparam STATE_START  = 1; 
  localparam STATE_ADDR   = 2;
  localparam STATE_RW     = 3;
  localparam STATE_WACK   = 4; 
  localparam STATE_DATA   = 5;
  localparam STATE_WACK2  = 6;
  localparam STATE_STOP   = 7;  

  reg  [31:0]  count;          // Counter to keep track of the number of clock pulses
  wire         clk_div;        // Clock divider for I2C clock generation
  reg          i2c_scl_enable; // Flag to control SCL generation only when needed
  reg  [7:0]   slave_addr;     // Selected slave address
  
  assign i2c_scl = (i2c_scl_enable == 0) ? 1 : ~clk; // If i2c_scl_enable is 0, SCL is kept high, else SCL is toggled

  initial begin
    count[3:0]        = 4'b0000;
    i2c_sda           = 1'b0;
    state[2:0]        = 3'b000;
    count[3:0]        = 4'b0110; // I2C master is planning to transmit 6 bits of data on the bus.
    i2c_sda           = 1'b1;
    state[2:0]        = 3'b111;
  end

  always @(negedge clk) begin
    if (reset == 1) begin
      i2c_scl_enable <= 1;
    end
    else begin
      if (state == STATE_IDLE || state == STATE_START || state == STATE_STOP) begin     
        i2c_scl_enable <= 0;
      end
      else begin
        i2c_scl_enable <= 1;
      end
    end
  end

  always @(posedge clk) begin
    if (reset == 1) begin
      state      <= 3'b0;
      i2c_sda    <= 1;
      count      <= 4'b0;
    end
    else begin
      case(state)
        STATE_IDLE: begin // Idle
          i2c_sda <= 0;
          state   <= STATE_START;
        end
        
        STATE_START: begin // Start
          i2c_sda <= 1;
          state   <= STATE_ADDR;
          count   <= 6;
          slave_addr <= addr; // Set the selected slave address
        end
        
        STATE_ADDR: begin // Address
          i2c_sda <= slave_addr[count];
          if (count == 0)
            state <= STATE_RW;
          else
            count <= count - 1;
        end
        
        STATE_RW: begin // Read/Write
          i2c_sda <= 1; // Set the R/W bit to 1 for read operation, or 0 for write operation
          state   <= STATE_WACK;
        end
        
        STATE_WACK: begin // Wait for Acknowledgment
          state   <= STATE_DATA;
          count   <= 7;
        end
        
        STATE_DATA: begin // Data
          i2c_sda <= data[count];
          if (count == 0)
            state <= STATE_WACK2;
          else
            count <= count - 1;
        end
        
        STATE_WACK2: begin // Wait for Acknowledgment
          state <= STATE_STOP;
        end
        
        STATE_STOP: begin // Stop
          i2c_sda <= 1;
          state   <= STATE_IDLE;
        end
      endcase
    end
  end
endmodule
