module i2c_test;

	// Inputs
	reg clk;
	reg reset;
	reg [6:0] addr;
	reg [7:0] data;

	// Outputs
	wire i2c_sda;
	wire i2c_scl;
	wire [7:0] state;

	// Instantiate the Unit Under Test (UUT)
	i2c uut (
		.clk(clk), 
		.reset(reset), 
		.addr(addr), 
		.data(data), 
		.i2c_sda(i2c_sda), 
		.i2c_scl(i2c_scl), 
		.state(state)
	);
	initial begin
		// Initialize Inputs
		clk = 0;
		forever begin
		clk = #1 ~clk;
		end
		end
	

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		addr = 1111111;
		data = 11111111;
		#100;

		// Wait 100 ns for global reset to finish
		reset = 0; 
		addr = 0001010;
		data = 00010100;
		#100;$finish;
        
		// Add stimulus here

	end
      
endmodule

