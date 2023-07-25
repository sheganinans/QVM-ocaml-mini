open Batteries

let h =
  let open Complex in
  let s = div one (sqrt (of_int 2)) in
  Owl_dense_matrix_z.of_array [| s; s; s; neg s |] 2 2

let cnot =
  let open Owl_dense_matrix_z in
  let ret = eye 4 in
  swap_rows ret 2 3;
  ret

let cphase angle =
  let open Owl_dense_matrix_z in
  let ret = eye 4 in
  set ret 3 3 Complex.(exp (mul i (of_float angle)));
  ret

let bell p q =
  [ Ast.Gate ({m=h}, [p]);
    Ast.Gate ({m=cnot}, [p; q]) ]

let ghz n =
  Ast.Gate ({m=h}, [0])
    :: (0 -- (n-2)
        |> Enum.map (fun i -> Ast.Gate ({m=cnot}, [i; 1+i]))
        |> List.of_enum)

let rec qft qbits =
  let open List in
  let bit_rev qbits =
    let n = length qbits in
    if n < 2
    then []
    else
      map2 (fun qs qe -> Ast.Gate ({m=Quantum_state.swap}, [qs; qe]))
        qbits
        (rev qbits)
      |> take (n / 2) in
  let qft_ qbits =
    match qbits with
    | [] -> []
    | q :: [] -> [Ast.Gate ({m=h}, [q])]
    | q :: qs ->
      let n = length qs + 1 in
      let cr =
        qs |> mapi (fun i qi ->
          let angle = Float.pi /. (2. ** Float.of_int (n-(i+1))) in
          Ast.Gate ({m=cphase angle}, [q; qi] )) in
      append (qft qs) (append cr [Ast.Gate ({m=h}, [q])]) in
  append (qft_ qbits) (bit_rev qbits)

let flip_coin () =
  let open Quantum_state in
  (run_quantum_program
    [Ast.Gate ({m=h}, [0]); Measure]
    { qm_state = mk_qs 1; register = 0 }).register
