/// Immediate-mode UI based on rxi/microui.
/// Authors: dd86k (dd@dax.moe)
/// Copyright: © 2020 rxi, © 2022 dd86k
/// License: BSD-3-Clause
module ddui;

// Original Copyright:
/*
** Copyright (c) 2020 rxi
**
** Permission is hereby granted, free of charge, to any person obtaining a copy
** of this software and associated documentation files (the "Software"), to
** deal in the Software without restriction, including without limitation the
** rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
** sell copies of the Software, and to permit persons to whom the Software is
** furnished to do so, subject to the following conditions:
**
** The above copyright notice and this permission notice shall be included in
** all copies or substantial portions of the Software.
**
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
** FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
** IN THE SOFTWARE.
*/

import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;

extern (C):

//TODO: Consider ballooning command stack
//      e.g., if initial size isn't enough, allocate more (forever)
//      might not be viable since dynamic allocation is performed

enum MU_VERSION = "0.0.3";

/// Buffer size for text command.
/// This affects all labels and text inputs.
enum MU_TEXTSTACK_SIZE = 1024;
/// Maximum number of commands that the UI can generate.
/// Demo uses around 497 commands.
enum MU_COMMANDLIST_SIZE = 4096;
enum MU_ROOTLIST_SIZE = 32;
enum MU_CONTAINERSTACK_SIZE = 32;
enum MU_CLIPSTACK_SIZE = 32;
enum MU_IDSTACK_SIZE = 32;
enum MU_LAYOUTSTACK_SIZE = 16;
enum MU_CONTAINERPOOL_SIZE = 48;
enum MU_TREENODEPOOL_SIZE = 48;
enum MU_MAX_WIDTHS = 16;
enum MU_MAX_FMT = 64;
enum const(char)* MU_REAL_FMT = "%.3g";
enum const(char)* MU_SLIDER_FMT = "%.2f";

/// Length of the text input buffer.
enum MU_TEXT_LEN = 32;

/// Defines a stack with a maximum number of items that can be inserted.
/// Params: n = Maximum number of stack items allowed.
struct mu_Stack(T, size_t n)
{
    size_t idx;
    T[n] items;
    
    void push(T val)
    {
        assert(idx < n, "idx < n");
        items[idx] = val;
        ++idx;
    }

    void pop()
    {
        assert(idx > 0, "idx > 0");
        --idx;
    }
}

/// Returns minimum item.
auto mu_min(A, B)(A a, B b)
{
    return a < b ? a : b;
}
/// Returns maximum item.
auto mu_max(A, B)(A a, B b)
{
    return a > b ? a : b;
}
/// Returns a clamped value with a given minimum and maximum.
auto mu_clamp(X, A, B)(X x, A a, B b)
{
    return mu_min(b, mu_max(a, x));
}

alias mu_Id = uint;
alias mu_Real = float;
alias mu_Font = void*;

enum
{
    MU_CLIP_PART = 1,
    MU_CLIP_ALL
}

enum
{
    MU_COMMAND_JUMP = 1,
    MU_COMMAND_CLIP,
    MU_COMMAND_RECT,
    MU_COMMAND_TEXT,
    MU_COMMAND_ICON,
    MU_COMMAND_MAX
}

enum
{
    MU_COLOR_TEXT,
    MU_COLOR_BORDER,
    MU_COLOR_WINDOWBG,
    MU_COLOR_TITLEBG,
    MU_COLOR_TITLETEXT,
    MU_COLOR_PANELBG,
    MU_COLOR_BUTTON,
    MU_COLOR_BUTTONHOVER,
    MU_COLOR_BUTTONFOCUS,
    MU_COLOR_BASE,
    MU_COLOR_BASEHOVER,
    MU_COLOR_BASEFOCUS,
    MU_COLOR_SCROLLBASE,
    MU_COLOR_SCROLLTHUMB,
    MU_COLOR_MAX
}

enum
{
    MU_ICON_CLOSE = 1,
    MU_ICON_CHECK,
    MU_ICON_COLLAPSED,
    MU_ICON_EXPANDED,
    MU_ICON_MAX
}

enum
{
    MU_RES_ACTIVE = (1 << 0),
    MU_RES_SUBMIT = (1 << 1),
    MU_RES_CHANGE = (1 << 2)
}

enum
{
    MU_OPT_ALIGNCENTER = (1 << 0),
    MU_OPT_ALIGNRIGHT = (1 << 1),
    MU_OPT_NOINTERACT = (1 << 2),
    MU_OPT_NOFRAME = (1 << 3),
    MU_OPT_NORESIZE = (1 << 4),
    MU_OPT_NOSCROLL = (1 << 5),
    MU_OPT_NOCLOSE = (1 << 6),
    MU_OPT_NOTITLE = (1 << 7),
    MU_OPT_HOLDFOCUS = (1 << 8),
    MU_OPT_AUTOSIZE = (1 << 9),
    MU_OPT_POPUP = (1 << 10),
    MU_OPT_CLOSED = (1 << 11),
    MU_OPT_EXPANDED = (1 << 12)
}

enum
{
    MU_MOUSE_LEFT = (1 << 0),
    MU_MOUSE_RIGHT = (1 << 1),
    MU_MOUSE_MIDDLE = (1 << 2)
}

enum
{
    MU_KEY_SHIFT = (1 << 0),
    MU_KEY_CTRL = (1 << 1),
    MU_KEY_ALT = (1 << 2),
    MU_KEY_BACKSPACE = (1 << 3),
    MU_KEY_RETURN = (1 << 4)
}

/// 2D vector point
struct mu_Vec2
{
    int x, y;
}

/// 2D rectangle
struct mu_Rect
{
    int x, y, w, h;
}

/// RGBA color
struct mu_Color
{
    ubyte r, g, b, a;
}

///
struct mu_PoolItem
{
    mu_Id id;
    int last_update;
}

///
struct mu_BaseCommand
{
    int type;
}

/// These are used to skip command items to the next valid one.
struct mu_JumpCommand
{
    mu_BaseCommand base;
    int dst_idx;
}

///
struct mu_ClipCommand
{
    mu_BaseCommand base;
    mu_Rect rect;
}

///
struct mu_RectCommand
{
    mu_BaseCommand base;
    mu_Rect rect;
    mu_Color color;
}

///
struct mu_TextCommand
{
    mu_BaseCommand base;
    mu_Font font;
    mu_Vec2 pos;
    mu_Color color;
    //TODO: Consider adding size_t length
    char[MU_TEXTSTACK_SIZE] str;
}

///
struct mu_IconCommand
{
    mu_BaseCommand base;
    mu_Rect rect;
    int id;
    mu_Color color;
}

///
union mu_Command
{
    int type;
    mu_BaseCommand base;
    mu_JumpCommand jump;
    mu_ClipCommand clip;
    mu_RectCommand rect;
    mu_TextCommand text;
    mu_IconCommand icon;
}

///
struct mu_Layout
{
    mu_Rect body_;
    mu_Rect next;
    mu_Vec2 position;
    mu_Vec2 size;
    mu_Vec2 max;
    //TODO: Consider columns pointer with count
    int[MU_MAX_WIDTHS] widths;
    int items;
    int item_index;
    int next_row;
    int next_type;
    int indent;
}

///
struct mu_Container
{
    int head_idx, tail_idx;
    mu_Rect rect;
    mu_Rect body_;
    mu_Vec2 content_size;
    mu_Vec2 scroll;
    int zindex;
    int open;
}

///
struct mu_Style
{
    mu_Font font;
    mu_Vec2 size;
    int padding;
    int spacing;
    int indent;
    int title_height;
    int scrollbar_size;
    int thumb_size;
    mu_Color[MU_COLOR_MAX] colors;
}

/// Main DDUI context structure.
/// The instance of which will be given to DDUI functions.
struct mu_Context
{
    /// Text width callback.
    int function(mu_Font font, const(char)* str, int len) text_width;
    /// Text height callback.
    int function(mu_Font font) text_height;
    /// Callback for drawing boxes.
    void function(mu_Context* ctx, mu_Rect rect, int colorid) mu_draw_frame;
    
    //
    // core state
    //
    
    mu_Style* style;
    mu_Id hover;
    mu_Id focus;
    mu_Id last_id;
    mu_Rect last_rect;
    int last_zindex;
    int updated_focus;
    int frame;
    mu_Container* hover_root;
    mu_Container* next_hover_root;
    mu_Container* scroll_target;
    char[MU_MAX_FMT] number_edit_buf;
    mu_Id number_edit;
    
    //
    // stacks
    //
    
    mu_Stack!(mu_Command,    MU_COMMANDLIST_SIZE)    command_list;
    mu_Stack!(mu_Container*, MU_ROOTLIST_SIZE)       root_list;
    mu_Stack!(mu_Container*, MU_CONTAINERSTACK_SIZE) container_stack;
    mu_Stack!(mu_Rect,       MU_CLIPSTACK_SIZE)      clip_stack;
    mu_Stack!(mu_Id,         MU_IDSTACK_SIZE)        id_stack;
    mu_Stack!(mu_Layout,     MU_LAYOUTSTACK_SIZE)    layout_stack;
    
    //
    // retained state pools
    //
    
    mu_PoolItem [MU_CONTAINERPOOL_SIZE] container_pool;
    mu_Container[MU_CONTAINERPOOL_SIZE] containers;
    mu_PoolItem [MU_TREENODEPOOL_SIZE]  treenode_pool;
    
    //
    // input state
    //
    
    mu_Vec2 mouse_pos;
    mu_Vec2 last_mouse_pos;
    mu_Vec2 mouse_delta;
    mu_Vec2 scroll_delta;
    int mouse_down;
    int mouse_pressed;
    int key_down;
    int key_pressed;
    char[MU_TEXT_LEN] input_text; //TODO: Move into text_stack?
}

/// Creates a button.
int mu_button(mu_Context* ctx, const(char)* label)
{
    return mu_button_ex(ctx, label, 0, MU_OPT_ALIGNCENTER);
}

/// Creates a editable textbox.
int mu_textbox(mu_Context* ctx, char* buf, int bufsz)
{
    return mu_textbox_ex(ctx, buf, bufsz, 0);
}

/// Creates a slider.
int mu_slider(mu_Context* ctx, mu_Real* value, mu_Real low, mu_Real high)
{
    return mu_slider_ex(ctx, value, low, high, 0, MU_SLIDER_FMT, MU_OPT_ALIGNCENTER);
}

/// Creates a number box.
int mu_number(mu_Context* ctx, mu_Real* value, mu_Real step)
{
    return mu_number_ex(ctx, value, step, MU_SLIDER_FMT, MU_OPT_ALIGNCENTER);
}

/// 
int mu_header(mu_Context* ctx, const(char)* label)
{
    return mu_header_ex(ctx, label, 0);
}

/// 
int mu_begin_treenode(mu_Context* ctx, const(char)* label)
{
    return mu_begin_treenode_ex(ctx, label, 0);
}

/// Creates a window.
int mu_begin_window(mu_Context* ctx, const(char)* title, mu_Rect rect)
{
    return mu_begin_window_ex(ctx, title, rect, 0);
}

/// Creates a panel.
mu_Container* mu_begin_panel(mu_Context* ctx, const(char)* name)
{
    return mu_begin_panel_ex(ctx, name, 0);
}

immutable mu_Rect unclipped_rect = { 0, 0, 0x1000000, 0x1000000 };

/// Default style.
pragma(mangle, "mu_default_style")
__gshared mu_Style default_style = {
    // Font
    null,
    // Size in pixels
    { 68, 10 },
    // Padding in pixels
    5,
    // Margin in pixels
    4,
    // Indentation
    24,
    // Title height
    24,
    // Scrollbar size
    12,
    // Thumb size
    8,
    [
        // MU_COLOR_TEXT
        { 230, 230, 230, 255 },
        // MU_COLOR_BORDER
        {  25,  25,  25, 255 },
        // MU_COLOR_WINDOWBG
        {  50,  50,  50, 255 },
        // MU_COLOR_TITLEBG
        {  25,  25,  25, 255 },
        // MU_COLOR_TITLETEXT
        { 240, 240, 240, 255 },
        // MU_COLOR_PANELBG
        {   0,   0,   0,   0 },
        // MU_COLOR_BUTTON
        {  75,  75,  75, 255 },
        // MU_COLOR_BUTTONHOVER
        {  95,  95,  95, 255 },
        // MU_COLOR_BUTTONFOCUS
        { 115, 115, 115, 255 },
        // MU_COLOR_BASE
        {  30,  30,  30, 255 },
        // MU_COLOR_BASEHOVER
        {  35,  35,  35, 255 },
        // MU_COLOR_BASEFOCUS
        {  40,  40,  40, 255 },
        // MU_COLOR_SCROLLBASE
        {  43,  43,  43, 255 },
        // MU_COLOR_SCROLLTHUMB
        {  30,  30,  30, 255 },
    ]
};

/// Expand a rectangle from its center by n pixels.
/// Params:
///     rect = Rectangle
///     n = Pixels
/// Returns: New rectangle
mu_Rect mu_expand_rect(mu_Rect rect, int n)
{
    return mu_Rect(rect.x - n, rect.y - n, rect.w + n * 2, rect.h + n * 2);
}

mu_Rect mu_intersect_rects(mu_Rect r1, mu_Rect r2)
{
    int x1 = mu_max(r1.x, r2.x);
    int y1 = mu_max(r1.y, r2.y);
    int x2 = mu_min(r1.x + r1.w, r2.x + r2.w);
    int y2 = mu_min(r1.y + r1.h, r2.y + r2.h);
    if (x2 < x1)
    {
        x2 = x1;
    }
    if (y2 < y1)
    {
        y2 = y1;
    }
    return mu_Rect(x1, y1, x2 - x1, y2 - y1);
}

int rect_overlaps_vec2(mu_Rect r, mu_Vec2 p)
{
    return p.x >= r.x && p.x < r.x + r.w && p.y >= r.y && p.y < r.y + r.h;
}

/// Draw a frame of a window
void mu_draw_frame(mu_Context* ctx, mu_Rect rect, int colorid)
{
    mu_draw_rect(ctx, rect, ctx.style.colors[colorid]);
    
    if (colorid == MU_COLOR_SCROLLBASE ||
        colorid == MU_COLOR_SCROLLTHUMB ||
        colorid == MU_COLOR_TITLEBG)
    {
        return;
    }
    
    // draw border
    if (ctx.style.colors[MU_COLOR_BORDER].a)
    {
        mu_draw_box(ctx, mu_expand_rect(rect, 1), ctx.style.colors[MU_COLOR_BORDER]);
    }
}

void mu_init(mu_Context* ctx, mu_Style *style = null)
{
    memset(ctx, 0, mu_Context.sizeof);
    ctx.mu_draw_frame = &mu_draw_frame;
    ctx.style = style ? style : cast(mu_Style*)&default_style;
}

void mu_begin(mu_Context* ctx)
{
    assert(ctx.text_width && ctx.text_height, "ctx.text_width && ctx.text_height");
    ctx.command_list.idx = 0;
    ctx.root_list.idx = 0;
    ctx.scroll_target = null;
    ctx.hover_root = ctx.next_hover_root;
    ctx.next_hover_root = null;
    ctx.mouse_delta.x = ctx.mouse_pos.x - ctx.last_mouse_pos.x;
    ctx.mouse_delta.y = ctx.mouse_pos.y - ctx.last_mouse_pos.y;
    ctx.frame++;
}

int mu_compare_zindex(const void* a, const void* b)
{
    mu_Container *A = cast(mu_Container*) a;
    mu_Container *B = cast(mu_Container*) b;
    return A.zindex - B.zindex;
}

void mu_end(mu_Context* ctx)
{
    // check stacks
    assert(ctx.container_stack.idx == 0, "ctx.container_stack.idx == 0");
    assert(ctx.clip_stack.idx == 0, "ctx.clip_stack.idx == 0");
    assert(ctx.id_stack.idx == 0, "ctx.id_stack.idx == 0");
    assert(ctx.layout_stack.idx == 0, "ctx.layout_stack.idx == 0");

    // handle scroll input
    if (ctx.scroll_target)
    {
        ctx.scroll_target.scroll.x += ctx.scroll_delta.x;
        ctx.scroll_target.scroll.y += ctx.scroll_delta.y;
    }

    // unset focus if focus id was not touched this frame
    if (!ctx.updated_focus)
    {
        ctx.focus = 0;
    }
    
    ctx.updated_focus = 0;

    // bring hover root to front if mouse was pressed
    if (ctx.mouse_pressed && ctx.next_hover_root &&
        ctx.next_hover_root.zindex < ctx.last_zindex &&
        ctx.next_hover_root.zindex)
    {
        mu_bring_to_front(ctx, ctx.next_hover_root);
    }

    // reset input state
    ctx.input_text[0] = '\0';
    ctx.key_pressed = 0;
    ctx.mouse_pressed = 0;
    ctx.scroll_delta = mu_Vec2(0, 0);
    ctx.last_mouse_pos = ctx.mouse_pos;

    // sort root containers by zindex (insertion sort, max MU_ROOTLIST_SIZE=32 elements)
    // needed to track zindex, otherwise very minimal perf impact
    size_t n = ctx.root_list.idx;
    for (size_t i = 1; i < n; i++)
    {
        mu_Container* key = ctx.root_list.items[i];
        size_t j = i;
        while (j > 0 && ctx.root_list.items[j - 1].zindex > key.zindex) {
            ctx.root_list.items[j] = ctx.root_list.items[j - 1];
            j--;
        }
        ctx.root_list.items[j] = key;
    }
    
    // Set root container jump commands
    // First container should have the first command jump to it
    mu_Command* cmd = cast(mu_Command*) ctx.command_list.items;
    cmd.jump.dst_idx = ctx.root_list.items[0].head_idx + 1;
    
    // Otherwise set the previous container's tail to jump to this one
    for (size_t i = 1; i < n; ++i)
    {
        mu_Container* cnt  = ctx.root_list.items[i];
        mu_Container* prev = ctx.root_list.items[i - 1];
        ctx.command_list.items[prev.tail_idx].jump.dst_idx = cnt.head_idx + 1;
        if (i == n - 1)
        {
            ctx.command_list.items[cnt.tail_idx].jump.dst_idx = cast(int)ctx.command_list.idx;
        }
    }
}

void mu_set_focus(mu_Context* ctx, mu_Id id)
{
    ctx.focus = id;
    ctx.updated_focus = 1;
}

/// 32bit fnv-1a hash
private enum HASH_INITIAL = 0x811c_9dc5;

private
void mu_hash(mu_Id* hash, const(void)* data, size_t size)
{
    const(ubyte)* p = cast(const(ubyte)*) data;
    while (size--)
    {
        *hash = (*hash ^ *p++) * 0x1000193;
    }
}

mu_Id mu_get_id(mu_Context* ctx, const(void)* data, size_t size)
{
    int idx = cast(int)ctx.id_stack.idx;
    mu_Id res = (idx > 0) ? ctx.id_stack.items[idx - 1] : HASH_INITIAL;
    mu_hash(&res, data, size);
    ctx.last_id = res;
    return res;
}

void mu_push_id(mu_Context* ctx, const void* data, int size)
{
    ctx.id_stack.push(mu_get_id(ctx, data, size));
}

void mu_pop_id(mu_Context* ctx)
{
    ctx.id_stack.pop();
}

void mu_push_clip_rect(mu_Context* ctx, mu_Rect rect)
{
    mu_Rect last = mu_get_clip_rect(ctx);
    ctx.clip_stack.push(mu_intersect_rects(rect, last));
}

void mu_pop_clip_rect(mu_Context* ctx)
{
    ctx.clip_stack.pop();
}

mu_Rect mu_get_clip_rect(mu_Context* ctx)
{
    assert(ctx.clip_stack.idx > 0, "ctx.clip_stack.idx > 0");
    return ctx.clip_stack.items[ctx.clip_stack.idx - 1];
}

int mu_check_clip(mu_Context* ctx, mu_Rect r)
{
    mu_Rect cr = mu_get_clip_rect(ctx);
    if (r.x > cr.x + cr.w || r.x + r.w < cr.x ||
        r.y > cr.y + cr.h || r.y + r.h < cr.y)
    {
        return MU_CLIP_ALL;
    }
    if (r.x >= cr.x && r.x + r.w <= cr.x + cr.w &&
        r.y >= cr.y && r.y + r.h <= cr.y + cr.h)
    {
        return 0;
    }
    return MU_CLIP_PART;
}

void mu_push_layout(mu_Context* ctx, mu_Rect body_, mu_Vec2 scroll)
{
    mu_Layout layout = void;
    int width = 0;
    memset(&layout, 0, layout.sizeof);
    layout.body_ = mu_Rect(body_.x - scroll.x, body_.y - scroll.y, body_.w, body_.h);
    layout.max = mu_Vec2(-0x1000000, -0x1000000); // ?
    ctx.layout_stack.push(layout);
    mu_layout_row(ctx, 1, &width, 0);
}

mu_Layout* mu_get_layout(mu_Context* ctx)
{
    return &ctx.layout_stack.items[ctx.layout_stack.idx - 1];
}

void mu_pop_container(mu_Context* ctx)
{
    mu_Container* cnt = mu_get_current_container(ctx);
    mu_Layout* layout = mu_get_layout(ctx);
    cnt.content_size.x = layout.max.x - layout.body_.x;
    cnt.content_size.y = layout.max.y - layout.body_.y;
    // pop container, layout and id
    ctx.container_stack.pop();
    ctx.layout_stack.pop();
    mu_pop_id(ctx);
}

mu_Container* mu_get_current_container(mu_Context* ctx)
{
    assert(ctx.container_stack.idx > 0, "ctx.container_stack.idx > 0");
    return ctx.container_stack.items[ctx.container_stack.idx - 1];
}

mu_Container* mu_get_container2(mu_Context* ctx, mu_Id id, int opt)
{
    // try to get existing container from pool
    int idx = mu_pool_get(ctx, ctx.container_pool.ptr, MU_CONTAINERPOOL_SIZE, id);
    if (idx >= 0)
    {
        if (ctx.containers[idx].open || ~opt & MU_OPT_CLOSED)
        {
            mu_pool_update(ctx, ctx.container_pool.ptr, idx);
        }
        return &ctx.containers[idx];
    }
    if (opt & MU_OPT_CLOSED)
    {
        return null;
    }
    
    // container not found in pool: init new container
    idx = mu_pool_init(ctx, ctx.container_pool.ptr, MU_CONTAINERPOOL_SIZE, id);
    mu_Container* cnt = &ctx.containers[idx];
    memset(cnt, 0, mu_Container.sizeof);
    cnt.open = 1;
    mu_bring_to_front(ctx, cnt);
    return cnt;
}

mu_Container* mu_get_container(mu_Context* ctx, const(char)* name)
{
    mu_Id id = mu_get_id(ctx, name, cast(int) strlen(name));
    return mu_get_container2(ctx, id, 0);
}

void mu_bring_to_front(mu_Context* ctx, mu_Container* cnt)
{
    cnt.zindex = ++ctx.last_zindex;
}

/*============================================================================
** pool
**============================================================================*/

int mu_pool_init(mu_Context* ctx, mu_PoolItem* items, int len, mu_Id id)
{
    int i, n = -1, f = ctx.frame;
    for (i = 0; i < len; i++)
    {
        if (items[i].last_update < f)
        {
            f = items[i].last_update;
            n = i;
        }
    }
    assert(n > -1, "n > -1");
    items[n].id = id;
    mu_pool_update(ctx, items, n);
    return n;
}

int mu_pool_get(mu_Context* ctx, mu_PoolItem* items, int len, mu_Id id)
{
    for (int i = 0; i < len; i++)
    {
        if (items[i].id == id)
        {
            return i;
        }
    }
    return -1;
}

void mu_pool_update(mu_Context* ctx, mu_PoolItem* items, int idx)
{
    items[idx].last_update = ctx.frame;
}

/*============================================================================
** input handlers
**============================================================================*/

void mu_input_mousemove(mu_Context* ctx, int x, int y)
{
    ctx.mouse_pos = mu_Vec2(x, y);
}

void mu_input_mousedown(mu_Context* ctx, int x, int y, int btn)
{
    mu_input_mousemove(ctx, x, y);
    ctx.mouse_down |= btn;
    ctx.mouse_pressed |= btn;
}

void mu_input_mouseup(mu_Context* ctx, int x, int y, int btn)
{
    mu_input_mousemove(ctx, x, y);
    ctx.mouse_down &= ~btn;
}

void mu_input_scroll(mu_Context* ctx, int x, int y)
{
    ctx.scroll_delta.x += x;
    ctx.scroll_delta.y += y;
}

void mu_input_keydown(mu_Context* ctx, int key)
{
    ctx.key_pressed |= key;
    ctx.key_down |= key;
}

void mu_input_keyup(mu_Context* ctx, int key)
{
    ctx.key_down &= ~key;
}

void mu_input_text(mu_Context* ctx, const(char)* text)
{
    size_t len  = strlen(ctx.input_text.ptr);
    size_t size = strlen(text) + 1;
    assert(len + size <= ctx.input_text.sizeof,
        "len + size <= ctx.input_text.sizeof");
    memcpy(ctx.input_text.ptr + len, text, size);
}

/*============================================================================
** commandlist
**============================================================================*/

mu_Command* mu_push_command(mu_Context* ctx, int type)
{
    mu_Command* cmd = &ctx.command_list.items[ctx.command_list.idx];
    cmd.base.type = type;
    ++ctx.command_list.idx;
    return cmd;
}

/// Get the range of commands as they appear in the command list,
/// useful with a foreach loop.
///
/// However, if you do care about zindex ordering (for multi-window),
/// use mu_get_next_command instead.
/// Params: ctx = ddui context.
/// Returns: Commands.
mu_Command[] mu_command_range(mu_Context* ctx)
{
    return ctx.command_list.items.ptr[0 .. ctx.command_list.idx];
}

/// An alternative to mu_command_range, iterate commands in z-index order
/// by following JUMP commands, useful if you plan to use multi-window.
/// Params:
///     ctx = ddui context.
///     cmd = Command pointer, needs to be intiated to null.
/// Returns: 1 while there are commands.
// Initialize cmd to null, call in a while loop. Returns 1 while commands remain.
int mu_get_next_command(mu_Context* ctx, mu_Command** cmd)
{
    if (*cmd)
    {
        *cmd = *cmd + 1;
    }
    else // First
    {
        *cmd = ctx.command_list.items.ptr;
    }
    while (*cmd != &ctx.command_list.items[ctx.command_list.idx])
    {
        if ((*cmd).type != MU_COMMAND_JUMP)
        {
            return 1;
        }
        *cmd = &ctx.command_list.items[(*cmd).jump.dst_idx];
    }
    return 0;
}

deprecated("Use mu_get_next_command.")
int mu_next_command(mu_Context* ctx, mu_Command** cmd)
{
    return mu_get_next_command(ctx, cmd);
}

int mu_push_jump(mu_Context* ctx, int idx)
{
    mu_Command *cmd = mu_push_command(ctx, MU_COMMAND_JUMP);
    cmd.jump.dst_idx = idx;
    assert(cmd == &ctx.command_list.items[ctx.command_list.idx - 1]);
    return cast(int)(ctx.command_list.idx - 1);
}

void mu_set_clip(mu_Context* ctx, mu_Rect rect)
{
    mu_Command* cmd = mu_push_command(ctx, MU_COMMAND_CLIP/*, mu_ClipCommand.sizeof*/);
    cmd.clip.rect = rect;
}

void mu_draw_rect(mu_Context* ctx, mu_Rect rect, mu_Color color)
{
    rect = mu_intersect_rects(rect, mu_get_clip_rect(ctx));
    if (rect.w > 0 && rect.h > 0)
    {
        mu_Command* cmd = mu_push_command(ctx, MU_COMMAND_RECT/*, mu_RectCommand.sizeof*/);
        cmd.rect.rect = rect;
        cmd.rect.color = color;
    }
}

void mu_draw_box(mu_Context* ctx, mu_Rect rect, mu_Color color)
{
    mu_draw_rect(ctx, mu_Rect(rect.x + 1, rect.y, rect.w - 2, 1), color);
    mu_draw_rect(ctx, mu_Rect(rect.x + 1, rect.y + rect.h - 1, rect.w - 2, 1), color);
    mu_draw_rect(ctx, mu_Rect(rect.x, rect.y, 1, rect.h), color);
    mu_draw_rect(ctx, mu_Rect(rect.x + rect.w - 1, rect.y, 1, rect.h), color);
}

void mu_draw_text(mu_Context* ctx, mu_Font font, const(char)* str, int len,
    mu_Vec2 pos, mu_Color color)
{
    mu_Rect rect = mu_Rect(pos.x, pos.y, ctx.text_width(font, str, len), ctx.text_height(font));
    int clipped = mu_check_clip(ctx, rect);
    if (clipped == MU_CLIP_ALL)
    {
        return;
    }
    if (clipped == MU_CLIP_PART)
    {
        mu_set_clip(ctx, mu_get_clip_rect(ctx));
    }
    
    // add command
    if (len < 0)
    {
        len = cast(int)strlen(str);
    }
    
    mu_Command* cmd = mu_push_command(ctx, MU_COMMAND_TEXT/*, cast(int)(mu_TextCommand.sizeof + len)*/);
    memcpy(cmd.text.str.ptr, str, len);
    cmd.text.str[len] = '\0';
    cmd.text.pos = pos;
    cmd.text.color = color;
    cmd.text.font = font;
    
    // reset clipping if it was set
    if (clipped)
    {
        mu_set_clip(ctx, unclipped_rect);
    }
}

void mu_draw_icon(mu_Context* ctx, int id, mu_Rect rect, mu_Color color)
{
    // do clip command if the rect isn't fully contained within the cliprect
    int clipped = mu_check_clip(ctx, rect);
    if (clipped == MU_CLIP_ALL)
    {
        return;
    }
    if (clipped == MU_CLIP_PART)
    {
        mu_set_clip(ctx, mu_get_clip_rect(ctx));
    }
    // do icon command
    mu_Command* cmd = mu_push_command(ctx, MU_COMMAND_ICON/*, mu_IconCommand.sizeof*/);
    cmd.icon.id = id;
    cmd.icon.rect = rect;
    cmd.icon.color = color;
    // reset clipping if it was set
    if (clipped)
    {
        mu_set_clip(ctx, unclipped_rect);
    }
}

/*============================================================================
** layout
**============================================================================*/

enum
{
    RELATIVE = 1,
    ABSOLUTE = 2
}

void mu_layout_begin_column(mu_Context* ctx)
{
    mu_push_layout(ctx, mu_layout_next(ctx), mu_Vec2(0, 0));
}

void mu_layout_end_column(mu_Context* ctx)
{
    mu_Layout* b = mu_get_layout(ctx);
    ctx.layout_stack.pop();
    // inherit position/next_row/max from child layout if they are greater
    mu_Layout* a = mu_get_layout(ctx);
    a.position.x = mu_max(a.position.x, b.position.x + b.body_.x - a.body_.x);
    a.next_row = mu_max(a.next_row, b.next_row + b.body_.y - a.body_.y);
    a.max.x = mu_max(a.max.x, b.max.x);
    a.max.y = mu_max(a.max.y, b.max.y);
}

void mu_layout_row(mu_Context* ctx, int items, const(int)* widths, int height)
{
    mu_Layout* layout = mu_get_layout(ctx);
    if (widths)
    {
        assert(items <= MU_MAX_WIDTHS, "items <= MU_MAX_WIDTHS");
        memcpy(layout.widths.ptr, widths, items * widths[0].sizeof);
    }
    layout.items = items;
    layout.position = mu_Vec2(layout.indent, layout.next_row);
    layout.size.y = height;
    layout.item_index = 0;
}

void mu_layout_width(mu_Context* ctx, int width)
{
    mu_get_layout(ctx).size.x = width;
}

void mu_layout_height(mu_Context* ctx, int height)
{
    mu_get_layout(ctx).size.y = height;
}

void mu_layout_set_next(mu_Context* ctx, mu_Rect r, int relative)
{
    mu_Layout* layout = mu_get_layout(ctx);
    layout.next = r;
    layout.next_type = relative ? RELATIVE : ABSOLUTE;
}

mu_Rect mu_layout_next(mu_Context* ctx)
{
    mu_Layout* layout = mu_get_layout(ctx);
    mu_Style* style = ctx.style;
    mu_Rect res = void;

    if (layout.next_type)
    {
        /* handle rect set by `mu_layout_set_next` */
        int type = layout.next_type;
        layout.next_type = 0;
        res = layout.next;
        if (type == ABSOLUTE)
        {
            return (ctx.last_rect = res);
        }
    }
    else
    {
        // handle next row
        if (layout.item_index == layout.items)
        {
            mu_layout_row(ctx, layout.items, null, layout.size.y);
        }

        // position
        res.x = layout.position.x;
        res.y = layout.position.y;

        // size
        res.w = layout.items > 0 ? layout.widths[layout.item_index] : layout.size.x;
        res.h = layout.size.y;
        if (res.w == 0)
        {
            res.w = style.size.x + style.padding * 2;
        }
        if (res.h == 0)
        {
            res.h = style.size.y + style.padding * 2;
        }
        if (res.w < 0)
        {
            res.w += layout.body_.w - res.x + 1;
        }
        if (res.h < 0)
        {
            res.h += layout.body_.h - res.y + 1;
        }

        layout.item_index++;
    }

    // update position
    layout.position.x += res.w + style.spacing;
    layout.next_row = mu_max(layout.next_row, res.y + res.h + style.spacing);

    // apply body_ offset
    res.x += layout.body_.x;
    res.y += layout.body_.y;

    // update max position
    layout.max.x = mu_max(layout.max.x, res.x + res.w);
    layout.max.y = mu_max(layout.max.y, res.y + res.h);

    return (ctx.last_rect = res);
}

/*============================================================================
** controls
**============================================================================*/

int mu_in_hover_root(mu_Context* ctx)
{
    size_t i = ctx.container_stack.idx;
    while (i--)
    {
        if (ctx.container_stack.items[i] == ctx.hover_root)
        {
            return 1;
        }
        // only root containers have their `head` field set; stop searching if we've
        // reached the current root container
        if (ctx.container_stack.items[i].head_idx != -1)
        {
            break;
        }
    }
    return 0;
}

void mu_draw_control_frame(mu_Context* ctx, mu_Id id, mu_Rect rect,
    int colorid, int opt)
{
    if (opt & MU_OPT_NOFRAME)
    {
        return;
    }
    colorid += (ctx.focus == id) ? 2 : (ctx.hover == id) ? 1 : 0;
    ctx.mu_draw_frame(ctx, rect, colorid);
}

void mu_draw_control_text(mu_Context* ctx, const(char)* str, mu_Rect rect,
    int colorid, int opt)
{
    mu_Font font = ctx.style.font;
    int tw = ctx.text_width(font, str, -1);
    mu_push_clip_rect(ctx, rect);
    
    mu_Vec2 pos = void;
    pos.y = rect.y + (rect.h - ctx.text_height(font)) / 2;
    if (opt & MU_OPT_ALIGNCENTER)
    {
        pos.x = rect.x + (rect.w - tw) / 2;
    }
    else if (opt & MU_OPT_ALIGNRIGHT)
    {
        pos.x = rect.x + rect.w - tw - ctx.style.padding;
    }
    else
    {
        pos.x = rect.x + ctx.style.padding;
    }
    
    mu_draw_text(ctx, font, str, -1, pos, ctx.style.colors[colorid]);
    mu_pop_clip_rect(ctx);
}

int mu_mouse_over(mu_Context* ctx, mu_Rect rect)
{
    return rect_overlaps_vec2(rect, ctx.mouse_pos) &&
        rect_overlaps_vec2(mu_get_clip_rect(ctx), ctx.mouse_pos) &&
        mu_in_hover_root(ctx);
}

void mu_update_control(mu_Context* ctx, mu_Id id, mu_Rect rect, int opt)
{
    int mouseover = mu_mouse_over(ctx, rect);

    if (ctx.focus == id)
    {
        ctx.updated_focus = 1;
    }
    
    if (opt & MU_OPT_NOINTERACT)
    {
        return;
    }
    
    if (mouseover && !ctx.mouse_down)
    {
        ctx.hover = id;
    }

    if (ctx.focus == id)
    {
        if (ctx.mouse_pressed && !mouseover)
        {
            mu_set_focus(ctx, 0);
        }
        if (!ctx.mouse_down && ~opt & MU_OPT_HOLDFOCUS)
        {
            mu_set_focus(ctx, 0);
        }
    }

    if (ctx.hover == id)
    {
        if (ctx.mouse_pressed)
        {
            mu_set_focus(ctx, id);
        }
        else if (!mouseover)
        {
            ctx.hover = 0;
        }
    }
}

void mu_text(mu_Context* ctx, const(char)* text)
{
    const(char)* start = void, end = void, p = text;
    int width = -1;
    mu_Font font = ctx.style.font;
    mu_Color color = ctx.style.colors[MU_COLOR_TEXT];
    mu_layout_begin_column(ctx);
    mu_layout_row(ctx, 1, &width, ctx.text_height(font));
    do
    {
        mu_Rect r = mu_layout_next(ctx);
        int w = 0;
        start = end = p;
        do
        {
            const(char)* word = p;
            while (*p && *p != ' ' && *p != '\n')
            {
                ++p;
            }
            w += ctx.text_width(font, word, cast(int)(p - word));
            if (w > r.w && end != start)
            {
                break;
            }
            w += ctx.text_width(font, p, 1);
            end = p++;
        } while (*end && *end != '\n');
        mu_draw_text(ctx, font, start, cast(int)(end - start), mu_Vec2(r.x, r.y), color);
        p = end + 1;
    } while (*end);
    mu_layout_end_column(ctx);
}

void mu_label(mu_Context* ctx, const(char)* text)
{
    mu_draw_control_text(ctx, text, mu_layout_next(ctx), MU_COLOR_TEXT, 0);
}

int mu_button_ex(mu_Context* ctx, const(char)* label, int icon, int opt)
{
    int res = 0;
    mu_Id id = label ?
        mu_get_id(ctx, label, strlen(label)) :
        mu_get_id(ctx, &icon, icon.sizeof);
    mu_Rect r = mu_layout_next(ctx);
    mu_update_control(ctx, id, r, opt);
    
    // handle click
    if (ctx.mouse_pressed == MU_MOUSE_LEFT && ctx.focus == id)
    {
        res |= MU_RES_SUBMIT;
    }
    
    // draw
    mu_draw_control_frame(ctx, id, r, MU_COLOR_BUTTON, opt);
    if (label)
    {
        mu_draw_control_text(ctx, label, r, MU_COLOR_TEXT, opt);
    }
    
    if (icon)
    {
        mu_draw_icon(ctx, icon, r, ctx.style.colors[MU_COLOR_TEXT]);
    }
    
    return res;
}

int mu_checkbox(mu_Context* ctx, const(char)* label, int* state)
{
    int res = 0;
    mu_Id id = mu_get_id(ctx, &state, state.sizeof); // sizeof(state), so pointer?
    mu_Rect r = mu_layout_next(ctx);
    mu_Rect box = mu_Rect(r.x, r.y, r.h, r.h);
    mu_update_control(ctx, id, r, 0);
    
    // handle click
    if (ctx.mouse_pressed == MU_MOUSE_LEFT && ctx.focus == id)
    {
        res |= MU_RES_CHANGE;
        *state = !*state;
    }
    
    // draw
    mu_draw_control_frame(ctx, id, box, MU_COLOR_BASE, 0);
    if (*state)
    {
        mu_draw_icon(ctx, MU_ICON_CHECK, box, ctx.style.colors[MU_COLOR_TEXT]);
    }
    
    r = mu_Rect(r.x + box.w, r.y, r.w - box.w, r.h);
    mu_draw_control_text(ctx, label, r, MU_COLOR_TEXT, 0);
    return res;
}

int mu_textbox_raw(mu_Context* ctx, char* buf, int bufsz, mu_Id id, mu_Rect r,
    int opt)
{
    int res = 0;
    mu_update_control(ctx, id, r, opt | MU_OPT_HOLDFOCUS);

    if (ctx.focus == id)
    {
        // handle text input
        size_t len = strlen(buf);
        size_t n = mu_min(bufsz - len - 1, strlen(ctx.input_text.ptr));
        if (n > 0)
        {
            memcpy(buf + len, ctx.input_text.ptr, n);
            len += n;
            buf[len] = '\0';
            res |= MU_RES_CHANGE;
        }
        
        // handle backspace
        if (ctx.key_pressed & MU_KEY_BACKSPACE && len > 0)
        {
            // skip utf-8 continuation bytes
            while ((buf[--len] & 0xc0) == 0x80 && len > 0) {}
            buf[len] = '\0';
            res |= MU_RES_CHANGE;
        }
        
        // handle return
        if (ctx.key_pressed & MU_KEY_RETURN)
        {
            mu_set_focus(ctx, 0);
            res |= MU_RES_SUBMIT;
        }
    }

    // draw
    mu_draw_control_frame(ctx, id, r, MU_COLOR_BASE, opt);
    if (ctx.focus == id)
    {
        mu_Color color = ctx.style.colors[MU_COLOR_TEXT];
        mu_Font font = ctx.style.font;
        int textw = ctx.text_width(font, buf, -1);
        int texth = ctx.text_height(font);
        int ofx = r.w - ctx.style.padding - textw - 1;
        int textx = r.x + mu_min(ofx, ctx.style.padding);
        int texty = r.y + (r.h - texth) / 2;
        mu_push_clip_rect(ctx, r);
        mu_draw_text(ctx, font, buf, -1, mu_Vec2(textx, texty), color);
        mu_draw_rect(ctx, mu_Rect(textx + textw, texty, 1, texth), color);
        mu_pop_clip_rect(ctx);
    }
    else
    {
        mu_draw_control_text(ctx, buf, r, MU_COLOR_TEXT, opt);
    }

    return res;
}

int mu_number_textbox(mu_Context* ctx, mu_Real* value, mu_Rect r, mu_Id id)
{
    if (ctx.mouse_pressed == MU_MOUSE_LEFT &&
        ctx.key_down & MU_KEY_SHIFT &&
        ctx.hover == id)
    {
        ctx.number_edit = id;
        sprintf(ctx.number_edit_buf.ptr, MU_REAL_FMT, *value);
    }
    
    if (ctx.number_edit == id)
    {
        int res = mu_textbox_raw(
            ctx, ctx.number_edit_buf.ptr, (ctx.number_edit_buf).sizeof, id, r, 0);
        if (res & MU_RES_SUBMIT || ctx.focus != id)
        {
            *value = strtod(ctx.number_edit_buf.ptr, null);
            ctx.number_edit = 0;
        }
        else
        {
            return 1;
        }
    }
    
    return 0;
}

int mu_textbox_ex(mu_Context* ctx, char* buf, int bufsz, int opt)
{
    mu_Id id = mu_get_id(ctx, &buf, buf.sizeof);
    mu_Rect r = mu_layout_next(ctx);
    return mu_textbox_raw(ctx, buf, bufsz, id, r, opt);
}

int mu_slider_ex(mu_Context* ctx, mu_Real* value, mu_Real low, mu_Real high,
    mu_Real step, const(char)* fmt, int opt)
{
    int res = 0;
    mu_Real last = *value, v = last;
    mu_Id id = mu_get_id(ctx, &value, value.sizeof); // out of a pointer? not mu_Real.sizeof?
    mu_Rect base = mu_layout_next(ctx);

    // handle text input mode
    if (mu_number_textbox(ctx, &v, base, id))
    {
        return res;
    }

    // handle normal mode
    mu_update_control(ctx, id, base, opt);

    // handle input
    if (ctx.focus == id &&
        (ctx.mouse_down | ctx.mouse_pressed) == MU_MOUSE_LEFT)
    {
        v = low + (ctx.mouse_pos.x - base.x) * (high - low) / base.w;
        if (step)
        {
            v = ((v + step / 2) / step) * step;
        }
    }
    
    // clamp and store value, update res
    *value = v = mu_clamp(v, low, high);
    if (last != v)
    {
        res |= MU_RES_CHANGE;
    }

    // draw base
    mu_draw_control_frame(ctx, id, base, MU_COLOR_BASE, opt);

    // draw thumb
    int w = ctx.style.thumb_size;
    int x = cast(int)((v - low) * (base.w - w) / (high - low)); //TODO: fix float to int
    mu_Rect thumb = mu_Rect(base.x + x, base.y, w, base.h);
    mu_draw_control_frame(ctx, id, thumb, MU_COLOR_BUTTON, opt);

    // draw text
    char[MU_MAX_FMT] buf = void;
    sprintf(buf.ptr, fmt, v);
    mu_draw_control_text(ctx, buf.ptr, base, MU_COLOR_TEXT, opt);

    return res;
}

int mu_number_ex(mu_Context* ctx, mu_Real* value, mu_Real step,
    const(char)* fmt, int opt)
{
    char[MU_MAX_FMT] buf = void;
    int res = 0;
    mu_Id id = mu_get_id(ctx, &value, value.sizeof); // sizeof(value)
    mu_Rect base = mu_layout_next(ctx);
    mu_Real last = *value;

    // handle text input mode
    if (mu_number_textbox(ctx, value, base, id))
    {
        return res;
    }

    // handle normal mode
    mu_update_control(ctx, id, base, opt);

    // handle input
    if (ctx.focus == id && ctx.mouse_down == MU_MOUSE_LEFT)
    {
        *value += ctx.mouse_delta.x * step;
    }
    // set flag if value changed
    if (*value != last)
    {
        res |= MU_RES_CHANGE;
    }

    // draw base
    mu_draw_control_frame(ctx, id, base, MU_COLOR_BASE, opt);
    // draw text
    sprintf(buf.ptr, fmt, *value);
    mu_draw_control_text(ctx, buf.ptr, base, MU_COLOR_TEXT, opt);

    return res;
}

int mu_header2(mu_Context* ctx, const(char)* label, int istreenode, int opt)
{
    mu_Rect r;
    int active, expanded;
    mu_Id id = mu_get_id(ctx, label, cast(int)strlen(label));
    int idx = mu_pool_get(ctx, ctx.treenode_pool.ptr, MU_TREENODEPOOL_SIZE, id);
    int width = -1;
    mu_layout_row(ctx, 1, &width, 0);

    active = (idx >= 0);
    expanded = (opt & MU_OPT_EXPANDED) ? !active : active;
    r = mu_layout_next(ctx);
    mu_update_control(ctx, id, r, 0);

    // handle click
    active ^= (ctx.mouse_pressed == MU_MOUSE_LEFT && ctx.focus == id);

    // update pool ref
    if (idx >= 0)
    {
        if (active)
        {
            mu_pool_update(ctx, ctx.treenode_pool.ptr, idx);
        }
        else
        {
            memset(&ctx.treenode_pool[idx], 0, mu_PoolItem.sizeof);
        }
    }
    else if (active)
    {
        mu_pool_init(ctx, ctx.treenode_pool.ptr, MU_TREENODEPOOL_SIZE, id);
    }

    // draw
    if (istreenode)
    {
        if (ctx.hover == id)
        {
            ctx.mu_draw_frame(ctx, r, MU_COLOR_BUTTONHOVER);
        }
    }
    else
    {
        mu_draw_control_frame(ctx, id, r, MU_COLOR_BUTTON, 0);
    }
    mu_draw_icon(
        ctx, expanded ? MU_ICON_EXPANDED : MU_ICON_COLLAPSED,
        mu_Rect(r.x, r.y, r.h, r.h), ctx.style.colors[MU_COLOR_TEXT]);
    r.x += r.h - ctx.style.padding;
    r.w -= r.h - ctx.style.padding;
    mu_draw_control_text(ctx, label, r, MU_COLOR_TEXT, 0);

    return expanded ? MU_RES_ACTIVE : 0;
}

int mu_header_ex(mu_Context* ctx, const(char)* label, int opt)
{
    return mu_header2(ctx, label, 0, opt);
}

int mu_begin_treenode_ex(mu_Context* ctx, const(char)* label, int opt)
{
    int res = mu_header2(ctx, label, 1, opt);
    if (res & MU_RES_ACTIVE)
    {
        mu_get_layout(ctx).indent += ctx.style.indent;
        ctx.id_stack.push(ctx.last_id);
    }
    return res;
}

void mu_end_treenode(mu_Context* ctx)
{
    mu_get_layout(ctx).indent -= ctx.style.indent;
    mu_pop_id(ctx);
}

private
void mu_scrollbar(mu_Context* ctx, mu_Container* cnt,
    mu_Rect* b, ref mu_Vec2 cs, const(char)* name)
{
    // only add scrollbar if content size is larger than body_
    int maxscroll = cs.y - b.h;
    if (maxscroll > 0 && b.h > 0)
    {
        mu_Rect base, thumb;
        // "!scrollbar" #y and "!scrollbar" #x
        mu_Id id = mu_get_id(ctx, name, 11);

        // get sizing / positioning
        base = *b;
        base.x = b.x + b.w;
        base.w = ctx.style.scrollbar_size;

        // handle input
        mu_update_control(ctx, id, base, 0);
        if (ctx.focus == id && ctx.mouse_down == MU_MOUSE_LEFT)
        {
            cnt.scroll.y += ctx.mouse_delta.y * cs.y / base.h;
        }

        // clamp scroll to limits
        cnt.scroll.y = mu_clamp(cnt.scroll.y, 0, maxscroll);

        // draw base and thumb
        ctx.mu_draw_frame(ctx, base, MU_COLOR_SCROLLBASE);
        thumb = base;
        thumb.h = mu_max(ctx.style.thumb_size, base.h * b.h / cs.y);
        thumb.y += cnt.scroll.y * (base.h - thumb.h) / maxscroll;
        ctx.mu_draw_frame(ctx, thumb, MU_COLOR_SCROLLTHUMB);

        // set this as the scroll_target (will get scrolled on mousewheel)
        // if the mouse is over it
        if (mu_mouse_over(ctx, *b))
        {
            ctx.scroll_target = cnt;
        }
    }
    else
    {
        cnt.scroll.y = 0;
    }
}

void mu_scrollbars(mu_Context* ctx, mu_Container* cnt, mu_Rect* body_)
{
    int sz = ctx.style.scrollbar_size;
    mu_Vec2 cs = cnt.content_size;
    cs.x += ctx.style.padding * 2;
    cs.y += ctx.style.padding * 2;
    mu_push_clip_rect(ctx, *body_);
    // resize body_ to make room for scrollbars
    if (cs.y > cnt.body_.h)
    {
        body_.w -= sz;
    }
    if (cs.x > cnt.body_.w)
    {
        body_.h -= sz;
    }
    // to create a horizontal or vertical scrollbar almost-identical code is
    // used; only the references to `x|y` `w|h` need to be switched
    mu_scrollbar(ctx, cnt, body_, cs, "!scrollbarx");
    mu_scrollbar(ctx, cnt, body_, cs, "!scrollbary");
    mu_pop_clip_rect(ctx);
}

void mu_push_container_body(mu_Context* ctx, mu_Container* cnt, mu_Rect body_, int opt)
{
    if (~opt & MU_OPT_NOSCROLL)
    {
        mu_scrollbars(ctx, cnt, &body_);
    }
    mu_push_layout(ctx, mu_expand_rect(body_, -ctx.style.padding), cnt.scroll);
    cnt.body_ = body_;
}

void mu_begin_root_container(mu_Context* ctx, mu_Container* cnt)
{
    ctx.container_stack.push(cnt);
    // push container to roots list and push head command
    ctx.root_list.push(cnt);
    cnt.head_idx = mu_push_jump(ctx, -1);
    // set as hover root if the mouse is overlapping this container and it has a
    // higher zindex than the current hover root
    if (rect_overlaps_vec2(cnt.rect, ctx.mouse_pos) &&
        (!ctx.next_hover_root || cnt.zindex > ctx.next_hover_root.zindex))
    {
        ctx.next_hover_root = cnt;
    }
    // clipping is reset here in case a root-container is made within
    // another root-containers's begin/end block; this prevents the inner
    // root-container being clipped to the outer
    ctx.clip_stack.push(unclipped_rect);
}

void mu_end_root_container(mu_Context* ctx)
{
    // push tail 'goto' jump command and set head 'skip' command. the final steps
    // on initing these are done in mu_end()
    mu_Container* cnt = mu_get_current_container(ctx);
    cnt.tail_idx = mu_push_jump(ctx, -1);
    ctx.command_list.items[cnt.head_idx].jump.dst_idx = cast(int)ctx.command_list.idx;
    // pop base clip rect and container
    mu_pop_clip_rect(ctx);
    mu_pop_container(ctx);
}

int mu_begin_window_ex(mu_Context* ctx, const(char)* title, mu_Rect rect, int opt)
{
    mu_Rect body_;
    mu_Id id = mu_get_id(ctx, title, cast(int)strlen(title));
    mu_Container* cnt = mu_get_container2(ctx, id, opt);
    if (!cnt || !cnt.open)
    {
        return 0;
    }
    ctx.id_stack.push(id);

    if (cnt.rect.w == 0)
    {
        cnt.rect = rect;
    }
    mu_begin_root_container(ctx, cnt);
    rect = body_ = cnt.rect;

    // draw frame
    if (~opt & MU_OPT_NOFRAME)
    {
        ctx.mu_draw_frame(ctx, rect, MU_COLOR_WINDOWBG);
    }

    // do title bar
    if (~opt & MU_OPT_NOTITLE)
    {
        mu_Rect tr = rect;
        tr.h = ctx.style.title_height;
        ctx.mu_draw_frame(ctx, tr, MU_COLOR_TITLEBG);

        // do title text
        if (~opt & MU_OPT_NOTITLE)
        {
            mu_Id id3 = mu_get_id(ctx, cast(const(char)*)"!title", 6);
            mu_update_control(ctx, id3, tr, opt);
            mu_draw_control_text(ctx, title, tr, MU_COLOR_TITLETEXT, opt);
            if (id3 == ctx.focus && ctx.mouse_down == MU_MOUSE_LEFT)
            {
                cnt.rect.x += ctx.mouse_delta.x;
                cnt.rect.y += ctx.mouse_delta.y;
            }
            body_.y += tr.h;
            body_.h -= tr.h;
        }

        // do `close` button
        if (~opt & MU_OPT_NOCLOSE)
        {
            mu_Id id1 = mu_get_id(ctx, cast(const(char)*)"!close", 6);
            mu_Rect r = mu_Rect(tr.x + tr.w - tr.h, tr.y, tr.h, tr.h);
            tr.w -= r.w;
            mu_draw_icon(ctx, MU_ICON_CLOSE, r, ctx.style.colors[MU_COLOR_TITLETEXT]);
            mu_update_control(ctx, id1, r, opt);
            if (ctx.mouse_pressed == MU_MOUSE_LEFT && id1 == ctx.focus)
            {
                cnt.open = 0;
            }
        }
    }

    mu_push_container_body(ctx, cnt, body_, opt);

    // do `resize` handle
    if (~opt & MU_OPT_NORESIZE)
    {
        int sz = ctx.style.title_height;
        mu_Id id2 = mu_get_id(ctx, cast(const(char)*)"!resize", 7);
        mu_Rect r = mu_Rect(rect.x + rect.w - sz, rect.y + rect.h - sz, sz, sz);
        mu_update_control(ctx, id2, r, opt);
        if (id2 == ctx.focus && ctx.mouse_down == MU_MOUSE_LEFT)
        {
            cnt.rect.w = mu_max(96, cnt.rect.w + ctx.mouse_delta.x);
            cnt.rect.h = mu_max(64, cnt.rect.h + ctx.mouse_delta.y);
        }
    }

    // resize to content size
    if (opt & MU_OPT_AUTOSIZE)
    {
        mu_Rect r = mu_get_layout(ctx).body_;
        cnt.rect.w = cnt.content_size.x + (cnt.rect.w - r.w);
        cnt.rect.h = cnt.content_size.y + (cnt.rect.h - r.h);
    }

    // close if this is a popup window and elsewhere was clicked
    if (opt & MU_OPT_POPUP && ctx.mouse_pressed && ctx.hover_root != cnt)
    {
        cnt.open = 0;
    }

    mu_push_clip_rect(ctx, cnt.body_);
    return MU_RES_ACTIVE;
}

void mu_end_window(mu_Context* ctx)
{
    mu_pop_clip_rect(ctx);
    mu_end_root_container(ctx);
}

void mu_open_popup(mu_Context* ctx, const(char)* name)
{
    mu_Container* cnt = mu_get_container(ctx, name);
    // set as hover root so popup isn't closed in begin_window_ex()
    ctx.hover_root = ctx.next_hover_root = cnt;
    // position at mouse cursor, open and bring-to-front
    cnt.rect = mu_Rect(ctx.mouse_pos.x, ctx.mouse_pos.y, 1, 1);
    cnt.open = 1;
    mu_bring_to_front(ctx, cnt);
}

int mu_begin_popup(mu_Context* ctx, const(char)* name)
{
    return mu_begin_window_ex(ctx, name, mu_Rect(0, 0, 0, 0),
        MU_OPT_POPUP | MU_OPT_AUTOSIZE | MU_OPT_NORESIZE |
        MU_OPT_NOSCROLL | MU_OPT_NOTITLE | MU_OPT_CLOSED);
}

void mu_end_popup(mu_Context* ctx)
{
    mu_end_window(ctx);
}

mu_Container* mu_begin_panel_ex(mu_Context* ctx, const(char)* name, int opt)
{
    mu_Container* cnt;
    mu_push_id(ctx, name, cast(int)strlen(name));
    cnt = mu_get_container2(ctx, ctx.last_id, opt);
    cnt.rect = mu_layout_next(ctx);
    if (~opt & MU_OPT_NOFRAME)
    {
        ctx.mu_draw_frame(ctx, cnt.rect, MU_COLOR_PANELBG);
    }
    ctx.container_stack.push(cnt);
    mu_push_container_body(ctx, cnt, cnt.rect, opt);
    mu_push_clip_rect(ctx, cnt.body_);
    return cnt;
}

void mu_end_panel(mu_Context* ctx)
{
    mu_pop_clip_rect(ctx);
    mu_pop_container(ctx);
}
