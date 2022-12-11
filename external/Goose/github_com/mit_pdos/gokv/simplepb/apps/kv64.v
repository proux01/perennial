(* autogenerated from github.com/mit-pdos/gokv/simplepb/apps/kv64 *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.mit_pdos.gokv.map_marshal.
From Goose Require github_com.mit_pdos.gokv.simplepb.clerk.
From Goose Require github_com.mit_pdos.gokv.simplepb.simplelog.
From Goose Require github_com.tchajed.marshal.

From Perennial.goose_lang Require Import ffi.grove_prelude.

(* 1_server.go *)

Definition KVState := struct.decl [
  "kvs" :: mapT (slice.T byteT)
].

Definition OP_PUT : expr := #(U8 0).

Definition OP_GET : expr := #(U8 1).

(* begin arg structs and marshalling *)
Definition PutArgs := struct.decl [
  "Key" :: uint64T;
  "Val" :: slice.T byteT
].

Definition EncodePutArgs: val :=
  rec: "EncodePutArgs" "args" :=
    let: "enc" := ref_to (slice.T byteT) (NewSliceWithCap byteT #1 (#8 + slice.len (struct.loadF PutArgs "Val" "args"))) in
    SliceSet byteT (![slice.T byteT] "enc") #0 OP_PUT;;
    "enc" <-[slice.T byteT] marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF PutArgs "Key" "args");;
    "enc" <-[slice.T byteT] marshal.WriteBytes (![slice.T byteT] "enc") (struct.loadF PutArgs "Val" "args");;
    ![slice.T byteT] "enc".

Definition DecodePutArgs: val :=
  rec: "DecodePutArgs" "raw_args" :=
    let: "enc" := ref_to (slice.T byteT) "raw_args" in
    let: "args" := struct.alloc PutArgs (zero_val (struct.t PutArgs)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF PutArgs "Key" "args" "0_ret";;
    struct.storeF PutArgs "Val" "args" "1_ret";;
    "args".

Definition getArgs: ty := uint64T.

Definition EncodeGetArgs: val :=
  rec: "EncodeGetArgs" "args" :=
    let: "enc" := ref_to (slice.T byteT) (NewSliceWithCap byteT #1 #8) in
    SliceSet byteT (![slice.T byteT] "enc") #0 OP_GET;;
    "enc" <-[slice.T byteT] marshal.WriteInt (![slice.T byteT] "enc") "args";;
    ![slice.T byteT] "enc".

Definition DecodeGetArgs: val :=
  rec: "DecodeGetArgs" "raw_args" :=
    let: ("key", <>) := marshal.ReadInt "raw_args" in
    "key".

Definition KVState__put: val :=
  rec: "KVState__put" "s" "args" :=
    MapInsert (struct.loadF KVState "kvs" "s") (struct.loadF PutArgs "Key" "args") (struct.loadF PutArgs "Val" "args");;
    NewSlice byteT #0.

Definition KVState__get: val :=
  rec: "KVState__get" "s" "args" :=
    Fst (MapGet (struct.loadF KVState "kvs" "s") "args").

Definition KVState__apply: val :=
  rec: "KVState__apply" "s" "args" :=
    let: "ret" := ref (zero_val (slice.T byteT)) in
    let: "n" := slice.len "args" in
    (if: (SliceGet byteT "args" #0 = OP_PUT)
    then "ret" <-[slice.T byteT] KVState__put "s" (DecodePutArgs (SliceSubslice byteT "args" #1 "n"))
    else
      (if: (SliceGet byteT "args" #0 = OP_GET)
      then "ret" <-[slice.T byteT] KVState__get "s" (DecodeGetArgs (SliceSubslice byteT "args" #1 "n"))
      else Panic ("unexpected op type")));;
    ![slice.T byteT] "ret".

Definition KVState__getState: val :=
  rec: "KVState__getState" "s" :=
    map_marshal.EncodeMapU64ToBytes (struct.loadF KVState "kvs" "s").

Definition KVState__setState: val :=
  rec: "KVState__setState" "s" "snap" :=
    let: ("0_ret", "1_ret") := map_marshal.DecodeMapU64ToBytes "snap" in
    struct.storeF KVState "kvs" "s" "0_ret";;
    "1_ret";;
    #().

Definition MakeKVStateMachine: val :=
  rec: "MakeKVStateMachine" <> :=
    let: "s" := struct.alloc KVState (zero_val (struct.t KVState)) in
    struct.storeF KVState "kvs" "s" (NewMap (slice.T byteT) #());;
    struct.new simplelog.InMemoryStateMachine [
      "ApplyVolatile" ::= KVState__apply "s";
      "GetState" ::= KVState__getState "s";
      "SetState" ::= KVState__setState "s"
    ].

Definition Start: val :=
  rec: "Start" "fname" "me" :=
    let: "r" := simplelog.MakePbServer (MakeKVStateMachine #()) "fname" in
    pb.Server__Serve "r" "me";;
    #().

(* clerk.go *)

Definition Clerk := struct.decl [
  "cl" :: ptrT
].

Definition MakeClerk: val :=
  rec: "MakeClerk" "confHost" :=
    struct.new Clerk [
      "cl" ::= clerk.Make "confHost"
    ].

Definition Clerk__Put: val :=
  rec: "Clerk__Put" "ck" "key" "val" :=
    let: "putArgs" := struct.new PutArgs [
      "Key" ::= "key";
      "Val" ::= "val"
    ] in
    clerk.Clerk__Apply (struct.loadF Clerk "cl" "ck") (EncodePutArgs "putArgs");;
    #().

Definition Clerk__Get: val :=
  rec: "Clerk__Get" "ck" "key" :=
    clerk.Clerk__Apply (struct.loadF Clerk "cl" "ck") (EncodeGetArgs "key").