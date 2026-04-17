import parser
import ast


when isMainModule:
    let source = """
    var x: uint8
    var health: uint8 @ wram:0xC000
    var lives: uint8 = 3
    var buffer: array[256, uint8]
    """
    var p = initParser(source)
    let tree = p.parse()
    if p.hadError:
        echo "Parsing failed with errors."
    else:
        echo "Parsing succeeded. AST:"
        echo tree