#include <string>

namespace Hello
{
    void SayHi();

    void SayHelloTo(const char* person);

    int PlusOne(int value);

    class Greeter
    {
        char* name;
        int age;
    public:
        Greeter(const char* name, int age);
        ~Greeter();

        void Greet() const;
    };
}