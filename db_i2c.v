module i2c(
	input  clk,
	input reset,
	input[6:0]addr,
	input[7:0] data,
	output reg i2c_sda,
	output wire i2c_scl,
	output reg [7:0]state 
    );

	localparam STATE_IDLE = 0;//different states
	localparam STATE_START = 1; 
	localparam STATE_ADDR = 2;
	localparam STATE_RW = 3;
	localparam STATE_WACK = 4; 
	localparam STATE_DATA = 5;
	localparam STATE_WACK2 = 6;
	localparam STATE_STOP = 7;  

	reg [31:0] count;//counter to keep track on noof clock pulses
	wire clk_div;//to divide the clk frequency
	reg i2c_scl_enable = 0;//flag to control SCl(scl generation only when needed)
	assign i2c_scl = (i2c_scl_enable == 0) ? 1 : ~clk;//if Flag control is 0 sdc is kept high else sdc is togggle
	
	initial begin
	count[3:0] =4'b0000;
	i2c_sda =1'b0;
	state[2:0] = 3'b000;
	count[3:0] =4'b0110;//I2C master is planning to transmit 6 bits of data on the bus.
	i2c_sda =1'b1;       /*In the initial block, the value of state is first set to 0 (3'b000),and then later set to 7 (3'b111). This suggests that the 
	                           I2C master is initializing the state machine
	                        to the idle state (STATE_IDLE), and then sending a start condition (STATE_START) followed by a 6-bit data transfer 
	                        (STATE_DATA) and a stop condition (STATE_STOP).*/
	state[2:0] = 3'b111;
	end
	
	always @(negedge clk)//This means that the I2C clock line (i2c_scl) is held high (i.e., logic 1) when the device is being reset.
	begin
	if (reset == 1)
	begin
	i2c_scl_enable <= 1;
	end
	
	else begin
	if((state == STATE_IDLE) || (state == STATE_START) || (state == STATE_STOP))
	begin     
	i2c_scl_enable <= 0;  /*If the state machine is in the STATE_IDLE, STATE_START, or STATE_STOP states, then i2c_scl_enable is set to 0 
	                      (i.e., the clock is not toggled). This is because the I2C protocol requires that the clock line remain high when the bus is idle, 
	                      during a start condition, and during a stop condition.Otherwise, if the state machine is in any other state,
	                       then i2c_scl_enable is set to 1 (i.e., the clock is toggled). This is because the clock line must be toggled during data
	                        transfer operations.*/
	end
	else begin
	i2c_scl_enable <= 1;
	end
	end
	end
	
	always@(posedge clk)/*this code initializes the I2C module to a known state whenever the system is reset.*/
	begin
	if (reset==1)
	begin
	state<= 3'b0;
	i2c_sda <= 1;
	count <= 4'b0;
	end
	
	else begin
	case(state)
	
	STATE_IDLE: begin //idle
	i2c_sda <= 0;   /*the I2C bus is currently idle, waiting for a start condition to initiate communication. The i2c_sda signal is set to 0 to 
	                   initiate the start condition, and the state variable is updated to STATE_START to indicate that the start condition has been sent.*/
	state <= STATE_START;
	end
	
	/*These lines of code represent the "Start" state in the I2C communication protocol. In this state, the master device sends a start signal
	   to the slave device to initiate communication.The line i2c_sda <= 1; sets the data line (SDA) to logic high (1), while the line 
	   state <= STATE_ADDR; sets the state to the "Address" state, indicating that the master device is now ready to send the slave device's 
	   address. The line count <= 6; sets the counter to 6, indicating that the next 7 bits sent on the data line will be the 7-bit address of the slave device.*/
	STATE_START: begin //start
	i2c_sda <= 1;
	state <= STATE_ADDR;//address byte is transmitted with MSB first
	count <= 6;   
	//addr <= 7'b0110010;
	end
	
	
	/*In the I2C protocol, this block of code is responsible for sending the 7-bit slave address to the slave device. The slave address 
	is sent bit-by-bit, starting from the most significant bit (MSB) to the least significant bit (LSB). The current bit is sent on the i2c_sda line, 
	and the count variable is used to keep track of the current bit being sent. If all bits of the address have been sent, the state machine moves to 
	the STATE_RW state, otherwise count is decremented to send the next bit on the next clock cycle.*/
	STATE_ADDR: begin 
	i2c_sda <= addr[count];
	if (count == 0) state <= STATE_RW;
	else count <= count - 1;
	end
	
	/*In the STATE_RW state, the SDA line is set to high (1) to indicate that the master wants to read 
	data from the slave device. Then, the state is changed to STATE_WACK, indicating that the master is waiting for the slave's acknowledgment.*/
	STATE_RW: begin
	i2c_sda <= 1;
	state <= STATE_WACK;//rw bit specify whether the next byte is read or write
	end
	
	
	/*In the STATE_WACK state, the state variable is updated to STATE_DATA, indicating that the next state is to send data.
	 The count variable is also set to 7 to indicate that 7 bits of data will be transmitted in the next state.*/
	STATE_WACK: begin
	state <= STATE_DATA;//data byte is transmitted with LSB first
	count <=7;
	//data <= 8'b00001010;
	end
	
	/*In this state, the i2c_sda signal is set to the value of data[count], which represents the data bit currently being transmitted.
	 The count value is decremented until it reaches 0, indicating that all 8 bits of data have been transmitted, at which point the state 
	 is changed to STATE_WACK2.*/
	STATE_DATA: begin
	i2c_sda <= data[count];
	if (count == 0) state <= STATE_WACK2;//wait for acknowledgement for the data trasnfer
	else count <= count - 1;
	end
	
	
	/*In this state, the state machine waits for the acknowledge signal from the slave device indicating that it has received the data byte. 
	Once the acknowledge is received, the state machine moves to the STOP state to end the transmission.*/
	STATE_WACK2: begin
	state <= STATE_STOP;
	end
	
	STATE_STOP: begin
	i2c_sda <= 1;
	state <= STATE_IDLE;//stopbit
	end
	endcase
	end
	end 
endmodule

