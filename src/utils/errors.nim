type
    ErrorKind* = enum
        ekSyntax
        ekUnexpectedToken
        ekUnterminatedString
        ekInvalidNumber
        ekGeneral
    
    CompileError* = object of CatchableError
        kind*: ErrorKind
        line*: int
        column*: int
        message*: string
        hint*: string


proc newCompileError*(kind: ErrorKind, line, column: int, 
                      message: string, hint: string = ""): ref CompileError =
    result = newException(CompileError, message)
    result.kind = kind
    result.line = line
    result.column = column
    result.message = message
    result.hint = hint


proc formatError*(err: ref CompileError): string =
    result = "Error at line " & $err.line & ", column " & $err.column & ": " & err.message
    if err.hint.len > 0:
        result &= "\nHint: " & err.hint

#[
# Basic usage
let err: ref CompileError = newCompileError(
    ekUnexpectedToken,
    line = 5,
    column = 12,
    message = "Expected ':' after variable name",
    hint = "Variable declarations need a type annotation"
)
echo formatError(err)
# Output:
# Error at line 5, column 12: Expected ':' after variable name
# Hint: Variable declarations need a type annotation
]#