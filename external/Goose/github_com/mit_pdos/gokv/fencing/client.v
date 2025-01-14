(* autogenerated from github.com/mit-pdos/gokv/fencing/client *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.mit_pdos.gokv.fencing.config.
From Goose Require github_com.mit_pdos.gokv.fencing.frontend.

From Perennial.goose_lang Require Import ffi.grove_prelude.

Definition Clerk := struct.decl [
  "configCk" :: ptrT;
  "frontendCk" :: ptrT
].

Definition Clerk__FetchAndIncrement: val :=
  rec: "Clerk__FetchAndIncrement" "ck" "key" :=
    let: "ret" := ref (zero_val uint64T) in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "err" := frontend.Clerk__FetchAndIncrement (struct.loadF Clerk "frontendCk" "ck") "key" "ret" in
      (if: ("err" = #0)
      then Break
      else
        let: "currentFrontend" := config.Clerk__Get (struct.loadF Clerk "configCk" "ck") in
        struct.storeF Clerk "frontendCk" "ck" (frontend.MakeClerk "currentFrontend");;
        Continue));;
    ![uint64T] "ret".

Definition MakeClerk: val :=
  rec: "MakeClerk" "configHost" :=
    let: "ck" := struct.alloc Clerk (zero_val (struct.t Clerk)) in
    struct.storeF Clerk "configCk" "ck" (config.MakeClerk "configHost");;
    let: "currentFrontend" := config.Clerk__Get (struct.loadF Clerk "configCk" "ck") in
    struct.storeF Clerk "frontendCk" "ck" (frontend.MakeClerk "currentFrontend");;
    "ck".
