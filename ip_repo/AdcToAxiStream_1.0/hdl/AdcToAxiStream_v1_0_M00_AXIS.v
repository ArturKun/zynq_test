
`timescale 1 ns / 1 ps

	module AdcToAxiStream_v1_0_M00_AXIS #
	(
		// Users to add parameters here
		parameter integer BIT_NUM_DEPTH_OF_RECEIVER_DATA_FIFO = 18,
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here
		input StartAxiStream_i,
		input [15:0] AdcData16_i,
		input FifoEmpty_i,
		input [BIT_NUM_DEPTH_OF_RECEIVER_DATA_FIFO-1:0] NumberOfOutputWords_i,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global ports
		input wire  M_AXIS_ACLK,
		// 
		input wire  M_AXIS_ARESETN,
		// Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		output wire  M_AXIS_TVALID,
		// TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
		// TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,
		// TLAST indicates the boundary of a packet.
		output wire  M_AXIS_TLAST,
		// TREADY indicates that the slave can accept a transfer in the current cycle.
		input wire  M_AXIS_TREADY
	);                                        
	                                                                                     
	// Define the states of state machine                                                
	// The control state machine oversees the writing of input streaming data to the FIFO,
	// and outputs the streaming data from the FIFO                                      
	parameter [1:0] IDLE = 2'b00,        // This is the initial/idle state               
	                                                                                         
	                SEND_STREAM   = 2'b01; // In this state the                          
	                                     // stream data is output through M_AXIS_TDATA   
	// State variable                                                                    
	reg [1:0] mst_exec_state;                                                            
	// Example design FIFO read pointer                                                  
	reg [BIT_NUM_DEPTH_OF_RECEIVER_DATA_FIFO-1:0] read_pointer;                                                   

	// AXI Stream internal signals
	//streaming data valid
	wire  	axis_tvalid;
	//streaming data valid delayed by one clock cycle
	reg  	axis_tvalid_delay;
	//Last of the streaming data 
	wire  	axis_tlast;
	//Last of the streaming data delayed by one clock cycle
	reg  	axis_tlast_delay;
	//FIFO implementation signals
	reg [C_M_AXIS_TDATA_WIDTH-1 : 0] 	stream_data_out;
	wire  	tx_en;
	//The master has issued all the streaming data stored in FIFO
	reg  	tx_done;
	
	// Вспомогательный флаг фиксации состояния передачи
	reg startStreamFlag;
	// Регистр выходных данных
	reg [C_M_AXIS_TDATA_WIDTH-1:0] dataOutReg;

	// I/O Connections assignments

	assign M_AXIS_TVALID	= axis_tvalid_delay;
	assign M_AXIS_TDATA	= stream_data_out;

	assign M_AXIS_TLAST	= axis_tlast_delay;

	assign M_AXIS_TSTRB	= {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};


		// Control state machine implementation                             
	always @(posedge M_AXIS_ACLK)                                             
	begin                                                                     
	  if (!M_AXIS_ARESETN)                                                    
	  // Synchronous reset (active low)                                       
	    begin                                                                 
	      mst_exec_state <= IDLE;                                             
	      startStreamFlag <= 0;                                                  
	    end                                                                   
	  else                                                                    
	    case (mst_exec_state)                                                 
	      IDLE:                                                               
	        // The slave starts accepting tdata when                          
	        // there tvalid is asserted to mark the                           
	        // presence of valid streaming data                                   
			if (StartAxiStream_i == 0) begin
				startStreamFlag <= 1;
			end
			else if (StartAxiStream_i == 1 && startStreamFlag == 1) begin
				startStreamFlag <= 0;
				mst_exec_state  <= SEND_STREAM;
			end
			else begin
				mst_exec_state  <= IDLE;
			end                                                           
	                                                                          
	      SEND_STREAM:                                                        
	        // The example design streaming master functionality starts       
	        // when the master drives output tdata from the FIFO and the slave
	        // has finished storing the S_AXIS_TDATA                          
	        if (tx_done)                                                      
	          begin                                                           
	            mst_exec_state <= IDLE;                                       
	          end                                                             
	        else                                                              
	          begin                                                           
	            mst_exec_state <= SEND_STREAM;                                
	          end                                                             
	    endcase                                                               
	end                                                                       

	//tvalid generation
	//axis_tvalid is asserted when the control state machine's state is SEND_STREAM and
	//number of output streaming data is less than the NumberOfOutputWords_i.
	assign axis_tvalid = ((mst_exec_state == SEND_STREAM) && (read_pointer < NumberOfOutputWords_i) && (!FifoEmpty_i) );
	                                                                                               
	// AXI tlast generation                                                                        
	// axis_tlast is asserted number of output streaming data is NumberOfOutputWords_i-1          
	// (0 to NumberOfOutputWords_i-1)                                                             
	assign axis_tlast = ( (read_pointer == NumberOfOutputWords_i-1) && (!FifoEmpty_i) );                                
	                                                                                               
	                                                                                               
	// Delay the axis_tvalid and axis_tlast signal by one clock cycle                              
	// to match the latency of M_AXIS_TDATA 
	always @(posedge M_AXIS_ACLK)                                                                  
	begin                                                                                          
	  if (!M_AXIS_ARESETN)                                                                         
	    begin                                                                                      
			axis_tvalid_delay <= 1'b0;                                                               
			axis_tlast_delay <= 1'b0;                                                              
	    end                                                                                        
	  else                                                                                         
	    begin
	    	axis_tvalid_delay <= axis_tvalid;                                                        
			axis_tlast_delay <= axis_tlast;
	    end                                                                                        
	end                                                                                            
	
	//read_pointer pointer
reg read_pointer_clear;
	always@(posedge M_AXIS_ACLK)                                               
	begin                                                                            
	  if(!M_AXIS_ARESETN)                                                            
	    begin                                                                        
	      read_pointer <= 1'b0;                                                         
	      tx_done <= 1'b0;    
	      dataOutReg <= 32'b0;  

	      read_pointer_clear <= 1'b0;                                                     
	    end                                                                          
	  else                                                                           
	    if (read_pointer <= NumberOfOutputWords_i-1)                                
	      begin                                                                      
	        if (tx_en)                                                               
	          // read pointer is incremented after every read from the FIFO          
	          // when FIFO read signal is enabled.                                   
	          begin                                                                  
	            read_pointer <= read_pointer + 1;  
	            dataOutReg <= dataOutReg + 1;                                  
	            tx_done <= 1'b0;                                                     
	          end                                                                    
	      end                                                                        
	    else if (read_pointer == NumberOfOutputWords_i)                             
	      begin                                                                      
	        // tx_done is asserted when NumberOfOutputWords_i numbers of streaming data
	        // has been out.                                                         
	        tx_done <= 1'b1;  
	        read_pointer_clear <= 1;
                                       
	      end  

	    if (read_pointer_clear == 1) begin
	    	read_pointer_clear <= 0;
	    	read_pointer <= 0;
	    	tx_done <= 0;
	    end                                                                        
	end                                                                              


	//FIFO read enable generation 

	assign tx_en = M_AXIS_TREADY && axis_tvalid;   
	                                                     
	    // Streaming output data is read from FIFO       
	    always @( posedge M_AXIS_ACLK )                  
	    begin                                            
	      if(!M_AXIS_ARESETN)                            
	        begin                                        
	          stream_data_out <= 0;                      
	        end                                          
	      else if (tx_en)// && M_AXIS_TSTRB[byte_index]  
	        begin                                        
	          stream_data_out <= {16'b0, AdcData16_i};   
	        end                                          
	    end                                              

	// Add user logic here

	// User logic ends

	endmodule
