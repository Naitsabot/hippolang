# Hippo Language Formal Grammar

## Lexical Structure

### Comments
```
Comment := '#' ~[\n]* '\n'
```

### Keywords
```
Keywords := 
    'var' | 'const' | 'proc' | 'type' | 'object' | 'array'
    | 'if' | 'elif' | 'else' | 'while' | 'for' | 'in' | 'return'
    | 'and' | 'or' | 'not' | 'xor' | 'shl' | 'shr' | 'div' | 'mod'
    | 'true' | 'false' | 'asm' | 'addr'
```

### Identifiers
```
Identifier := [a-zA-Z_][a-zA-Z0-9_]*
```

### Literals
```
IntLiteral := DecimalLit | HexLit | BinaryLit
DecimalLit := [0-9]+
HexLit := '0x' [0-9a-fA-F]+
BinaryLit := '0b' [01]+

StringLiteral := '"' (~["\n] | EscapeSeq)* '"'
EscapeSeq := '\' [nrt"\\]

BoolLiteral := 'true' | 'false'
```

### Operators
```
ArithOp := '+' | '-' | '*' | 'div' | 'mod'
BitwiseOp := 'and' | 'or' | 'xor' | 'not' | 'shl' | 'shr'
CompareOp := '==' | '!=' | '<' | '>' | '<=' | '>='
LogicalOp := 'and' | 'or' | 'not'
AssignOp := '=' | '+=' | '-=' | '*='
```

### Punctuation
```
Punct := '{' | '}' | '(' | ')' | '[' | ']' 
       | ':' | ',' | '.' | '@' | '..<'
```

---

## Syntax Grammar

### Program Structure
```
Program := TopLevelDecl*

TopLevelDecl := 
    | PragmaDecl
    | VarDecl
    | ConstDecl
    | TypeDecl
    | ProcDecl
```

### Pragmas
```
PragmaDecl := '{.' PragmaList '.}'

PragmaList := Pragma (',' Pragma)*

Pragma := 
    | Identifier
    | Identifier ':' PragmaValue

PragmaValue := 
    | Identifier
    | IntLiteral
```

### Type Declarations
```
TypeDecl := 'type' Identifier '=' TypeDef

TypeDef := 
    | PrimitiveType
    | ObjectType
    | ArrayType

PrimitiveType := 
    'uint8' | 'int8' | 'uint16' | 'int16' | 'bool' | 'ptr'

ObjectType := 'object' '{' FieldList '}'

FieldList := (Field)*

Field := Identifier ':' TypeExpr

ArrayType := 'array' '[' (IntLiteral ',')? TypeExpr ']'

TypeExpr := 
    | PrimitiveType
    | Identifier
    | ArrayType
```

### Variable Declarations
```
VarDecl := 'var' Identifier ':' TypeExpr MemoryLocation? ('=' Expr)? 

ConstDecl := 'const' Identifier (':' TypeExpr)? MemoryLocation? '=' Expr

MemoryLocation := '@' MemoryRegion ':' IntLiteral
                | '@' IntLiteral

MemoryRegion := 'rom0' | 'rom1' | 'wram' | 'hram'
```

### Procedure Declarations
```
ProcDecl := PragmaDecl* 'proc' Identifier '(' ParamList? ')' (':' TypeExpr)? Block

ParamList := Param (',' Param)*

Param := Identifier (',' Identifier)* ':' TypeExpr
```

### Statements
```
Block := '{' Statement* '}'

Statement := 
    | VarDecl
    | AssignStmt
    | ProcCallStmt
    | IfStmt
    | WhileStmt
    | ForStmt
    | ReturnStmt
    | AsmStmt
    | Block

AssignStmt := LValue AssignOp Expr

LValue := 
    | Identifier
    | LValue '.' Identifier
    | LValue '[' Expr ']'
    | LValue '[]'

ProcCallStmt := Identifier '(' ArgList? ')'

ArgList := Expr (',' Expr)*

IfStmt := 'if' Expr Block ('elif' Expr Block)* ('else' Block)?

WhileStmt := 'while' Expr Block

ForStmt := 'for' Identifier 'in' Expr '..<' Expr Block

ReturnStmt := 'return' Expr?

AsmStmt := 'asm' StringLiteral
```

### Expressions
```
Expr := LogicalOrExpr

LogicalOrExpr := LogicalAndExpr ('or' LogicalAndExpr)*

LogicalAndExpr := CompareExpr ('and' CompareExpr)*

CompareExpr := BitwiseOrExpr (CompareOp BitwiseOrExpr)?

BitwiseOrExpr := BitwiseXorExpr ('or' BitwiseXorExpr)*

BitwiseXorExpr := BitwiseAndExpr ('xor' BitwiseAndExpr)*

BitwiseAndExpr := ShiftExpr ('and' ShiftExpr)*

ShiftExpr := AddExpr (('shl' | 'shr') AddExpr)*

AddExpr := MultExpr (('+' | '-') MultExpr)*

MultExpr := UnaryExpr (('*' | 'div' | 'mod') UnaryExpr)*

UnaryExpr := 
    | '-' UnaryExpr
    | 'not' UnaryExpr
    | 'addr' '(' Expr ')'
    | PostfixExpr

PostfixExpr := 
    | PrimaryExpr
    | PostfixExpr '.' Identifier
    | PostfixExpr '[' Expr ']'
    | PostfixExpr '[]'
    | PostfixExpr '(' ArgList? ')'

PrimaryExpr := 
    | Identifier
    | IntLiteral
    | BoolLiteral
    | StringLiteral
    | '(' Expr ')'
    | HwRegister
    | BuiltinCall
    | ArrayLiteral

HwRegister := 'hw' '.' Identifier

BuiltinCall := 
    | 'memcpy' '(' Expr ',' Expr ',' Expr ')'
    | 'memset' '(' Expr ',' Expr ',' Expr ')'
    | 'switchBank' '(' Expr ')'
    | 'switchBankRestore' '(' ')'
    | 'sizeof' '(' TypeExpr ')'
    | 'includeBin' '(' StringLiteral ')'
    | 'includeTiles' '(' StringLiteral ')'
    | 'includeStruct' '(' StringLiteral ')'

ArrayLiteral := '[' (Expr (',' Expr)*)? ']'
```

---

## Operator Precedence (Highest to Lowest)

1. Postfix operators: `.`, `[]`, `()`
2. Unary operators: `-`, `not`, `addr()`
3. Multiplicative: `*`, `div`, `mod`
4. Additive: `+`, `-`
5. Shift: `shl`, `shr`
6. Bitwise AND: `and` (when used bitwise)
7. Bitwise XOR: `xor`
8. Bitwise OR: `or` (when used bitwise)
9. Comparison: `==`, `!=`, `<`, `>`, `<=`, `>=`
10. Logical AND: `and` (when used logically)
11. Logical OR: `or` (when used logically)
12. Assignment: `=`, `+=`, `-=`, `*=`

---

## Semantic Rules

### Type System
1. All variables must have explicit types or be inferrable from initialization
2. Integer types cannot be implicitly converted between sizes
3. `bool` is distinct from integers
4. Pointers are typed as `ptr` (untyped pointer)

### Scope Rules
1. Module-level declarations are visible throughout the module
2. Block-scoped variables are destroyed at end of block
3. Variables cannot shadow other variables in outer scopes
4. Forward references to procedures are allowed

### Memory Allocation
1. All variables are statically allocated
2. Memory addresses must not overlap
3. Compiler assigns addresses for variables without `@` specification
4. Variables can be reused after going out of scope

### Bank Switching
1. Procedures with `{.bank: N.}` must be in ROM bank N
2. Calling cross-bank procedures generates switch code
3. Interrupt handlers cannot call procedures in other banks
4. `{.noBankSwitch.}` procedures must be called from correct bank

### Interrupts
1. Interrupt handlers must have `{.interrupt: X.}` pragma
2. Interrupt handlers cannot have parameters or return values
3. Available interrupts: `vblank`, `lcdStat`, `timer`, `serial`, `joypad`

### Restrictions
1. No recursion (compiler warning/error)
2. No dynamic memory allocation
3. Array bounds must be compile-time constants
4. Hardware registers are read/write only (no address-of)

---

## Standard Pragmas

```
{.entry.}               # Mark entry point procedure
{.bank: N.}             # Assign to ROM bank N
{.inline.}              # Suggest inlining
{.interrupt: X.}        # Interrupt handler
{.noBankSwitch.}        # Disable automatic bank switching
{.patchable.}           # Mark data as patchable
{.lut.}                 # Mark as lookup table
{.compressed.}          # Mark data for compression
{.mbc: TYPE.}           # Memory bank controller type
{.romBanks: N.}         # Number of ROM banks
{.ramBanks: N.}         # Number of RAM banks
```

---

## Built-in Identifiers

### Hardware Namespace
```
hw.joypad
hw.lcdControl
hw.lcdStat
hw.scrollY
hw.scrollX
hw.scrollWindowY
hw.scrollWindowX
hw.bgPalette
hw.objPalette0
hw.objPalette1
# ... additional hardware registers
```

### Built-in Procedures
```
memcpy(dest, src: ptr, count: uint8)
memset(dest: ptr, value: uint8, count: uint8)
switchBank(bank: uint8)
switchBankRestore()
sizeof(T: type): uint16
includeBin(path: string): array[uint8]
includeTiles(path: string): array[uint8]
includeStruct(path: string): array[T]
```