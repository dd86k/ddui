# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ddui is a BetterC-compatible Immediate Mode UI library written in D, ported from [rxi/microui](https://github.com/rxi/microui). The library generates drawing commands (text, shapes, icons) but does no rendering itself — rendering must be implemented by the application.

**Status**: No longer maintained.

## Build Commands

Important: Currently, dmd 2.112 has issues compiling BetterC code. Switch to `gdc` or `ldc2` for testing.

**Library** (source library, no binary output):
```
dub
```

Both demos require SDL2 dynamic libraries to be installed.

**Demo application** (multi-window):
```
dub build ddui:demo                          # default (GL 1.1)
dub build ddui:demo --configuration=gl11     # OpenGL 1.1
dub build ddui:demo --configuration=gl33     # OpenGL 3.3
```

**Demo application** (full-window):
```
dub build ddui:demo_app                          # default (GL 1.1)
dub build ddui:demo_app --configuration=gl11     # OpenGL 1.1
dub build ddui:demo_app --configuration=gl33     # OpenGL 3.3
```

There is no test suite. The demo application serves as the functional test.

## Architecture

**Single-file core**: The entire UI library is `source/ddui.d` (~1800 lines). It uses `extern(C)` linkage, BetterC mode (no D runtime), and fixed-size stack-based buffers with no dynamic allocation.

**Key concepts**:
- `mu_Context` — central state: command stack, container/layout stacks, input state, focus/hover tracking, styling
- **Command stack** — UI building produces a flat list of drawing commands (JUMP, CLIP, RECT, TEXT, ICON) using array indices rather than pointers
- **Pool-based containers** — windows/panels stored in fixed-size pools with ID-based lookup (FNV-1a hash)
- **Layout** — row-based with configurable column widths, supports relative/absolute positioning

**Naming conventions**: Public API uses `mu_` prefix (microui legacy). Renderer functions in demo use `r_` prefix.

## Demo Structure

```
demo/source/
├── main.d              — SDL2/OpenGL init, input routing, render loop
├── stopwatch.d         — Cross-platform timing (Windows/POSIX)
└── renderer/sdl2/
    ├── gl11.d          — OpenGL 1.1 backend (primary)
    └── gl33.d          — OpenGL 3.3 backend (has known issues with glGenVertexArrays)
```

Demo dependencies: bindbc-opengl, bindbc-sdl, bindbc-loader (all dynamic configuration).
