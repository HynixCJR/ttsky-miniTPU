module cocotb_iverilog_dump();
initial begin
    $dumpfile("/home/dphhs/projects/ttsky-miniTPU/test/IO_Interface/test_result/IO_interface.fst");
    $dumpvars(0, IO_interface);
end
endmodule
