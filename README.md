# ddui, Immediate Mode UI

![demo](images/demo.png)

ddui is a BetterC compatible Immediate Mode User Interface.

This is a D port of [rxi/microui](https://github.com/rxi/microui) after being
angry at my Imgui/Nuklear bindings not working. I'd like to personally thank rxi
for making microui and Mike Parker for bindbc-opengl and bindbc-sdl.

Like the original, the library does not do any rendering of its own, but contains
commands to draw text, shapes, and icons originating from the library that needs
to be implemented in your application in order to work.

**NOTE**: A few things broke when converting the source to D, and I'm still new to OpenGL!

# Features

- BetterC compatibility.
- Index-based command stack buffer.
- Demo: Fixed host window resizing (clipping).
  - But broke control clipping...

# Roadmap

- Simplify codebase.
- Rename mu_ prefixes.
- Embedded documentation.
- Improve string handling.
  - Maybe introduce string_t, at least reduce dependency on strlen.
- Replace FNV-1a hash by Murmurhash3-32.
- Improve ID system.
- Textbox input navigation.
- Triangle corner hint and/or cursor change for resizable windows.
- Fix window dragging when on-top of each other for current example.
- Fix z-index global state (window management).
- Demo: Support OpenGL 3.3 and/or ES 2.0.
- (Considering) Dedicated helper functions to aid SDL2/Allegro/GLFW integration.

# Example

There is currently only one example using SDL2 and OpenGL 1.1.

Building the demo:
1. Navigate to the `demo` directory.
2. Obviously, you'll need a fairly recent DUB and D compiler.
3. Install the SDL2 library (Ubuntu: `libsdl2` package, Windows: place `sdl2.dll` in directory). (Note: this uses the dynamic configuration)
4. Type `dub`.