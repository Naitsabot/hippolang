# Recursive decent with Pratt Parser (operator preference)

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


proc initParser*(source: string): Parser =
    ## Initializes the parser with the given source code.
    result.lexer = initLexer(source)
    result.hadError = false
    result.panicMode = false
    result.advance()  # Load first token


proc error*(p: var Parser, message: string) =
    ## Report an error at the current token
    if p.panicMode:
        return  # Already in error recovery
    
    p.panicMode = true
    p.hadError = true
    
    stderr.write fmt"[line {p.current.line}] Error"
    
    if p.current.kind == tkEof:
        stderr.write " at end"
    else:
        stderr.write fmt" at '{p.current.lexeme}'"
    
    stderr.writeLine ": " & message


proc errorAt*(p: var Parser, token: Token, message: string) =
    ## Report an error at a specific token
    if p.panicMode:
        return
    
    p.panicMode = true
    p.hadError = true
    
    stderr.write fmt"[line {token.line}] Error at '{token.lexeme}': {message}"
    stderr.writeLine ""


proc errorAtPrevious*(p: var Parser, message: string) =
    ## Report an error at the previous token
    p.errorAt(p.previous, message)


proc advance(p: var Parser) =
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


proc match(p: var Parser, kind: varargs[TokenKind]): bool = 
    ## Checks if the current token matches any of the expected kinds and advances if it does.
    for kind in kinds:
        if p.check(kind):
            p.advance()
            return true
    return false


proc consume(p: var Parser, kind: TokenKind, msg: string) =
    ## Consume a token of the given kind, or report an error
    if p.check(kind):
        p.advance()
        return true
    
    p.error(message)
    return false


proc synchronize*(p: var Parser) =
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





