open Batteries

let id2x2 = Owl_dense_matrix_z.eye 2

let swap =
  let open Owl_dense_matrix_z in
  let ret = eye 4 in
  swap_rows ret 1 2;
  ret

let apply_op m c =
  let open Owl_dense_matrix_z in
  let mat_size, _ = shape m in
  let res = Array.init mat_size (fun _ -> Complex.zero) in
  for i=0 to mat_size-1 do
    let el = ref Complex.zero in
    for j=0 to mat_size-1 do
      el := Complex.add !el (Complex.mul (get m i j) (Array.get c j))
    done;
    Array.set res i !el;
  done;
  res

let comp_ops = Owl_dense_matrix_z.dot

let kronecker_prod a b =
  let open Owl_dense_matrix_z in
  let m, n = shape a in
  let p, q = shape b in
  let res = init (m*p) (n*q) (fun _ -> Complex.zero) in
  for i=0 to m-1 do
    for j=0 to n-1 do
      let aij = get a i j in
      let y = i*p in
      let x = j*q in
      for u=0 to p-1 do
        for v=0 to q-1 do
          set res (y+u) (x+v) (Complex.mul aij (get b u v))
  done done done done;
  res

let rec kronecker_exp u n =
  match n with
  | n when n < 1 -> Owl_dense_matrix_z.create 1 1 Complex.one
  | n when n = 1 -> u
  | _ -> kronecker_prod (kronecker_exp u (n-1)) u

let pp_complex_arr fmt xs =
  let open Format in
  fprintf fmt "%s" "[|\n";
  xs |> Array.iter (fun x -> fprintf fmt "    %s;\n" (Complex.to_string x));
  fprintf fmt "%s" "|]"

type machine =
  {
    mutable qm_state: Complex.t array [@printer pp_complex_arr];
    mutable register: int
  }
  [@@deriving show]

let dimension_qbits d = Stdlib.Float.(d |> float_of_int |> log2 |> ceil) |> int_of_float

let mk_qs n = Array.init (Int.pow 2 n) Complex.(fun i -> if i = 0 then one else zero)

let lift u i n =
  let left = kronecker_exp id2x2 (n - i - (u |> Owl_dense_matrix_z.shape |> fst |> dimension_qbits)) in
  let right = kronecker_exp id2x2 i in
  kronecker_prod left (kronecker_prod u right)

let apply_1q_gate state u q = apply_op (lift u q (dimension_qbits (Array.length state))) state

let perm_to_transp permuation =
  let open List in
  let swaps = ref [] in
  for dest = 0 to length permuation - 1 do
    let src = ref (nth permuation dest) in
    while !src < dest do
      src := nth permuation !src
    done;
    match !src, dest with
    | src, dest when src < dest -> swaps := (src, dest) :: !swaps
    | src, dest when src > dest -> swaps := (dest, src) :: !swaps
    | _ -> ()
  done;
  !swaps |> rev

let transps_to_adj_transps transps =
  let open List in
  let expand_cons (a, b) =
    if b - a = 1
    then [a]
    else let trans = of_enum (a -- (b-1)) in trans |> rev |> drop 1 |> append trans
  in transps |> concat_map expand_cons

let apply_nq_gate state u qbits =
  let n = state |> Array.length |> dimension_qbits in
  let swap i = lift swap i n in
  let transps_to_operator trans =
    trans |> List.fold (fun acc x -> comp_ops acc (swap x)) (kronecker_exp id2x2 n) in
  let u01 = lift u 0 n in
  let from_space =
    List.(append (rev qbits) (0 -- (n-1) |> Enum.filter (fun i -> not (mem i qbits)) |> of_enum)) in
  let trans = transps_to_adj_transps (perm_to_transp from_space) in
  let to_from = transps_to_operator trans in
  let from_to = transps_to_operator (List.rev trans) in
  let upq = comp_ops to_from (comp_ops u01 from_to) in
  apply_op upq state

let apply_gate state u qubits  =
  assert (List.length qubits = (u |> Owl_dense_matrix_z.shape |> fst |> dimension_qbits));
  if List.length qubits = 1
  then apply_1q_gate state u (qubits |> List.hd)
  else apply_nq_gate state u qubits

let sample s =
  let rec loop i r =
    let r = r -. Float.pow (Array.get s i |> Complex.to_float |> Float.abs) 2. in
    if r < 0.
    then i
    else loop (i+1) r
  in loop 0 (Random.float 1.)

let collapse s e = s |> Array.mapi Complex.(fun i _ -> if i = e then one else zero)

let observe machine =
  let b = sample machine.qm_state in
  machine.qm_state <- collapse machine.qm_state b;
  machine.register <- b;
  machine

let run_quantum_program prog machine =
  List.fold
    (fun machine i ->
      match i with
      | Ast.Gate ({m = gate}, qbits) ->
        machine.qm_state <- apply_gate machine.qm_state gate qbits;
        machine
      | Ast.Measure -> observe machine)
    machine
    prog