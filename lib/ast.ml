type mat =
  {
    m: Owl_dense_matrix_z.mat [@printer fun fmt -> Owl_pretty.pp_dsnda fmt];
  }
  [@@deriving show]

type instruction =
  | Gate of mat * int list
  | Measure
  [@@deriving show]