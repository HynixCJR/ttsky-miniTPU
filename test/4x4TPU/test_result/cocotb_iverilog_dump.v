module cocotb_iverilog_dump();
initial begin
    $dumpfile("/home/dphhs/projects/ttsky-miniTPU/test/4x4TPU/test_result/tt_um_4x4TPU.fst");
    $dumpvars(0, tt_um_4x4TPU);
end
endmodule
