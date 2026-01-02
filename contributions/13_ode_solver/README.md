# Contribution 13: ODE Solver (微積分運算)

## Overview

This contribution implements a hardware **Ordinary Differential Equation (ODE) Solver** using the **Forward Euler Method**. This represents a true implementation of calculus operations in hardware, as solving ODEs requires both differentiation and integration concepts.

## Mathematical Background

### State-Space Representation

The solver computes solutions to systems of ODEs in state-space form:

```
dX/dt = A·X + B·U
```

Where:
- **X** is the state vector (size N)
- **A** is the system matrix (N×N)
- **B** is the input matrix (N×M)
- **U** is the input vector (size M)

### Forward Euler Method

The numerical solution uses the Forward Euler integration formula:

```
X(t+h) = X(t) + h · dX/dt
       = X(t) + h · (A·X + B·U)
```

This implements:
1. **Differentiation**: dX/dt ≈ (X(t+h) - X(t)) / h
2. **Integration**: X(t+h) = X(t) + ∫(dX/dt)dt ≈ X(t) + h·f(X,U)

## Why This is More Complex Than CORDIC

| Aspect | CORDIC (Contribution 9) | ODE Solver (Contribution 13) |
|--------|------------------------|------------------------------|
| **Core Algorithm** | Shift-add iterations | Matrix multiplication + Euler integration |
| **Operations** | Single trig function | System of differential equations |
| **Data Structure** | Scalar | Vectors and Matrices |
| **Control Logic** | Fixed 16-stage pipeline | FSM with 6 states |
| **Memory** | None | 8K × 64-bit RAM |
| **Math Level** | Trigonometry | **Calculus (微積分)** |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    System.v (Top)                        │
│  ┌─────────────────┐    ┌──────────────────────────┐   │
│  │   RAM Module    │◄──►│     Euler Solver         │   │
│  │  (8K × 64-bit)  │    │                          │   │
│  │                 │    │  ┌──────────────────┐    │   │
│  │  A Matrix       │    │  │ State Machine    │    │   │
│  │  B Matrix       │    │  │ ┌────┐ ┌─────┐   │    │   │
│  │  X Vector       │    │  │ │Load│→│Calc │   │    │   │
│  │  U Vector       │    │  │ └────┘ └─────┘   │    │   │
│  │  Results        │    │  └──────────────────┘    │   │
│  └─────────────────┘    │                          │   │
│                         │  ┌──────────────────┐    │   │
│                         │  │ 16-bit Multiplier│    │   │
│                         │  │ (Wallace Tree)   │    │   │
│                         │  └──────────────────┘    │   │
│                         │                          │   │
│                         │  ┌──────────────────┐    │   │
│                         │  │ CLA Adder        │    │   │
│                         │  │ (Carry Lookahead)│    │   │
│                         │  └──────────────────┘    │   │
│                         └──────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## State Machine

```
┌───────┐     ┌─────────┐     ┌─────────────┐
│ Start │────►│ Prepare │────►│ Interpolate │
└───────┘     └─────────┘     └─────────────┘
                                     │
              ┌──────────────────────┘
              ▼
        ┌───────┐     ┌───────┐     ┌────────────┐
        │ Load1 │────►│ Load2 │────►│ Final_Calc │
        └───────┘     └───────┘     └────────────┘
           │              │                │
           │  B·U         │  A·X           │  X + h·(A·X + B·U)
           ▼              ▼                ▼
```

## File Structure

```
13_ode_solver/
├── Euler.v                    # Main ODE solver module (279 lines)
├── System.v                   # Top-level wrapper
├── RAM-Pre.v                  # Dual-port RAM for matrices/vectors
├── multiplier_16bit.v         # 16-bit Wallace tree multiplier
├── add_sub_cla.v              # Carry Lookahead Adder
├── carry_lookahead_adder_*.v  # CLA building blocks
├── m_full_adder.v             # Full adder
├── m_half_adder.v             # Half adder
├── nbits_adder.v              # N-bit adder
├── wallace_16bit_multiplier.v # Wallace tree implementation
├── booth_16bit_multiplier.v   # Booth multiplier (alternative)
├── nx1_product.v              # Partial product
├── mux2x1.v                   # 2-to-1 multiplexer
├── tb_ode_solver.v            # Testbench
└── README.md                  # This file
```

## Memory Map

| Address | Content | Description |
|---------|---------|-------------|
| 0 | N | State vector dimension |
| 1 | M | Input vector dimension |
| 4 | h | Step size |
| 7 | A | System matrix (N×N) |
| 2507 | B | Input matrix (N×M) |
| 5207 | X | Current state vector |
| 5257 | U | Input vector |
| 5307 | Temp1 | Intermediate result B·U |
| 5357 | Temp2 | Intermediate result A·X |
| 5407 | X_new | **Output: New state X(t+h)** |

## Example: Spring-Mass-Damper System

The classic 2nd-order ODE for a spring-mass-damper:

```
m·ẍ + c·ẋ + k·x = F(t)
```

Converted to state-space form (x₁ = x, x₂ = ẋ):

```
dX/dt = [  0      1   ] · X + [  0  ] · F
        [-k/m  -c/m ]       [1/m ]
```

## Vivado Simulation

### One-Liner Command (Recommended)
```tcl
close_sim -force; set_property top tb_ode_solver [get_filesets sim_1]; launch_simulation; run 5000ns
```

### Verified Test Results (2026-01-02)

```
========================================
  ODE Solver Testbench - Euler Method
========================================
  Solving: dX/dt = A*X + B*U
  Method:  Forward Euler
  X(t+h) = X(t) + h * (A*X + B*U)
========================================

Test Setup:
  N = 2, M = 1, h = 1
  A = [[1, 0], [0, 1]] (Identity Matrix)
  B = [[1], [1]]
  X0 = [10, 20]
  U = [5]

Expected Calculation:
  X(t+h) = X(t) + h * (A*X + B*U)
  X(t+h) = [10, 20] + 1 * ([10, 20] + [5, 5])
  X(t+h) = [10, 20] + [15, 25] = [25, 45]

========================================
  Results:
========================================
  X_new[0] = 25 (Expected: 25) ✓
  X_new[1] = 45 (Expected: 45) ✓

  [PASS] ODE Solver working correctly!
========================================

Calculus Operations Demonstrated:
  1. Differentiation: dX/dt ≈ (X(t+h) - X(t))/h
  2. Integration: X(t+h) = X(t) + ∫(dX/dt)dt
  3. Matrix operations: A·X + B·U
```

**Simulation Time**: 570 ns

## Performance

| Metric | Value |
|--------|-------|
| Clock Frequency | ~50 MHz |
| Solver Method | Forward Euler |
| Data Width | 16-bit fixed-point |
| Address Width | 13-bit (8K entries) |
| Matrix Size | Up to 50×50 |
| Multiplier Type | Wallace Tree |
| Adder Type | Carry Lookahead |

## Source Attribution

Based on: [3amrA7med/ODE-Solver](https://github.com/3amrA7med/ODE-Solver)

This implementation was integrated and adapted for our MIPS pipeline processor project to demonstrate hardware implementation of calculus concepts.

## Keywords

微積分 | Calculus | Differential Equations | ODE | Euler Method | Numerical Integration | State-Space | Matrix Operations | Hardware Accelerator
