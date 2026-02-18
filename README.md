# ddui, Immediate Mode UI

![demo](images/demo.png)

ddui is a BetterC-compatible Immediate Mode User Interface.

This is a D port of [rxi/microui](https://github.com/rxi/microui) after being
angry at my Imgui/Nuklear bindings not working. I'd like to personally thank rxi
for making microui and Mike Parker for bindbc-opengl and bindbc-sdl.

Like the original, the library does not do any rendering of its own, but contains
commands to draw text, shapes, and icons originating from the library that needs
to be implemented in your application in order to work.

# Features

- BetterC compatibility.
- Index-based command stack buffer.
- Demo: Fixed host window resizing (clipping).

# Roadmap

- Embedded documentation.
- Improve string handling.
  - Maybe introduce string_t, at least reduce dependency on strlen.
- Textbox input navigation.
- Fix z-index global state (window management).

# Examples

There are two examples: `demo` (multi-embedded windows) and `demo_app` (full window).

Both use SDL2 dynamic packages, which you will need on your system.
On Windows, place `sdl2.dll` in the same directory.

Both have `gl11` (OpenGL 1.1, default) and `gl33` (OpenGL 3.3) configurations.

Running the `demo` example: `dub :demo -c gl33 --compiler=ldc2`
