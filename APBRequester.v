module APBRequester #(parameter DataWidth = 32, AddrWidth = 32, Slaves = 4)
(PCLK,reset,Start,RD,WR,Addr,Sel,SendData,Strb,PREADY,PRDATA,PSELx,PENABLE,PWRITE,
PADDR,PWDATA,PSTRB,DataReceived,Busy);

    localparam StrbWidth = DataWidth/8;
    localparam DecoSlaves = (Slaves>1) ? $clog2(Slaves) : 1;


    input PCLK,reset,Start,RD,WR,PREADY;
    input [AddrWidth-1:0] Addr;
    input [DataWidth-1:0] SendData,PRDATA;
    input [StrbWidth-1:0] Strb;
    input [DecoSlaves-1:0] Sel;
    output reg[Slaves-1:0] PSELx;
    output reg PENABLE,PWRITE,Busy;
    output reg [AddrWidth-1:0] PADDR;
    output reg [DataWidth-1:0] PWDATA,DataReceived;
    output reg [StrbWidth-1:0] PSTRB;

    /////FSM Logic

    reg EnPRDataReg,EnPSELxDeco,EnPStrb,EnPWData,EnPADDR;
    localparam Idle = 3'b000,
                RSetUp = 3'b001,
                RAccess = 3'b010,
                WSetUp = 3'b011,
                WAccess = 3'b100;

    reg [2:0] CS,NS;
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
                if(Start && RD)
                    NS = RSetUp;
                else if(Start && WR)
                    NS = WSetUp;
                else
                    NS = Idle;
            end
            RSetUp:
                NS = RAccess;
            RAccess:
            begin
                if(PREADY)
                    NS = Idle;
                else
                    NS = RAccess;
            end
            WSetUp:
                NS = WAccess;
            WAccess:
            begin
                if(PREADY)
                    NS = Idle;
                else
                    NS = WAccess;
            end
            default:
                NS = Idle;
        endcase
    end

    always@(*)
    begin
        case(CS)
            Idle:
            begin
                EnPADDR = (Start) ? 1'b1 : 1'b0;
                EnPWData = (Start && WR) ? 1'b1 : 1'b0;
                EnPStrb = (Start && WR) ? 1'b1 : 1'b0;
                PENABLE = 1'b0;
                PWRITE = 1'b0;
                EnPSELxDeco = 1'b0;
                EnPRDataReg = 1'b0;
                Busy = 1'b0;
            end
            RSetUp:
            begin
                EnPADDR = 1'b1;
                EnPWData = 1'b0;
                EnPStrb = 1'b0;
                PENABLE = 1'b0;
                PWRITE = 1'b0;
                EnPSELxDeco = 1'b1;
                EnPRDataReg = 1'b0;
                Busy = 1'b1;
            end
            RAccess:
            begin
                EnPADDR = 1'b1;
                EnPWData = 1'b0;
                EnPStrb = 1'b0;
                PENABLE = 1'b1;
                PWRITE = 1'b0;
                EnPSELxDeco = 1'b1;
                EnPRDataReg = (PREADY) ? 1'b1 : 1'b0;
                Busy = 1'b1;
            end
            WSetUp:
            begin
                EnPADDR = 1'b1;
                EnPWData = 1'b1;
                EnPStrb = 1'b1;
                PENABLE = 1'b0;
                PWRITE = 1'b1;
                EnPSELxDeco = 1'b1;
                EnPRDataReg = 1'b0;
                Busy = 1'b1;
            end
            WAccess:
            begin
                EnPADDR = 1'b1;
                EnPWData = 1'b1;
                EnPStrb = 1'b1;
                PENABLE = 1'b1;
                PWRITE = 1'b1;
                EnPSELxDeco = 1'b1;
                EnPRDataReg = 1'b0;
                Busy = 1'b1;
            end
            default:
            begin
                EnPADDR = 1'b0;
                EnPWData = 1'b0;
                EnPStrb = 1'b0;
                PENABLE = 1'b0;
                PWRITE = 1'b0;
                EnPSELxDeco = 1'b0;
                EnPRDataReg = 1'b0;
                Busy = 1'b0;
            end
        endcase
    end

    /////

    integer i;
    always@(*)      //Generic Demuxer 
    begin
        for(i=0; i<Slaves; i=i+1)
            PSELx[i] = ((i==Sel)&&(EnPSELxDeco)) ? 1'b1 : 1'b0;
    end

    always@(posedge PCLK) //Regs
    begin
        PADDR <= (EnPADDR) ? Addr : PADDR;
        PWDATA <= (EnPWData) ? SendData : PWDATA;
        PSTRB <= (EnPStrb) ? Strb : 0;
        DataReceived <= (EnPRDataReg) ? PRDATA : DataReceived;
    end

endmodule