import std/unittest
import ../src/[parser, ast, lexer]

suite "Parser Tests - Variables":
    test "Simple variable declaration":
        let source = "var x: uint8"
        var p = initParser(source)
        let ast = p.parse()
        
        check not p.hadError
        check ast.kind == nkProgram
        check ast.declarations.len == 1
        check ast.declarations[0].kind == nkVarDecl
        check ast.declarations[0].varName == "x"
        check ast.declarations[0].varType.kind == nkTypeIdent
        check ast.declarations[0].varType.typeIdent == "uint8"
    
    test "Variable with memory location":
        let source = "var health: uint8 @ wram:0xC000"
        var p = initParser(source)
        let ast = p.parse()
        
        check not p.hadError
        let varDecl = ast.declarations[0]
        check varDecl.kind == nkVarDecl
        check varDecl.varLocation != nil
        check varDecl.varLocation.kind == nkMemoryLocation
        check varDecl.varLocation.memRegion == "wram"
    
    test "Variable with initialization":
        let source = "var lives: uint8 = 3"
        var p = initParser(source)
        let ast = p.parse()
        
        check not p.hadError
        let varDecl = ast.declarations[0]
        check varDecl.varInit != nil
        check varDecl.varInit.kind == nkIntLit
        check varDecl.varInit.intVal == 3
    
    test "Array type":
        let source = "var buffer: array[256, uint8]"
        var p = initParser(source)
        let ast = p.parse()
        
        check not p.hadError
        let varDecl = ast.declarations[0]
        check varDecl.varType.kind == nkArrayType
        check varDecl.varType.arraySize.kind == nkIntLit
        check varDecl.varType.arrayElementType.kind == nkTypeIdent
