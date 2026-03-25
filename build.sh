#!/bin/bash
set -euo pipefail

echo "Compiling Tinker CPU..."
iverilog -g2012 -s tb_tinker -o vvp/sim.vvp test/test.sv hdl/*.sv

echo "Running Simulation..."
vvp vvp/sim.vvp