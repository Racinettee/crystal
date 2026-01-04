require "clang"

module Crystal::ClangInterop
  @cplusplus_types = Hash(Clang::Type, Crystal::Path).new()

  protected def cpp_to_crystal_type(clang_type : Clang::Type) : ASTNode
    case clang_type.kind
    when .void?
      Crystal::Path.new("Void")
    when .bool?
      Crystal::Path.new("Bool")
    when .u_int?
      Crystal::Path.new("UInt32")
    when .int?
      Crystal::Path.new("Int32")
    when .long_long?
      Crystal::Path.new("Int64")
    when .u_long_long?
      Crystal::Path.new("Uint64")
    when .float?
      Crystal::Path.new("Float32")
    when .double?
      Crystal::Path.new("Float64")
    when .pointer?
      pointee_type = cpp_to_crystal_type(clang_type.pointee_type)

      Crystal::Generic.new(
        Crystal::Path.new("Pointer"),
        [pointee_type] of Crystal::ASTNode
      )
    else
      Crystal::Path.new("Untyped")
    end
  end

  protected def visit_cpp_nodes(fileOfInterest, parent, location, deep=0)
    ast_nodes = Array(ASTNode).new()

    parent.visit_children do |cursor|
      if deep == 0
        unless cursor.kind.macro_definition? ||
          cursor.kind.macro_expansion? ||
          cursor.kind.inclusion_directive?
          puts
        end
      else
        print " " * deep
      end

      #puts "#{cursor.kind}: spelling=#{cursor.spelling} type.kind=#{cursor.type.kind} type.spelling=#{cursor.type.spelling.inspect} at #{cursor.location}"

      case cursor.kind
      when .class_decl?
        puts [:class, cursor.type.size_of].inspect
      when .field_decl?
        puts [:field, cursor.offset_of_field].inspect
      when .function_decl?
        func_args = [] of Crystal::Arg

        cursor.arguments.each_with_index do |arg, i|
          argument_name = arg.spelling
          if argument_name.empty?; argument_name = "arg#{i}"; end
          
          func_args << Crystal::Arg.new(
            name: argument_name,
            restriction: cpp_to_crystal_type(arg.type)
          )
        end

        fun_def = Crystal::FunDef.new(
          name: cursor.spelling.underscore.downcase,
          args: func_args,
          return_type: Crystal::Path.new("Void"),
          real_name: if cursor.mangling.starts_with?("__ZN"); cursor.mangling[1..-1]; else cursor.mangling; end,
        )
        ast_nodes << fun_def
        puts [:function, cursor.mangling].inspect
      when .constructor?
        puts [:constructor, cursor.cxx_manglings].inspect
      when .destructor?
        puts [:destructor, cursor.cxx_manglings].inspect
      #when .cxx_method?
      #  puts [:cxx_method, cursor.spelling].inspect
      when .cxx_access_specifier?
        puts [:cxx_access_specifier, cursor.cxx_access_specifier].inspect
      end

      if "#{cursor.location}".includes?(fileOfInterest)
        if cursor.kind == LibC::CXCursorKind::Namespace
          module_nodes = visit_cpp_nodes(fileOfInterest, cursor, location, deep + 2)
          # we've found a namespace
          # create an equivalent module def
          #module_def = Crystal::ModuleDef.new(
          #  name: Crystal::Path.new(cursor.spelling),
          #  body: Expressions.from(module_nodes),
          #)
          lib_def = Crystal::LibDef.new(
            name: Crystal::Path.new("Lib#{cursor.spelling}"),
            body: Expressions.from(module_nodes)
          )
          lib_def.location = location
          #Wmodule_def.resolved_type = NonGenericModuleType.new(@program, nil, cursor.spelling)
          ast_nodes << lib_def
        else
          visit_cpp_nodes(fileOfInterest, cursor, location, deep + 2)
        end
      end
      Clang::ChildVisitResult::Continue
    end
    ast_nodes
  end
end