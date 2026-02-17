# ddui Reference Manual

A guide to building applications with ddui, a BetterC-compatible Immediate Mode UI library for D, ported from [rxi/microui](https://github.com/rxi/microui).

## Table of Contents

- [How ddui Works](#how-ddui-works)
- [Getting Started](#getting-started)
- [Initialization](#initialization)
- [The Main Loop](#the-main-loop)
- [Input Handling](#input-handling)
- [Windows](#windows)
- [Layout System](#layout-system)
- [Controls](#controls)
- [Panels](#panels)
- [Popups](#popups)
- [Tree Nodes](#tree-nodes)
- [Drawing Commands](#drawing-commands)
- [Rendering](#rendering)
- [Styling](#styling)
- [API Reference](#api-reference)

---

## How ddui Works

ddui is an **immediate mode** UI library. Unlike retained mode UIs (GTK, Qt), you don't create widget objects that persist between frames. Instead, you call UI functions every frame inside a begin/end block, and ddui produces a flat list of **drawing commands** (rectangles, text, icons, clip regions). Your application is responsible for consuming those commands and rendering them however you like (OpenGL, Vulkan, SDL2 software rendering, a terminal, etc.).

The flow each frame is:

```
1. Feed input events to ddui
2. Call mu_begin()
3. Define your UI (windows, buttons, sliders, etc.)
4. Call mu_end()
5. Iterate the command list and render each command
6. Present/swap buffers
```

ddui does **no rendering, no memory allocation, and no I/O**. It is a pure UI logic engine.

---

## Getting Started

### Adding ddui as a Dependency

You can add ddui locally:

In `dub.sdl`:
```sdl
dependency "ddui" path="/path/to/ddui"
```

Or in `dub.json`:

```json
{
  "dependencies": {
    "ddui": { "path": "/path/to/ddui" }
  }
}
```

Or as a git repository:

In `dub.sdl`:
```sdl
dependency "ddui" path="/path/to/ddui"

dependency "ddui" repository="git+https://github.com/dd86k/ddui.git" version="c8cb6bafedb438d629db7c22526c2e5e1ebe7bc5"
```

Or in `dub.json`:

```json
{
  "dependencies": {
    "ddui": {
        "repository": "git+https://github.com/dd86k/ddui.git",
        "version": "c8cb6bafedb438d629db7c22526c2e5e1ebe7bc5"
    }
  }
}
```

### Minimal Example

Here is the simplest possible ddui application structure (pseudocode, rendering backend omitted):

```d
import ddui;

extern (C):

__gshared mu_Context ctx;

// You must provide these two callbacks — they tell ddui how to measure text.
int my_text_width(mu_Font font, const(char)* str, int len)
{
    // Return pixel width of the string. len=-1 means null-terminated.
    if (len == -1) len = cast(int)strlen(str);
    return len * 8; // e.g., 8px fixed-width font
}

int my_text_height(mu_Font font)
{
    return 18; // e.g., 18px line height
}

void main()
{
    // --- Your rendering backend init here ---

    mu_init(&ctx);
    ctx.text_width  = &my_text_width;
    ctx.text_height = &my_text_height;

    while (running)
    {
        // 1. Feed input (see Input Handling section)
        handle_input(&ctx);

        // 2. Build UI
        mu_begin(&ctx);
        my_ui(&ctx);
        mu_end(&ctx);

        // 3. Render commands (see Rendering section)
        render_commands(&ctx);

        // 4. Present
        swap_buffers();
    }
}

void my_ui(mu_Context* ctx)
{
    if (mu_begin_window(ctx, "My Window", mu_Rect(40, 40, 300, 200)))
    {
        mu_label(ctx, "Hello, ddui!");

        if (mu_button(ctx, "Click Me"))
        {
            // Button was clicked this frame
        }

        mu_end_window(ctx);
    }
}
```

---

## Initialization

### mu_init

```d
void mu_init(mu_Context* ctx, mu_Style* style = null);
```

Zeroes out the context and sets up defaults. If `style` is null, the built-in `mu_default_style` is used. Call this once before the main loop.

After calling `mu_init`, you **must** set the two text measurement callbacks before calling `mu_begin`:

```d
mu_init(&ctx);
ctx.text_width  = &my_text_width;  // required
ctx.text_height = &my_text_height; // required
```

### Text Callbacks

ddui needs to know how wide and tall text is so it can lay out controls. You must provide these based on your font/rendering system:

```d
// Return pixel width of `str` (length `len` bytes). If len == -1, str is null-terminated.
int function(mu_Font font, const(char)* str, int len) text_width;

// Return the pixel height of a line of text.
int function(mu_Font font) text_height;
```

The `mu_Font` type is `void*` — you can use it to pass your own font handle if you support multiple fonts, or ignore it if you only use one font.

---

## The Main Loop

Every frame follows this pattern:

```d
// 1. Process platform events and feed them to ddui
//    (see Input Handling)

// 2. Begin the UI frame
mu_begin(&ctx);

// 3. Define all UI content
//    (windows, controls, etc.)

// 4. End the UI frame — finalizes command list
mu_end(&ctx);

// 5. Iterate commands and render
foreach (ref cmd; mu_command_range(&ctx))
{
    switch (cmd.type)
    {
        case MU_COMMAND_TEXT: /* draw text */   break;
        case MU_COMMAND_RECT: /* draw rect */   break;
        case MU_COMMAND_ICON: /* draw icon */   break;
        case MU_COMMAND_CLIP: /* set scissor */ break;
        default: break;
    }
}
```

**Important**: All UI definitions (windows, buttons, etc.) must happen between `mu_begin` and `mu_end`. The command list is only valid after `mu_end` returns.

---

## Input Handling

Feed platform input events to ddui between frames (before `mu_begin`). ddui tracks mouse position, button state, keyboard state, scroll, and text input.

### Mouse

```d
// Mouse moved to (x, y)
void mu_input_mousemove(mu_Context* ctx, int x, int y);

// Mouse button pressed at (x, y). btn is a MU_MOUSE_* flag.
void mu_input_mousedown(mu_Context* ctx, int x, int y, int btn);

// Mouse button released at (x, y)
void mu_input_mouseup(mu_Context* ctx, int x, int y, int btn);

// Scroll wheel. Typically (0, y) where y is scroll amount.
void mu_input_scroll(mu_Context* ctx, int x, int y);
```

Mouse button flags:

| Flag              | Value  |
|-------------------|--------|
| `MU_MOUSE_LEFT`   | 1 << 0 |
| `MU_MOUSE_RIGHT`  | 1 << 1 |
| `MU_MOUSE_MIDDLE` | 1 << 2 |

### Keyboard

```d
// Key pressed
void mu_input_keydown(mu_Context* ctx, int key);

// Key released
void mu_input_keyup(mu_Context* ctx, int key);

// Text input (for textbox typing). Pass the text string for the event.
void mu_input_text(mu_Context* ctx, const(char)* text);
```

Key flags:

| Flag              | Value  | Notes                          |
|-------------------|--------|--------------------------------|
| `MU_KEY_SHIFT`    | 1 << 0 | Shift+click enables number edit in sliders |
| `MU_KEY_CTRL`     | 1 << 1 |                                |
| `MU_KEY_ALT`      | 1 << 2 |                                |
| `MU_KEY_BACKSPACE`| 1 << 3 | Deletes characters in textboxes |
| `MU_KEY_RETURN`   | 1 << 4 | Submits textbox input          |

### SDL2 Input Mapping Example

Map SDL2 events to ddui calls. Here is a typical event loop:

```d
SDL_Event e;
while (SDL_PollEvent(&e))
{
    switch (e.type)
    {
        case SDL_QUIT:
            running = false;
            break;

        case SDL_MOUSEMOTION:
            mu_input_mousemove(&ctx, e.motion.x, e.motion.y);
            break;

        case SDL_MOUSEWHEEL:
            mu_input_scroll(&ctx, 0, e.wheel.y * -30);
            break;

        case SDL_TEXTINPUT:
            mu_input_text(&ctx, e.text.text.ptr);
            break;

        case SDL_MOUSEBUTTONDOWN:
            int b = sdl_button_to_mu(e.button.button);
            if (b) mu_input_mousedown(&ctx, e.button.x, e.button.y, b);
            break;

        case SDL_MOUSEBUTTONUP:
            int b = sdl_button_to_mu(e.button.button);
            if (b) mu_input_mouseup(&ctx, e.button.x, e.button.y, b);
            break;

        case SDL_KEYDOWN:
            int k = sdl_key_to_mu(e.key.keysym.sym);
            if (k) mu_input_keydown(&ctx, k);
            break;

        case SDL_KEYUP:
            int k = sdl_key_to_mu(e.key.keysym.sym);
            if (k) mu_input_keyup(&ctx, k);
            break;

        default: break;
    }
}

// Helper mappings:
int sdl_button_to_mu(int btn)
{
    switch (btn)
    {
        case SDL_BUTTON_LEFT:   return MU_MOUSE_LEFT;
        case SDL_BUTTON_RIGHT:  return MU_MOUSE_RIGHT;
        case SDL_BUTTON_MIDDLE: return MU_MOUSE_MIDDLE;
        default: return 0;
    }
}

int sdl_key_to_mu(int sym)
{
    switch (sym)
    {
        case SDLK_LSHIFT, SDLK_RSHIFT:       return MU_KEY_SHIFT;
        case SDLK_LCTRL, SDLK_RCTRL:         return MU_KEY_CTRL;
        case SDLK_LALT, SDLK_RALT:           return MU_KEY_ALT;
        case SDLK_BACKSPACE:                  return MU_KEY_BACKSPACE;
        case SDLK_RETURN, SDLK_KP_ENTER:     return MU_KEY_RETURN;
        default: return 0;
    }
}
```

---

## Windows

Windows are the top-level containers for UI content. They can be dragged, resized, closed, and scrolled.

### Creating a Window

```d
if (mu_begin_window(ctx, "Window Title", mu_Rect(x, y, w, h)))
{
    // ... controls go here ...
    mu_end_window(ctx);
}
```

- The `mu_Rect` is the **initial** position and size. Once the window exists, ddui remembers its position (the user can drag/resize it).
- The title string is used as the window's unique ID (via FNV-1a hash). **Each window must have a unique title**.
- `mu_begin_window` returns 0 if the window is closed/hidden — `mu_end_window` must only be called when it returns non-zero.

### Window Options

Use `mu_begin_window_ex` for full control:

```d
int mu_begin_window_ex(mu_Context* ctx, const(char)* title, mu_Rect rect, int opt);
```

Options can be combined with `|`:

| Option             | Effect                                      |
|--------------------|---------------------------------------------|
| `MU_OPT_NOFRAME`  | Don't draw the window background             |
| `MU_OPT_NOTITLE`  | Hide the title bar                           |
| `MU_OPT_NOCLOSE`  | Remove the close button from the title bar   |
| `MU_OPT_NORESIZE` | Prevent user resizing                        |
| `MU_OPT_NOSCROLL` | Disable scrollbars                           |
| `MU_OPT_AUTOSIZE` | Auto-resize window to fit content            |

Example — a non-resizable, non-closable window:

```d
if (mu_begin_window_ex(ctx, "Fixed Panel",
    mu_Rect(10, 10, 200, 300),
    MU_OPT_NORESIZE | MU_OPT_NOCLOSE))
{
    mu_label(ctx, "This window can't be resized or closed.");
    mu_end_window(ctx);
}
```

### Constraining Window Size

After beginning a window, you can enforce minimum dimensions:

```d
if (mu_begin_window(ctx, "My Window", mu_Rect(40, 40, 300, 200)))
{
    mu_Container* win = mu_get_current_container(ctx);
    win.rect.w = mu_max(win.rect.w, 240); // minimum width
    win.rect.h = mu_max(win.rect.h, 150); // minimum height

    // ... controls ...
    mu_end_window(ctx);
}
```

---

## Layout System

ddui uses a **row-based** layout system. You define rows of items with specified widths and height, and ddui automatically positions each control.

### mu_layout_row

```d
void mu_layout_row(mu_Context* ctx, int items, const(int)* widths, int height);
```

Defines a row with `items` columns. The `widths` array specifies the pixel width of each column. Special width values:

| Value     | Meaning                                        |
|-----------|------------------------------------------------|
| Positive  | Fixed width in pixels                          |
| `0`       | Use the default widget size from the style     |
| Negative  | Width relative to the right edge of the container (e.g., `-1` = fill remaining space, `-100` = 100px from right edge) |

`height` is the row height in pixels. `0` means use the default height from the style.

### Examples

**Single column, fill width:**

```d
int[1] widths = [-1];
mu_layout_row(ctx, 1, widths.ptr, 0);
mu_label(ctx, "This label fills the entire row");
```

**Two-column label + value layout:**

```d
int[2] widths = [80, -1];
mu_layout_row(ctx, 2, widths.ptr, 0);
mu_label(ctx, "Name:");
mu_label(ctx, "Value goes here");
mu_label(ctx, "Score:");
mu_label(ctx, "42");
```

Rows auto-repeat: if you place more controls than `items`, a new row starts automatically with the same widths.

**Three columns with mixed sizing:**

```d
int[3] widths = [100, -110, -1];
mu_layout_row(ctx, 3, widths.ptr, 0);
mu_label(ctx, "Label");
mu_button(ctx, "Button A");  // stretches, leaving 110px for last col
mu_button(ctx, "Button B");  // fills remaining space
```

### Columns (Sub-layouts)

Split a row cell into its own vertical layout:

```d
int[2] widths = [150, -1];
mu_layout_row(ctx, 2, widths.ptr, 0);

// Left column
mu_layout_begin_column(ctx);
    int[1] inner = [-1];
    mu_layout_row(ctx, 1, inner.ptr, 0);
    mu_label(ctx, "Left A");
    mu_label(ctx, "Left B");
mu_layout_end_column(ctx);

// Right column
mu_layout_begin_column(ctx);
    mu_layout_row(ctx, 1, inner.ptr, 0);
    mu_label(ctx, "Right A");
    mu_label(ctx, "Right B");
    mu_label(ctx, "Right C");
mu_layout_end_column(ctx);
```

### Manual Positioning

For absolute or relative placement of the next control:

```d
// Place next control at absolute position
mu_layout_set_next(ctx, mu_Rect(100, 50, 80, 30), 0);
mu_button(ctx, "Absolute");

// Place next control relative to current layout position
mu_layout_set_next(ctx, mu_Rect(10, 5, 80, 30), 1);
mu_button(ctx, "Relative");
```

### Setting Individual Dimensions

```d
mu_layout_width(ctx, 200);  // next control is 200px wide
mu_layout_height(ctx, 40);  // next control is 40px tall
```

---

## Controls

All controls are placed inside a window's begin/end block. They use the current layout to determine their position and size.

### Label

Displays static text:

```d
mu_label(ctx, "Some text");
```

### Wrapped Text

Displays a block of text that wraps to fit the available width:

```d
mu_text(ctx, "This is a longer paragraph of text that will "
    "automatically wrap to fit within the layout width.");
```

### Button

Returns non-zero (`MU_RES_SUBMIT`) when clicked:

```d
if (mu_button(ctx, "Click Me"))
{
    // handle click
}
```

For icon-only or custom buttons:

```d
// Button with icon, no label
int mu_button_ex(mu_Context* ctx, const(char)* label, int icon, int opt);

// Icon-only close button, right-aligned
if (mu_button_ex(ctx, null, MU_ICON_CLOSE, MU_OPT_ALIGNRIGHT))
{
    // ...
}
```

### Checkbox

Toggles an `int` between 0 and 1. Returns `MU_RES_CHANGE` when toggled:

```d
__gshared int my_flag = 0;

if (mu_checkbox(ctx, "Enable Feature", &my_flag) & MU_RES_CHANGE)
{
    // my_flag just changed
}
```

### Slider

Drag to adjust a floating-point value within a range. Returns `MU_RES_CHANGE` when the value changes:

```d
__gshared mu_Real volume = 0.5;

mu_slider(ctx, &volume, 0.0, 1.0);
```

For more control:

```d
int mu_slider_ex(mu_Context* ctx, mu_Real* value,
    mu_Real low, mu_Real high,
    mu_Real step,          // snap increment (0 = smooth)
    const(char)* fmt,      // printf format for display (e.g., "%.0f%%")
    int opt);
```

Example — integer percentage slider:

```d
__gshared mu_Real pct = 50;
mu_slider_ex(ctx, &pct, 0, 100, 1, "%.0f%%", MU_OPT_ALIGNCENTER);
```

**Tip**: Shift+click on a slider switches it to text input mode for precise entry.

### Number Box

Drag left/right to adjust a value by `step`. Also supports Shift+click for text input:

```d
__gshared mu_Real speed = 1.0;

mu_number(ctx, &speed, 0.1);  // step = 0.1
```

### Textbox

Editable single-line text field. Returns `MU_RES_CHANGE` on text change and `MU_RES_SUBMIT` on Enter:

```d
__gshared char[128] buf = [0];

int res = mu_textbox(ctx, buf.ptr, 128);
if (res & MU_RES_SUBMIT)
{
    // User pressed Enter; buf contains the text
    do_something(buf.ptr);
    buf[0] = '\0'; // clear
    mu_set_focus(ctx, ctx.last_id); // keep focus on the textbox
}
```

### Header

Collapsible section header. Returns `MU_RES_ACTIVE` when expanded:

```d
if (mu_header(ctx, "Settings"))
{
    // This content is only shown when the header is expanded
    mu_label(ctx, "Setting 1");
    mu_label(ctx, "Setting 2");
}
```

Start expanded by default:

```d
if (mu_header_ex(ctx, "Details", MU_OPT_EXPANDED))
{
    // expanded by default on first frame
}
```

---

## Panels

Panels are scrollable sub-regions within a window. They are non-interactive containers (no title bar, no dragging).

```d
int[1] widths = [-1];
mu_layout_row(ctx, 1, widths.ptr, 200); // 200px tall area
mu_begin_panel(ctx, "my_panel");
    // Content here can scroll if it exceeds 200px
    mu_layout_row(ctx, 1, widths.ptr, -1);
    mu_text(ctx, long_text_ptr);
mu_end_panel(ctx);
```

Panel names must be unique within the window. Use `mu_begin_panel_ex` with `MU_OPT_NOFRAME` to hide the panel background.

### Scrolling to Bottom (Chat/Log Pattern)

```d
mu_begin_panel(ctx, "Log");
mu_Container* panel = mu_get_current_container(ctx);
// ... add content ...
mu_end_panel(ctx);

if (new_content_added)
{
    panel.scroll.y = panel.content_size.y; // scroll to bottom
}
```

---

## Popups

Popups are auto-closing windows that appear at the mouse cursor position and close when the user clicks elsewhere.

```d
// Open the popup (typically on a button click or right-click)
if (mu_button(ctx, "Options"))
{
    mu_open_popup(ctx, "context_menu");
}

// Define the popup content
if (mu_begin_popup(ctx, "context_menu"))
{
    if (mu_button(ctx, "Cut"))   { /* ... */ }
    if (mu_button(ctx, "Copy"))  { /* ... */ }
    if (mu_button(ctx, "Paste")) { /* ... */ }
    mu_end_popup(ctx);
}
```

Popups automatically size to their content (`MU_OPT_AUTOSIZE`).

---

## Tree Nodes

Collapsible tree structure for hierarchical content:

```d
if (mu_begin_treenode(ctx, "Root"))
{
    mu_label(ctx, "Child item 1");
    mu_label(ctx, "Child item 2");

    if (mu_begin_treenode(ctx, "Sub-tree"))
    {
        mu_label(ctx, "Nested item");
        mu_end_treenode(ctx);
    }

    mu_end_treenode(ctx);
}
```

Each level of nesting is automatically indented by `ctx.style.indent` pixels (default 24).

---

## Drawing Commands

After `mu_end`, the context contains a list of drawing commands. These describe exactly what to draw — ddui does no rendering itself.

### Iterating Commands

```d
foreach (ref mu_Command cmd; mu_command_range(&ctx))
{
    switch (cmd.type)
    {
        case MU_COMMAND_RECT:
            // cmd.rect.rect — mu_Rect (x, y, w, h)
            // cmd.rect.color — mu_Color (r, g, b, a)
            draw_filled_rect(cmd.rect.rect, cmd.rect.color);
            break;

        case MU_COMMAND_TEXT:
            // cmd.text.str — null-terminated char array
            // cmd.text.pos — mu_Vec2 (x, y)
            // cmd.text.color — mu_Color
            // cmd.text.font — mu_Font (your font handle)
            draw_text(cmd.text.str.ptr, cmd.text.pos, cmd.text.color);
            break;

        case MU_COMMAND_ICON:
            // cmd.icon.id — icon ID (MU_ICON_CLOSE, MU_ICON_CHECK, etc.)
            // cmd.icon.rect — mu_Rect (destination area)
            // cmd.icon.color — mu_Color
            draw_icon(cmd.icon.id, cmd.icon.rect, cmd.icon.color);
            break;

        case MU_COMMAND_CLIP:
            // cmd.clip.rect — mu_Rect (scissor rectangle)
            set_scissor_rect(cmd.clip.rect);
            break;

        default: break;
    }
}
```

### Command Types

| Type               | Description                                      |
|--------------------|--------------------------------------------------|
| `MU_COMMAND_RECT`  | Draw a filled rectangle                          |
| `MU_COMMAND_TEXT`  | Draw a text string at a position                 |
| `MU_COMMAND_ICON`  | Draw an icon within a rectangle                  |
| `MU_COMMAND_CLIP`  | Set the clipping/scissor rectangle               |
| `MU_COMMAND_JUMP`  | Internal — used for command list ordering; skip these |

### Custom Drawing

You can draw directly into the command stream for custom visuals:

```d
// Draw a colored rectangle at the next layout position
mu_Rect r = mu_layout_next(ctx);
mu_draw_rect(ctx, r, mu_Color(255, 0, 0, 255));

// Draw a box (outline only)
mu_draw_box(ctx, r, mu_Color(255, 255, 0, 255));

// Draw text at an arbitrary position
mu_draw_text(ctx, ctx.style.font, "Custom!", -1,
    mu_Vec2(100, 200), mu_Color(0, 255, 0, 255));
```

---

## Rendering

ddui is rendering-backend agnostic. You implement the rendering. Here is what each command requires from your renderer:

### Requirements

1. **Filled rectangles** with RGBA color (`MU_COMMAND_RECT`)
2. **Text rendering** at a pixel position with a color (`MU_COMMAND_TEXT`)
3. **Icon rendering** — you decide how to draw the 4 built-in icons (`MU_COMMAND_ICON`)
4. **Scissor/clip rectangle** — restrict drawing to a rectangular region (`MU_COMMAND_CLIP`)

### Built-in Icons

| ID                  | Typical Usage     |
|---------------------|-------------------|
| `MU_ICON_CLOSE`    | Window close button |
| `MU_ICON_CHECK`    | Checkbox check mark |
| `MU_ICON_COLLAPSED`| Collapsed tree/header arrow |
| `MU_ICON_EXPANDED` | Expanded tree/header arrow  |

The demo uses a built-in bitmap atlas texture for both font and icons. You can use any method: bitmap fonts, TrueType fonts, vector icons, Unicode characters, etc.

### Minimal Software Renderer Skeleton

```d
void render_commands(mu_Context* ctx)
{
    foreach (ref cmd; mu_command_range(ctx))
    {
        switch (cmd.type)
        {
            case MU_COMMAND_RECT:
                fill_rect(cmd.rect.rect.x, cmd.rect.rect.y,
                          cmd.rect.rect.w, cmd.rect.rect.h,
                          cmd.rect.color);
                break;

            case MU_COMMAND_TEXT:
                draw_string(cmd.text.str.ptr,
                            cmd.text.pos.x, cmd.text.pos.y,
                            cmd.text.color);
                break;

            case MU_COMMAND_ICON:
                draw_icon(cmd.icon.id,
                          cmd.icon.rect.x, cmd.icon.rect.y,
                          cmd.icon.rect.w, cmd.icon.rect.h,
                          cmd.icon.color);
                break;

            case MU_COMMAND_CLIP:
                set_clip(cmd.clip.rect.x, cmd.clip.rect.y,
                         cmd.clip.rect.w, cmd.clip.rect.h);
                break;

            default: break;
        }
    }
}
```

---

## Styling

### The mu_Style Structure

```d
struct mu_Style
{
    mu_Font font;          // your font handle (void*)
    mu_Vec2 size;          // default widget size (w=68, h=10)
    int padding;           // inner padding (5)
    int spacing;           // spacing between controls (4)
    int indent;            // tree node indentation (24)
    int title_height;      // window title bar height (24)
    int scrollbar_size;    // scrollbar width (12)
    int thumb_size;        // scrollbar thumb minimum size (8)
    mu_Color[MU_COLOR_MAX] colors;  // theme colors
}
```

### Modifying Colors at Runtime

You can modify the style at any time. Changes take effect on the next frame:

```d
// Make buttons red
ctx.style.colors[MU_COLOR_BUTTON] = mu_Color(180, 40, 40, 255);
ctx.style.colors[MU_COLOR_BUTTONHOVER] = mu_Color(200, 60, 60, 255);
ctx.style.colors[MU_COLOR_BUTTONFOCUS] = mu_Color(220, 80, 80, 255);
```

### Using a Custom Style

```d
__gshared mu_Style my_style = {
    null,           // font
    { 80, 14 },     // default widget size
    6,              // padding
    5,              // spacing
    28,             // indent
    28,             // title height
    14,             // scrollbar size
    10,             // thumb size
    [
        { 220, 220, 220, 255 },  // MU_COLOR_TEXT
        {  20,  20,  20, 255 },  // MU_COLOR_BORDER
        {  40,  40,  40, 255 },  // MU_COLOR_WINDOWBG
        {  20,  20,  20, 255 },  // MU_COLOR_TITLEBG
        { 240, 240, 240, 255 },  // MU_COLOR_TITLETEXT
        {   0,   0,   0,   0 },  // MU_COLOR_PANELBG
        {  60,  60,  60, 255 },  // MU_COLOR_BUTTON
        {  80,  80,  80, 255 },  // MU_COLOR_BUTTONHOVER
        { 100, 100, 100, 255 },  // MU_COLOR_BUTTONFOCUS
        {  25,  25,  25, 255 },  // MU_COLOR_BASE
        {  30,  30,  30, 255 },  // MU_COLOR_BASEHOVER
        {  35,  35,  35, 255 },  // MU_COLOR_BASEFOCUS
        {  40,  40,  40, 255 },  // MU_COLOR_SCROLLBASE
        {  25,  25,  25, 255 },  // MU_COLOR_SCROLLTHUMB
    ]
};

mu_init(&ctx, &my_style);
```

### Color Indices

| Index                  | Used For                         |
|------------------------|----------------------------------|
| `MU_COLOR_TEXT`        | Default text color               |
| `MU_COLOR_BORDER`     | Control borders                  |
| `MU_COLOR_WINDOWBG`   | Window background                |
| `MU_COLOR_TITLEBG`    | Title bar background             |
| `MU_COLOR_TITLETEXT`  | Title bar text                   |
| `MU_COLOR_PANELBG`    | Panel background                 |
| `MU_COLOR_BUTTON`     | Button normal state              |
| `MU_COLOR_BUTTONHOVER`| Button hover state               |
| `MU_COLOR_BUTTONFOCUS`| Button pressed/focused state     |
| `MU_COLOR_BASE`       | Textbox/slider background        |
| `MU_COLOR_BASEHOVER`  | Textbox/slider hover             |
| `MU_COLOR_BASEFOCUS`  | Textbox/slider focused           |
| `MU_COLOR_SCROLLBASE` | Scrollbar track                  |
| `MU_COLOR_SCROLLTHUMB`| Scrollbar thumb                  |

### Custom Draw Frame Callback

Override how control frames (borders + backgrounds) are drawn:

```d
void my_draw_frame(mu_Context* ctx, mu_Rect rect, int colorid)
{
    mu_draw_rect(ctx, rect, ctx.style.colors[colorid]);
    // Add custom border, shadow, etc.
    if (ctx.style.colors[MU_COLOR_BORDER].a)
    {
        mu_draw_box(ctx, mu_expand_rect(rect, 1), ctx.style.colors[MU_COLOR_BORDER]);
    }
}

ctx.mu_draw_frame = &my_draw_frame;
```

---

## API Reference

### Core Types

| Type        | Definition     | Description            |
|-------------|----------------|------------------------|
| `mu_Id`     | `uint`         | FNV-1a hashed widget ID |
| `mu_Real`   | `float`        | Floating-point value   |
| `mu_Font`   | `void*`        | User-defined font handle |
| `mu_Vec2`   | `{int x, y}`  | 2D point               |
| `mu_Rect`   | `{int x, y, w, h}` | Rectangle         |
| `mu_Color`  | `{ubyte r, g, b, a}` | RGBA color       |
| `mu_Context`| struct         | Central UI state       |

### Response Flags

Returned by interactive controls (buttons, sliders, textboxes):

| Flag            | Value  | Meaning                           |
|-----------------|--------|-----------------------------------|
| `MU_RES_ACTIVE` | 1 << 0 | Control is active/expanded        |
| `MU_RES_SUBMIT` | 1 << 1 | Button clicked or Enter pressed   |
| `MU_RES_CHANGE` | 1 << 2 | Value changed (slider, checkbox, textbox) |

### Option Flags

Used with `_ex` variants of controls and windows:

| Flag                | Effect                               |
|---------------------|--------------------------------------|
| `MU_OPT_ALIGNCENTER`| Center-align text                   |
| `MU_OPT_ALIGNRIGHT` | Right-align text                    |
| `MU_OPT_NOINTERACT` | Disable mouse interaction           |
| `MU_OPT_NOFRAME`    | Don't draw background/border        |
| `MU_OPT_NORESIZE`   | Disable window resizing             |
| `MU_OPT_NOSCROLL`   | Disable scrollbars                  |
| `MU_OPT_NOCLOSE`    | Hide window close button            |
| `MU_OPT_NOTITLE`    | Hide window title bar               |
| `MU_OPT_HOLDFOCUS`  | Keep focus until explicitly lost     |
| `MU_OPT_AUTOSIZE`   | Resize container to fit content     |
| `MU_OPT_POPUP`      | Close on outside click (used internally) |
| `MU_OPT_CLOSED`     | Start container as closed           |
| `MU_OPT_EXPANDED`   | Start header/treenode as expanded   |

### Function Quick Reference

**Lifecycle:**
- `mu_init(ctx, style?)` — Initialize context
- `mu_begin(ctx)` — Start frame
- `mu_end(ctx)` — End frame, finalize commands

**Input:**
- `mu_input_mousemove(ctx, x, y)`
- `mu_input_mousedown(ctx, x, y, btn)`
- `mu_input_mouseup(ctx, x, y, btn)`
- `mu_input_scroll(ctx, x, y)`
- `mu_input_keydown(ctx, key)`
- `mu_input_keyup(ctx, key)`
- `mu_input_text(ctx, text)`

**Windows:**
- `mu_begin_window(ctx, title, rect)` / `mu_end_window(ctx)`
- `mu_begin_window_ex(ctx, title, rect, opt)` / `mu_end_window(ctx)`

**Containers:**
- `mu_begin_panel(ctx, name)` / `mu_end_panel(ctx)`
- `mu_begin_panel_ex(ctx, name, opt)` / `mu_end_panel(ctx)`
- `mu_begin_popup(ctx, name)` / `mu_end_popup(ctx)`
- `mu_open_popup(ctx, name)`
- `mu_get_current_container(ctx)` — Returns current `mu_Container*`
- `mu_get_container(ctx, name)` — Look up container by name

**Layout:**
- `mu_layout_row(ctx, items, widths, height)`
- `mu_layout_begin_column(ctx)` / `mu_layout_end_column(ctx)`
- `mu_layout_width(ctx, width)`
- `mu_layout_height(ctx, height)`
- `mu_layout_set_next(ctx, rect, relative)`
- `mu_layout_next(ctx)` — Returns `mu_Rect` for the next control position

**Controls:**
- `mu_label(ctx, text)`
- `mu_text(ctx, text)` — word-wrapped text
- `mu_button(ctx, label)` / `mu_button_ex(ctx, label, icon, opt)`
- `mu_checkbox(ctx, label, state)`
- `mu_slider(ctx, value, low, high)` / `mu_slider_ex(ctx, value, low, high, step, fmt, opt)`
- `mu_number(ctx, value, step)` / `mu_number_ex(ctx, value, step, fmt, opt)`
- `mu_textbox(ctx, buf, bufsz)` / `mu_textbox_ex(ctx, buf, bufsz, opt)`
- `mu_header(ctx, label)` / `mu_header_ex(ctx, label, opt)`
- `mu_begin_treenode(ctx, label)` / `mu_end_treenode(ctx)`
- `mu_begin_treenode_ex(ctx, label, opt)` / `mu_end_treenode(ctx)`

**Drawing:**
- `mu_draw_rect(ctx, rect, color)` — filled rectangle
- `mu_draw_box(ctx, rect, color)` — outline rectangle
- `mu_draw_text(ctx, font, str, len, pos, color)` — text at position
- `mu_draw_icon(ctx, id, rect, color)` — icon in rectangle
- `mu_draw_control_text(ctx, str, rect, colorid, opt)` — text in a control area

**Commands:**
- `mu_command_range(ctx)` — Returns command slice for iteration

**Utility:**
- `mu_set_focus(ctx, id)` — Set keyboard focus to a widget
- `mu_get_id(ctx, data, size)` — Generate a widget ID from data
- `mu_push_id(ctx, data, size)` / `mu_pop_id(ctx)` — Push/pop ID scope

---

## Limits and Constants

ddui uses fixed-size buffers with no dynamic allocation. These are the compile-time limits:

| Constant                  | Default | Description                          |
|---------------------------|---------|--------------------------------------|
| `MU_COMMANDLIST_SIZE`     | 4096    | Maximum drawing commands per frame   |
| `MU_ROOTLIST_SIZE`        | 32      | Maximum top-level windows            |
| `MU_CONTAINERSTACK_SIZE`  | 32      | Maximum nested container depth       |
| `MU_CLIPSTACK_SIZE`       | 32      | Maximum nested clip regions          |
| `MU_IDSTACK_SIZE`         | 32      | Maximum ID nesting depth             |
| `MU_LAYOUTSTACK_SIZE`     | 16      | Maximum nested layout depth          |
| `MU_CONTAINERPOOL_SIZE`   | 48      | Maximum unique containers            |
| `MU_TREENODEPOOL_SIZE`    | 48      | Maximum tree nodes                   |
| `MU_MAX_WIDTHS`           | 16      | Maximum columns per row              |
| `MU_TEXTSTACK_SIZE`       | 1024    | Maximum text length per command      |
| `MU_TEXT_LEN`             | 32      | Text input buffer size               |
| `MU_MAX_FMT`             | 64       | Format string buffer size            |

---

## Cookbook

### Color Picker

```d
void color_picker(mu_Context* ctx, mu_Color* color)
{
    mu_push_id(ctx, &color, color.sizeof);

    int[2] widths = [46, -1];
    mu_layout_row(ctx, 2, widths.ptr, 0);

    // Make a temporary float for each channel
    mu_Real r = color.r, g = color.g, b = color.b, a = color.a;

    mu_label(ctx, "R:"); mu_slider(ctx, &r, 0, 255);
    mu_label(ctx, "G:"); mu_slider(ctx, &g, 0, 255);
    mu_label(ctx, "B:"); mu_slider(ctx, &b, 0, 255);
    mu_label(ctx, "A:"); mu_slider(ctx, &a, 0, 255);

    color.r = cast(ubyte) r;
    color.g = cast(ubyte) g;
    color.b = cast(ubyte) b;
    color.a = cast(ubyte) a;

    // Preview swatch
    mu_Rect preview = mu_layout_next(ctx);
    mu_draw_rect(ctx, preview, *color);

    mu_pop_id(ctx);
}
```

### Console / Log Window

```d
__gshared char[64000] logbuf = 0;
__gshared size_t log_len = 0;
__gshared int logbuf_updated = 0;

void append_log(const(char)* text)
{
    import core.stdc.string : strlen, memcpy;
    size_t l = strlen(text);
    if (l == 0) return;
    memcpy(logbuf.ptr + log_len, text, l);
    log_len += l;
    logbuf[log_len] = '\n';
    logbuf[++log_len] = 0;
    logbuf_updated = 1;
}

void console_window(mu_Context* ctx)
{
    if (mu_begin_window(ctx, "Console", mu_Rect(350, 40, 300, 200)))
    {
        int[1] full = [-1];

        // Output panel
        mu_layout_row(ctx, 1, full.ptr, -25);
        mu_begin_panel(ctx, "log_output");
        mu_Container* panel = mu_get_current_container(ctx);
        mu_layout_row(ctx, 1, full.ptr, -1);
        mu_text(ctx, logbuf.ptr);
        mu_end_panel(ctx);
        if (logbuf_updated)
        {
            panel.scroll.y = panel.content_size.y;
            logbuf_updated = 0;
        }

        // Input row
        __gshared char[128] input_buf = [0];
        int[2] input_cols = [-70, -1];
        mu_layout_row(ctx, 2, input_cols.ptr, 0);
        if (mu_textbox(ctx, input_buf.ptr, 128) & MU_RES_SUBMIT)
        {
            mu_set_focus(ctx, ctx.last_id);
            append_log(input_buf.ptr);
            input_buf[0] = '\0';
        }
        if (mu_button(ctx, "Send"))
        {
            append_log(input_buf.ptr);
            input_buf[0] = '\0';
        }

        mu_end_window(ctx);
    }
}
```

### Confirmable Action

```d
if (mu_button(ctx, "Delete All"))
{
    mu_open_popup(ctx, "confirm_delete");
}

if (mu_begin_popup(ctx, "confirm_delete"))
{
    mu_label(ctx, "Are you sure?");

    int[2] widths = [80, 80];
    mu_layout_row(ctx, 2, widths.ptr, 0);
    if (mu_button(ctx, "Yes"))
    {
        delete_all_items();
    }
    if (mu_button(ctx, "No"))
    {
        // popup closes automatically on any click outside
    }
    mu_end_popup(ctx);
}
```

### Unique IDs for Dynamic Content

When creating controls in a loop, each must have a unique ID. Use `mu_push_id` / `mu_pop_id`:

```d
for (int i = 0; i < item_count; i++)
{
    mu_push_id(ctx, &i, i.sizeof);

    int[2] widths = [-1, 80];
    mu_layout_row(ctx, 2, widths.ptr, 0);
    mu_label(ctx, items[i].name);
    if (mu_button(ctx, "Remove"))
    {
        remove_item(i);
    }

    mu_pop_id(ctx);
}
```
