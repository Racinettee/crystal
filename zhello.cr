puts "hello 3"

lib LibHello
    fun say_hi(to : LibC::Char*)
end

LibHello.say_hi("hello".to_unsafe)