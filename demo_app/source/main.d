/// DDUI SDL2 full-window app demo
module demo;

import core.stdc.stdio : printf, sprintf, snprintf;
import core.stdc.string;
import core.stdc.ctype;
import core.stdc.stdarg;
import bindbc.opengl;
import bindbc.sdl, bindbc.sdl.dynload;
import ddui, stopwatch;
version (Demo_GL33)
    import renderer.sdl2.gl33;
else
    import renderer.sdl2.gl11;

extern (C):

// Start and runtime window dimension.
__gshared int window_width  = 960;
__gshared int window_height = 640;
__gshared SDL_Window *window;
__gshared SDL_GLContext glctx;
__gshared mu_Context uictx;

void main(int argc, const(char) **args)
{
    bool cli_debug;
    int  cli_vsync = 1;

    for (int argi = 1; argi < argc; ++argi)
    {
        const(char) *arg = args[argi];

        if (strcmp(arg, "--debug") == 0)
            cli_debug = true;
        else if (strcmp(arg, "--vsync") == 0)
            cli_vsync = 1;
        else if (strcmp(arg, "--no-vsync") == 0)
            cli_vsync = 0;
        else if (strcmp(arg, "--adaptive-vsync") == 0)
            cli_vsync = -1;
    }

    if (cli_debug)
    {
        printf("* mu_Context.sizeof: %zu\n", mu_Context.sizeof);
        printf("* mu_Command.sizeof: %zu\n", mu_Command.sizeof);
    }

    import std.compiler : version_major, version_minor;
    printf("* COMPILER    : "~__VENDOR__~" v%u.%03u\n", version_major, version_minor);
    printf("* CONFIG      : "~CONFIGURATION~"\n");

    SDLSupport sdlstatus = loadSDL();
    switch (sdlstatus) with (SDLSupport) {
    case noLibrary:  assert(0, "No SDL libraries found on system, aborting.");
    case badLibrary: assert(0, "SDL library older than configuration, aborting.");
    default:
    }

    // Setup SDL
    SDL_SetHint(SDL_HINT_VIDEO_HIGHDPI_DISABLED, "0");
    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_EVENTS);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    version (Demo_GL33)
    {
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    }
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

    // Initiate SDL window
    window = SDL_CreateWindow("DDUI App Demo",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        window_width, window_height,
        SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);
    SDL_SetWindowMinimumSize(window, 600, 400);
    glctx  = SDL_GL_CreateContext(window);
    SDL_GL_SetSwapInterval(cli_vsync);

    // Print SDL version
    SDL_version verconf = void, verdyn = void;
    SDL_VERSION(&verconf);
    SDL_GetVersion(&verdyn);
    printf("* SDL_VERSION : %u.%u.%u configured, %u.%u.%u running\n",
        verconf.major, verconf.minor, verconf.patch,
        verdyn.major, verdyn.minor, verdyn.patch);

    // OpenGL setup
    initiate_renderer();
    printf("* GL_RENDERER : %s\n", glGetString(GL_RENDERER));
    printf("* GL_VERSION  : %s\n", glGetString(GL_VERSION));
    if (cli_debug)
        printf("* GL_EXTENSIONS : %s\n", glGetString(GL_EXTENSIONS));

    // Init UI
    mu_init(&uictx);
    uictx.text_width  = &text_width;
    uictx.text_height = &text_height;

    stopwatch_t.setup();

    Lgame: while (true)
    {
        // Transmit SDL input events to UI
        SDL_Event e = void;
        sw_input.start;
        while (SDL_PollEvent(&e))
        {
            switch (e.type)
            {
                case SDL_QUIT: break Lgame;

                case SDL_WINDOWEVENT:
                    if (e.window.event == SDL_WINDOWEVENT_RESIZED)
                    {
                        window_width  = e.window.data1;
                        window_height = e.window.data2;
                    }
                    continue;

                case SDL_MOUSEMOTION:
                    mu_input_mousemove(&uictx, e.motion.x, e.motion.y);
                    continue;
                case SDL_MOUSEWHEEL:
                    mu_input_scroll(&uictx, 0, e.wheel.y * -30);
                    continue;
                case SDL_TEXTINPUT:
                    mu_input_text(&uictx, e.text.text.ptr);
                    continue;

                case SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP:
                    int b = button_map[e.button.button & 0xff];
                    if (!b) continue;
                    switch (e.type) {
                    case SDL_MOUSEBUTTONDOWN:
                        mu_input_mousedown(&uictx, e.button.x, e.button.y, b);
                        continue;
                    case SDL_MOUSEBUTTONUP:
                        mu_input_mouseup(&uictx, e.button.x, e.button.y, b);
                        continue;
                    default: continue;
                    }

                case SDL_KEYDOWN, SDL_KEYUP:
                    int k = key_map[e.key.keysym.sym & 0xff];
                    if (!k) continue;
                    switch (e.type) {
                    case SDL_KEYDOWN: mu_input_keydown(&uictx, k); continue;
                    case SDL_KEYUP:   mu_input_keyup(&uictx, k);   continue;
                    default:
                    }
                    continue;

                default:
            }
        }
        sw_input.stop;

        // Process UI
        sw_ui.stop;
        mu_begin(&uictx);
        full_window(&uictx);
        mu_end(&uictx);
        sw_ui.start;

        // Clear screen and process rendering commands from UI
        stat_commands = uictx.command_list.idx;
        stat_id       = uictx.id_stack.idx;
        sw_commands.start;
        r_clear(mu_Color(cast(ubyte)bg[0], cast(ubyte)bg[1], cast(ubyte)bg[2], 255));
        foreach (ref mu_Command cmd ; mu_command_range(&uictx))
        {
            switch (cmd.type)
            {
                case MU_COMMAND_TEXT: r_draw_text(cmd.text.str.ptr, cmd.text.pos, cmd.text.color); continue;
                case MU_COMMAND_RECT: r_draw_rect(cmd.rect.rect, cmd.rect.color); continue;
                case MU_COMMAND_ICON: r_draw_icon(cmd.icon.id, cmd.icon.rect, cmd.icon.color); continue;
                case MU_COMMAND_CLIP: r_set_clip_rect(cmd.clip.rect); continue;
                default: continue;
            }
        }
        sw_commands.stop;

        // Render screen
        sw_render.start;
        r_present();
        sw_render.stop;
    }

    destroy_renderer();
    SDL_GL_DeleteContext(glctx);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

private:

__gshared stopwatch_t sw_input;
__gshared stopwatch_t sw_ui;
__gshared stopwatch_t sw_commands;
__gshared stopwatch_t sw_render;

__gshared size_t stat_commands;
__gshared size_t stat_id;

// --- Active navigation tab ---
enum Tab { color_mixer, calculator, style_editor }
__gshared Tab active_tab = Tab.color_mixer;

// --- Main layout ---

void full_window(mu_Context *ctx)
{
    enum opt = MU_OPT_NOTITLE | MU_OPT_NORESIZE | MU_OPT_NOCLOSE | MU_OPT_NOFRAME | MU_OPT_NOSCROLL;

    if (mu_begin_window_ex(ctx, "Full Window", mu_Rect(0, 0, window_width, window_height), opt))
    {
        mu_Container *win = mu_get_current_container(ctx);
        win.rect = mu_Rect(0, 0, window_width, window_height);

        // Three-column layout: sidebar | content | console
        int[3] top_cols = [ 150, -250, -1 ];
        mu_layout_row(ctx, 3, top_cols.ptr, -1);

        // --- Left: navigation sidebar ---
        mu_layout_begin_column(ctx);
        sidebar_panel(ctx);
        mu_layout_end_column(ctx);

        // --- Center: active content ---
        mu_layout_begin_column(ctx);
        content_panel(ctx);
        mu_layout_end_column(ctx);

        // --- Right: console log ---
        mu_layout_begin_column(ctx);
        console_panel(ctx);
        mu_layout_end_column(ctx);

        mu_end_window(ctx);
    }
}

// --- Sidebar: navigation tree + background color ---

void sidebar_panel(mu_Context *ctx)
{
    if (mu_header_ex(ctx, "Navigation", MU_OPT_EXPANDED))
    {
        static immutable int[1] cols = [ -1 ];
        mu_layout_row(ctx, 1, cols.ptr, 0);

        if (mu_button(ctx, "Color Mixer"))  { active_tab = Tab.color_mixer;   write_log("Opened Color Mixer"); }
        if (mu_button(ctx, "Calculator"))   { active_tab = Tab.calculator;    write_log("Opened Calculator"); }
        if (mu_button(ctx, "Style Editor")) { active_tab = Tab.style_editor;  write_log("Opened Style Editor"); }
    }

    if (mu_header_ex(ctx, "Background", MU_OPT_EXPANDED))
    {
        static immutable int[2] cols = [ 36, -1 ];
        mu_layout_row(ctx, 2, cols.ptr, 0);
        mu_label(ctx, "R:"); mu_slider(ctx, &bg[0], 0, 255);
        mu_label(ctx, "G:"); mu_slider(ctx, &bg[1], 0, 255);
        mu_label(ctx, "B:"); mu_slider(ctx, &bg[2], 0, 255);
    }

    if (mu_header(ctx, "About"))
    {
        static immutable int[1] cols = [ -1 ];
        mu_layout_row(ctx, 1, cols.ptr, 0);
        mu_text(ctx, "DDUI App Demo");
        mu_text(ctx, "An immediate-mode UI library ported from microui.");
    }
}

// --- Center content: switches based on active tab ---

void content_panel(mu_Context *ctx)
{
    final switch (active_tab)
    {
        case Tab.color_mixer:   color_mixer_panel(ctx);  return;
        case Tab.calculator:    calculator_panel(ctx);   return;
        case Tab.style_editor:  style_editor_panel(ctx); return;
    }
}

// --- Color Mixer ---

__gshared float[4][4] mixer_colors = [
    [ 255, 60, 60, 255 ],    // color A
    [ 60, 120, 255, 255 ],   // color B
    [ 0, 0, 0, 0 ],          // result (computed)
    [ 50, 0, 0, 0 ],         // mix ratio (index 0 = ratio%)
];

void color_mixer_panel(mu_Context *ctx)
{
    if (mu_header_ex(ctx, "Color Mixer", MU_OPT_EXPANDED))
    {
        static immutable int[1] full = [ -1 ];

        // Color A
        mu_layout_row(ctx, 1, full.ptr, 0);
        mu_label(ctx, "Color A:");
        static immutable int[2] cols = [ 50, -1 ];
        mu_layout_row(ctx, 2, cols.ptr, 0);
        mu_label(ctx, "Red:");   mu_slider(ctx, &mixer_colors[0][0], 0, 255);
        mu_label(ctx, "Green:"); mu_slider(ctx, &mixer_colors[0][1], 0, 255);
        mu_label(ctx, "Blue:");  mu_slider(ctx, &mixer_colors[0][2], 0, 255);
        mu_label(ctx, "Alpha:"); mu_slider(ctx, &mixer_colors[0][3], 0, 255);

        // Color A preview
        mu_layout_row(ctx, 1, full.ptr, 30);
        mu_Rect ra = mu_layout_next(ctx);
        mu_draw_rect(ctx, ra, mu_Color(
            cast(ubyte)mixer_colors[0][0], cast(ubyte)mixer_colors[0][1],
            cast(ubyte)mixer_colors[0][2], cast(ubyte)mixer_colors[0][3]));
        char[32] bufa = void;
        sprintf(bufa.ptr, "#%02X%02X%02X%02X",
            cast(int)mixer_colors[0][0], cast(int)mixer_colors[0][1],
            cast(int)mixer_colors[0][2], cast(int)mixer_colors[0][3]);
        mu_draw_control_text(ctx, bufa.ptr, ra, MU_COLOR_TEXT, MU_OPT_ALIGNCENTER);

        // Color B
        mu_layout_row(ctx, 1, full.ptr, 0);
        mu_label(ctx, "Color B:");
        mu_layout_row(ctx, 2, cols.ptr, 0);
        mu_label(ctx, "Red:");   mu_slider(ctx, &mixer_colors[1][0], 0, 255);
        mu_label(ctx, "Green:"); mu_slider(ctx, &mixer_colors[1][1], 0, 255);
        mu_label(ctx, "Blue:");  mu_slider(ctx, &mixer_colors[1][2], 0, 255);
        mu_label(ctx, "Alpha:"); mu_slider(ctx, &mixer_colors[1][3], 0, 255);

        // Color B preview
        mu_layout_row(ctx, 1, full.ptr, 30);
        mu_Rect rb = mu_layout_next(ctx);
        mu_draw_rect(ctx, rb, mu_Color(
            cast(ubyte)mixer_colors[1][0], cast(ubyte)mixer_colors[1][1],
            cast(ubyte)mixer_colors[1][2], cast(ubyte)mixer_colors[1][3]));
        char[32] bufb = void;
        sprintf(bufb.ptr, "#%02X%02X%02X%02X",
            cast(int)mixer_colors[1][0], cast(int)mixer_colors[1][1],
            cast(int)mixer_colors[1][2], cast(int)mixer_colors[1][3]);
        mu_draw_control_text(ctx, bufb.ptr, rb, MU_COLOR_TEXT, MU_OPT_ALIGNCENTER);

        // Mix ratio
        mu_layout_row(ctx, 2, cols.ptr, 0);
        mu_label(ctx, "Mix %:"); mu_slider(ctx, &mixer_colors[3][0], 0, 100);

        // Compute mixed color
        float t = mixer_colors[3][0] / 100.0f;
        for (int i = 0; i < 4; ++i)
            mixer_colors[2][i] = mixer_colors[0][i] * (1.0f - t) + mixer_colors[1][i] * t;

        // Result preview (larger)
        mu_layout_row(ctx, 1, full.ptr, 50);
        mu_Rect rr = mu_layout_next(ctx);
        mu_draw_rect(ctx, rr, mu_Color(
            cast(ubyte)mixer_colors[2][0], cast(ubyte)mixer_colors[2][1],
            cast(ubyte)mixer_colors[2][2], cast(ubyte)mixer_colors[2][3]));
        char[48] bufr = void;
        sprintf(bufr.ptr, "Result: #%02X%02X%02X%02X",
            cast(int)mixer_colors[2][0], cast(int)mixer_colors[2][1],
            cast(int)mixer_colors[2][2], cast(int)mixer_colors[2][3]);
        mu_draw_control_text(ctx, bufr.ptr, rr, MU_COLOR_TEXT, MU_OPT_ALIGNCENTER);

        // Log result button
        mu_layout_row(ctx, 1, full.ptr, 0);
        if (mu_button(ctx, "Copy Result to Console"))
        {
            char[64] msg = void;
            sprintf(msg.ptr, "Mixed: #%02X%02X%02X%02X (%.0f%%)",
                cast(int)mixer_colors[2][0], cast(int)mixer_colors[2][1],
                cast(int)mixer_colors[2][2], cast(int)mixer_colors[2][3],
                mixer_colors[3][0]);
            write_log(msg.ptr);
        }
    }

    // Color palette grid
    if (mu_header_ex(ctx, "Palette", MU_OPT_EXPANDED))
    {
        // 8-column grid of preset colors
        enum PCOLS = 8;
        static immutable int[PCOLS] pcols = [ 30, 30, 30, 30, 30, 30, 30, 30 ];
        mu_layout_row(ctx, PCOLS, pcols.ptr, 24);

        static immutable ubyte[4][16] palette = [
            [ 0,   0,   0,   255 ], [ 127, 127, 127, 255 ],
            [ 255, 0,   0,   255 ], [ 255, 127, 0,   255 ],
            [ 255, 255, 0,   255 ], [ 0,   255, 0,   255 ],
            [ 0,   255, 255, 255 ], [ 0,   0,   255, 255 ],
            [ 127, 0,   255, 255 ], [ 255, 0,   255, 255 ],
            [ 255, 255, 255, 255 ], [ 191, 191, 191, 255 ],
            [ 127, 0,   0,   255 ], [ 0,   127, 0,   255 ],
            [ 0,   0,   127, 255 ], [ 127, 127, 0,   255 ],
        ];

        for (int i = 0; i < 16; ++i)
        {
            mu_Rect pr = mu_layout_next(ctx);
            mu_Color pc = mu_Color(palette[i][0], palette[i][1], palette[i][2], palette[i][3]);
            mu_draw_rect(ctx, pr, pc);
            mu_draw_box(ctx, pr, ctx.style.colors[MU_COLOR_BORDER]);

            // Click to load into Color A or Color B
            mu_Id pid = mu_get_id(ctx, &i, int.sizeof);
            mu_update_control(ctx, pid, pr, 0);
            if (ctx.mouse_pressed == MU_MOUSE_LEFT && ctx.focus == pid)
            {
                for (int c = 0; c < 4; ++c)
                    mixer_colors[0][c] = palette[i][c];
                write_log("Loaded palette color into A");
            }
            else if (ctx.mouse_pressed == MU_MOUSE_RIGHT && ctx.focus == pid)
            {
                for (int c = 0; c < 4; ++c)
                    mixer_colors[1][c] = palette[i][c];
                write_log("Loaded palette color into B");
            }
        }

        static immutable int[1] full = [ -1 ];
        mu_layout_row(ctx, 1, full.ptr, 0);
        mu_text(ctx, "Left-click: load into A. Right-click: load into B.");
    }
}

// --- Calculator ---

__gshared float calc_a = 0;
__gshared float calc_b = 0;
__gshared float calc_result = 0;
__gshared char[64] calc_display = "0\0";
__gshared int calc_op = 0; // 0=none 1=+ 2=- 3=* 4=/

void calculator_panel(mu_Context *ctx)
{
    if (mu_header_ex(ctx, "Calculator", MU_OPT_EXPANDED))
    {
        static immutable int[1] full = [ -1 ];
        static immutable int[2] num_cols = [ 80, -1 ];

        // Numeric inputs using mu_number
        mu_layout_row(ctx, 2, num_cols.ptr, 0);
        mu_label(ctx, "Value A:"); mu_number(ctx, &calc_a, 1);
        mu_label(ctx, "Value B:"); mu_number(ctx, &calc_b, 1);

        // Operation buttons
        static immutable int[4] op_cols = [ 60, 60, 60, 60 ];
        mu_layout_row(ctx, 4, op_cols.ptr, 0);
        if (mu_button(ctx, "+")) { calc_result = calc_a + calc_b; calc_op = 1; }
        if (mu_button(ctx, "-")) { calc_result = calc_a - calc_b; calc_op = 2; }
        if (mu_button(ctx, "*")) { calc_result = calc_a * calc_b; calc_op = 3; }
        if (mu_button(ctx, "/"))
        {
            if (calc_b != 0)
            {
                calc_result = calc_a / calc_b;
                calc_op = 4;
            }
            else
            {
                write_log("Error: division by zero");
                calc_op = 0;
            }
        }

        // Result display
        mu_layout_row(ctx, 1, full.ptr, 30);
        mu_Rect rr = mu_layout_next(ctx);
        mu_draw_rect(ctx, rr, ctx.style.colors[MU_COLOR_BASE]);
        mu_draw_box(ctx, rr, ctx.style.colors[MU_COLOR_BORDER]);
        char[64] rbuf = void;
        static immutable ops = "?+-*/";
        sprintf(rbuf.ptr, "%.2f %c %.2f = %.4f",
            calc_a, ops[calc_op], calc_b, calc_result);
        mu_draw_control_text(ctx, rbuf.ptr, rr, MU_COLOR_TEXT, MU_OPT_ALIGNCENTER);

        // Quick actions
        mu_layout_row(ctx, 2, num_cols.ptr, 0);
        if (mu_button(ctx, "Result -> A")) { calc_a = calc_result; write_log("Result copied to A"); }
        if (mu_button(ctx, "Log Result"))
        {
            char[80] msg = void;
            sprintf(msg.ptr, "Calc: %.2f %c %.2f = %.4f",
                calc_a, ops[calc_op], calc_b, calc_result);
            write_log(msg.ptr);
        }
    }

    // Unit converter
    if (mu_header_ex(ctx, "Unit Converter", MU_OPT_EXPANDED))
    {
        __gshared float celsius = 20;
        __gshared float pixels  = 16;
        __gshared float degrees = 0;

        static immutable int[2] cols = [ 80, -1 ];
        mu_layout_row(ctx, 2, cols.ptr, 0);

        // Temperature
        mu_label(ctx, "Celsius:"); mu_number(ctx, &celsius, 0.5);
        {
            char[48] buf = void;
            float fahr = celsius * 9.0f / 5.0f + 32.0f;
            sprintf(buf.ptr, "= %.1f F / %.1f K", fahr, celsius + 273.15f);
            mu_label(ctx, ""); mu_label(ctx, buf.ptr);
        }

        // Pixels to em/rem
        mu_label(ctx, "Pixels:"); mu_number(ctx, &pixels, 1);
        {
            char[48] buf = void;
            sprintf(buf.ptr, "= %.3f em (base 16)", pixels / 16.0f);
            mu_label(ctx, ""); mu_label(ctx, buf.ptr);
        }

        // Degrees to radians
        mu_label(ctx, "Degrees:"); mu_number(ctx, &degrees, 1);
        {
            char[48] buf = void;
            sprintf(buf.ptr, "= %.4f rad", degrees * 3.14159265f / 180.0f);
            mu_label(ctx, ""); mu_label(ctx, buf.ptr);
        }
    }

    // Checkboxes and state
    if (mu_header(ctx, "Toggles"))
    {
        __gshared int[5] toggles = [ 1, 0, 1, 0, 1 ];
        static immutable int[1] full = [ -1 ];
        mu_layout_row(ctx, 1, full.ptr, 0);
        mu_checkbox(ctx, "Enable feature A", &toggles[0]);
        mu_checkbox(ctx, "Enable feature B", &toggles[1]);
        mu_checkbox(ctx, "Verbose logging",  &toggles[2]);
        mu_checkbox(ctx, "Dark mode",        &toggles[3]);
        mu_checkbox(ctx, "Auto-refresh",     &toggles[4]);

        int count = 0;
        for (int i = 0; i < 5; ++i)
            if (toggles[i]) ++count;
        char[32] buf = void;
        sprintf(buf.ptr, "%d of 5 enabled", count);
        mu_label(ctx, buf.ptr);
    }
}

// --- Style Editor ---

struct color_t
{
    const(char) *label;
    int idx;
}

immutable color_t[] colors = [
    { "text",         MU_COLOR_TEXT        },
    { "border",       MU_COLOR_BORDER      },
    { "windowbg",     MU_COLOR_WINDOWBG    },
    { "titlebg",      MU_COLOR_TITLEBG     },
    { "titletext",    MU_COLOR_TITLETEXT   },
    { "panelbg",      MU_COLOR_PANELBG     },
    { "button",       MU_COLOR_BUTTON      },
    { "buttonhover",  MU_COLOR_BUTTONHOVER },
    { "buttonfocus",  MU_COLOR_BUTTONFOCUS },
    { "base",         MU_COLOR_BASE        },
    { "basehover",    MU_COLOR_BASEHOVER   },
    { "basefocus",    MU_COLOR_BASEFOCUS   },
    { "scrollbase",   MU_COLOR_SCROLLBASE  },
    { "scrollthumb",  MU_COLOR_SCROLLTHUMB },
    { null }
];

void style_editor_panel(mu_Context *ctx)
{
    if (mu_header_ex(ctx, "Theme Colors", MU_OPT_EXPANDED))
    {
        int sw = cast(int)(mu_get_current_container(ctx).body_.w * 0.14f);
        int[6] r = [ 80, sw, sw, sw, sw, -1 ];
        mu_layout_row(ctx, 6, r.ptr, 0);
        for (size_t i; colors[i].label; ++i)
        {
            mu_label(ctx, colors[i].label);
            uint8_slider(ctx, &ctx.style.colors[i].r, 0, 255);
            uint8_slider(ctx, &ctx.style.colors[i].g, 0, 255);
            uint8_slider(ctx, &ctx.style.colors[i].b, 0, 255);
            uint8_slider(ctx, &ctx.style.colors[i].a, 0, 255);
            mu_draw_rect(ctx, mu_layout_next(ctx), ctx.style.colors[i]);
        }
    }

    if (mu_header(ctx, "Spacing"))
    {
        __gshared float spacing = 0;
        __gshared float padding = 5;
        __gshared float indent  = 24;
        static immutable int[2] cols = [ 80, -1 ];
        mu_layout_row(ctx, 2, cols.ptr, 0);
        mu_label(ctx, "Spacing:"); mu_number(ctx, &spacing, 1);
        mu_label(ctx, "Padding:"); mu_number(ctx, &padding, 1);
        mu_label(ctx, "Indent:");  mu_number(ctx, &indent, 1);
        ctx.style.spacing = cast(int)spacing;
        ctx.style.padding = cast(int)padding;
        ctx.style.indent  = cast(int)indent;
    }
}

int uint8_slider(mu_Context *ctx, ubyte *value, int low, int high)
{
    mu_push_id(ctx, &value, value.sizeof);
    float tmp = *value;
    int res = mu_slider_ex(ctx, &tmp, low, high, 0, "%.0f", MU_OPT_ALIGNCENTER);
    *value = cast(ubyte)tmp;
    mu_pop_id(ctx);
    return res;
}

// --- Console panel ---

void console_panel(mu_Context *ctx)
{
    static immutable int[1] cols1 = [ -1 ];
    mu_layout_row(ctx, 1, cols1.ptr, -25);
    mu_begin_panel(ctx, "Log Output");
    mu_Container *panel = mu_get_current_container(ctx);
    mu_layout_row(ctx, 1, cols1.ptr, -1);
    mu_text(ctx, logbuf.ptr);
    mu_end_panel(ctx);
    if (logbuf_updated) {
        panel.scroll.y = panel.content_size.y;
        logbuf_updated = 0;
    }

    // Input textbox + submit button
    static immutable int[2] cols2 = [ -70, -1 ];
    __gshared char[128] buf = [ 0 ];
    int submitted = 0;
    mu_layout_row(ctx, 2, cols2.ptr, 0);
    if (mu_textbox(ctx, buf.ptr, 128) & MU_RES_SUBMIT) {
        mu_set_focus(ctx, ctx.last_id);
        submitted = 1;
    }
    if (mu_button(ctx, "Submit")) { submitted = 1; }
    if (submitted) {
        write_log(buf.ptr);
        buf[0] = '\0';
    }
}

// --- Shared state ---

__gshared char[64000] logbuf = 0;
__gshared      size_t logi;
__gshared         int logbuf_updated = 0;
__gshared    float[3] bg = [ 45, 50, 55 ];

void write_log(const(char) *text)
{
    size_t l = strlen(text);
    if (l == 0) return;
    memcpy(logbuf.ptr + logi, text, l);
    logi += l;
    logbuf[logi] = '\n';
    logbuf[++logi] = 0;
    logbuf_updated = 1;
}

/// SDL-DDUI mouse button mapping
immutable const(ubyte)[256] button_map = [
    SDL_BUTTON_LEFT   & 0xff :  MU_MOUSE_LEFT,
    SDL_BUTTON_RIGHT  & 0xff :  MU_MOUSE_RIGHT,
    SDL_BUTTON_MIDDLE & 0xff :  MU_MOUSE_MIDDLE,
];

/// SDL-DDUI keyboard key mapping
immutable const(ubyte)[256] key_map = [
    SDLK_LSHIFT       & 0xff : MU_KEY_SHIFT,
    SDLK_RSHIFT       & 0xff : MU_KEY_SHIFT,
    SDLK_LCTRL        & 0xff : MU_KEY_CTRL,
    SDLK_RCTRL        & 0xff : MU_KEY_CTRL,
    SDLK_LALT         & 0xff : MU_KEY_ALT,
    SDLK_RALT         & 0xff : MU_KEY_ALT,
    SDLK_RETURN       & 0xff : MU_KEY_RETURN,
    SDLK_KP_ENTER     & 0xff : MU_KEY_RETURN,
    SDLK_BACKSPACE    & 0xff : MU_KEY_BACKSPACE,
];

int text_width(mu_Font font, const(char) *text, int len)
{
    if (len == -1) { len = cast(int)strlen(text); }
    return r_get_text_width(text, len);
}

int text_height(mu_Font font)
{
    return r_get_text_height();
}
