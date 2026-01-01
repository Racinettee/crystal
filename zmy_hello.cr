@[Link(ldflags: "#{__DIR__}/zhello.o -lstdc++")]
require "./zhello.hpp"

puts "trying to call say hi:"
Hello.say_hi()