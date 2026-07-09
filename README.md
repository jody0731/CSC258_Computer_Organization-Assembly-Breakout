# CSC258 – Final Project: Breakout (MIPS Assembly)

Individual final project for University of Toronto's CSC258 (Computer Organization): a Breakout clone written in MIPS assembly, targeting the MARS simulator's memory-mapped bitmap display and keyboard input.

## Layout

- **`breakout.asm`** — the main program: game state, memory layout, and game logic (see below).
- **`bitmap_display.asm`, `keyboard.asm`** — course-provided reference examples for the memory-mapped bitmap display and keyboard input MMIO interfaces.
- **`functions.asm`** — helper routines for computing pixel addresses and drawing squares/lines to the bitmap display.
- **`project_report.tex` / `.pdf`** — the project report (memory layout design, collision physics, feature list, how-to-play instructions), with screenshots `1.png` (memory layout) and `2.png` (static scene).
- **`project-handout.pdf`** — the assignment handout.

## Memory layout

- `ADDR_DSPL` (`0x10008000`) / `ADDR_KBRD` (`0xffff0000`) — memory-mapped display and keyboard addresses.
- `MY_COLOURS` — the color palette used for bricks/ball/paddle.
- `BRICKS` (50 bricks × x/y/lives) / `PADDLE` / `BALL` (x/y position + x/y momentum) / `LIVES` — mutable game state.
- The display is 512×256 pixels at 1×1 pixel units; a `.space 491520` padding is added before `.data` to prevent the display address from overflowing into adjacent memory.

## Gameplay & features

- Ball bounces off walls/bricks (flips the relevant momentum component) and off the paddle (redirected based on where it was hit).
- Multiple lives (3 attempts), retaining broken-brick state across attempts.
- Variable ball speed on collision, a pause/resume key (`P`/`R`), a countdown time limit, unbreakable bricks, and two-hit bricks that change color to show damage progress before breaking.
- Controls: `A`/`D` to move the paddle, `P` to pause, `R` to resume/retry, `Q` to quit.

## Author

Zixuan Zeng
