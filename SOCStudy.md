Study Journal of SOC design labs.
===
Lab 1:   
===
關於Linux檔案權限可以使用chmod指令來進行調整。  
parts: xc7z020clg400-1

整體流程:  
>1. 在Vitis建立專案，丟入C/C++檔案，建立directive，並開始sim和syn(或cosim驗證).  
>2. Export RTL，匯出到Vivado進行下一步  
>3. 在Vivado import在Vitis建立的IP  
>4. Create Block Design，並在diagram tab加入元件  
>5. 調整Configuration，建立Connection(可以善用自動化)  
>6. 在Sources視窗建立HDL Wrapper。
>7. 建立Bitstream*  
>8. 用MOBA租借FPGA版，把相關檔案(bit, hwh, python code)上傳後到Jupyter Notebook後，就可執行。
>
>*:在Linux下進行，Bitstream檔需在Vivado專案所在處找。  
>bit檔位於./xxx.runs/impl_1，  
>hwh檔位於./xxx.gen/sources_1/bd/yyy/hw_handoff。



Multiplication.h defines valuable: n32In1, n32In2m and pn32ResOut (pointer).  
Multiplication.cpp with the valuable pragmas, and has a line to assign the output: 

> *pn32ResOut = n32In1 * n32In2;

About the ap_ctrl_none:

>https://docs.xilinx.com/r/2022.1-English/ug1399-vitis-hls/Using-ap_ctrl_none-Inside-the-Dataflow

Note that when doing Cosim , the following error occurs: 

> ERROR: [COSIM 212-345] Cosim only supports the following 'ap_ctrl_none' designs: (1) combinational designs; (2) pipelined 
design with II of 1; (3) designs with array streaming or hls_stream or AXI4 stream ports.

We should be careful about the ap_ctrl setting before Cosim.

在觀察波型時，可以利用Go to source code，和Object視窗去尋找reg訊號，有些訊號可能沒有列在top design裡。

Lab 2  
===
parts: xc7z020clg400-1

整體流程:
>1. 建立專案，複製檔案到相對位置 → add new
source, testbench, top function (設定要與c code裡面一樣)→ directives → C simulation → C synthesis →
Export RTL
>2. 


FIR.cpp組成:  
fir_n11_maxi含有三個inputs, 一個output  
inputs:  
\*pn32HPInput: input data(此testbench為 從1到75，再下降到-75，再往上到75，每一步都差1。)  
an32Coef[MAP_ALIGN_4INT]: taps，為運算用參數  
regXferLeng: 輸入總bit數  
output:  
pn32HPOutput: 乘累加的最後結果  

此code運行是將輸入存入register，並用pipeline的方式對an32Coef進行乘法，最後進行累加，累加結果就是輸出。  
至於PYNQ的結果，則可以分析an32Coef的設計，可以注意到，an32Coef配上convultion的算法，可以發現這是一個延遲4個cycle，並且有個DC gain (約183) 的結果。這是因為input data是等差增加(到75)或減少(到-75)的，使乘累加的結果也是等差。  

STREAM區別:
由於加入了DMA的設計，input跟output是data一組一組的讀寫，因此需要增加了跟DMA的溝通command:  
> line 24 value_t valTemp = pstrmInput->read();  
> line 38 pstrmOutput->write(valTemp);  
> line 39 if (valTemp.last) break;  


DMA Block diagram: 要注意in要enable read channel, out要enable write channel.  

遇到問題: 
>1. 檔名不對: 請記得上傳所有需要用到的檔案，並確認python code的檔名。
>2. 路徑問題: 目錄用\\取代\，路徑才會正確，並可以用絕對路徑。
>3. fc和diff: fc是用於Windows上的指令，用來比對兩個檔案差異，diff則是用於Linux
//>4. FIRTester Co-sim出現error: 由於FIRTester.cpp 會建一個NUM_SAMPLES * sizeof(int32_t) 的valuable，但這個值太大，導致co-sim無法執行。以下是我解決方式:  
>(1) FIRTester.cpp line 39: NUM_SAMPLES * sizeof(int32_t) -> NUM_SAMPLES。   
>(2) FIR.cpp line 14: (regXferLeng + (sizeof(int32_t) - 1)) / sizeof(int32_t) -> regXferLeng + ((sizeof(int32_t) - 1) / sizeof(int32_t)) 確保(1)改掉參數後，功能上還是等價 -> 待確認
>5. 跑synthesis的時候，出現warning(The report is not created yet...): rpt檔開著，需要把視窗關掉。  

觀察
1. interface接口不太一樣  
2. 使用的資源(FF、LUT等)也有些許不同 



Lab 3:   
===
1. 在計算開始前，會收到由 host 提供的 data_length 和 tap coef 並伴隨著它們的地址。
awriting 在 0 時，awready 為 1，並在 awvalid 為 1 的同時收入 awaddr，收入後將
awriting 設為 1，awready 則變為 0，等待寫入完成後再將 awriting 設回 0。
writing 在 0 時， wready為 1，並在 wvalid 為 1 的同時收入 wdata，收入後將
writing 設為 1，wready 則變為 0，等待寫入完成後再將 writing 設回 0。在writing
&& awriting 時，則開始進行寫入，此時 tap_Di = wdata, tap_EN = 1, tap_WE =
4’b1111, tap_A = awaddr - 12’h20 (這是因為 tap coef 的 awaddr 從 0x20 開始，所以
直接用一個 offset 來將 awaddr 接到 tap_A)，data_length (0x10)則存在 datalength 的
registers。
2. 然後是 host 將存入的 tap coef 的 read back 處理。在 rr 為 0 時，arready = 1,
rvalid=0， 並在 arvalid 為 1 的同時收入 araddr。這個 araddr 會直接連到 tap_A (一
樣有 offset = -0x20)，此時 tap_EN = 1, tap_WE = 4’b0000，這樣 tap_RAM 就可以先
準備。下一個 clock 會將 rr 設為 1，此時 arready = 0, rvalid = 1，剛才的 araddr 對應
到此時的 tap_Do ，並會直接連到 rdata。rr 會在 rvalid && rready 後設 0，此時
arready = 1, rvalid = 0，準備收入下一個 araddr。
3. 再來是 program ap_start。ap_start 設成 1 之後的下個 clock，會開始初始化 (init =
1)、ap_idle 設為 0、ap_start 設回 0。初始化會將 data_RAM 內的所有資料清零
(data_A = from 0x00 to 0x28, data_Di = 32’b0, data_EN = 1, data_WE = 4’b1111)。初始
化結束後 init 設成 0，並拉高 ss_tready 開始收入資料進行計算。
4. s從 ss_tready 拉高的同時，會將收到的 ss_tdata 存入 data_RAM 裡面、將計算結果
(temp)清零，cnt <= cnt + 1並在下一個cycle 開始計算過程 ，sswait 此時也會設成 1 。
計算的方式如下 (假設本次 ss_tdata 收到的為 data20 並存在 data_RAM 的 0x28 裡)：
tap_A 從 0x00 累加到 0x28，data_A 則是從 0x28 累減到 0x00。每一次 cycle 計算
temp <= tap_Do * data_Do + temp。在 tap_A 數到 0x28 後就會暫停計算，並拉高
smset，smset 為 1 時，sm_tvalid = 1，而算完的 temp 則會有兩種情況 ：
1). result (output buffer) 為空或被讀取過：將此計算完的結果存入 result，並準
備開始下一次運算。
2). result 還存有上一次的計算結果，而且還沒被 sm 讀取過：將此次計算結果
暫存在 temp ，並拉高 backp，暫停 ss 的 input。等到讀取後再將 temp 內的結
果存入 result 裡。
5. ss_tready 再次拉高，tap_A 會回到 0x00，而 data_A 則是繼續停在上一組計算的最
後一個 address (因為那個 data 已經用不到了)，並將 ss 收進來的 data 存入該
address裡，然後再開始新一輪的計算 (0x00 進行累減的話會拉回 0x28)。
6. 直到 cnt == datalength，這時可以判定整個 FIR 計算進入尾聲，將 last 設成 1。
sm_tlast 則會與最後一個 FIR 的計算結果及 sm_tvalid 一起輸出 1，並代表計算結束。
sm_tlast && sm_tvalid && sm_tready後，ap_idle 和 ap_done 都會在下一個 cycle 設
回 1。此時 host 可以讀取 ap_done，也可以 program ap_start 進行下一組 FIR。
7. 在我的設計中，各個 read/write channel 基本上是能獨立運作的。但由於初始化
data_RAM (init = 1)時 和 FIR 計算中 (ap_idle = 0) 會對 BRAM 的 address 進行頻繁的
變換，為了避免資料汙染，在這兩個狀況下，針對 BRAM 的讀寫是 forbidden 的。
8. 在我的設計中，計算會在 ss_tdata 收進來後的第 2 個 clock 開始計算，並在第12個
clock 得出計算結果。延遲一個 cycle 的原因是 BRAM 的讀取，因此不會影響從ss
收 data ，故在最大的效率下 (ss 隨時輸入，sm 隨時輸出)，一個 data 的計算只需
要 11 個 clocks，最大化了乘法器和加法器的利用率。


Lab 4-1:   
===
Interface between BRAM and wishbone
1. To make sure the mprjram is selected ,where wbs_adr_i[31:20] is from
12’h380 (12’b0011_1000_0000) to 12’h384 (12’b0011_1000_0100) , we
assign a signal Sel as wbs_adr_i[31:23] is 9’h070 (9’b001110000) to
determine whether the wishbone address is in the range.
2. clock (clk) of the BRAM and reset (rst) are assigned to the ones from
wishbone (wb_clk_i and wb_rst_i)
3. enble (EN0) of the BRAM is assigned to wbs_cyc_i && wbs_stb_i && Sel
4. write enable (WE0) is assigned to wbs_sel_i & {4{wbs_we_i}}
5. DataIn(write data) is assigned to wbs_dat_i
6. Address(A0) is assigned to Sel ? (wbs_adr_i & 32'h003FFFFF) : 32’b0,
using a mask to make the bram size smaller.
7. We used a simple 4 bits counter and a “ready” signal to control the
desired delay time from enable to wbs_ack_o.
8. DataOut(read data) is connected to wbs_data_o for output.
9. BRAM size parameter N = 9


Lab 4-2:
===
1. How firmware handshaking to design

>Outputs start with Mark (A5) on mprj[23:16] to notify Testbench to
start latencytimer
RISC-V sends X[n] to FIR
RISC-V receives Y[n] from FIR
When transfer finish, write final Y and EndMark to record the
latency
Testbench will finally check correctness by checking mprj[31:24],
and print out the latency

2. Interface protocol between different Design

>The interface between firmware and user project is through
wishbone. The Wishbone protocol also defines a number of control
signals, which are used to coordinate the data transfer between the
bus master and the bus slave. signals include : Address ,Write ,
Data, Clock.
And the functionality of testbench is combined them together to a
simulation unit so that we can utilize caravel platform to transfer
data and control signals.
3.  What is the FIR engine theoretical throughput, i.e. data rate? Actually measured throughput?

>Data rate :
>In the design the output is 3467us - 3441us = 26us per output which
means that in every output of fir design 26us generate an output.
Throughput:
The definition of throughput is total workload in every time unit
Therefore, from perspective of output 692us-324us=368us having 3
outputs. 3/368us is equal to 0.00833 * 10^9 = 8.33 * 10^6 is the
throughput.

Lab 5:
===
1. Read_romcode
>This block is to copy the data in PS side into BRAM or write the data from
BRAM to PS side
In each transaction, we have different bus to send the different base
address.
For example, PS side set the port _BUS_0 just to send data to PL side,
another transaction is vice versa.

2. Spiflash
> Spi slave only support read command and its mmio address is 0x03 owing
to return the data from BRAM to Caravel
SPI protocal consist of MOSI MISO SCK SS and the transaction is serial
transmiting from lsb to msb and the slave side also.

3. Caravel PS

> In this PS side, the caravel provide a interface which is consist of AXI port to
read the mprj bits.
The port can be in or out.
The programming address of mprj in is 0x10 and address of mprj out is
0x1c.

4. Reset control

>After firmware loaded into RAM we start to execute reset control, and the
riscv cpu start to running and send data to spi flash.


Lab 6:
===

1. UART

>UART Control: This block consists of Rx Control - This block
samples received data with respect to generated baud rate and
writes it to Receive Data FIFO.
Tx Control: This block reads data from Transmit Data FIFO and
sends it out on the UART Tx interface.
Interrupt Control: The AXI UART Lite core provides interrupt
enable/disable control. If interrupts are enabled, a rising-edge
sensitive interrupt is generated when the receive FIFO becomes
non-empty or when the transmit FIFO becomes empty

2. How uart in this project work

>This time we use isr routine inside the firmware code to generate
interrupt signal to
CPU just for receive data for uart.
we use uart.h to define the register to configure uart reg
caravel_uart_tx is connected to axi_lite_uart_rx and caravel_uart_rx is
coneected to axi_lire_uart_tx
PS site write data to uart_lite and caravel will use the data by using
uart port
if caravel_soc wanna send data to PS side it will trigger a interupt to
axi interrupt controller and controller will tell the irq inside PS side that
there is a data inside axi_lite and then PS side read the data putting it
into buffer

In this lab, we have learned how to use caravel soc in real FPGA to
deploy a platform and its detail. In lab, writing a robust firmware
code is essential because the firmware code can drastically affect
the performance. It is also a good practice to have experience like
how to use wishbone but in IP mode as protocol to transfer data
to user project and use mprj pin to deliver result which is from fir
back to RISC CPU. UART is a big challenge in this lab because we
have to make sure we put the correct code into right place in the
waveform we can observe that uart is accept data at first and send
it to Tx port later on. In order to decrease the latency for uart.
We may try to add an additional buffer to it and then use interrupt
as a way to not to disturb CPU.

Final:
===
Check the report from the following github link to get more info:

> https://github.com/JackeyUi/SoC_Final