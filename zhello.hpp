#include <string>

namespace Hello
{
    void SayHi();

    void SayHelloTo(const char* person);

    class Greeter
    {
        std::string name;
    public:
        Greeter(const char* name);

        void Greet() const;
    };
}