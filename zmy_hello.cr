@[Link(ldflags: "#{__DIR__}/zhello.o -lstdc++")]
require "./zhello.hpp"

puts "trying to call say hi:"
LibHello.say_hi()

module Hello
    class Blah
        def hello
        end
    end
end