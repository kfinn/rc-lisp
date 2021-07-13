#import "Basic";
#import "Compiler";

#run {  
  build_options := get_build_options();
  build_options.output_type = .NO_OUTPUT;
  set_build_options(build_options);

  test_workspace := compiler_create_workspace("tests");
  if !test_workspace {
    print("Workspace creation failed.\n");
    return;
  }

  test_workspace_options := get_build_options();
  test_workspace_options.output_type = .NO_OUTPUT;
  set_build_options(test_workspace_options, test_workspace);

  compiler_begin_intercept(test_workspace);
  add_build_file("rc-lisp.jai", test_workspace);
  
  tests_count := 0;
  while true {
    message := compiler_wait_for_message();
    if !message break;
    if message.kind == .COMPLETE break;

    if message.kind == .TYPECHECKED {
      message_typechecked := cast(*Message_Typechecked) message;
      for declaration: message_typechecked.declarations {
        if declaration.name {
          for note: declaration.notes {
            if note.text == "Test" {
              add_build_string(sprint("#run %();", declaration.name), test_workspace);
              tests_count += 1;
            }
          }
        }
      }
    }
  }
  compiler_end_intercept(test_workspace);
  print("run % tests\n", tests_count);

  target_workspace := compiler_create_workspace("target");
  target_build_options := get_build_options();
  target_build_options.output_executable_name = "rc-lisp";
  set_build_options(target_build_options, target_workspace);

  compiler_begin_intercept(target_workspace);
  add_build_file("rc-lisp.jai", target_workspace);
  while true {
    message := compiler_wait_for_message();
    if !message break;
    if message.kind == .COMPLETE break;
  }
  compiler_end_intercept(target_workspace);
  print("compiled\n");
};
