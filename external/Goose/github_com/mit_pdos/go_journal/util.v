(* autogenerated from github.com/mit-pdos/go-journal/util *)
From Perennial.goose_lang Require Import prelude.
Section code.
Context `{ext_ty: ext_types}.
Local Coercion Var' s: expr := Var s.

Definition Debug : expr := #0.

Definition DPrintf: val :=
  rec: "DPrintf" "level" "format" "a" :=
    (if: "level" ≤ Debug
    then
      (* log.Printf(format, a...) *)
      #()
    else #()).

Definition RoundUp: val :=
  rec: "RoundUp" "n" "sz" :=
    ("n" + "sz" - #1) `quot` "sz".

Definition Min: val :=
  rec: "Min" "n" "m" :=
    (if: "n" < "m"
    then "n"
    else "m").

(* returns n+m>=2^64 (if it were computed at infinite precision) *)
Definition SumOverflows: val :=
  rec: "SumOverflows" "n" "m" :=
    "n" + "m" < "n".

Definition SumOverflows32: val :=
  rec: "SumOverflows32" "n" "m" :=
    "n" + "m" < "n".

Definition CloneByteSlice: val :=
  rec: "CloneByteSlice" "s" :=
    let: "s2" := NewSlice byteT (slice.len "s") in
    SliceCopy byteT "s2" "s";;
    "s2".

End code.
