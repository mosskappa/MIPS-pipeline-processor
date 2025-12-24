# Parentheses Support for Expression Parser

This contribution implements the "Stack-based Parentheses Handling" suggested by the professor. It extends the Shunting-yard algorithm in the `converter` module to support `(` and `)` operators.

## Features
*   **Full Arithmetic Support**: ADD, SUB, MUL, DIV, EXP (Power).
*   **Parentheses Support**: Changes precedence (e.g., `5*(3+4)`).
*   **Correct Associativity**: 
    *   Left-associative for `+`, `-`, `*`, `/`.
    *   **Right-associative for `^`** (e.g., `2^3^2 = 2^9 = 512`).

## Encoding (Aligned with Contribution 5)
*   `ADD` : `000`
*   `SUB` : `001`
*   `MUL` : `010`
*   `DIV` : `011`
*   `EXP` : `100`
*   `=`   : `101` (End of Expression)
*   `(`   : `110`
*   `)`   : `111`

## Files
*   `converter.v`: Extended Shunting-yard algorithm with priority logic.
*   `stack.v`: Standard stack implementation.
*   `calculator.v`: ALU logic supporting all 5 operations.
*   `tb_parentheses.v`: Verifies complex expressions and associativity.

## Demo Expressions verified
1.  `5 * ( 3 + 4 ) = 35` (Parentheses Precedence)
2.  `2 ^ 3 ^ 2 = 512` (Right Associativity)
3.  `100 / ( 2 + 3 ) = 20` (Division validation)

