require "clang"

module Crystal::ClangInterop
  # Contains a mapping of c++ types to crystal types that have been generated
  @cplusplus_types = Hash(Clang::Type, ASTNode).new()

  protected def cpp_to_crystal_type(clang_type : Clang::Type) : ASTNode
    case clang_type.kind
    when .void? then Crystal::Path.new("Void")
    when .bool? then Crystal::Path.new("Bool")
    when .u_int? then Crystal::Path.new("UInt32")
    when .int? then Crystal::Path.new("Int32")
    when .long_long? then Crystal::Path.new("Int64")
    when .u_long_long? then Crystal::Path.new("Uint64")
    when .float? then Crystal::Path.new("Float32")
    when .double? then Crystal::Path.new("Float64")
    when .char_s?, .char_u? then Crystal::Path.new(["LibC", "Char"])
    when .pointer?
      pointee_type = cpp_to_crystal_type(clang_type.pointee_type)

      Crystal::Generic.new(
        Crystal::Path.new("Pointer"),
        [pointee_type] of Crystal::ASTNode
      )
    else @cplusplus_types[clang_type]? || Crystal::Path.new("Untyped")
    end
  end

  protected def visit_cpp_nodes(fileOfInterest, parent, location, deep=0)
    ast_nodes = Array(ASTNode).new()

    parent.visit_children do |cursor|
      if deep == 0
        unless cursor.kind.macro_definition? ||
          cursor.kind.macro_expansion? ||
          cursor.kind.inclusion_directive?
        end
      else
        print " " * deep
      end

      #puts "#{cursor.kind}: spelling=#{cursor.spelling} type.kind=#{cursor.type.kind} type.spelling=#{cursor.type.spelling.inspect} at #{cursor.location}"

      case cursor.kind
      when .class_decl?
        cstruct = CStructOrUnionDef.new(name: cursor.spelling)

        # add the type to the mapping in case the type is recursive
        @cplusplus_types[cursor.type] = cstruct

        fields = Array(ASTNode).new()

        cursor.visit_children do |ccursor|
          case ccursor.kind
          when .field_decl?
            fields << Crystal::TypeDeclaration.new(
              Crystal::Var.new(ccursor.spelling.underscore.downcase),
              cpp_to_crystal_type(ccursor.type)
            )
          when .cxx_method?
            method_decl = visit_function_decl(ccursor, Crystal::Arg.new(
              name: "this",
              restriction: Crystal::Generic.new(
                Crystal::Path.new("Pointer"),
                [Crystal::Path.new(cursor.spelling)] of Crystal::ASTNode)
            ))
            # structs in the lib definition can't contain methods, so
            # this bit is gonna add it directly to the enclosing scope instead of as a member of this
            # structs body
            ast_nodes << method_decl
          when .constructor?
            ctor_decl = visit_function_decl(ccursor, Crystal::Arg.new(
              name: "this",
              restriction: Crystal::Generic.new(
                Crystal::Path.new("Pointer"),
                [Crystal::Path.new(cursor.spelling)] of Crystal::ASTNode)
            ), special_name: "initialize_#{cursor.spelling.downcase.underscore}")
            ast_nodes << ctor_decl
          when .destructor?
            dtor_decl = visit_function_decl(ccursor, Crystal::Arg.new(
              name: "this",
              restriction: Crystal::Generic.new(
                Crystal::Path.new("Pointer"),
                [Crystal::Path.new(cursor.spelling)] of Crystal::ASTNode)
            ), special_name: "deinitialize_#{cursor.spelling.downcase.underscore}")
            ast_nodes << dtor_decl
          end
          Clang::ChildVisitResult::Continue
        end

        cstruct.body = Expressions.from(fields)
        ast_nodes << cstruct

        puts [:class, cursor.type.size_of].inspect
      when .field_decl?
        puts [:field, cursor.offset_of_field].inspect
      when .function_decl? then ast_nodes << visit_function_decl(cursor)
        #puts fun_def.inspect
      when .constructor?
        puts [:constructor, cursor.cxx_manglings].inspect
      when .destructor?
        puts [:destructor, cursor.cxx_manglings].inspect

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

  protected def visit_function_decl(cursor, this_pointer : Crystal::Arg? = nil, special_name : String? = nil)
    func_args = [] of Crystal::Arg

    if this_pointer
      func_args << this_pointer
    end

    cursor.arguments.each_with_index do |arg, i|
      argument_name = arg.spelling
      if argument_name.empty?; argument_name = "arg#{i}"; end
      
      func_args << Crystal::Arg.new(
        name: argument_name,
        restriction: cpp_to_crystal_type(arg.type)
      )
    end

    Crystal::FunDef.new(
      name: special_name || cursor.spelling.underscore.downcase,
      args: func_args,
      return_type: cpp_to_crystal_type(cursor.result_type),
      real_name: if cursor.mangling.starts_with?("__ZN"); cursor.mangling[1..-1]; else cursor.mangling; end,
    )
  end
end