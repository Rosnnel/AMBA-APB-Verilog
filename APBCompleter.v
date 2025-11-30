module APBCompleter #(parameter DataWidth = 32, AddrWidth = 32)
(PCLK,reset,PSEL,PWRITE,PENABLE,RespReady,PSTRB,PWDATA,PADDR,PRDATA,PREADY,
Address,ReceivedData,ResponseData);

    localparam StrbWidth = DataWidth/8;

    input PCLK,reset,PSEL,PWRITE,PENABLE,RespReady;
    input [StrbWidth-1:0] PSTRB;
    input [DataWidth-1:0] PWDATA,PRDATA,ResponseData;
    input [AddrWidth-1:0] PADDR;
    output reg PREADY;
    output reg [AddrWidth-1:0] Address;
    output reg [DataWidth-1:0] ReceivedData;

    /////FSM Logic
    localparam Idle = 2'b00,
                RAccess = 2'b01,
                WAccess = 2'b10;

    reg [1:0] CS,NS;
    always@(posedge PCLK or posedge reset)
    begin
        if(reset)
            CS <= Idle;
        else
            CS <= NS;
    end

    always@(*)
    begin
        case(CS)
            Idle:
            begin
                if(PSEL && !PWRITE)
                    NS = RAccess;
                else if(PSEL && PWRITE)
                    NS = WAccess;
                else
                    NS = Idle;
            end
            RAccess:
            begin
                if(PENABLE && RespReady)
                    NS = Idle;
                else
                    NS = RAccess;
            end
            WAccess:
            begin
                if(PENABLE && RespReady)
                    NS = Idle;
                else
                    NS = WAccess;
            end
            default:
                NS = Idle;
        endcase
    end

    reg PRDATAReg, PWDATAReg, PADDRReg;
    always@(*)
    begin
        case(CS)
            Idle:
            begin
                PREADY = 1'b0;
                Busy = (PSEL) ? 1'b1 : 1'b0;
                PRDATAReg = (PSEL && !PWRITE) ? 1'b1 : 1'b0;
                PWDATAReg = (PSEL && PWRITE) ? 1'b1 : 1'b0;
                PADDRReg = (PSEL) ? 1'b1 : 1'b0;
            end
            RAccess:
            begin
                PREADY = (RespReady) ? 1'b1 : 1'b0;
                Busy = 1'b1;
                PRDATAReg = 1'b1;
                PWDATAReg = 1'b0;
                PADDRReg = 1'b1;
            end
            WAccess:
            begin
                PREADY = (RespReady) ? 1'b1 : 1'b0;
                Busy = 1'b1;
                PRDATAReg = 1'b0;
                PWDATAReg = 1'b1;
                PADDRReg = 1'b1;
            end
            default:
            begin
                PREADY = 1'b0;
                Busy = 1'b0;
                PRDATAReg = 1'b0;
                PWDATAReg = 1'b0;
                PADDRReg = 1'b0;
            end
        endcase
    end
    ////////

    always@(posedge PCLK)
    begin
        Address <= (PADDRReg) ? PADDR : Address;
        PRDATA <= (PRDATAReg) ? PRDATAReg : PRDATA;
    end

    integer i;
    always@(posedge PCLK)
    begin
        if(PWDATAReg)
        begin
            for(i=0; i<StrbWidth; i=i+1)
            begin
                if(PSTRB[i])
                    ReceivedData[i*8 +: 8] <= PWDATA[i*8 +: 8];
            end
        end
    end

    

endmodule