`timescale 1ns/1ps
`default_nettype none

// Minimal smoke test: one AHB-Lite write followed by one AHB-Lite read.
module tb_ahb_slave;
    logic ahb_clk, tpu_rst_n, hsel, hwrite, hreadyin;
    logic [2:0] hsize, hburst;
    logic [1:0] htrans;
    logic [3:0] hprot;
    logic [31:0] haddr, hwdata, ahb_rd_data;
    wire hready, hresp, ahb_wr_en, ahb_rd_en;
    wire [31:0] hrdata, ahb_wr_data;
    wire [9:0] ahb_addr;
    integer failures;

    ahb_slave dut (
        .ahb_clk(ahb_clk), .tpu_rst_n(tpu_rst_n),
        .hsel(hsel), .hsize(hsize), .haddr(haddr),
        .hburst(hburst), .htrans(htrans), .hwrite(hwrite),
        .hwdata(hwdata), .hreadyin(hreadyin), .hprot(hprot),
        .hready(hready), .hrdata(hrdata), .hresp(hresp),
        .ahb_rd_data(ahb_rd_data), .ahb_addr(ahb_addr),
        .ahb_wr_data(ahb_wr_data), .ahb_wr_en(ahb_wr_en),
        .ahb_rd_en(ahb_rd_en)
    );

    initial ahb_clk = 1'b0;
    always #5 ahb_clk = ~ahb_clk;

`ifdef FSDB
    string fsdb_file;
    initial begin
        if (!$value$plusargs("FSDB_FILE=%s", fsdb_file))
            fsdb_file = "main.fsdb";
        $fsdbDumpfile(fsdb_file);
        $fsdbDumpvars(0, tb_ahb_slave, "+all");
    end
`endif

    initial begin
        failures = 0;
        tpu_rst_n = 1'b0;
        hsel = 1'b0;
        hsize = 3'b010;       // 32-bit word
        haddr = 32'h0;
        hburst = 3'b000;      // SINGLE
        htrans = 2'b00;       // IDLE
        hwrite = 1'b0;
        hwdata = 32'h0;
        hreadyin = 1'b1;
        hprot = 4'b0011;
        ahb_rd_data = 32'h0;

        repeat (3) @(posedge ahb_clk);
        @(negedge ahb_clk);
        tpu_rst_n = 1'b1;

        // One write: byte address 0x4000_0008 -> word index 0x002.
        hsel = 1'b1;
        htrans = 2'b10;       // NONSEQ
        hwrite = 1'b1;
        haddr = 32'h4000_0008;
        hwdata = 32'h1234_5678;
        @(posedge ahb_clk);   // IDLE -> address sampling
        @(posedge ahb_clk);   // write data phase
        #1;
        if (!(hready === 1'b1 && hresp === 1'b0 &&
              ahb_wr_en === 1'b1 && ahb_rd_en === 1'b0 &&
              ahb_addr === 10'h002 && ahb_wr_data === 32'h1234_5678)) begin
            failures = failures + 1;
            $error("write mismatch: READY=%b RESP=%b WR_EN=%b ADDR=%h DATA=%h",
                   hready, hresp, ahb_wr_en, ahb_addr, ahb_wr_data);
        end

        @(negedge ahb_clk);
        hsel = 1'b0;
        htrans = 2'b00;
        @(posedge ahb_clk);   // return to IDLE

        // One read: byte address 0x4000_0024 -> word index 0x009.
        @(negedge ahb_clk);
        hsel = 1'b1;
        htrans = 2'b10;
        hwrite = 1'b0;
        haddr = 32'h4000_0024;
        ahb_rd_data = 32'hA5A5_5A5A;
        @(posedge ahb_clk);   // IDLE -> address sampling
        @(posedge ahb_clk);   // read data phase
        #1;
        if (!(hready === 1'b1 && hresp === 1'b0 &&
              ahb_rd_en === 1'b1 && ahb_wr_en === 1'b0 &&
              ahb_addr === 10'h009 && hrdata === 32'hA5A5_5A5A)) begin
            failures = failures + 1;
            $error("read mismatch: READY=%b RESP=%b RD_EN=%b ADDR=%h HRDATA=%h",
                   hready, hresp, ahb_rd_en, ahb_addr, hrdata);
        end

        @(negedge ahb_clk);
        hsel = 1'b0;
        htrans = 2'b00;
        @(posedge ahb_clk);

        $display("SUMMARY: smoke writes=1 reads=1 failures=%0d", failures);
        if (failures == 0) begin
            $display("PASS: tb_ahb_slave (one write + one read)");
            $finish;
        end
        $fatal(1, "FAIL: tb_ahb_slave failures=%0d", failures);
    end
endmodule

`default_nettype wire
