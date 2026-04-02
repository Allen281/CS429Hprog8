unit:
	iverilog -g2012 -o unit_test test/unit_test.sv tinker.sv
	vvp unit_test
general:
	iverilog -g2012 -s tb_tinker -o vvp/sim.vvp test/test.sv tinker.sv
	vvp vvp/sim.vvp