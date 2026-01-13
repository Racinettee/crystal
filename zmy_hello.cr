@[Link(ldflags: "#{__DIR__}/zhello.o -lstdc++")]
require "./zhello.hpp"

LibHello.say_hi()
LibHello.say_hello_to("hudson".to_unsafe)

puts LibHello.plus_one(1)

# Creates and initializes a C++ Greeter
LibHello.initialize_greeter(out person, "Garth", 41)

# alternative way to create an initialize a greeter
#person = Greeter.new()
#person.name = "Garth".to_unsafe
#person.age = 40

# prints "Hola, my name is Garth...", etc
LibHello.greet(pointerof(person))

# Deinit the C++ object
LibHello.deinitialize_greeter(pointerof(person))
