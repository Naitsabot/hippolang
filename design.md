# Hippo Language Design Document (Nim-inspired)

## Overview
Hippo is a low-level programming language that compiles to SM83 assembly for the Nintendo Game Boy. It provides structured programming constructs while maintaining close-to-metal control over hardware.

## Design Philosophy
- Static memory allocation only
- Always optimize aggressively
- Explicit memory layout control
- No hidden costs or magic
- Direct hardware access
- Block-scoped variables with static allocation

---

## Types

### Primitive Types
```hippo
uint8      # Unsigned 8-bit integer
int8       # Signed 8-bit integer
uint16     # Unsigned 16-bit integer
int16      # Signed 16-bit integer
bool       # Boolean (true or false)
ptr        # 16-bit pointer
```

### Composite Types
```hippo
type Sprite = object {
    x: uint8
    y: uint8
    tile_id: uint8
    flags: uint8
}

# Arrays
var buffer: array[16, uint8]
var entities: array[40, Sprite]
```

---

## Memory Regions

### Address Space
```hippo
rom0: 0x0000..0x3FFF    # Fixed ROM bank
rom1: 0x4000..0x7FFF    # Switchable ROM banks
wram: 0xC000..0xDFFF    # Working RAM
hram: 0xFF80..0xFFFE    # High RAM (fast)
```

### Hardware Registers
```hippo
hw.joypad       # 0xFF00
hw.lcdControl   # 0xFF40
hw.lcdStat      # 0xFF41
hw.scrollY      # 0xFF42
hw.scrollX      # 0xFF43
# ... more hardware registers
```

---

## Variable Declarations

### Basic Variables
```hippo
# Compiler allocates location
var temp: uint8
var counter: uint16

# Explicit memory location
var lives: uint8 @ wram:0xC000
var score: uint16 @ wram:0xC001

# Arrays
var buffer: array[256, uint8] @ wram:0xC100

# Struct instances
var player: Sprite @ wram:0xC200
```

### Constants
```hippo
# ROM constants
const MaxLives = 3
const StartScore: uint16 = 0

# Constant arrays in ROM
const levelData: array[256, uint8] @ rom0:0x2000 = [...]

# Include binary data
const spriteData: array[uint8] @ rom0:0x4000 = includeBin("sprites.bin")
const tileSet: array[uint8] = includeTiles("tiles.png")
```

---

## Operators

### Arithmetic
```hippo
+  -  *  div  mod
```

### Bitwise
```hippo
and  or  xor  not  shl  shr
```

### Comparison
```hippo
==  !=  <  >  <=  >=
```

### Logical
```hippo
and  or  not
```

### Compound Assignment
```hippo
+=  -=  *=
```

### Pointer Operations
```hippo
addr(variable)    # Address of
variable[]        # Dereference
```

---

## Control Flow

### If Statements
```hippo
if condition {
    # code
}

if condition {
    # code
} else {
    # code
}

if condition {
    # code
} elif otherCondition {
    # code
} else {
    # code
}
```

### Loops
```hippo
# While loop
while condition {
    # code
}

# For loop (range-based)
for i in 0..<10 {
    # code
}

for i in start..<end {
    # code
}
```

---

## Procedures

### Basic Procedures
```hippo
proc functionName() {
    # code
}

proc add(a, b: uint8): uint8 {
    return a + b
}

proc updateSprite(x, y: uint8) {
    player.x = x
    player.y = y
}
```

### Procedure Calls
```hippo
updateSprite(10, 20)
var result = add(5, 3)
```

---

## Scoping Rules

### Module Scope
Top-level declarations are accessible throughout the module:
```hippo
var moduleVar: uint8

proc functionOne() {
    moduleVar = 10  # OK
}

proc functionTwo() {
    moduleVar = 20  # OK
}
```

### Block Scope
Variables declared in blocks are abandoned when leaving the block:
```hippo
proc example() {
    var a: uint8 = 5  # Lives until end of procedure
    
    if a > 3 {
        var b: uint8 = 10  # Abandoned at end of if block
        a = b
    }
    # b no longer exists here
    
    for i in 0..<10 {
        var temp = i * 2  # Abandoned each iteration
    }
    # temp no longer exists
}
```

All variables are statically allocated. When a variable goes out of scope, its memory can be reused.

---

## Pragmas (Meta Attributes)

### Bank Assignment
```hippo
{.bank: 0.}
proc main() {
    # Code in fixed ROM bank 0
}

{.bank: 2.}
proc loadLevel(num: uint8) {
    # Code in ROM bank 2
}

{.bank: 3.}
const musicData: array[uint8] = includeBin("music.bin")
```

### Entry Point
```hippo
{.entry.}
proc main() {
    # Program starts here
}
```

### Inlining Hints
```hippo
{.inline.}
proc smallFunction() {
    # Strongly suggest inlining
}
```

### Interrupts
```hippo
{.interrupt: vblank.}
proc onVblank() {
    # VBlank interrupt handler
    # Cannot call functions in other banks
}

{.interrupt: timer.}
proc onTimer() {
    # Timer interrupt handler
}

# Available interrupts:
# vblank, lcdStat, timer, serial, joypad
```

### Bank Switch Control
```hippo
{.noBankSwitch.}
proc performanceCritical() {
    # Must be called from correct bank
    # No automatic bank switching code generated
}
```

### Data Annotations
```hippo
{.patchable.}
const difficulty: uint8 @ rom0:0x1000 = 5

{.lut.}
const sinTable: array[256, uint8] @ rom0:0x2000 = generateSin()

{.compressed.}
const level1: array[uint8] @ rom1:0x4000 = includeBin("level1.bin")
```

---

## Bank Switching

### Configuration
```hippo
{.mbc: MBC5.}
{.romBanks: 32.}
{.ramBanks: 4.}
```

### Automatic Bank Switching
Calling procedures in other banks automatically generates bank switch code:
```hippo
{.bank: 0.}
proc main() {
    loadMusic()  # Compiler generates bank switch
}

{.bank: 3.}
proc loadMusic() {
    # Implementation
}
```

### Manual Bank Switching
```hippo
proc manualExample() {
    switchBank(3)
    # Multiple operations in bank 3
    var a = dataA[0]
    var b = dataB[0]
    switchBankRestore()
}
```

---

## Object Usage

### Definition and Instantiation
```hippo
type Sprite = object {
    x: uint8
    y: uint8
    tileId: uint8
    flags: uint8
}

var player: Sprite @ wram:0xC000
var oamBuffer: array[40, Sprite] @ 0xFE00
```

### Member Access
```hippo
player.x = 80
player.y = 72
player.tileId = 1

# Copy entire object
oamBuffer[0] = player

# Access through pointer
var spritePtr = addr(player)
spritePtr.x = 100
```

---

## Inline Assembly

For low-level control:
```hippo
proc criticalTiming() {
    asm """
        ld a, [hl]
        inc a
        ld [hl], a
    """
}
```

---

## Built-in Procedures

```hippo
memcpy(dest, src: ptr, count: uint8)
memset(dest: ptr, value: uint8, count: uint8)
switchBank(bank: uint8)
switchBankRestore()
sizeof(T: type): uint16
```

---

## File Inclusion

```hippo
# Binary data
const data = includeBin("data.bin")

# Structured data
const enemies = includeStruct("enemies.dat")

# Tile data from image
const tiles = includeTiles("tiles.png")
```

---

## Module System

Simple copy-paste semantics - no complex import system for now. Files can be concatenated or included at compile time.

---

## Example Program

```hippo
{.mbc: MBC5.}
{.romBanks: 8.}
{.ramBanks: 1.}

type Entity = object {
    x: uint8
    y: uint8
    health: uint8
}

var player: Entity @ wram:0xC000
var frameCount: uint8 @ wram:0xC010

const spriteData: array[uint8] @ rom0:0x4000 = includeBin("sprites.bin")

{.entry.}
{.bank: 0.}
proc main() {
    initHardware()
    player.x = 80
    player.y = 72
    player.health = 100
    
    while true {
        waitVblank()
        updateGame()
        render()
    }
}

{.inline.}
proc waitVblank() {
    while (hw.lcdStat and 0x03) != 0x01 {}
}

proc updateGame() {
    var input = hw.joypad
    
    if (input and 0x01) != 0 {  # Right
        player.x += 1
    }
    if (input and 0x02) != 0 {  # Left
        player.x -= 1
    }
    
    frameCount += 1
}

{.bank: 2.}
proc loadLevel(levelNum: uint8) {
    # Level loading code in bank 2
}

{.interrupt: vblank.}
proc onVblank() {
    # VBlank handler
}
```