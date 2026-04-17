# Recursive decent with Pratt parser (operator preference)
# https://en.wikipedia.org/wiki/Recursive_descent_parser
# https://en.wikipedia.org/wiki/Operator-precedence_parser 


import std/[strutils]
import lexer, ast, utils/[errors]


type
    Parser* = object
        ## Holds the state of the parser
        lexer: Lexer
        current: Token
        previous: Token
        hadError*: bool
        panicMode: bool


proc initParser*(source: string): Parser
proc error*(p: var Parser, message: string, hint: string = ""): void
proc advance(p: var Parser): void
proc check(p: var Parser, kind: TokenKind): bool
proc match(p: var Parser, kinds: varargs[TokenKind]): bool
proc consume(p: var Parser, kind: TokenKind, msg: string): bool
proc synchronize*(p: var Parser): void
proc expect*(p: var Parser, kind: TokenKind, message: string): Token


proc initParser*(source: string): Parser =
    ## Initializes the parser with the given source code.
    result.lexer = initLexer(source)
    result.hadError = false
    result.panicMode = false
    result.advance()  # Load first token


proc error*(p: var Parser, message: string, hint: string = ""): void =
    ## Report an error at the current token
    if p.panicMode:
        return  # Already in error recovery
    
    p.panicMode = true
    p.hadError = true

    let err: ref CompileError = newCompileError(
        ekSyntax,
        p.current.line,
        p.current.column,
        message,
        hint.strip()
    )

    echo formatError(err)


proc advance(p: var Parser): void =
    ## Advances to the next token, updating the current and previous tokens.
    p.previous = p.current
    p.current = p.lexer.nextToken()

    # Skip invalid tokens and report them
    while p.current.kind == tkInvalid:
        p.error("Invalid token: " & p.current.lexeme)
        p.current = p.lexer.nextToken()


proc check(p: var Parser, kind: TokenKind): bool =
    ## Checks if the current token matches the expected kind.
    result = p.current.kind == kind


proc match(p: var Parser, kinds: varargs[TokenKind]): bool = 
    ## Checks if the current token matches any of the expected kinds and advances if it does.
    for kind in kinds:
        if p.check(kind):
            p.advance()
            return true
    return false


proc consume(p: var Parser, kind: TokenKind, msg: string): bool =
    ## Consume a token of the given kind, or report an error
    if p.check(kind):
        p.advance()
        return true
    
    p.error(msg)
    return false


proc synchronize*(p: var Parser): void =
    ## Skip tokens until we reach a statement boundary for error recovery
    p.panicMode = false
    
    while p.current.kind != tkEof:
        if p.previous.kind == tkRBrace:
            return
        
        case p.current.kind
        of tkProc, tkVar, tkConst, tkType, tkIf, tkWhile, tkFor, tkReturn:
            return
        else:
            p.advance()


proc expect*(p: var Parser, kind: TokenKind, message: string): Token =
    ## Like consume but returns the consumed token for use
    if p.check(kind):
        result = p.current
        p.advance()
    else:
        p.error(message)
        result = p.current  # Return current token even on error


#[ 
error() - report error at current token
consume() - expect and consume a token
synchronize() - recover from errors
expect() - consume and return token
 ]#

# Parsing

# Toplevel
proc parse*(p: var Parser): Node
proc parseDeclaration(p: var Parser): Node
# Declarations
proc parseVarDecl(p: var Parser): Node
proc parseConstDecl(p: var Parser): Node
proc parseProcDecl(p: var Parser, pragmas: seq[Node]): Node
proc parseTypeDecl(p: var Parser): Node
proc parsePragma(p: var Parser): Node
proc parseParamList(p: var Parser): seq[Node] # List of nkFieldDecl
proc parseFieldDecl(p: var Parser): Node
# Types
proc parseTypeExpr(p: var Parser): Node
proc parseObjectType(p: var Parser): Node # object { ... }
# Statements
proc parseStatement(p: var Parser): Node
proc parseBlock(p: var Parser): Node # { ... }
proc parseIfStmt(p: var Parser): Node # if / elif / else
proc parseWhileStmt(p: var Parser): Node
proc parseForStmt(p: var Parser): Node
proc parsereturnStmt(p: var Parser): Node
proc parseAssignstmt(p: var Parser): Node
proc parseCallStmt(p: var Parser): Node
proc parseAsmStmt(p: var Parser): Node
# Expressions Pratt parser with precedence climbing
proc parseExpression(p: var Parser, precedence: int = 0): Node
proc parsePrefix(p: var Parser): Node
proc parseInfix(p: var Parser, left: Node): Node
proc getPrecedence(p: var Parser): int
proc parsePrimary(p: var Parser): Node
proc parseCallExpr(p: var Parser, callee: Node): Node
proc parseMemberAccess(p: var Parser, obj: Node): Node
proc parseArrayAccess(p: var Parser, arr: Node): Node
proc parseUnaryOp(p: var Parser): Node
# Helpers
proc parseMemoryLocation(p: var Parser): Node
proc parseArrayLiteral(p: var Parser): Node
proc parseHwRegister(p: var Parser): Node
proc parsePragmaValue(p: var Parser): Node
# Utility
proc isAssignOp(p: var Parser): bool
proc isStartOfStatement(p: var Parser): bool
proc isStartOfExpression (p: var Parser): bool


# Top level parse function

proc parse*(p: var Parser): Node =
    ## Parsing entry point - returns the root AST node
    var declarations: seq[Node] = @[]

    # While not end of file, parse declarations
    while not p.check(tkEof):
        let decl: Node = p.parseDeclaration()
        if decl != nil: 
            declarations.add(decl)
        
        # If parse error, recover and continue parsing
        if p.panicMode:
            p.synchronize()

    result = Node(
        kind: nkProgram,
        declarations: declarations,
        line: 1,
        column: 1
    )


# Declarations

proc parseDeclaration(p: var Parser): Node =
    ## Parses top-level declarations
    # Handle pragmas
    var pragmas: seq[Node] = @[]
    while p.check(tkLBraceDot):
        pragmas.add(p.parsePragma())
    
    # Handle based on keywords
    case p.current.kind
    of tkVar:
        result = p.parseVarDecl()
    of tkConst:
        result = p.parseConstDecl()
    of tkProc:
        result = p.parseProcDecl(pragmas)
    of tkType:
        result = p.parseTypeDecl()
    else:
        p.error("Expected declaration")
        p.advance()
        result = nil


proc parseVarDecl(p: var Parser): Node =
    ## var nanme: type @ location = value
    let startLine: int = p.current.line
    let startCol: int = p.current.column
    
    # Consume "var"
    discard p.consume(tkVar, "Expected 'var' keyword")

    # Expect/parse identifier
    let nameToken: Token = p.expect(tkIdent, "Expected variable name")
    let name: string = nameToken.lexeme

    # Consume ":"
    discard p.consume(tkColon, "Expected ':' after variable name")

    # Expect/parse type expression
    let varType: Node = p.parseTypeExpr()
    if varType == nil:
        # Error should already be reported
        return nil

    # Optional Memory Location
    # @ location
    # Example @ wram:0xC000
    var location: Node = nil
    if p.match(tkAt):
        # match() advances if tkAt is present

        # Expect/parse memory location
        let region: Token = p.expect(tkIdent, "Expected memory region after '@'")
        discard p.consume(tkColon, "Expected ':' after memory region") 
        let address: Token = p.expect(tkIntLit, "Expected address after memory region and ':'")

        location = Node(
            kind: nkMemoryLocation,
            memRegion: region.normalized,
            memAddress: Node(
                kind: nkIntLit,
                intVal: parseBiggestInt(address.lexeme), # Convert string to int, will report error if invalid number
                line: address.line,
                column: address.column
            ),
            line: region.line,
            column: region.column,
        )
    
    # Expect/parse value initializer (optional)
    var initValue: Node = nil
    # match() advances if tkEqual is present
    if p.match(tkEqual):
        initValue = p.parseExpression()
        if initValue == nil:
            # Error should already be reported
            return nil
    
    # Build VarDecl Node
    result = Node(
        kind: nkVarDecl,
        varName: name,
        varType: varType,
        varLocation: location,
        varInit: initValue,
        line: startLine,
        column: startCol
    )


proc parseConstDecl(p: var Parser): Node =
    ## const name: type @ location = value
    discard
    
    #[ # Consume "const"
    discard p.consume(tkConst, "Expected 'const' keyword")

    # Expect/parse identifier
    let nameToken: Token = p.expect(tkIdent, "Expected constant name")
    let name: string = nameToken.lexeme

    # Consume ":"
    discard p.consume(tkColon, "Expected ':' after constant name")

    let constType: Node = p.parseTypeExpr()
    if constType == nil:
        return nil ]#

proc parseProcDecl(p: var Parser, pragmas: seq[Node]): Node = 
    ## proc name(params) { body }
    discard


proc parseTypeDecl(p: var Parser): Node = 
    ## var temp: type
    discard


proc parsePragma(p: var Parser): Node = 
    ## Such as: {.bank: 0.}
    discard


proc parseParamList(p: var Parser): seq[Node] =
    ## List of parameters in procedure declaration
    discard


proc parseFieldDecl(p: var Parser): Node =
    ## Single field in record/object type
    discard


# Types

proc parseTypeExpr(p: var Parser): Node =
    # Type expressions: uint8, array[256, uint8], CustomType, etc.
    let startLine: int = p.current.line
    let startCol: int = p.current.column

    case p.current.kind
    of tkIdent:
        # Simple type identifier: uint8, int16, MyType
        let typeName: string = p.current.normalized
        p.advance() # Keep for reporting
        
        result = Node(
            kind: nkTypeIdent,
            typeIdent: typeName,
            line: startLine,
            column: startCol
        )

    of tkArray:
        # Array type: array[size, elementType]
        p.advance()  # advances  "array" keyword
        # consume "["
        discard p.consume(tkLBracket, "Expected '[' after 'array'")
        # TODO: parse array size and element type
        discard
    else:
        p.error("Expected type expression")
        result = nil


proc parseObjectType(p: var Parser): Node =
    ## Parse object type definition
    discard



# Statements

proc parseStatement(p: var Parser): Node =
    ## Parse a statement
    discard


proc parseBlock(p: var Parser): Node =
    ## Parse block: { statements }
    discard


proc parseIfStmt(p: var Parser): Node =
    ## Parse if statement
    discard


proc parseWhileStmt(p: var Parser): Node =
    ## Parse while loop
    discard


proc parseForStmt(p: var Parser): Node =
    ## Parse for loop
    discard


proc parsereturnStmt(p: var Parser): Node =
    ## Parse return statement
    discard


proc parseAssignstmt(p: var Parser): Node =
    ## Parse assignment or compound assignment
    discard


proc parseCallStmt(p: var Parser): Node =
    ## Parse procedure call as statement
    discard


proc parseAsmStmt(p: var Parser): Node =
    ## Parse inline assembly
    discard


# Expressions (Pratt Parser)

proc parseExpression(p: var Parser, precedence: int = 0): Node =
    ## Parse expression with operator precedence climbing
    discard


proc parsePrefix(p: var Parser): Node =
    ## Parse prefix expressions
    discard


proc parseInfix(p: var Parser, left: Node): Node =
    ## Parse infix operators
    discard


proc getPrecedence(p: var Parser): int =
    ## Get precedence of current operator
    discard


proc parsePrimary(p: var Parser): Node =
    ## Parse primary expressions
    discard


proc parseCallExpr(p: var Parser, callee: Node): Node =
    ## Parse function call
    discard


proc parseMemberAccess(p: var Parser, obj: Node): Node =
    ## Parse member access: obj.field
    discard


proc parseArrayAccess(p: var Parser, arr: Node): Node =
    ## Parse array access: arr[index]
    discard


proc parseUnaryOp(p: var Parser): Node =
    ## Parse unary operators
    discard


# Helpers

proc parseMemoryLocation(p: var Parser): Node =
    ## Parse memory location
    discard


proc parseArrayLiteral(p: var Parser): Node =
    ## Parse array literal
    discard


proc parseHwRegister(p: var Parser): Node =
    ## Parse hardware register
    discard


proc parsePragmaValue(p: var Parser): Node =
    ## Parse pragma value
    discard


# Utility

proc isAssignOp(p: var Parser): bool =
    ## Check if current token is assignment operator
    discard


proc isStartOfStatement(p: var Parser): bool =
    ## Check if current token starts a statement
    discard


proc isStartOfExpression(p: var Parser): bool =
    ## Check if current token starts an expression
    discard
