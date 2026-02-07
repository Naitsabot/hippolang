# Hippo - A Nim-inspired systems language for Game Boy (SM83) with:

- Clean syntax: Nim-style with braces, camelCase identifiers
- Static allocation: All memory statically allocated, block-scoped
- Direct hardware control: hw. namespace, explicit memory placement with @
- Bank switching: Automatic cross-bank calls with {.bank: N.} pragmas
- Type safety: Explicit types (uint8, int16, etc.), objects, arrays
- Optimization: Always optimize, no opt-out
- Embedded features: Interrupts, inline assembly, binary file inclusion

all identifiers are treated as lowercase with underlines removed.

## Project Structure
hippo/
├── hippo.nimble          # Package file
├── src/
│   ├── hippo.nim         # Main compiler entry point
│   ├── lexer.nim           # Lexical analyzer
│   ├── parser.nim          # Parser
│   ├── ast.nim             # AST definitions
│   ├── types.nim           # Type system
│   ├── semantic.nim        # Semantic analysis
│   ├── codegen.nim         # Code generation
│   ├── sm83.nim            # SM83 assembly helpers
│   └── utils/
│       ├── errors.nim      # Error reporting
│       └── source.nim      # Source location tracking
├── tests/
│   ├── test_lexer.nim
│   ├── test_parser.nim
│   └── examples/
│       └── simple.pg       # Test programs
└── README.md