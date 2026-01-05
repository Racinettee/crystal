@[Link(ldflags: "#{__DIR__}/zhello.o -lstdc++")]
require "./zhello.hpp"

LibHello.say_hi()
LibHello.say_hello_to("hudson".to_unsafe)

puts LibHello.plus_one(1)

lib LibHello2
    struct HelloStruct2
        value : Int32
    end
end

module Hello
    class Blah
        def hello
        end
    end
end