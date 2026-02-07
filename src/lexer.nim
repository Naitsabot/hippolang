import std/[strutils, tables]


type
    TokenKind* = enum
        ##  Represents the different kinds of tokens in the source code.
        # Literals
        tkIntLit
        tkStringLit
        tkTrue
        tkFalse
        
        # Identifiers
        tkIdent
        
        # Keywords
        tkVar
        tkConst
        tkProc
        tkType
        tkObject
        tkArray
        tkIf
        tkElif
        tkElse
        tkWhile
        tkFor
        tkIn
        tkReturn
        tkAsm
        tkAddr
        
        # Operators (word-based)
        tkAnd
        tkOr
        tkNot
        tkXor
        tkShl
        tkShr
        tkDiv
        tkMod
        
        # Symbols
        tkPlus          # +
        tkMinus         # -
        tkStar          # *
        tkEqual         # =
        tkPlusEqual     # +=
        tkMinusEqual    # -=
        tkStarEqual     # *=
        tkEqualEqual    # ==
        tkNotEqual      # !=
        tkLess          # 
        tkLessEqual     # <=
        tkGreater       # >
        tkGreaterEqual  # >=
        tkDot           # .
        tkDotDotLess    # ..
        tkComma         # ,
        tkColon         # :
        tkAt            # @
        tkLParen        # (
        tkRParen        # )
        tkLBrace        # {
        tkRBrace        # }
        tkLBracket      # [
        tkRBracket      # ]
        tkLBraceDot     # {.
        tkDotRBrace     # .}
        
        # Special
        tkEof
        tkInvalid

    Token* = object
        ## Represents a token in the source code.
        kind*: TokenKind 
        lexeme*: string # The actual text of the token
        normalized*: string  # Normalized form for keywords (lowercase, no underscores)
        line*: int # The line number where the token was found
        column*: int # The column number where the token starts
    
    Lexer* = object
        ## A simple lexer for tokenizing source code.
        source: string # The source code to be tokenized
        pos: int # The current position in the source code
        line: int # The current line number (starting from 1)
        column: int # The current column number (starting from 1)


proc normalizeIdent*(s: string): string =
    ## Normalize identifier: lowercase with underscores removed
    result = ""
    for c in s:
        if c != '_':
            result.add c.toLowerAscii()


# A set of keywords for quick lookup
const keywords = {
    "var": tkVar,
    "const": tkConst,
    "proc": tkProc,
    "type": tkType,
    "object": tkObject,
    "array": tkArray,
    "if": tkIf,
    "elif": tkElif,
    "else": tkElse,
    "while": tkWhile,
    "for": tkFor,
    "in": tkIn,
    "return": tkReturn,
    "and": tkAnd,
    "or": tkOr,
    "not": tkNot,
    "xor": tkXor,
    "shl": tkShl,
    "shr": tkShr,
    "div": tkDiv,
    "mod": tkMod,
    "true": tkTrue,
    "false": tkFalse,
    "asm": tkAsm,
    "addr": tkAddr,
}.toTable


proc initLexer*(source: string): Lexer =
    ## Initializes a new lexer with the given source code.
    result.source = source
    result.pos = 0
    result.line = 1
    result.column = 1


proc peek(lex: Lexer, offset = 0): char =
    ## Peeks at the next character in the source code without advancing the lexer.
    let pos = lex.pos + offset
    if pos < lex.source.len:
        result = lex.source[pos]
    else:
        result = '\0'


proc advance(lex: var Lexer): char =
    ## Advances the lexer to the next character in the source code.
    if lex.pos < lex.source.len:
        result = lex.source[lex.pos]
        inc lex.pos
        inc lex.column
        if result == '\n':
            inc lex.line
            lex.column = 1
    else:
        result = '\0'


proc skipWhitespace(lex: var Lexer) =
    # Skips over whitespace characters in the source code.
    while lex.peek() in {' ', '\t', '\n', '\r'}:
        discard lex.advance()


proc skipComment(lex: var Lexer) =
    ## Skips over comments in the source code.
    ## Comments are discarded until the end of the line.
    if lex.peek() == '#':
        while lex.peek() != '\n' and lex.peek() != '\0':
            discard lex.advance()
        if lex.peek() == '\n':
            discard lex.advance()


proc makeToken(lex: Lexer, kind: TokenKind, lexeme: string): Token =
    ## Creates a new token with the given kind and lexeme, 
    ## along with the current line and column information.
    Token(kind: kind, lexeme: lexeme, line: lex.line, column: lex.column)


proc lexNumber(lex: var Lexer): Token =
    ## Lexes a numeric literal from the source code, 
    ## handling decimal, hexadecimal, and binary formats.
    let startLine = lex.line
    let startCol = lex.column
    var lexeme = ""
    
    # Check for hex (0x) or binary (0b)
    if lex.peek() == '0' and lex.peek(1) in {'x', 'X', 'b', 'B'}:
        lexeme.add lex.advance()  # '0'
        lexeme.add lex.advance()  # 'x' or 'b'
        
        if lexeme[1] in {'x', 'X'}:
            # Hex number
            while lex.peek() in HexDigits:
                lexeme.add lex.advance()
        else:
            # Binary number
            while lex.peek() in {'0', '1'}:
                lexeme.add lex.advance()
    else:
        # Decimal number
        while lex.peek() in Digits:
            lexeme.add lex.advance()
    
    result = Token(kind: tkIntLit, lexeme: lexeme, line: startLine, column: startCol)


proc lexIdentifier(lex: var Lexer): Token =
    ## Lexes an identifier or keyword from the source code.
    let startLine = lex.line
    let startCol = lex.column
    var lexeme = ""
    
    while lex.peek() in IdentChars + Digits:
        lexeme.add lex.advance()
    
    # Normalize for keyword lookup
    let normalized = normalizeIdent(lexeme)
    # Check if it's a keyword
    let kind = keywords.getOrDefault(normalized, tkIdent)
    # Keep original lexeme for display, but store normalized for comparison
    result = Token(kind: kind, lexeme: lexeme, normalized: normalized, line: startLine, column: startCol)


proc lexString(lex: var Lexer): Token =
    ## Lexes a string literal from the source code, handling escape sequences.
    let startLine = lex.line
    let startCol = lex.column
    var lexeme = ""
    
    discard lex.advance()  # Opening "
    
    while lex.peek() != '"' and lex.peek() != '\0':
        if lex.peek() == '\\':
            discard lex.advance()
            case lex.peek()
            of 'n': lexeme.add '\n'
            of 'r': lexeme.add '\r'
            of 't': lexeme.add '\t'
            of '"': lexeme.add '"'
            of '\\': lexeme.add '\\'
            else: lexeme.add lex.peek()
            discard lex.advance()
        else:
            lexeme.add lex.advance()
    
    if lex.peek() == '"':
        discard lex.advance()  # Closing "
    else:
        # Error: unterminated string
        return Token(kind: tkInvalid, lexeme: "unterminated string", 
                    line: startLine, column: startCol)
    
    result = Token(kind: tkStringLit, lexeme: lexeme, line: startLine, column: startCol)


proc nextToken*(lex: var Lexer): Token =
    ## Retrieves the next token from the source code, skipping whitespace and comments.
    lex.skipWhitespace()
    
    # Skip comments
    while lex.peek() == '#':
        lex.skipComment()
        lex.skipWhitespace()
    
    if lex.peek() == '\0':
        return lex.makeToken(tkEof, "")
    
    let startLine = lex.line
    let startCol = lex.column
    let c = lex.peek()
    
    # Numbers
    if c in Digits:
        return lex.lexNumber()
    
    # Identifiers and keywords
    if c in IdentStartChars:
        return lex.lexIdentifier()
    
    # Strings
    if c == '"':
        return lex.lexString()
    
    # Two-character operators
    case c
    of '+':
        discard lex.advance()
        if lex.peek() == '=':
            discard lex.advance()
            return lex.makeToken(tkPlusEqual, "+=")
        return lex.makeToken(tkPlus, "+")
    of '-':
        discard lex.advance()
        if lex.peek() == '=':
            discard lex.advance()
            return lex.makeToken(tkMinusEqual, "-=")
        return lex.makeToken(tkMinus, "-")
    of '*':
        discard lex.advance()
        if lex.peek() == '=':
            discard lex.advance()
            return lex.makeToken(tkStarEqual, "*=")
        return lex.makeToken(tkStar, "*")
    of '=':
        discard lex.advance()
        if lex.peek() == '=':
            discard lex.advance()
            return lex.makeToken(tkEqualEqual, "==")
        return lex.makeToken(tkEqual, "=")
    of '!':
        discard lex.advance()
        if lex.peek() == '=':
            discard lex.advance()
            return lex.makeToken(tkNotEqual, "!=")
        return lex.makeToken(tkInvalid, "!")
    of '<':
        discard lex.advance()
        if lex.peek() == '=':
            discard lex.advance()
            return lex.makeToken(tkLessEqual, "<=")
        return lex.makeToken(tkLess, "<")
    of '>':
        discard lex.advance()
        if lex.peek() == '=':
            discard lex.advance()
            return lex.makeToken(tkGreaterEqual, ">=")
        return lex.makeToken(tkGreater, ">")
    of '.':
        discard lex.advance()
        if lex.peek() == '.':
            discard lex.advance()
            if lex.peek() == '<':
                discard lex.advance()
                return lex.makeToken(tkDotDotLess, "..<")
        elif lex.peek() == '}':
            discard lex.advance()
            return lex.makeToken(tkDotRBrace, ".}")
        return lex.makeToken(tkDot, ".")
    of '{':
        discard lex.advance()
        if lex.peek() == '.':
            discard lex.advance()
            return lex.makeToken(tkLBraceDot, "{.")
        return lex.makeToken(tkLBrace, "{")
    
    # Single character tokens
    of ',':
        discard lex.advance()
        return lex.makeToken(tkComma, ",")
    of ':':
        discard lex.advance()
        return lex.makeToken(tkColon, ":")
    of '@':
        discard lex.advance()
        return lex.makeToken(tkAt, "@")
    of '(':
        discard lex.advance()
        return lex.makeToken(tkLParen, "(")
    of ')':
        discard lex.advance()
        return lex.makeToken(tkRParen, ")")
    of '}':
        discard lex.advance()
        return lex.makeToken(tkRBrace, "}")
    of '[':
        discard lex.advance()
        return lex.makeToken(tkLBracket, "[")
    of ']':
        discard lex.advance()
        return lex.makeToken(tkRBracket, "]")
    else:
        discard lex.advance()
        return Token(kind: tkInvalid, lexeme: $c, line: startLine, column: startCol)


# Helper iterator for consuming all tokens
iterator tokens*(lex: var Lexer): Token =
    ## An iterator that yields all tokens from the source code until EOF is reached.
    while true:
        let tok = lex.nextToken()
        yield tok
        if tok.kind == tkEof:
            break
