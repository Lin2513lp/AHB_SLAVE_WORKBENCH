`timescale 1ns/1ps
`default_nettype none

// Minimal error example: one unmapped address and the two-cycle ERROR response.
module tb_ahb_slave_error;
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
            fsdb_file = "error.fsdb";
        $fsdbDumpfile(fsdb_file);
        $fsdbDumpvars(0, tb_ahb_slave_error, "+all");
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
        hwrite = 1'b1;
        hwdata = 32'hDEAD_BEEF;
        hreadyin = 1'b1;
        hprot = 4'b0011;
        ahb_rd_data = 32'h0;

        repeat (3) @(posedge ahb_clk);
        @(negedge ahb_clk);
        tpu_rst_n = 1'b1;
        hsel = 1'b1;
        htrans = 2'b10;
        haddr = 32'h4000_0064;  // unmapped word index 0x019

        @(posedge ahb_clk);     // IDLE -> address sampling
        @(posedge ahb_clk);     // ERROR cycle 1
        #1;
        if (!(hready === 1'b0 && hresp === 1'b1 &&
              ahb_wr_en === 1'b0 && ahb_rd_en === 1'b0)) begin
            failures = failures + 1;
            $error("ERROR cycle 1 mismatch: HREADY=%b HRESP=%b", hready, hresp);
        end

        @(negedge ahb_clk);
        hsel = 1'b0;
        htrans = 2'b00;
        @(posedge ahb_clk);     // ERROR cycle 2
        #1;
        if (!(hready === 1'b1 && hresp === 1'b1 &&
              ahb_wr_en === 1'b0 && ahb_rd_en === 1'b0)) begin
            failures = failures + 1;
            $error("ERROR cycle 2 mismatch: HREADY=%b HRESP=%b", hready, hresp);
        end

        @(posedge ahb_clk);     // return to IDLE
        #1;
        if (!(hready === 1'b0 && hresp === 1'b0)) begin
            failures = failures + 1;
            $error("ERROR response did not return to IDLE");
        end

        $display("SUMMARY: error cases=1 failures=%0d", failures);
        if (failures == 0) begin
            $display("PASS: tb_ahb_slave_error (one unmapped address)");
            $finish;
        end
        $fatal(1, "FAIL: error test failures=%0d", failures);
    end
endmodule

`default_nettype wire
