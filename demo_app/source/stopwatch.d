/**
 * Stopwatch module.
 * 
 * Windows uses QueryPerformanceFrequency and QueryPerformanceCounter.
 * Posix platforms use clock_gettime (CLOCK_MONOTONIC).
 */
module stopwatch;

version (Windows)
{
    import core.sys.windows.windows;
    private __gshared long __freq;
}
else version (Posix)
{
    import core.sys.posix.time :
        CLOCK_MONOTONIC, timespec, clock_getres, clock_gettime;
    private enum CLOCK_TYPE = CLOCK_MONOTONIC;
    private enum TIME_NS = 1.0e12;	// ns, used with clock_gettime
    private enum TIME_US = 1.0e9;	// µs, used with clock_gettime
    private enum TIME_MS = 1.0e6;	// ms, used with clock_gettime
    private enum BASE    = TIME_US; // base time
    private __gshared timespec __freq;
}

struct stopwatch_t
{
    version (Windows)
    {
        private alias time_t = long;
    }
    else version (Posix)
    {
        private alias time_t = timespec;
    }
    
    private time_t time0, time1;
    bool running;
    
    static void setup()
    {
        version (Windows)
        {
            LARGE_INTEGER l = void;
            QueryPerformanceFrequency(&l);
            __freq = l.QuadPart;
        }
        else version (Posix)
        {
            clock_getres(CLOCK_TYPE, &__freq);
        }
        //TODO: Take time delta to call os functions
    }
    
    void start()
    {
        version (Windows)
        {
            LARGE_INTEGER l = void;
            QueryPerformanceCounter(&l);
            time0 = l.QuadPart;
        }
        else version (Posix)
        {
            clock_gettime(CLOCK_TYPE, &time0);
        }
        
        running = true;
    }
    
    void stop()
    {
        version (Windows)
        {
            LARGE_INTEGER l = void;
            QueryPerformanceCounter(&l);
            time1 = l.QuadPart;
        }
        else version (Posix)
        {
            clock_gettime(CLOCK_TYPE, &time1);
        }
        running = false;
    }
    
    void reset()
    {
        time0 = time1 = time_t.init;
    }
    
    float ms()
    {
        version (Windows)
        {
            return ((time1 - time0) * 1000.0f) / __freq;
        }
        else version (Posix)
        {
            return cast(float)
                ((BASE * (time1.tv_sec - time0.tv_sec))
                + time1.tv_nsec - time0.tv_nsec) / 1_000_000f;
        }
    }
    
    float us()
    {
        version (Windows)
        {
            return (time1 - time0) / __freq;
        }
        else version (Posix)
        {
            return cast(float)
                ((BASE * (time1.tv_sec - time0.tv_sec))
                + time1.tv_nsec - time0.tv_nsec) / 1_000f;
        }
    }
}