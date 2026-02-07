# Package

version       = "0.1.0"
author        = "Your Name"
description   = "Hippo - A Nim-inspired systems language compiler for Game Boy (SM83)"
license       = "MIT"
srcDir        = "src"
bin           = @["hippo"]


# Dependencies

requires "nim >= 2.0.0"


# Tasks

task test, "Run tests":
  exec "nim c -r tests/test_lexer.nim"
