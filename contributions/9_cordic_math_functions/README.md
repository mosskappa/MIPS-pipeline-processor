# CORDIC-Based Trigonometric Functions (Graduate-Level Extension)

This contribution integrates a **research-grade CORDIC (COordinate Rotation DIgital Computer)** algorithm for calculating sine and cosine functions, representing a significant upgrade from basic arithmetic operations.

## Background

**CORDIC** is a widely-used algorithm in:
- Digital Signal Processing (DSP)
- Navigation systems (航空航天)
- Graphics processing
- Scientific computing

It is particularly suitable for hardware implementation because it **avoids costly multipliers**, using only:
- Bit-shifts (移位)
- Additions/Subtractions (加減法)
- Look-up tables (查表)

---

## Source & Attribution

**Original Project**: [Pranav-2045/CORDIC](https://github.com/Pranav-2045/CORDIC)  
**Author**: Pranav-2045  
**Integrated by**: 劉俊逸 (M143140014)

This is a **direct integration** of the original project to demonstrate graduate-level mathematical capabilities.

---

## Technical Specifications

### Architecture
- **16-bit fixed-point** arithmetic (Q2.14 format)
- **16-stage fully pipelined** design
- **High throughput**: Accepts new input every clock cycle after initial latency
- **Multiplier-free**: Hardware-efficient implementation

### Supported Functions
- `sin(θ)`: Sine function
- `cos(θ)`: Cosine function
- Angle range: -90° to +90° (可擴展到全範圍)

### Performance
- **Latency**: 16 clock cycles
- **Throughput**: 1 result/cycle (pipelined)
- **Precision**: ~14 bits (定點運算精度)

---

## Files

- `cordic.v`: Main CORDIC engine (16-stage pipeline)
- `tb_cordic.v`: Comprehensive testbench with multiple test angles

---

## How to Run (Vivado)

1. Open Vivado 2022
2. Add both `cordic.v` and `tb_cordic.v` to simulation sources
3. Run behavioral simulation
4. Expected output:
   ```
   Testing angle: 30.0 degrees
   DUT Output: cos=0.866, sin=0.500
   Expected:   cos=0.866, sin=0.500
   ```

---

## Connection to Course Objectives

This contribution demonstrates:

1. **Advanced Mathematics**: Extends beyond basic ALU to transcendental functions (超越基本四則運算)
2. **Algorithm Implementation**: Shows understanding of iterative approximation algorithms
3. **Resource-Aware Design**: Multiplier-free design demonstrates understanding of hardware constraints
4. **Research Integration**: Ability to leverage and integrate existing academic work

---

## Professor's Feedback Addressed

> "你要不要去找一個別人研究所等級的 SIMD 研究？...譬如說有微積分、積分等等針對 Complex Mathematic Function 的。"

**Response**: CORDIC is a graduate-level algorithm commonly taught in advanced computer architecture and DSP courses. While not calculus per se, trigonometric functions are fundamental to many scientific computations including numerical integration, Fourier transforms, and signal analysis.

---

## Future Extensions (Optional)

If time permits, this module could be extended to:
- **Hyperbolic functions**: `sinh`, `cosh`, `tanh`
- **Vector mode**: Calculate magnitude and phase
- **SIMD integration**: Parallel CORDIC units for 8-lane vector processing
