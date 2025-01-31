From Perennial.program_proof Require Export grove_prelude.
From Perennial.program_logic Require Export atomic. (* prefer the ncfupd atomics *)
(* Prefer untyped slices. *)
Export Perennial.goose_lang.lib.slice.slice.

Definition dbval := option string.
Canonical Structure dbvalO := leibnizO dbval.
Notation Nil := (None : dbval).
Notation Value x := (Some x : dbval).

Definition to_dbval (b : bool) (v : string) :=
  if b then Value v else Nil.

Definition dbmap := gmap u64 dbval.

Definition N_TXN_SITES : Z := 16.

Definition keys_all : gset u64 := fin_to_set u64.
Definition sids_all : list u64 := U64 <$> seqZ 0 N_TXN_SITES.

(* Invariant namespaces. *)
Definition mvccN := nroot .@ "mvcc".
Definition mvccNSST := mvccN .@ "sst".
Definition mvccNGC := mvccN .@ "gc".
Definition mvccNTID := mvccN .@ "tid".
