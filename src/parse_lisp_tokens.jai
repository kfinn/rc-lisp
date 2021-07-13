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

test_parse_lisp_tokens_with_an_empty_list :: () {
  empty_list_tokens := string.["(", ")"];
  actual := parse_lisp_tokens(empty_list_tokens);
  assert(actual.count == 1);
  actual_first_expression := actual[0];
  assert(actual_first_expression.kind == .LIST);
  actual_first_list_expression := cast(*ListExpression)actual_first_expression;
  assert(actual_first_list_expression.children.count == 0);
} @Test

test_parse_lisp_tokens_with_multiple_root_expressions :: () {
  tokens := string.["some_atom", "another_atom"];
  actual := parse_lisp_tokens(tokens);
  assert(actual.count == 2);

  actual_first_expression := actual[0];
  assert(actual_first_expression.kind == .ATOM);
  actual_first_list_expression := cast(*AtomExpression)actual_first_expression;
  assert(actual_first_list_expression.value == "some_atom");

  actual_second_expression := actual[1];
  assert(actual_second_expression.kind == .ATOM);
  actual_second_list_expression := cast(*AtomExpression)actual_second_expression;
  assert(actual_second_list_expression.value == "another_atom");
} @Test

test_parse_lisp_tokens_with_list_expressions :: () {
  // ((curry + 1) (* 2 (- 3 1)))
  tokens := string.[
    "(",
      "(",
        "curry",
        "+",
        "1",
      ")",
      "(",
        "*",
        "2",
        "(",
          "-",
          "3",
          "4",
        ")",
      ")",
    ")"
  ];

  actual := parse_lisp_tokens(tokens);
  assert(actual.count == 1);

  root_expression := actual[0];
  assert(root_expression.kind == .LIST);
  root_list_expression := cast(*ListExpression)root_expression;
  assert(root_list_expression.children.count == 2);

  curry_expression := root_list_expression.children[0];
  assert(curry_expression.kind == .LIST);
  curry_list_expression := cast(*ListExpression)curry_expression;
  assert(curry_list_expression.children.count == 3);

  curry_list_expression_0 := curry_list_expression.children[0];
  assert(curry_list_expression_0.kind == .ATOM);
  curry_atom_expression := cast(*AtomExpression)curry_list_expression_0;
  assert(curry_atom_expression.value == "curry");

  curry_list_expression_1 := curry_list_expression.children[1];
  assert(curry_list_expression_1.kind == .ATOM);
  plus_atom_expression := cast(*AtomExpression)curry_list_expression_1;
  assert(plus_atom_expression.value == "+");

  curry_list_expression_2 := curry_list_expression.children[2];
  assert(curry_list_expression_2.kind == .ATOM);
  one_atom_expression := cast(*AtomExpression)curry_list_expression_2;
  assert(one_atom_expression.value == "1");

  multiplication_expression := root_list_expression.children[1];
  assert(multiplication_expression.kind == .LIST);
  multiplication_list_expression := cast(*ListExpression)multiplication_expression;
  assert(multiplication_list_expression.children.count == 3);

  multiplication_list_expression_0 := multiplication_list_expression.children[0];
  assert(multiplication_list_expression_0.kind == .ATOM);
  multiplication_atom := cast(*AtomExpression)multiplication_list_expression_0;
  assert(multiplication_atom.value == "*");

  multiplication_list_expression_1 := multiplication_list_expression.children[1];
  assert(multiplication_list_expression_1.kind == .ATOM);
  two_atom := cast(*AtomExpression)multiplication_list_expression_1;
  assert(two_atom.value == "2");

  subtraction_expression := multiplication_list_expression.children[2];
  assert(subtraction_expression.kind == .LIST);
  subtraction_list_expression := cast(*ListExpression)subtraction_expression;
  assert(subtraction_list_expression.children.count == 3);

  subtraction_list_expression_0 := subtraction_list_expression.children[0];
  assert(subtraction_list_expression_0.kind == .ATOM);
  subtraction_atom := cast(*AtomExpression)subtraction_list_expression_0;
  assert(subtraction_atom.value == "-");

  subtraction_list_expression_1 := subtraction_list_expression.children[1];
  assert(subtraction_list_expression_1.kind == .ATOM);
  three_atom := cast(*AtomExpression)subtraction_list_expression_1;
  assert(three_atom.value == "3");

  subtraction_list_expression_2 := subtraction_list_expression.children[2];
  assert(subtraction_list_expression_2.kind == .ATOM);
  four_atom := cast(*AtomExpression)subtraction_list_expression_2;
  assert(four_atom.value == "4");
} @Test
