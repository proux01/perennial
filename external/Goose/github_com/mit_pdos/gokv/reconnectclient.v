(* autogenerated from github.com/mit-pdos/gokv/reconnectclient *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.mit_pdos.gokv.urpc.

From Perennial.goose_lang Require Import ffi.grove_prelude.

Definition ReconnectingClient := struct.decl [
  "mu" :: ptrT;
  "valid" :: boolT;
  "urpcCl" :: ptrT;
  "making" :: boolT;
  "made_cond" :: ptrT;
  "addr" :: uint64T
].

Definition MakeReconnectingClient: val :=
  rec: "MakeReconnectingClient" "addr" :=
    let: "r" := struct.alloc ReconnectingClient (zero_val (struct.t ReconnectingClient)) in
    struct.storeF ReconnectingClient "mu" "r" (lock.new #());;
    struct.storeF ReconnectingClient "valid" "r" #false;;
    struct.storeF ReconnectingClient "making" "r" #false;;
    struct.storeF ReconnectingClient "made_cond" "r" (lock.newCond (struct.loadF ReconnectingClient "mu" "r"));;
    struct.storeF ReconnectingClient "addr" "r" "addr";;
    "r".

Definition ReconnectingClient__getClient: val :=
  rec: "ReconnectingClient__getClient" "cl" :=
    lock.acquire (struct.loadF ReconnectingClient "mu" "cl");;
    (if: struct.loadF ReconnectingClient "valid" "cl"
    then
      let: "ret" := struct.loadF ReconnectingClient "urpcCl" "cl" in
      lock.release (struct.loadF ReconnectingClient "mu" "cl");;
      "ret"
    else
      struct.storeF ReconnectingClient "making" "cl" #true;;
      lock.release (struct.loadF ReconnectingClient "mu" "cl");;
      let: "newRpcCl" := ref (zero_val ptrT) in
      Skip;;
      (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
        let: "err" := ref (zero_val uint64T) in
        let: ("0_ret", "1_ret") := urpc.TryMakeClient (struct.loadF ReconnectingClient "addr" "cl") in
        "err" <-[uint64T] "0_ret";;
        "newRpcCl" <-[ptrT] "1_ret";;
        (if: (![uint64T] "err" = #0)
        then Break
        else
          time.Sleep #10000000;;
          Continue));;
      lock.acquire (struct.loadF ReconnectingClient "mu" "cl");;
      struct.storeF ReconnectingClient "urpcCl" "cl" (![ptrT] "newRpcCl");;
      lock.condBroadcast (struct.loadF ReconnectingClient "made_cond" "cl");;
      struct.storeF ReconnectingClient "valid" "cl" #true;;
      struct.storeF ReconnectingClient "making" "cl" #false;;
      lock.release (struct.loadF ReconnectingClient "mu" "cl");;
      ![ptrT] "newRpcCl").

Definition ReconnectingClient__Call: val :=
  rec: "ReconnectingClient__Call" "cl" "rpcid" "args" "reply" "timeout_ms" :=
    let: "urpcCl" := ReconnectingClient__getClient "cl" in
    let: "err" := urpc.Client__Call "urpcCl" "rpcid" "args" "reply" "timeout_ms" in
    (if: ("err" = urpc.ErrDisconnect)
    then
      lock.acquire (struct.loadF ReconnectingClient "mu" "cl");;
      struct.storeF ReconnectingClient "valid" "cl" #false;;
      lock.release (struct.loadF ReconnectingClient "mu" "cl")
    else #());;
    "err".

Definition ReconnectingClient__CallStart: val :=
  rec: "ReconnectingClient__CallStart" "cl" "rpcid" "args" "reply" "timeout_ms" :=
    let: "urpcCl" := ReconnectingClient__getClient "cl" in
    let: ("err", "cb") := urpc.Client__CallStart "urpcCl" "rpcid" "args" in
    (if: ("err" = urpc.ErrDisconnect)
    then
      lock.acquire (struct.loadF ReconnectingClient "mu" "cl");;
      struct.storeF ReconnectingClient "valid" "cl" #false;;
      lock.release (struct.loadF ReconnectingClient "mu" "cl")
    else #());;
    (λ: <>,
      (if: ("err" = urpc.ErrDisconnect)
      then "err"
      else urpc.Client__CallComplete "urpcCl" "cb" "reply" "timeout_ms")
      ).
