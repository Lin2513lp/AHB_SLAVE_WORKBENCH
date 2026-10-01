`timescale 1ns/1ps
`default_nettype none

// Small waveform example: four back-to-back AHB-Lite reads.
module tb_ahb_slave_continuous_read;
    localparam integer NUM_TRANSFERS = 4;
    logic ahb_clk, tpu_rst_n, hsel, hwrite, hreadyin;
    logic [2:0] hsize, hburst;
    logic [1:0] htrans;
    logic [3:0] hprot;
    logic [31:0] haddr, hwdata, ahb_rd_data;
    wire hready, hresp, ahb_wr_en, ahb_rd_en;
    wire [31:0] hrdata, ahb_wr_data;
    wire [9:0] ahb_addr;
    integer failures, index;

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
    always_comb ahb_rd_data = 32'hA500_0000 | {22'h0, ahb_addr};

`ifdef FSDB
    string fsdb_file;
    initial begin
        if (!$value$plusargs("FSDB_FILE=%s", fsdb_file))
            fsdb_file = "continuous_read.fsdb";
        $fsdbDumpfile(fsdb_file);
        $fsdbDumpvars(0, tb_ahb_slave_continuous_read, "+all");
    end
`endif

    initial begin
        failures = 0;
        tpu_rst_n = 1'b0;
        hsel = 1'b0;
        hsize = 3'b010;
        haddr = 32'h0;
        hburst = 3'b000;
        htrans = 2'b00;
        hwrite = 1'b0;
        hwdata = 32'h0;
        hreadyin = 1'b1;
        hprot = 4'b0011;

        repeat (3) @(posedge ahb_clk);
        @(negedge ahb_clk);
        tpu_rst_n = 1'b1;
        hsel = 1'b1;
        htrans = 2'b10;
        haddr = 32'h4000_0000;
        @(posedge ahb_clk);   // enter address sampling
        @(posedge ahb_clk);   // accept read 0

        for (index = 0; index < NUM_TRANSFERS; index = index + 1) begin
            @(negedge ahb_clk);
            if (index < NUM_TRANSFERS - 1)
                haddr = 32'h4000_0000 + ((index + 1) * 4);
            else begin
                hsel = 1'b0;
                htrans = 2'b00;
            end
            #1;
            if (!(hready === 1'b1 && hresp === 1'b0 &&
                  ahb_rd_en === 1'b1 && ahb_wr_en === 1'b0 &&
                  ahb_addr === index[9:0] &&
                  hrdata === (32'hA500_0000 + index))) begin
                failures = failures + 1;
                $error("read %0d mismatch: ADDR=%h HRDATA=%h", index, ahb_addr, hrdata);
            end
            @(posedge ahb_clk);
        end

        $display("SUMMARY: continuous_read transfers=4 failures=%0d", failures);
        if (failures == 0) begin
            $display("PASS: tb_ahb_slave_continuous_read (4 reads)");
            $finish;
        end
        $fatal(1, "FAIL: continuous read failures=%0d", failures);
    end
endmodule

`default_nettype wire
