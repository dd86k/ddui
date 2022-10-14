/// DDUI SDL2 OpenGL1.1 example
module demo;

import core.stdc.stdio : printf, sprintf;
import core.stdc.string;
import core.stdc.ctype;
import core.stdc.stdarg;
import bindbc.opengl;
import bindbc.sdl, bindbc.sdl.dynload;
import ddui;
version (Demo_GL33)
    import renderer.sdl2.gl33;
else
    import renderer.sdl2.gl11;

extern (C):

// Start and runtime window dimension.
__gshared int window_width  = 700;
__gshared int window_height = 550;
__gshared SDL_Window *window;
__gshared SDL_GLContext glctx;

void main()
{
    import std.compiler : version_major, version_minor;
    printf("* COMPILER    : "~__VENDOR__~" v%u.%03u\n", version_major, version_minor);
    
    // Comment this section if you plan to use
    // the bindbc-sdl:staticBC configuration.
    version (Windows)
    {
        loadSDL("sdl2.dll");
    }
    else
    {
        SDLSupport sdlstatus = loadSDL();
        switch (sdlstatus) with (SDLSupport) {
        case noLibrary:  assert(0, "No SDL libraries on system.");
        case badLibrary: assert(0, "Found SDL library older than one configured with.");
        default:
        }
    }
    
    // Setup SDL
    SDL_SetHint(SDL_HINT_VIDEO_HIGHDPI_DISABLED, "0");
    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_EVENTS);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    version (GL33)
    {
        //SDL_GL_SetAttribute (SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    }
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    
    // Initiate SDL window
    window = SDL_CreateWindow("Demo",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        window_width, window_height,
        SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);
    glctx  = SDL_GL_CreateContext(window);
    
    // Print SDL version
    SDL_version  sdlverconf = void, sdlverrt = void;
    SDL_VERSION(&sdlverconf);
    SDL_GetVersion(&sdlverrt);
    printf("* SDL_VERSION : %u.%u.%u configured, %u.%u.%u running\n",
        sdlverconf.major, sdlverconf.minor, sdlverconf.patch,
        sdlverrt.major, sdlverrt.minor, sdlverrt.patch);
    
    // OpenGL setup
    printf("* CONFIG      : "~CONFIGURATION~"\n");
    initiate_renderer();
    printf("* GL_RENDERER : %s\n", glGetString(GL_RENDERER));
    printf("* GL_VERSION  : %s\n", glGetString(GL_VERSION));
    
    // Init UI
    mu_Context ui = void;
    mu_init(&ui);
    ui.text_width  = &text_width;
    ui.text_height = &text_height;
    
    GAME: while (true)
    {
        // Transmit SDL input events to UI
        SDL_Event e = void;
        while (SDL_PollEvent(&e))
        {
            switch (e.type)
            {
                case SDL_QUIT: break GAME;
                case SDL_MOUSEMOTION:
                    mu_input_mousemove(&ui, e.motion.x, e.motion.y);
                    continue;
                case SDL_MOUSEWHEEL:
                    mu_input_scroll(&ui, 0, e.wheel.y * -30);
                    continue;
                case SDL_TEXTINPUT:
                    mu_input_text(&ui, e.text.text.ptr);
                    continue;

                case SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP:
                    int b = button_map[e.button.button & 0xff];
                    if (!b) continue;
                    switch (e.type) {
                    case SDL_MOUSEBUTTONDOWN:
                        mu_input_mousedown(&ui, e.button.x, e.button.y, b);
                        continue;
                    case SDL_MOUSEBUTTONUP:
                        mu_input_mouseup(&ui, e.button.x, e.button.y, b);
                        continue;
                    default: continue;
                    }

                case SDL_KEYDOWN, SDL_KEYUP:
                    int k = key_map[e.key.keysym.sym & 0xff];
                    if (!k) continue;
                    switch (e.type) {
                    case SDL_KEYDOWN: mu_input_keydown(&ui, k); continue;
                    case SDL_KEYUP:   mu_input_keyup(&ui, k);   continue;
                    default:
                    }
                    continue;
                
                default:
            }
        }
        
        // Process UI
        mu_begin(&ui);
        log_window(&ui);
        test_window(&ui);
        style_window(&ui);
        mu_end(&ui);
        
        // Process rendering commands from UI
        r_clear(mu_Color(cast(ubyte)bg[0], cast(ubyte)bg[1], cast(ubyte)bg[2], 255));
        mu_Command *cmd = null;
        while (mu_next_command(&ui, &cmd))
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
    
        // Render screen
        r_present();
    }
    
    destroy_renderer();
    SDL_GL_DeleteContext(glctx);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

private:

void test_window(mu_Context *ctx)
{
    /* do window */
    if (mu_begin_window(ctx, "Demo Window", mu_Rect(40, 40, 300, 450)))
    {
        mu_Container *win = mu_get_current_container(ctx);
        win.rect.w = mu_max(win.rect.w, 240);
        win.rect.h = mu_max(win.rect.h, 300);
        
        // window info
        if (mu_header(ctx, "Window Info"))
        {
            mu_Container *win2 = mu_get_current_container(ctx);
            char[64] buf = void;
            static immutable int[2] r = [ 54, -1 ];
            mu_layout_row(ctx, 2, r.ptr, 0);
            mu_label(ctx, "Position:");
            sprintf(buf.ptr, "%d, %d", win2.rect.x, win2.rect.y); mu_label(ctx, buf.ptr);
            mu_label(ctx, "Size:");
            sprintf(buf.ptr, "%d, %d", win2.rect.w, win2.rect.h); mu_label(ctx, buf.ptr);
        }
        
        // labels + buttons
        if (mu_header_ex(ctx, "Test Buttons", MU_OPT_EXPANDED))
        {
            static immutable int[3] r2 = [ 86, -110, -1 ];
            mu_layout_row(ctx, 3, r2.ptr, 0);
            mu_label(ctx, "Test buttons 1:");
            if (mu_button(ctx, "Button 1")) { write_log("Pressed button 1"); }
            if (mu_button(ctx, "Button 2")) { write_log("Pressed button 2"); }
            mu_label(ctx, "Test buttons 2:");
            if (mu_button(ctx, "Button 3")) { write_log("Pressed button 3"); }
            if (mu_button(ctx, "Popup")) { mu_open_popup(ctx, "Test Popup"); }
            if (mu_begin_popup(ctx, "Test Popup")) {
                mu_button(ctx, "Hello");
                mu_button(ctx, "World");
                mu_end_popup(ctx);
            }
        }
        
        // tree
        if (mu_header_ex(ctx, "Tree and Text", MU_OPT_EXPANDED))
        {
            static immutable int[2] cols1 = [ 140, -1 ];
            mu_layout_row(ctx, 2, cols1.ptr, 0);
            mu_layout_begin_column(ctx);
            if (mu_begin_treenode(ctx, "Test 1")) {
                if (mu_begin_treenode(ctx, "Test 1a")) {
                    mu_label(ctx, "Hello");
                    mu_label(ctx, "world");
                    mu_end_treenode(ctx);
                }
                if (mu_begin_treenode(ctx, "Test 1b")) {
                    if (mu_button(ctx, "Button 1")) { write_log("Pressed button 1"); }
                    if (mu_button(ctx, "Button 2")) { write_log("Pressed button 2"); }
                    mu_end_treenode(ctx);
                }
                mu_end_treenode(ctx);
            }
            if (mu_begin_treenode(ctx, "Test 2"))
            {
                static immutable int[2] cols2 = [ 54, 54 ];
                mu_layout_row(ctx, 2, cols2.ptr, 0);
                if (mu_button(ctx, "Button 3")) { write_log("Pressed button 3"); }
                if (mu_button(ctx, "Button 4")) { write_log("Pressed button 4"); }
                if (mu_button(ctx, "Button 5")) { write_log("Pressed button 5"); }
                if (mu_button(ctx, "Button 6")) { write_log("Pressed button 6"); }
                mu_end_treenode(ctx);
            }
            if (mu_begin_treenode(ctx, "Test 3"))
            {
                __gshared int[3] checks = [ 1, 0, 1 ]; // Mutable
                mu_checkbox(ctx, "Checkbox 1", &checks[0]);
                mu_checkbox(ctx, "Checkbox 2", &checks[1]);
                mu_checkbox(ctx, "Checkbox 3", &checks[2]);
                mu_end_treenode(ctx);
            }
            mu_layout_end_column(ctx);
            
            mu_layout_begin_column(ctx);
            static immutable int[1] cols3 = [ -1 ];
            mu_layout_row(ctx, 1, cols3.ptr, 0);
            mu_text(ctx, 
                "Lorem ipsum dolor sit amet, consectetur adipiscing "~
                "elit. Maecenas lacinia, sem eu lacinia molestie, mi risus faucibus "~
                "ipsum, eu varius magna felis a nulla.");
            mu_layout_end_column(ctx);
        }
        
        /* background color sliders */
        if (mu_header_ex(ctx, "Background Color", MU_OPT_EXPANDED))
        {
            static immutable int[2] cols4 = [ -78, -1 ];
            mu_layout_row(ctx, 2, cols4.ptr, 74);
            // sliders
            mu_layout_begin_column(ctx);
            static immutable int[2] cols5 = [ 46, -1 ];
            mu_layout_row(ctx, 2, cols5.ptr, 0);
            mu_label(ctx, "Red:");   mu_slider(ctx, &bg[0], 0, 255);
            mu_label(ctx, "Green:"); mu_slider(ctx, &bg[1], 0, 255);
            mu_label(ctx, "Blue:");  mu_slider(ctx, &bg[2], 0, 255);
            mu_layout_end_column(ctx);
            // color preview
            mu_Rect r = mu_layout_next(ctx);
            mu_draw_rect(ctx, r,
                mu_Color(cast(ubyte)bg[0], cast(ubyte)bg[1], cast(ubyte)bg[2], 255));
            char[32] buf = void;
            sprintf(buf.ptr, "#%02X%02X%02X",
                cast(int)bg[0], cast(int)bg[1], cast(int)bg[2]);
            mu_draw_control_text(ctx, buf.ptr, r, MU_COLOR_TEXT, MU_OPT_ALIGNCENTER);
        }

        mu_end_window(ctx);
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

void style_window(mu_Context *ctx)
{
    if (mu_begin_window(ctx, "Style Editor", mu_Rect(350, 250, 300, 240))) 
    {
        int sw = cast(int)(mu_get_current_container(ctx).body_.w * 0.14f); // ~1/5
        int[6] r = [ 80, sw, sw, sw, sw, -1 ];
        mu_layout_row(ctx, 6, r.ptr, 0);
        for (int i = 0; colors[i].label; ++i) {
            mu_label(ctx, colors[i].label);
            uint8_slider(ctx, &ctx.style.colors[i].r, 0, 255);
            uint8_slider(ctx, &ctx.style.colors[i].g, 0, 255);
            uint8_slider(ctx, &ctx.style.colors[i].b, 0, 255);
            uint8_slider(ctx, &ctx.style.colors[i].a, 0, 255);
            mu_draw_rect(ctx, mu_layout_next(ctx), ctx.style.colors[i]);
        }
        mu_end_window(ctx);
    }
}

__gshared char[64000] logbuf = 0; // char.init == 0xff, confuses strlen
__gshared      size_t logi;
__gshared         int logbuf_updated = 0;
__gshared    float[3] bg = [ 90, 95, 100 ];

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

void log_window(mu_Context *ctx)
{
    if (mu_begin_window(ctx, "Console", mu_Rect(350, 40, 300, 200)))
    {
        /* output text panel */
        static immutable int[1] cols1 = [ -1 ]; // (int[]) { -1 }
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
        
        /* input textbox + submit button */
        static immutable int[2] cols2 = [ -70, -1 ];
        __gshared char[128] buf = [ 0 ]; // textbox buffer
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
        
        mu_end_window(ctx);
    }
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
