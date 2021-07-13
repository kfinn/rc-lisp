lex_lisp_file :: (lisp_file: File) -> []string {
  tokens: [..]string;
  next_token_builder: [..]u8;
  defer array_free(next_token_builder);

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

test_lex_lisp_file :: () {
  lisp_file, file_open_success := file_open("test_program.lisp");
  assert(file_open_success, "Failed to open file");
  defer file_close(*lisp_file);

  pool: Pool;
  set_allocators(*pool);
  defer release(*pool);

  {
    push_allocator(pool_allocator, *pool);
    lisp_tokens := lex_lisp_file(lisp_file);

    expected_tokens := string.[
      "(",
      "first",
      "(",
      "list",
      "1",
      "(",
      "+",
      "2",
      "3",
      ")",
      "9",
      ")",
      ")"
    ];

    assert(lisp_tokens.count == expected_tokens.count);
    for expected_token, index: expected_tokens {
      actual_token := lisp_tokens[index];
      assert(expected_token == actual_token, "Expected %, got %", expected_token, actual_token);
    }
  }
} @Test
