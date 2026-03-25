#!/bin/bash
echo "Compiling Tinker CPU..."
iverilog -g2012 -o vvp/sim.vvp test/test.sv hdl/*.sv
echo "Running Simulation..."
vvp vvp/sim.vvp