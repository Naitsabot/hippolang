import std/[unittest, strformat]
import ../src/lexer

suite "Lexer Tests":
    
    suite "Basic Tokens":
        test "Keywords":
            var lex = initLexer("var const proc type object array if elif else while for in return asm addr")
            let expected = [
                tkVar, tkConst, tkProc, tkType, tkObject, tkArray,
                tkIf, tkElif, tkElse, tkWhile, tkFor, tkIn, tkReturn,
                tkAsm, tkAddr, tkEof
            ]
            
            for exp in expected:
                let tok = lex.nextToken()
                check tok.kind == exp
        
        test "Word Operators":
            var lex = initLexer("and or not xor shl shr div mod")
            let expected = [
                tkAnd, tkOr, tkNot, tkXor, tkShl, tkShr, tkDiv, tkMod, tkEof
            ]
            
            for exp in expected:
                let tok = lex.nextToken()
                check tok.kind == exp
        
        test "Boolean Literals":
            var lex = initLexer("true false")
            check lex.nextToken().kind == tkTrue
            check lex.nextToken().kind == tkFalse
            check lex.nextToken().kind == tkEof
    
    suite "Operators and Symbols":
        test "Arithmetic Operators":
            var lex = initLexer("+ - * += -= *=")
            check lex.nextToken().kind == tkPlus
            check lex.nextToken().kind == tkMinus
            check lex.nextToken().kind == tkStar
            check lex.nextToken().kind == tkPlusEqual
            check lex.nextToken().kind == tkMinusEqual
            check lex.nextToken().kind == tkStarEqual
            check lex.nextToken().kind == tkEof
        
        test "Comparison Operators":
            var lex = initLexer("== != < > <= >=")
            check lex.nextToken().kind == tkEqualEqual
            check lex.nextToken().kind == tkNotEqual
            check lex.nextToken().kind == tkLess
            check lex.nextToken().kind == tkGreater
            check lex.nextToken().kind == tkLessEqual
            check lex.nextToken().kind == tkGreaterEqual
            check lex.nextToken().kind == tkEof
        
        test "Punctuation":
            var lex = initLexer(". , : @ ( ) { } [ ]")
            check lex.nextToken().kind == tkDot
            check lex.nextToken().kind == tkComma
            check lex.nextToken().kind == tkColon
            check lex.nextToken().kind == tkAt
            check lex.nextToken().kind == tkLParen
            check lex.nextToken().kind == tkRParen
            check lex.nextToken().kind == tkLBrace
            check lex.nextToken().kind == tkRBrace
            check lex.nextToken().kind == tkLBracket
            check lex.nextToken().kind == tkRBracket
            check lex.nextToken().kind == tkEof
        
        test "Special Tokens":
            var lex = initLexer("..< {. .}")
            check lex.nextToken().kind == tkDotDotLess
            check lex.nextToken().kind == tkLBraceDot
            check lex.nextToken().kind == tkDotRBrace
            check lex.nextToken().kind == tkEof
    
    suite "Literals":
        test "Decimal Numbers":
            var lex = initLexer("0 123 456789")
            
            var tok = lex.nextToken()
            check tok.kind == tkIntLit
            check tok.lexeme == "0"
            
            tok = lex.nextToken()
            check tok.kind == tkIntLit
            check tok.lexeme == "123"
            
            tok = lex.nextToken()
            check tok.kind == tkIntLit
            check tok.lexeme == "456789"
        
        test "Hexadecimal Numbers":
            var lex = initLexer("0x00 0xFF 0xABCD 0X1234")
            
            var tok = lex.nextToken()
            check tok.kind == tkIntLit
            check tok.lexeme == "0x00"
            
            tok = lex.nextToken()
            check tok.kind == tkIntLit
            check tok.lexeme == "0xFF"
            
            tok = lex.nextToken()
            check tok.kind == tkIntLit
            check tok.lexeme == "0xABCD"
            
            tok = lex.nextToken()
            check tok.kind == tkIntLit
            check tok.lexeme == "0X1234"
        
        test "Binary Numbers":
            var lex = initLexer("0b0 0b1010 0B11111111")
            
            var tok = lex.nextToken()
            check tok.kind == tkIntLit
            check tok.lexeme == "0b0"
            
            tok = lex.nextToken()
            check tok.kind == tkIntLit
            check tok.lexeme == "0b1010"
            
            tok = lex.nextToken()
            check tok.kind == tkIntLit
            check tok.lexeme == "0B11111111"
        
        test "String Literals":
            var lex = initLexer("""
                "hello"
                "world with spaces"
                "with\nnewline"
                "with\ttab"
                "with\"quote"
                "with\\backslash"
            """)
            
            var tok = lex.nextToken()
            check tok.kind == tkStringLit
            check tok.lexeme == "hello"
            
            tok = lex.nextToken()
            check tok.kind == tkStringLit
            check tok.lexeme == "world with spaces"
            
            tok = lex.nextToken()
            check tok.kind == tkStringLit
            check tok.lexeme == "with\nnewline"
            
            tok = lex.nextToken()
            check tok.kind == tkStringLit
            check tok.lexeme == "with\ttab"
            
            tok = lex.nextToken()
            check tok.kind == tkStringLit
            check tok.lexeme == "with\"quote"
            
            tok = lex.nextToken()
            check tok.kind == tkStringLit
            check tok.lexeme == "with\\backslash"
        
        test "Unterminated String":
            var lex = initLexer(""""unterminated""")
            let tok = lex.nextToken()
            check tok.kind == tkInvalid
            check tok.lexeme == "unterminated string"
    
    suite "Identifiers":
        test "Simple Identifiers":
            var lex = initLexer("x foo bar123 _private myVar")
            
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkEof
        
        test "Identifier Normalization - Case Insensitive":
            var lex = initLexer("playerHealth PlayerHealth PLAYERHEALTH")
            
            var tok1 = lex.nextToken()
            var tok2 = lex.nextToken()
            var tok3 = lex.nextToken()
            
            check tok1.kind == tkIdent
            check tok2.kind == tkIdent
            check tok3.kind == tkIdent
            
            # All normalize to the same thing
            check tok1.normalized == "playerhealth"
            check tok2.normalized == "playerhealth"
            check tok3.normalized == "playerhealth"
            
            # But preserve original lexeme
            check tok1.lexeme == "playerHealth"
            check tok2.lexeme == "PlayerHealth"
            check tok3.lexeme == "PLAYERHEALTH"
        
        test "Identifier Normalization - Underscore Removal":
            var lex = initLexer("player_health playerHealth player___health")
            
            var tok1 = lex.nextToken()
            var tok2 = lex.nextToken()
            var tok3 = lex.nextToken()
            
            # All normalize to the same thing
            check tok1.normalized == "playerhealth"
            check tok2.normalized == "playerhealth"
            check tok3.normalized == "playerhealth"
            
            # But preserve original lexeme
            check tok1.lexeme == "player_health"
            check tok2.lexeme == "playerHealth"
            check tok3.lexeme == "player___health"
        
        test "Keyword Case Insensitivity":
            var lex = initLexer("Var VAR var Proc PROC proc")
            
            check lex.nextToken().kind == tkVar
            check lex.nextToken().kind == tkVar
            check lex.nextToken().kind == tkVar
            check lex.nextToken().kind == tkProc
            check lex.nextToken().kind == tkProc
            check lex.nextToken().kind == tkProc
    
    suite "Comments":
        test "Single Line Comment":
            var lex = initLexer("var # this is a comment\nx")
            check lex.nextToken().kind == tkVar
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkEof
        
        test "Comment at End of File":
            var lex = initLexer("var x # comment")
            check lex.nextToken().kind == tkVar
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkEof
        
        test "Multiple Comments":
            var lex = initLexer("""
                # First comment
                var x # inline comment
                # Another comment
                const y
            """)
            check lex.nextToken().kind == tkVar
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkConst
            check lex.nextToken().kind == tkIdent
    
    suite "Whitespace Handling":
        test "Various Whitespace":
            var lex = initLexer("var   x\n\t\ty\r\n  z")
            check lex.nextToken().kind == tkVar
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkEof
        
        test "Empty Input":
            var lex = initLexer("")
            check lex.nextToken().kind == tkEof
        
        test "Only Whitespace":
            var lex = initLexer("   \n\t\r\n  ")
            check lex.nextToken().kind == tkEof
        
        test "Only Comments":
            var lex = initLexer("# comment1\n# comment2")
            check lex.nextToken().kind == tkEof
    
    suite "Line and Column Tracking":
        test "Single Line":
            var lex = initLexer("var x")
            
            var tok = lex.nextToken()
            check tok.line == 1
            check tok.column == 1
            
            tok = lex.nextToken()
            check tok.line == 1
            check tok.column == 5
        
        test "Multiple Lines":
            var lex = initLexer("var\nx\ny")
            
            var tok = lex.nextToken()
            check tok.line == 1
            
            tok = lex.nextToken()
            check tok.line == 2
            
            tok = lex.nextToken()
            check tok.line == 3
        
        test "Complex Positioning":
            var lex = initLexer("""var playerHealth: uint8
const MaxLives = 3""")
            
            var tok = lex.nextToken()  # var
            check tok.line == 1
            check tok.column == 1
            
            tok = lex.nextToken()  # playerHealth
            check tok.line == 1
            check tok.column == 5
            
            tok = lex.nextToken()  # :
            check tok.line == 1
            
            tok = lex.nextToken()  # uint8
            check tok.line == 1
            
            tok = lex.nextToken()  # const
            check tok.line == 2
            check tok.column == 1
    
    suite "Real Code Examples":
        test "Variable Declaration":
            var lex = initLexer("var health: uint8 @ wram:0xC000")
            
            check lex.nextToken().kind == tkVar
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkColon
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkAt
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkColon
            check lex.nextToken().kind == tkIntLit
        
        test "Procedure Declaration":
            var lex = initLexer("proc update(delta: uint16) {")
            
            check lex.nextToken().kind == tkProc
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkLParen
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkColon
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkRParen
            check lex.nextToken().kind == tkLBrace
        
        test "Type Definition":
            var lex = initLexer("""
type Sprite = object {
    x: uint8
    y: uint8
}
""")
            check lex.nextToken().kind == tkType
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkEqual
            check lex.nextToken().kind == tkObject
            check lex.nextToken().kind == tkLBrace
            check lex.nextToken().kind == tkIdent  # x
            check lex.nextToken().kind == tkColon
            check lex.nextToken().kind == tkIdent  # uint8
            check lex.nextToken().kind == tkIdent  # y
            check lex.nextToken().kind == tkColon
            check lex.nextToken().kind == tkIdent  # uint8
            check lex.nextToken().kind == tkRBrace
        
        test "If Statement":
            var lex = initLexer("""
if health > 0 {
    health -= 1
} elif health == 0 {
    gameOver()
} else {
    reset()
}
""")
            check lex.nextToken().kind == tkIf
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkGreater
            check lex.nextToken().kind == tkIntLit
            check lex.nextToken().kind == tkLBrace
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkMinusEqual
            check lex.nextToken().kind == tkIntLit
            check lex.nextToken().kind == tkRBrace
            check lex.nextToken().kind == tkElif
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkEqualEqual
            check lex.nextToken().kind == tkIntLit
            check lex.nextToken().kind == tkLBrace
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkLParen
            check lex.nextToken().kind == tkRParen
            check lex.nextToken().kind == tkRBrace
            check lex.nextToken().kind == tkElse
        
        test "For Loop":
            var lex = initLexer("for i in 0..<10 {")
            
            check lex.nextToken().kind == tkFor
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkIn
            check lex.nextToken().kind == tkIntLit
            check lex.nextToken().kind == tkDotDotLess
            check lex.nextToken().kind == tkIntLit
            check lex.nextToken().kind == tkLBrace
        
        test "Pragma":
            var lex = initLexer("{.bank: 2.}")
            
            check lex.nextToken().kind == tkLBraceDot
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkColon
            check lex.nextToken().kind == tkIntLit
            check lex.nextToken().kind == tkDotRBrace
        
        test "Array Declaration":
            var lex = initLexer("var buffer: array[256, uint8]")
            
            check lex.nextToken().kind == tkVar
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkColon
            check lex.nextToken().kind == tkArray
            check lex.nextToken().kind == tkLBracket
            check lex.nextToken().kind == tkIntLit
            check lex.nextToken().kind == tkComma
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkRBracket
        
        test "Hardware Register Access":
            var lex = initLexer("hw.lcdControl = 0x91")
            
            check lex.nextToken().kind == tkIdent  # hw
            check lex.nextToken().kind == tkDot
            check lex.nextToken().kind == tkIdent  # lcdControl
            check lex.nextToken().kind == tkEqual
            check lex.nextToken().kind == tkIntLit
        
        test "Bitwise Expression":
            var lex = initLexer("(input and 0x01) != 0")
            
            check lex.nextToken().kind == tkLParen
            check lex.nextToken().kind == tkIdent
            check lex.nextToken().kind == tkAnd
            check lex.nextToken().kind == tkIntLit
            check lex.nextToken().kind == tkRParen
            check lex.nextToken().kind == tkNotEqual
            check lex.nextToken().kind == tkIntLit
        
        test "Complete Procedure":
            var lex = initLexer("""
{.inline.}
proc waitVblank() {
    while (hw.lcdStat and 0x03) != 0x01 {}
}
""")
            check lex.nextToken().kind == tkLBraceDot
            check lex.nextToken().kind == tkIdent  # inline
            check lex.nextToken().kind == tkDotRBrace
            check lex.nextToken().kind == tkProc
            check lex.nextToken().kind == tkIdent  # waitVblank
            check lex.nextToken().kind == tkLParen
            check lex.nextToken().kind == tkRParen
            check lex.nextToken().kind == tkLBrace
            check lex.nextToken().kind == tkWhile
            check lex.nextToken().kind == tkLParen
            check lex.nextToken().kind == tkIdent  # hw
            check lex.nextToken().kind == tkDot
            check lex.nextToken().kind == tkIdent  # lcdStat
    
    suite "Error Cases":
        test "Invalid Character":
            var lex = initLexer("var x $ y")
            check lex.nextToken().kind == tkVar
            check lex.nextToken().kind == tkIdent
            
            let invalid = lex.nextToken()
            check invalid.kind == tkInvalid
            check invalid.lexeme == "$"
            
            check lex.nextToken().kind == tkIdent
        
        test "Invalid Exclamation Without Equal":
            var lex = initLexer("!")
            let tok = lex.nextToken()
            check tok.kind == tkInvalid
            check tok.lexeme == "!"
    
    suite "Iterator Test":
        test "Token Iterator":
            var lex = initLexer("var x: uint8")
            var kinds: seq[TokenKind] = @[]
            
            for token in lex.tokens():
                kinds.add(token.kind)
            
            check kinds == @[tkVar, tkIdent, tkColon, tkIdent, tkEof]
        
        test "Empty Iterator":
            var lex = initLexer("")
            var count = 0
            
            for token in lex.tokens():
                inc count
            
            check count == 1  # Just EOF
