#include "zhello.hpp"
#include <cstring>
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

    Greeter::Greeter(const char* name, int age)
    {
        this->name = strdup(name);
        this->age = age;
    }

    Greeter::~Greeter()
    {
        std::free(name);
        std::cout << "Freed\n";
    }

    void Greeter::Greet() const
    {
        std::cout << "Hola, my name is " << name << ", I'm " << age << "\n";
    }
}