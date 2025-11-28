module APBRequester_TB();

    parameter AddrWidth = 32,
              DataWidth = 32,
              Slaves = 4,
              StrbWidth = DataWidth/8,
              DecoSlaves = (Slaves>1) ? $clog2(Slaves) : 1;
              
    reg PCLK,reset,Start,RD,WR,PREADY;
    reg [AddrWidth-1:0] Addr;
    reg [DataWidth-1:0] SendData,PRDATA;
    reg [StrbWidth-1:0] Strb;
    reg [DecoSlaves-1:0] Sel;
    wire [Slaves-1:0] PSELx;
    wire PENABLE,PWRITE,Busy;
    wire [AddrWidth-1:0] PADDR;
    wire [DataWidth-1:0] PWDATA,DataReceived;
    wire [StrbWidth-1:0] PSTRB;

    APBRequester #(DataWidth, AddrWidth, Slaves) DUT
    (PCLK,reset,Start,RD,WR,Addr,Sel,SendData,Strb,PREADY,PRDATA,PSELx,PENABLE,PWRITE,
    PADDR,PWDATA,PSTRB,DataReceived,Busy);

    initial
    begin
        PCLK=0;
        forever #5 PCLK = ~PCLK;
    end

    integer i=0;
    initial
    begin
        #0; reset=1; Strb=0; RD=0; WR=0; Start=0;
            Addr=0; Sel=0; SendData=0; Strb=0; PREADY=0; PRDATA=0;

        #10; reset=0;

        for(i=0; i<10; i=i+1)
        begin
            #10; Start=1; RD=1; WR=0; 
                Addr=i; Sel=1; Strb=4'b1111; PRDATA=1<<i;
            #10; Start=0;
            #20; PREADY=1;
            #10; PREADY=0;

            #10; Start=1; RD=0; WR=1; 
                Addr=i+10; Sel=2; SendData=(i+i); 
            #10; Start=0;
            #20; PREADY=1;
            #10; PREADY=0;
        end 
    end

endmodule
