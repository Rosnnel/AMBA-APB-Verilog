module APBCompleter_TB();

        parameter AddrWidth = 32,
              DataWidth = 32,
              Slaves = 4,
              StrbWidth = DataWidth/8;

    reg PCLK,reset,PSEL,PWRITE,PENABLE,RespReady;
    reg [StrbWidth-1:0] PSTRB;
    reg [DataWidth-1:0] PWDATA,ResponseData;
    reg [AddrWidth-1:0] PADDR;
    wire PREADY,Busy;
    wire [AddrWidth-1:0] Address;
    wire [DataWidth-1:0] ReceivedData,PRDATA;

    APBCompleter #(DataWidth, AddrWidth) DUT
    (PCLK,reset,PSEL,PWRITE,PENABLE,RespReady,PSTRB,PWDATA,PADDR,PRDATA,PREADY,
    Address,ReceivedData,ResponseData);

    initial
    begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end

    integer i;
    initial
    begin
        reset = 1; PSEL=0; PWRITE=0; PENABLE=0; RespReady=0; 
        PSTRB = 4'b1111; PWDATA = 32'b0; PADDR = 32'b0; ResponseData = 32'b0;
        #20;
        reset = 0;
        for(i=0;i<12;i=i+1)
        begin
            PSEL = 1; PWRITE = 0; PENABLE = 1; PSTRB=4'b1111;
            ResponseData = $random + i;
            PADDR =  i*i;
            #10;
            RespReady = 1;
            #10;
            RespReady = 0; PSEL = 0; PENABLE = 0;
            #100;
            PSEL = 1; PWRITE = 1; PENABLE = 1; PSTRB = ~i;
            PWDATA = $random + i;
            PADDR = i*i*i;
            #10;
            RespReady = 1;
            #10;
            RespReady = 0; PSEL = 0; PENABLE = 0;
            #100;
        end
    end

endmodule
