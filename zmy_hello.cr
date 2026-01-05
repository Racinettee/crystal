@[Link(ldflags: "#{__DIR__}/zhello.o -lstdc++")]
require "./zhello.hpp"

LibHello.say_hi()
LibHello.say_hello_to("hudson".to_unsafe)

puts LibHello.plus_one(1)

person = LibHello::Greeter.new()
LibHello.initialize_greeter(pointerof(person), "Garth", 41)
#person.name = "Garth".to_unsafe
#person.age = 40
LibHello.greet(pointerof(person))
LibHello.deinitialize_greeter(pointerof(person))
