open Mini_qvm.Examples
open Mini_qvm.Quantum_state

let _ =
  print_string "bell(0,1):\n";
  run_quantum_program (bell 0 1) { qm_state = mk_qs 2; register = 0 } |> show_machine |> print_string;
  print_string "\n\nghz(3):\n";
  run_quantum_program (ghz 3) { qm_state = mk_qs 3; register = 0 } |> show_machine |> print_string;
  print_string "\n\nqft(0,1,2):\n";
  run_quantum_program (qft [0;1;2]) { qm_state = mk_qs 3; register = 0 } |> show_machine |> print_string;
  print_string "\n\n10 coin flips:\n";
  for _=0 to 10 do
    flip_coin () |> print_int;
    print_newline ()
  done