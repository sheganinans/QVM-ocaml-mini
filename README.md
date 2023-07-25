# QVM-ocaml-mini

```text
$ dune exec mini_qvm
bell(0,1):
{ Quantum_state.qm_state =
  [|
    0.707106781187 + i 0.;
    0. + i 0.;
    0. + i 0.;
    0.707106781187 + i 0.;
|];
  register = 0 }

ghz(3):
{ Quantum_state.qm_state =
  [|
    0.707106781187 + i 0.;
    0. + i 0.;
    0. + i 0.;
    0. + i 0.;
    0. + i 0.;
    0. + i 0.;
    0. + i 0.;
    0.707106781187 + i 0.;
|];
  register = 0 }

qft(0,1,2):
{ Quantum_state.qm_state =
  [|
    0.353553390593 + i 0.;
    0.353553390593 + i 0.;
    0.353553390593 + i 0.;
    0.353553390593 + i 0.;
    0.353553390593 + i 0.;
    0.353553390593 + i 0.;
    0.353553390593 + i 0.;
    0.353553390593 + i 0.;
|];
  register = 0 }

10 coin flips:
1
0
1
0
0
1
0
1
0
1
1
```