`timescale 1ns / 10ps

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_SLAVES = 1;
parameter int I2C_DATA_WIDTH = 8;
parameter int I2C_ADDR_WIDTH = 7;

bit  clk;
bit  rst = 1'b0;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_SLAVES-1:0] scl;
tri  [NUM_I2C_SLAVES-1:0] sda;

// ****************************************************************************
// Clock generator

initial
begin
	
	clk = 1'b0; 
	forever #5 clk = ~clk;
end


// ****************************************************************************
// Reset generator

initial 
	begin
		#20 rst = 1'b1;
		#113 rst = 1'b0;
	end


// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript

//initial 
//begin

//	bit [WB_ADDR_WIDTH-1:0] address;
//	bit [WB_DATA_WIDTH-1:0] data;
//	bit write_enable;
//	forever begin
//	wb_bus.master_monitor(address,data,write_enable);
//	$display("Address : %h Data: %h WE: %b",address,data,write_enable);
//	end
//end

// ***************************************************************************
// Monitor i2c bus and display transfer in the transcript

initial 
begin
	bit [I2C_ADDR_WIDTH-1:0] address;
	bit [I2C_DATA_WIDTH-1:0] data[];
	bit operation;
	forever 
	begin
		i2c_bus.monitor(address,operation,data);
		if(data.size())
		begin 
			if(operation == 1'b1)
				$display("I2C_BUS READ Transfer:");
			else 
				$display("I2C_BUS WRITE Transfer:");
			for(int i=0;i<data.size();i++)
				$display(data[i]);
		end
	end
end

// ****************************************************************************
// Define the flow of the simulation
initial
begin
	bit [WB_ADDR_WIDTH-1:0] address;
	bit [WB_DATA_WIDTH-1:0] data;
	bit waiting_bit;
	byte unsigned value;


	#150 address = 8'h00;
	data = 8'hC0;
	wb_bus.master_write(address,data);

	// Now write 0x05 to the DPR
	address = 8'h01;
	data = 8'h00;
	wb_bus.master_write(address,data);
	
	// Write byte xxxxx110 to CMDR
	address = 8'h02;
	data = 8'b110;
	wb_bus.master_write(address,data);

	// Wait for interrupt or until DON bit of CMDR reads '1' ;
	
	@(posedge irq);
	wb_bus.master_read(address,data);
	
	// step 4
		
	address = 8'h02;
	data = 8'b100;
	wb_bus.master_write(address,data);
	
	// Step 5
			
	@(posedge irq);
	address = 8'h02;
	wb_bus.master_read(address,data);

	// Step 6

	address = 8'h01;
	data = 8'h44;
	wb_bus.master_write(address,data);
	
	//Step 7 

	address = 8'h02;
	data = 8'h01;
	wb_bus.master_write(address,data);
	
	// Step 8 
	wait(irq==1);
	wb_bus.master_read(address,data);

	
	value = 8'h0;
	repeat (32)
	begin
	
		address = 8'h01;
		data = value;
 		value = value + 1;
		wb_bus.master_write(address,data);
			
		address = 8'h02;
		data = 8'b0000_0001;
		wb_bus.master_write(address,data);
		
		wait(irq==1);
		wb_bus.master_read(address,data);
	
	end
	
	// Start 
	//$display("Reading 32 Bytes");	
	address = 8'h02;
	data = 8'b100;
	wb_bus.master_write(address,data);
	
	@(posedge irq);
	wb_bus.master_read(address,data);
	
	// Address and IRQ 
	
	address = 8'h01;
	data = 8'h45;
	wb_bus.master_write(address,data);
	
	address = 8'h02;
	data = 8'b001;
	wb_bus.master_write(address,data);
	
	wait(irq==1);
	wb_bus.master_read(address,data);

	// Loop for the data 
	address = 8'h02;
	data = 8'b010;
	
	repeat(31)
	begin
		address = 8'h02;
		data = 8'b010;
		//$display("Read here");
		wb_bus.master_write(address,data);

		wait(irq==1);
		wb_bus.master_read(address,data);

		wb_bus.master_read(8'h01,data);
		//$display("%d Data",data);
	end
	
	data = 8'b011;	
	wb_bus.master_write(address,data);
	
	wait(irq==1);
	wb_bus.master_read(address,data);
	wb_bus.master_read(8'h01,data);
	//$display("%d DATA",data);
	
	// Alternate between write and reads 
	
	value = 64;
	repeat(64)
	begin
		address = 8'h02;
		data = 8'b100;
		wb_bus.master_write(address,data);
	
		wait(irq==1);
		wb_bus.master_read(address,data);

		address = 8'h01;
		data = 8'h44;
		wb_bus.master_write(address,data);

		address = 8'h02;
		data = 8'b001;
		wb_bus.master_write(address,data);
	
		wait(irq==1);
		wb_bus.master_read(address,data);
		 
		address = 8'h01;
		data = value;
		wb_bus.master_write(address,data);
		
		address = 8'h02;
		data = 8'b001;
		wb_bus.master_write(address,data);

		wait(irq==1);
		wb_bus.master_read(address,data);

		//Read Start

		address = 8'h02;
		data = 8'b100;
		wb_bus.master_write(address,data);
		
		wait(irq==1);
		wb_bus.master_read(address,data);

		address = 8'h01;
		data = 8'h45;
		wb_bus.master_write(address,data);
		
		address = 8'h02;
		data = 8'b001;
		wb_bus.master_write(address,data);

		wait(irq==1);
		wb_bus.master_read(address,data);
		
		address = 8'h02;
		data = 8'b011;
		wb_bus.master_write(address,data);
		
		wait(irq==1);
		wb_bus.master_read(address,data);
		
		wb_bus.master_read(8'h01,data);
		//$display("data : Read : %d",data);	
		//$display("Value: %d",value);

		value = value+1;
		
	end 
	
	//STOP Condition 

	address = 8'h02;
	data = 8'b101;
	wb_bus.master_write(address,data);
	
	wait(irq==1);
	wb_bus.master_read(address,data);;

			 
end

// ****************************************
// Initial block with i2c

initial 
begin 

	bit [I2C_ADDR_WIDTH-1:0] address;
	bit [I2C_DATA_WIDTH-1:0] data[];
	bit operation;
	byte unsigned value;
	while(1)
	begin
		i2c_bus.wait_for_i2c_transfer(operation,data);
		//$display("operation %d",operation);
		if(operation==1'b1)
			break;
	end
	
	data = new [1];
	
	data[0] = 100;
	
	while(1)
	begin 
		//$display("I2C Read");
		i2c_bus.provide_read_data(data,operation);
		//$display("Transfer Complete : %d",operation);
		if(operation == 1'b1)
			break;
		data[0] = data[0]+1;
	end 

	for(int j=0;j<64;j++)
	begin
		while(1)
		begin 
			i2c_bus.wait_for_i2c_transfer(operation,data);
			if(operation==1'b1)
				break;
		end
		data[0] = 63-j;
		//$display("DATA I2C TEST Bench: %d",data[0]);
		i2c_bus.provide_read_data(data,operation);	
	end
	
	

end 


// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );

i2c_if #(.I2C_ADDR_WIDTH(I2C_ADDR_WIDTH), .I2C_DATA_WIDTH(I2C_DATA_WIDTH)) i2c_bus (.scl(scl),.sda(sda));


// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_SLAVES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );


endmodule
