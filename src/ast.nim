import lexer # TokenKind


type
    NodeKind* = enum
        ## Different kinds of AST nodes
        # Declarations
        nkProgram
        nkVarDecl
        nkConstDecl
        nkProcDecl
        nkTypeDecl
        nkFieldDecl

        # Types
        nkTypeIdent  # uint8, int16, etc.
        nkArrayType  # array[N,T]
        nkObjectType # object { ... }

        # Statements
        nkBlock
        nkIfStmt
        nkWhileStmt
        nkForStmt
        nkReturnStmt
        nkAssignStmt
        nkCallStmt # Proc call as a statement
        nkAsmStmt  # inline assembly

        # Expressions
        nkBinaryOp     # a + b, a * b, etc.
        nkUnaryOp      # -a, not a
        nkCall         # func(args)
        nkMemberAccess # obj.field
        nkArrayAccess  # arr[index]
        nkDeref        # ptr[]
        nkAddrOf       # addr(x)

        # Literals
        nkIdent     # Identifier
        nkIntLit    # 123, 0xFF, 0b1010
        nkStringLit # "hellooooo"
        nkBoolLit   # true, false

        # Special
        nkMemoryLocation # @ wram:0xC000
        nkPragma         # {.bank: 2.}
        nkHwRegister     # hw.lcdControl
    
    Node* = object
        line*: int
        column*: int
        case kind*: NodeKind
        
        # Declarations
        of nkProgram:
            declarations*: seq[Node]

        of nkVarDecl:
            varName*: string
            varType*: Node
            varLocation*: Node  # Optional memory location, can be nil
            varInit*: Node      # Optional initializer, can be nil

        of nkConstDecl:
            constName*: string
            constType*: Node        # Can be nil, with type inference
            constLocation*: Node    # Optional memory location, can be nil
            constValue*: Node

        of nkProcDecl:
            procName*: string
            procPragmas*: seq[Node]  # Optional pragmas, {.inline.}, {.bank: 2.}, etc.
            procParams*: seq[Node]   # List of nkFieldDecl
            procReturnType*: Node    # Can be nil for procedures (void)
            procBody*: Node          # nkBlock

        of nkTypeDecl:
            typeName*: string
            typeDef*: Node  # nkObjectType or nkArrayType

        of nkFieldDecl:
            fieldName*: string
            fieldType*: Node
        
        # Types
        of nkTypeIdent:
            typeIdent*: string       # "uint8", "int16", etc.
        
        of nkArrayType:
            arraySize*: Node         # Always has a size in Hippo, nkIntLit or nkIdent (for const)
            arrayElementType*: Node
        
        of nkObjectType:
            objectFields*: seq[Node] # List of nkFieldDecl
        
        # Statements
        of nkBlock:
            statements*: seq[Node]
        
        of nkIfStmt:
            ifCond*: Node
            ifThen*: Node            # nkBlock
            ifElifs*: seq[tuple[cond: Node, body: Node]]
            ifElse*: Node            # Can be nil
        
        of nkWhileStmt:
            whileCond*: Node
            whileBody*: Node         # nkBlock
        
        of nkForStmt:
            forVar*: string
            forStart*: Node
            forEnd*: Node
            forBody*: Node           # nkBlock
        
        of nkReturnStmt:
            returnValue*: Node       # Can be nil
        
        of nkAssignStmt:
            assignTarget*: Node      # LValue
            assignOp*: TokenKind     # tkEqual, tkPlusEqual, etc.
            assignValue*: Node
        
        of nkCallStmt:
            callExpr*: Node          # nkCall
        
        of nkAsmStmt:
            asmCode*: string
        
        # Expressions
        of nkBinaryOp:
            binaryOp*: TokenKind     # tkPlus, tkAnd, etc.
            left*: Node
            right*: Node
        
        of nkUnaryOp:
            unaryOp*: TokenKind      # tkMinus, tkNot
            operand*: Node
        
        of nkCall:
            callee*: Node            # Usually nkIdent (can also be nkMemberAccess, Array of function pointers if added)
            args*: seq[Node]
        
        of nkMemberAccess:
            obj*: Node
            field*: string
        
        of nkArrayAccess:
            array*: Node
            index*: Node
        
        of nkDeref:
            derefExpr*: Node
        
        of nkAddrOf:
            addrExpr*: Node

        # Literals
        of nkIdent:
            ident*: string
        
        of nkIntLit:
             intVal*: int64           # Store as 64-bit, raw value, checked against type later
        
        of nkStringLit:
            strVal*: string
        
        of nkBoolLit:
            boolVal*: bool
        
        of nkMemoryLocation:
            memRegion*: string       # "wram", "rom0", etc.
            memAddress*: Node        # nkIntLit
        
        of nkPragma:
            pragmaName*: string
            pragmaValue*: Node       # Can be nil
        
        of nkHwRegister:
            hwRegName*: string       # "lcdControl", "joypad", etc.


# Convenience constructor for creating new (common) AST nodes

proc newNode*(kind: NodeKind, line, column: int): Node =
    ## Generic Node construtor
    Node(kind: kind, line: line, column: column)


proc newIdent*(name: string, line, column: int): Node =
    ## Creates a new identifier node
    Node(kind: nkIdent, ident: name, line: line, column: column)


proc newIntLit*(value: int64, line, column: int): Node =
    ## Creates a new integer literal node
    Node(kind: nkIntLit, intVal: value, line: line, column: column)


proc newBoolLit*(value: bool, line, column: int): Node =
    ## Creates a new boolean literal node
    Node(kind: nkBoolLit, boolVal: value, line: line, column: column)


proc newBinaryOp*(op: TokenKind, left, right: Node, line, column: int): Node =
    ## Creates a new binary operation node
    Node(kind: nkBinaryOp, binaryOp: op, left: left, right: right, line: line, column: column)


# Printing repr

proc `$`*(node: Node): string =
    case node.kind
    of nkIdent:
        result = "Ident(" & node.ident & ")"
    of nkIntLit:
        result = "IntLit(" & $node.intVal & ")"
    of nkBoolLit:
        result = "BoolLit(" & $node.boolVal & ")"
    of nkBinaryOp:
        result = "BinaryOp(" & $node.binaryOp & ", " & $node.left & ", " & $node.right & ")"
    of nkUnaryOp:
        result = "UnaryOp(" & $node.unaryOp & ", " & $node.operand & ")"
    of nkVarDecl:
        result = "VarDecl(" & node.varName & ": " & $node.varType & ")"
    else:
        result = $node.kind
