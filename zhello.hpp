namespace Hello
{
    inline void SayHi()
    {
        extern "C" int puts(const char*);
        puts("Hello, C++");
    }
}