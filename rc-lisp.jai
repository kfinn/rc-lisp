#import "Basic";
#import "File";
#import "String";
#import "Pool";

#load "src/lex_lisp_file.jai";
#load "src/parse_lisp_tokens.jai";

main :: () {
  arguments := get_command_line_arguments();
  defer array_free(arguments);

  assert(arguments.count == 2, "Requires a path to the file to the parse. Ex: rc-lisp some_file.lisp");

  path := arguments[1];
  lisp_file, file_open_success := file_open(path);
  assert(file_open_success, "Failed to open file");
  defer file_close(*lisp_file);

  pool: Pool;
  set_allocators(*pool);
  defer release(*pool);

  {
    push_allocator(pool_allocator, *pool);
    lisp_ast := parse_lisp_file(lisp_file);
    pretty_print_lisp_ast(lisp_ast);
  }
}

parse_lisp_file :: (lisp_file: File) -> []*Expression {;
  tokens := lex_lisp_file(lisp_file);
  return parse_lisp_tokens(tokens);
}

pretty_print_lisp_ast :: (ast: []*Expression, indentation_prefix: string = "") {
  pool: Pool;
  set_allocators(*pool);
  defer release(*pool);

  {
    push_allocator(pool_allocator, *pool);
    for expression: ast {
      if #complete expression.kind == {
        case .LIST;
          list_expression := cast(*ListExpression)expression;

          print("%(\n", indentation_prefix);
          nested_prefix := sprint("%  ", indentation_prefix);
          defer free(nested_prefix);

          pretty_print_lisp_ast(list_expression.children, nested_prefix);

          print("%)\n", indentation_prefix);
        case .ATOM;
          atom_expression := cast(*AtomExpression)expression;
          print("%", indentation_prefix);
          print("%\n", atom_expression.value);
      }
    }
  }
}
