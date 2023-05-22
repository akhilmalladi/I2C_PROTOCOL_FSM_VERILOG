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

  // Clock generation
  always begin
    #5 clk = ~clk;
  end

  // Initialize Inputs
  initial begin
    clk   = 0;
    reset = 1;
    addr  = 7'b0000000; // Set the initial slave address
    data  = 8'b00000000; // Set the initial data
    #10;
    reset = 0;
    #10;

    // Test case 1: Write operation to slave 1
    addr = 7'b0010010; // Set slave 1 address
    data = 8'b10101010; // Set data to be written
    #100;

    // Test case 2: Write operation to slave 2
    addr = 7'b0101100; // Set slave 2 address
    data = 8'b01010101; // Set data to be written
    #100;

    // Test case 3: Read operation from slave 1
    addr = 7'b0010010; // Set slave 1 address
    data = 8'b00000000; // Clear data
    #100;

    // Test case 4: Read operation from slave 2
    addr = 7'b0101100; // Set slave 2 address
    data = 8'b00000000; // Clear data
    #100;

    // Finish simulation
    $finish;
  end

endmodule
