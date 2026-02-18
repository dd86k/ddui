/// DDUI Skeleton — minimal SDL2 + OpenGL ES 2.0 example
module skeleton;

import core.stdc.stdio : printf;
import core.stdc.string;
import bindbc.opengl;
import bindbc.sdl;
import ddui;
import renderer.sdl2.gles2;

extern (C):

__gshared int window_width  = 800;
__gshared int window_height = 600;
__gshared SDL_Window *window;
__gshared SDL_GLContext glctx;
__gshared mu_Context uictx;

void main()
{
    // Load SDL
    SDLSupport sdlstatus = loadSDL();
    if (sdlstatus == SDLSupport.noLibrary)
        assert(0, "No SDL libraries found on system, aborting.");
    else if (sdlstatus == SDLSupport.badLibrary)
        assert(0, "SDL library older than configuration, aborting.");

    // Setup SDL for OpenGL ES 2.0
    SDL_SetHint(SDL_HINT_VIDEO_HIGHDPI_DISABLED, "0");
    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_EVENTS);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

    window = SDL_CreateWindow("Skeleton",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        window_width, window_height,
        SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);
    SDL_SetWindowMinimumSize(window, 400, 300);
    glctx = SDL_GL_CreateContext(window);
    SDL_GL_SetSwapInterval(1);

    // OpenGL setup (must happen before any glGetString calls)
    initiate_renderer();

    import std.compiler : version_major, version_minor;
    printf("* COMPILER    : "~__VENDOR__~" v%u.%03u\n", version_major, version_minor);
    printf("* GL_RENDERER : %s\n", glGetString(GL_RENDERER));
    printf("* GL_VERSION  : %s\n", glGetString(GL_VERSION));

    // Init UI
    mu_init(&uictx);
    uictx.text_width  = &text_width;
    uictx.text_height = &text_height;

    Lapp: while (true)
    {
        SDL_Event e = void;
        while (SDL_PollEvent(&e))
        {
            switch (e.type)
            {
                case SDL_QUIT: break Lapp;
                case SDL_MOUSEMOTION:
                    mu_input_mousemove(&uictx, e.motion.x, e.motion.y);
                    continue;
                case SDL_MOUSEWHEEL:
                    mu_input_scroll(&uictx, 0, e.wheel.y * -30);
                    continue;
                case SDL_TEXTINPUT:
                    mu_input_text(&uictx, e.text.text.ptr);
                    continue;

                case SDL_WINDOWEVENT:
                    if (e.window.event == SDL_WINDOWEVENT_RESIZED)
                    {
                        window_width  = e.window.data1;
                        window_height = e.window.data2;
                    }
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

        // Process UI
        mu_begin(&uictx);
        skeleton_window(&uictx);
        mu_end(&uictx);

        // Render
        r_clear(mu_Color(cast(ubyte)bg[0], cast(ubyte)bg[1], cast(ubyte)bg[2], 255));
        mu_Command *cmd;
        while (mu_get_next_command(&uictx, &cmd))
        {
            switch (cmd.type)
            {
                case MU_COMMAND_TEXT: r_draw_text(cmd.text.str.ptr, cmd.text.pos, cmd.text.color); break;
                case MU_COMMAND_RECT: r_draw_rect(cmd.rect.rect, cmd.rect.color); break;
                case MU_COMMAND_ICON: r_draw_icon(cmd.icon.id, cmd.icon.rect, cmd.icon.color); break;
                case MU_COMMAND_CLIP: r_set_clip_rect(cmd.clip.rect); break;
                default:
            }
        }
        r_present();
    }

    destroy_renderer();
    SDL_GL_DeleteContext(glctx);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

private:

__gshared float[3] bg = [ 90, 95, 100 ];

void skeleton_window(mu_Context *ctx)
{
    enum opts = MU_OPT_NOTITLE | MU_OPT_NORESIZE | MU_OPT_NOCLOSE | MU_OPT_NOFRAME | MU_OPT_NOSCROLL;
    if (mu_begin_window_ex(ctx, "Skeleton", mu_Rect(0, 0, window_width, window_height), opts))
    {
        mu_Container *win = mu_get_current_container(ctx);
        win.rect = mu_Rect(0, 0, window_width, window_height);

        static immutable int[1] cols = [ -1 ];
        mu_layout_row(ctx, 1, cols.ptr, 0);
        mu_label(ctx, "DDUI Skeleton - OpenGL ES 2.0");

        if (mu_header_ex(ctx, "Background Color", MU_OPT_EXPANDED))
        {
            static immutable int[2] cols2 = [ 46, -1 ];
            mu_layout_row(ctx, 2, cols2.ptr, 0);
            mu_label(ctx, "Red:");   mu_slider(ctx, &bg[0], 0, 255);
            mu_label(ctx, "Green:"); mu_slider(ctx, &bg[1], 0, 255);
            mu_label(ctx, "Blue:");  mu_slider(ctx, &bg[2], 0, 255);
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
