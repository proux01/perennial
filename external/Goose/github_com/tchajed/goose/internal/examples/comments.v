(* autogenerated from github.com/tchajed/goose/internal/examples/comments *)
From Perennial.goose_lang Require Import prelude.
Section code.
Context `{ext_ty: ext_types}.
Local Coercion Var' s: expr := Var s.

(* 0consts.go *)

Definition ONE : expr := #1.

Definition TWO : expr := #2.

(* 1doc.go *)

(* comments tests package comments, like this one

   it has multiple files *)

Definition Foo := struct.decl [
  "a" :: boolT
].

End code.
