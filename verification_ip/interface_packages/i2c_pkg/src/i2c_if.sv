interface i2c_if #(int I2C_DATA_WIDTH = 8, int I2C_ADDR_WIDTH = 7) (input logic scl, inout triand sda);

	typedef bit i2c_opt_t;
	bit[I2C_ADDR_WIDTH-1:0] address;
	i2c_opt_t operation;
	bit[I2C_DATA_WIDTH-1:0] data_t[], data_tw[];
	bit start_bit, stop_bit;
	event start_signal, stop_signal;
	event print;	
	bit sda_output, release_or_not=1'b0;
	

always @ (negedge sda)
begin
	if(scl==1)
	begin
		start_bit <= 1'b1;
		-> start_signal;
	end
	else
		start_bit <= 1'b0; 
end 

always @ (posedge sda)
begin
	if(scl==1)
	begin
		stop_bit <= 1'b1;
		->stop_signal; 
	end
	else 
		stop_bit <= 1'b0;
end

// Assignment Statement for sda using continuous statement 

assign sda = release_or_not?sda_output:1'bz;

task wait_for_i2c_transfer(output i2c_opt_t op, output bit[I2C_DATA_WIDTH-1:0] write_data[]);

	// Write is 0 and Read is 1 
	bit[I2C_DATA_WIDTH-1:0] data;
	automatic int index = I2C_ADDR_WIDTH-1;
	automatic int size_array;
	
	op =1'b0;

	@(start_signal);

	//@(posedge scl);
	//data[I2C_ADDR_WIDTH] = sda;
	do
	begin 
		//data_t.delete();
		->print;
		index = 7;
		repeat (8) @ (posedge scl)               // 1 for write or read 
		begin
			data[index] = sda;
			index --;
		end
	
		address = data[I2C_ADDR_WIDTH:1];
		//$display("Address and WR %d",data);
		// Send ACK here 
 		@ (posedge scl);
		release_or_not = 1'b1;
		sda_output = 1'b0; 

		wait(scl==1'b0);
		operation = data[0];
		op = data[0];
		release_or_not = 1'b0;
		if(data[0]==1)
			return;

		@(posedge scl);
		data[I2C_DATA_WIDTH-1] = sda;

		while(1)
		begin 
			index = I2C_DATA_WIDTH-2;
                	repeat (I2C_DATA_WIDTH-1) @ (posedge scl)
			begin 
				data[index] =sda;
				index --;
			end
			size_array = write_data.size();
			write_data = new[size_array+1] (write_data);
			write_data[size_array] = data;
		
			//
			size_array = data_t.size();
			data_t = new [size_array+1] (data_t);
			data_t[size_array]=data;
			//$display("%d",data_t[size_array]);
			// SEND ACK HERE
			@ (posedge scl); 
			release_or_not = 1'b1;
			sda_output = 1'b0; 
			
			@(negedge scl);
			release_or_not = 1'b0;
			
			@(posedge scl);
			data[I2C_DATA_WIDTH-1] = sda;
			@(start_signal or stop_signal or negedge scl);
			//$display("Start Bit %d Stop Bit %d",start_bit, stop_bit);
			if(start_bit || stop_bit)
				break;
		
		end

		if(stop_bit)
		begin 
			return;
			->print;  
		end
	end while(1);	
endtask

task provide_read_data(input bit[I2C_DATA_WIDTH-1:0]read_data[], output bit transfer_complete);
	
	bit [I2C_DATA_WIDTH-1:0] data;
	data_t = new[data_t.size()+1] (data_t);
	data_t[data_t.size()-1] = read_data[0];	
	data = read_data[0];
	
	//$display("Here");	
	wait(scl);
	release_or_not = 1'b1;
	sda_output = data[7];
	//$display("Here again");
	@(posedge scl);
	sda_output = data[6];
	@(posedge scl);
	sda_output = data[5];
	@(posedge scl);
	sda_output = data[4];
	@(posedge scl);
	sda_output = data[3];
	@(posedge scl);
	sda_output = data[2];
	@(posedge scl);
	sda_output = data[1];
	@(posedge scl);
	sda_output = data[0];

	@(negedge scl);
	release_or_not = 1'b0;

	@(posedge scl);
	if(sda == 1'b0)
		transfer_complete = 1'b0;
	else 
	begin 
		transfer_complete = 1'b1;
		->print;
	end 
	@(negedge scl);

endtask


task monitor(output bit[I2C_ADDR_WIDTH-1:0] addr, output i2c_opt_t op, output bit[I2C_DATA_WIDTH-1:0] data[]);

	// Need to rework monitor here
	bit opt;
	@(print);
	opt = operation; 
	addr =address;
	op = operation;
	data = new[data_t.size()] (data_t);
	data_t.delete();	 
endtask

endinterface

