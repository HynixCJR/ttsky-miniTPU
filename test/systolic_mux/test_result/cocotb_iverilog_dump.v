module cocotb_iverilog_dump();
initial begin
    $dumpfile("/home/dphhs/projects/ttsky-miniTPU/test/systolic_mux/test_result/systolic_array_mux.fst");
    $dumpvars(0, systolic_array_mux);
end
endmodule
