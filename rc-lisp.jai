#import "Basic";
#import "File";
#import "String";
#import "Pool";

ExpressionKind :: enum {
  ATOM;
  LIST;
}

Expression :: struct {
  kind: ExpressionKind;
}

AtomExpression :: struct {
  using expression: Expression;
  expression.kind = .ATOM;

  value: string;
}

ListExpression :: struct {
  using expression: Expression;
  expression.kind = .LIST;

  children: []*Expression;
}

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

lex_lisp_file :: (lisp_file: File) -> []string {
  tokens: [..]string;
  next_token_builder: [..]u8;

  next_byte: u8;
  read_success: bool;
  read_success = file_read(lisp_file, *next_byte, 1);
  while read_success {
    if next_token_builder && character_terminates_token(next_byte) {
      next_token: string;
      next_token.count = next_token_builder.count;
      next_token.data = next_token_builder.data;

      array_add(*tokens, copy_string(next_token));
      array_reset_keeping_memory(*next_token_builder);
    }

    if next_byte == #char "(" {
      array_add(*tokens, "(");
    } else if next_byte == #char ")" {
      array_add(*tokens, ")");
    } else if !character_is_whitespace(next_byte) {
      array_add(*next_token_builder, next_byte);
    }

    read_success = file_read(lisp_file, *next_byte, 1);
  }
  return tokens;
}

parse_lisp_tokens :: (lisp_file_tokens: []string) -> []*Expression {
  children: [..]*Expression;

  next_token_index := 0;
  while next_token_index < lisp_file_tokens.count {
    next_token := lisp_file_tokens[next_token_index];

    assert(next_token != ")", "invalid syntax: extra )");

    if next_token == "(" {
      remaining_tokens := slice(lisp_file_tokens, next_token_index + 1, lisp_file_tokens.count - (next_token_index + 1));
      list_expression, consumed_tokens_count := parse_list_expression_from_tokens(remaining_tokens);
      array_add(*children, list_expression);
      next_token_index += consumed_tokens_count + 1;
    } else {
      atom_expression := New(AtomExpression);
      atom_expression.value = next_token;
      array_add(*children, atom_expression);
      next_token_index += 1;
    }
  }

  return children;
}

parse_list_expression_from_tokens :: (lisp_file_tokens: []string) -> *ListExpression, consumed_tokens_count: int {
  children: [..]*Expression;

  next_token_index := 0;
  while next_token_index < lisp_file_tokens.count {
    next_token := lisp_file_tokens[next_token_index];

    if next_token == "(" {
      remaining_tokens := slice(lisp_file_tokens, next_token_index + 1, lisp_file_tokens.count - (next_token_index + 1));
      list_expression, consumed_tokens_count := parse_list_expression_from_tokens(remaining_tokens);
      array_add(*children, list_expression);
      next_token_index += consumed_tokens_count + 1;
    } else if next_token == ")" {
      result := New(ListExpression);
      result.children = children;
      return result, (next_token_index + 1);
    } else {
      atom_expression := New(AtomExpression);
      atom_expression.value = next_token;
      array_add(*children, atom_expression);
      next_token_index += 1;
    }
  }

  assert(false, "invalid syntax: missing )");
  return null, 0;
}

character_terminates_token :: (character: u8) -> bool {
  return (
    character == #char "(" ||
    character == #char ")" ||
    character_is_whitespace(character)
  );
}

character_is_whitespace :: (character: u8) -> bool {
  return (
    character == #char " " ||
    character == #char "\n" ||
    character == #char "\r"
  );
}

slice :: inline (array: []$T, index: int, count: int) -> []T {
    assert(index >= 0, "index = %", index);
    assert(count >= 0, "count = %", count);
    if index >= array.count return T.[];

    if index + count > array.count {
        count = array.count - index;
    }

    result: [..]T = ---;
    result.data = array.data + index;
    result.count = count;
    return result;
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
