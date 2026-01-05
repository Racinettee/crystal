#include "zhello.hpp"

#include <iostream>

namespace Hello
{
    void SayHi()
    {
        std::cout << "Hello, C++\n";
    }

    void SayHelloTo(const char* person)
    {
        std::cout << "Hello, " << person << "\n";
    }

    int PlusOne(int value)
    {
        return value + 1;
    }

    Greeter::Greeter(const char* name): name(name)
    {
    }

    void Greeter::Greet() const
    {
        std::cout << "Hola, my name is " << name << "\n";
    }
}