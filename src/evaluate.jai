Value :: struct {

}

evaluate :: (ast: ..*Expression) -> int {
  assert(ast.count == 1);
  assert(ast[0].kind == .LIST);

  list_ast := cast(*ListExpression)ast[0];

  assert(list_ast.children.count >= 3);
  first_child := list_ast.children[0];
  assert(first_child.kind == .ATOM);
  first_child_atom := cast(*AtomExpression)first_child;
  assert(first_child_atom.value == "+");

  operands := slice(list_ast.children, 1, list_ast.children.count - 1);
  sum := 0;
  for operand: operands {
    if #complete operand.kind == {
      case .ATOM;
        atom_operand := cast(*AtomExpression)operand;
        sum += parse_int(*atom_operand.value);
      case .LIST;
        list_operand := cast(*ListExpression)operand;
        sum += evaluate(list_operand);
    }
  }

  return sum;
}

test_evaluate_can_handle_addition :: () {
  plus_atom: AtomExpression;
  plus_atom.value = "+";

  lhs_atom: AtomExpression;
  lhs_atom.value = "1";

  rhs_atom: AtomExpression;
  rhs_atom.value = "2";

  addition_children: [..]*Expression;
  array_add(*addition_children, *plus_atom);
  array_add(*addition_children, *lhs_atom);
  array_add(*addition_children, *rhs_atom);

  addition_list: ListExpression;
  addition_list.children = addition_children;

  result := evaluate(*addition_list);
  assert(result == 3);
} @Test
