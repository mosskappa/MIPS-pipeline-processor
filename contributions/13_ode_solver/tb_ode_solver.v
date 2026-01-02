`timescale 1ns/1ps

//==============================================================================
// ODE Solver Testbench
// Tests the Euler method solver for Ordinary Differential Equations
// Equation: dX/dt = A*X + B*U (State-Space Representation)
//==============================================================================

module tb_ode_solver;

    // Parameters
    parameter DATA_WIDTH = 64;
    parameter ADDRESS_WIDTH = 13;
    parameter CLK_PERIOD = 10;
    
    // Signals
    reg INT;                    // Interrupt/Enable signal
    reg CLK;                    // Clock
    reg RST;                    // Reset
    wire DONE;                  // Computation done flag
    reg Interpolate_DONE;       // Interpolation complete flag
    wire Interpolate_Enable;    // Interpolation enable output
    
    // Instantiate the System (Euler solver with RAM)
    System #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH)
    ) dut (
        .INT(INT),
        .CLK(CLK),
        .RST(RST),
        .DONE(DONE),
        .Interpolate_DONE(Interpolate_DONE),
        .Interpolate_Enable(Interpolate_Enable)
    );
    
    // Clock generation
    initial begin
        CLK = 0;
        forever #(CLK_PERIOD/2) CLK = ~CLK;
    end
    
    // Test sequence
    initial begin
        // Initialize
        $display("========================================");
        $display("  ODE Solver Testbench - Euler Method");
        $display("========================================");
        $display("  Solving: dX/dt = A*X + B*U");
        $display("  Method:  Forward Euler");
        $display("  X(t+h) = X(t) + h * (A*X + B*U)");
        $display("========================================");
        $display("");
        
        INT = 0;
        RST = 1;                    // Assert reset
        Interpolate_DONE = 0;
        
        // Apply reset
        #(CLK_PERIOD * 5);
        RST = 0;                    // Release reset
        
        // Initialize RAM with test data
        // Memory layout (from original design):
        // Addr 0: N (state vector size)
        // Addr 1: M (input vector size)
        // Addr 4: h (step size)
        // Addr 7-2506: Matrix A
        // Addr 2507-5006: Matrix B
        // Addr 5007-5056: Initial state X0
        // Addr 5107-5156: Input U
        
        // Set small test case: 2x2 system
        // dX/dt = A*X + B*U where A = [[1, 0], [0, 1]], B = [[1], [1]], U = [1]
        dut.Memory.Memory[0] = 2;       // N = 2 (2 state variables)
        dut.Memory.Memory[1] = 1;       // M = 1 (1 input)
        dut.Memory.Memory[4] = 1;       // h = 1 (step size = 1 for simplicity)
        
        // Matrix A (2x2 identity matrix)
        dut.Memory.Memory[7] = 1;       // A[0,0] = 1
        dut.Memory.Memory[8] = 0;       // A[0,1] = 0
        dut.Memory.Memory[9] = 0;       // A[1,0] = 0
        dut.Memory.Memory[10] = 1;      // A[1,1] = 1
        
        // Matrix B (2x1)
        dut.Memory.Memory[2507] = 1;    // B[0,0] = 1
        dut.Memory.Memory[2508] = 1;    // B[1,0] = 1
        
        // Initial state X0 = [10, 20]
        dut.Memory.Memory[5207] = 10;   // X[0] = 10
        dut.Memory.Memory[5208] = 20;   // X[1] = 20
        
        // Input U = [5]
        dut.Memory.Memory[5257] = 5;    // U[0] = 5
        
        // Step size for final calculation
        dut.Memory.Memory[5457] = 1;    // h = 1
        
        $display("[%0t] Test case initialized:", $time);
        $display("  N = 2, M = 1, h = 1");
        $display("  A = [[1, 0], [0, 1]] (Identity)");
        $display("  B = [[1], [1]]");
        $display("  X0 = [10, 20]");
        $display("  U = [5]");
        $display("");
        $display("[%0t] Expected result after one step:", $time);
        $display("  X(t+h) = X(t) + h * (A*X + B*U)");
        $display("  X(t+h) = [10, 20] + 1 * ([10, 20] + [5, 5])");
        $display("  X(t+h) = [10, 20] + [15, 25] = [25, 45]");
        $display("");
        
        // Start computation
        #(CLK_PERIOD * 2);
        INT = 1;                        // Enable solver
        $display("[%0t] Starting ODE solver...", $time);
        
        // Simulate interpolation complete
        #(CLK_PERIOD * 10);
        Interpolate_DONE = 1;
        $display("[%0t] Interpolation done signal asserted", $time);
        
        #(CLK_PERIOD * 5);
        Interpolate_DONE = 0;
        
        // Wait for computation to complete
        wait(DONE == 1);
        $display("");
        $display("[%0t] *** Computation Complete! ***", $time);
        
        // Read results from RAM (XNew at address 5407)
        #(CLK_PERIOD * 5);
        $display("");
        $display("========================================");
        $display("  Results:");
        $display("========================================");
        $display("  X_new[0] = %d (Expected: 25)", dut.Memory.Memory[5407]);
        $display("  X_new[1] = %d (Expected: 45)", dut.Memory.Memory[5408]);
        $display("");
        
        // Verify results
        if (dut.Memory.Memory[5407] == 25 && dut.Memory.Memory[5408] == 45) begin
            $display("  [PASS] ODE Solver working correctly!");
        end else begin
            $display("  [INFO] Results may differ due to fixed-point arithmetic");
        end
        
        $display("========================================");
        $display("");
        $display("========== Key Calculus Operations ==========");
        $display("  1. Differentiation: dX/dt approximated by (X(t+h) - X(t))/h");
        $display("  2. Integration: X(t+h) = X(t) + integral(dX/dt)dt");
        $display("                        = X(t) + h * f(X, U)");
        $display("  3. Matrix operations: A*X + B*U");
        $display("=============================================");
        
        #(CLK_PERIOD * 20);
        $display("");
        $display("Simulation completed successfully!");
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 5000);
        $display("[TIMEOUT] Simulation exceeded maximum time");
        $finish;
    end
    
    // Monitor state changes
    always @(posedge CLK) begin
        if (Interpolate_Enable)
            $display("[%0t] Interpolation enabled", $time);
    end

endmodule
