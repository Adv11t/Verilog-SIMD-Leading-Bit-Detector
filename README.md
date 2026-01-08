# Unified SIMD Leading Bit Detector for Posit Arithmetic

## Overview
This repository contains a synthesizable Verilog implementation of a **Multi-Precision SIMD Leading Bit Detector (LBD)**, specifically optimized for **Posit Arithmetic Regime Decoding**. 

Unlike standard binary Leading One Detectors (LODs), this design includes pre-processing logic to handle Posit Regime sequences (run-length encoded strings of `0`s or `1`s) by dynamically inverting the input based on the regime sign. It features a unified, hierarchical architecture that supports dynamic precision switching between **8-bit**, **16-bit**, and **32-bit** modes.

## Key Features
- **SIMD Architecture:** Dynamically reconfigurable to support:
  - **4 x 8-bit** (Quad Precision)
  - **2 x 16-bit** (Dual Precision)
  - **1 x 32-bit** (Single Precision)
- **Posit Regime Support:** Includes conditional inversion logic (`XOR` based) to detect the terminating bit of both positive (00...1) and negative (11...0) regimes.
- **Resource Sharing:** Built on a modular 4-bit priority encoder base (`lod4`) to maximize area efficiency across all precision modes.
- **Pipeline Ready:** Includes a synchronous wrapper (`LD_clocked`) for easy integration into pipelined processors.

## Architecture

The design follows a 3-step combinational logic flow before registering the output:
1. **Regime Detection & Inversion:** Determines the control bit for each byte lane and conditionally inverts the data to normalize the regime to a "Leading One" problem.
2. **Sign Masking:** Forces specific sign bits to `0` based on the selected SIMD mode to prevent false detections across boundaries.
3. **Hierarchical LOD:** - Base: 4-bit Look-Ahead Encoders.
   - 8-bit Logic: Merges 4-bit results.
   - 16/32-bit Logic: Further merges lower-level results using priority MUXing.

## Signal Description

| Signal | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `clk` | Input | 1-bit | System Clock |
| `in` | Input | 32-bit | Input Data Word (containing 1x32b, 2x16b, or 4x8b Posits) |
| `mode` | Input | 2-bit | Precision Select (See Modes below) |
| `count` | Output | 12-bit | Position of the leading bit (Packed format) |
| `valid` | Output | 4-bit | Validity flags for each sub-word |

## Modes of Operation

### Mode `00`: 8-bit Precision (Quad SIMD)
- **Input:** Treated as four independent 8-bit numbers.
- **Output:** - `count[11:9]`: Count for Byte 3
  - `count[8:6]`: Count for Byte 2
  - `count[5:3]`: Count for Byte 1
  - `count[2:0]`: Count for Byte 0
- **Valid:** `valid[3:0]` corresponds to each byte.

### Mode `01`: 16-bit Precision (Dual SIMD)
- **Input:** Treated as two independent 16-bit numbers.
- **Output:**
  - `count[7:4]`: Count for Upper 16-bit word.
  - `count[3:0]`: Count for Lower 16-bit word.
  - (Upper bits of `count` are zeroed).
- **Valid:** `valid[2]` and `valid[0]` indicate validity.

### Mode `10`: 32-bit Precision (Single)
- **Input:** Treated as one 32-bit number.
- **Output:**
  - `count[4:0]`: Count for the full 32-bit word.
- **Valid:** `valid[0]` indicates validity.

## Performance & Timing
- **Target Frequency:** 100 MHz (Verified)
- **Timing Analysis:** Validated using Xilinx Vivado Static Timing Analysis (STA).
- **Slack:** Achieved positive slack (~0.138 ns on critical path) ensuring robust synchronous operation.

## File Structure
- `SIMD_LD.v`: Contains the top-level `LD_clocked` module, the combinational core `LD_comb`, and the 4-bit primitive `lod4`.
- `Testbench.v`: (Optional) Simulation testbench covering regime crossings and boundary conditions.
