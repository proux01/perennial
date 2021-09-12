(* autogenerated from github.com/mit-pdos/gokv/bank *)
From Perennial.goose_lang Require Import prelude.
From Perennial.goose_lang Require Import ffi.grove_prelude.

From Goose Require github_com.mit_pdos.gokv.connman.
From Goose Require github_com.mit_pdos.gokv.lockservice.
From Goose Require github_com.mit_pdos.gokv.memkv.

Definition BankClerk := struct.decl [
  "lck" :: struct.ptrT lockservice.LockClerk;
  "kvck" :: struct.ptrT memkv.MemKVClerk;
  "acc1" :: uint64T;
  "acc2" :: uint64T
].

Definition acquire_two: val :=
  rec: "acquire_two" "lck" "l1" "l2" :=
    (if: "l1" < "l2"
    then
      lockservice.LockClerk__Lock "lck" "l1";;
      lockservice.LockClerk__Lock "lck" "l2"
    else
      lockservice.LockClerk__Lock "lck" "l2";;
      lockservice.LockClerk__Lock "lck" "l1");;
    #().

Definition release_two: val :=
  rec: "release_two" "lck" "l1" "l2" :=
    (if: "l1" < "l2"
    then
      lockservice.LockClerk__Unlock "lck" "l2";;
      lockservice.LockClerk__Unlock "lck" "l1"
    else
      lockservice.LockClerk__Unlock "lck" "l1";;
      lockservice.LockClerk__Unlock "lck" "l2");;
    #().

(* Requires that the account numbers are smaller than num_accounts
   If account balance in acc_from is at least amount, transfer amount to acc_to *)
Definition BankClerk__transfer_internal: val :=
  rec: "BankClerk__transfer_internal" "bck" "acc_from" "acc_to" "amount" :=
    acquire_two (struct.loadF BankClerk "lck" "bck") "acc_from" "acc_to";;
    let: "old_amount" := memkv.DecodeUint64 (memkv.MemKVClerk__Get (struct.loadF BankClerk "kvck" "bck") "acc_from") in
    (if: "old_amount" ≥ "amount"
    then
      memkv.MemKVClerk__Put (struct.loadF BankClerk "kvck" "bck") "acc_from" (memkv.EncodeUint64 ("old_amount" - "amount"));;
      memkv.MemKVClerk__Put (struct.loadF BankClerk "kvck" "bck") "acc_to" (memkv.EncodeUint64 (memkv.DecodeUint64 (memkv.MemKVClerk__Get (struct.loadF BankClerk "kvck" "bck") "acc_to") + "amount"));;
      #()
    else #());;
    release_two (struct.loadF BankClerk "lck" "bck") "acc_from" "acc_to".

Definition BankClerk__SimpleTransfer: val :=
  rec: "BankClerk__SimpleTransfer" "bck" "amount" :=
    BankClerk__transfer_internal "bck" (struct.loadF BankClerk "acc1" "bck") (struct.loadF BankClerk "acc2" "bck") "amount".

(* If account balance in acc_from is at least amount, transfer amount to acc_to *)
Definition BankClerk__SimpleAudit: val :=
  rec: "BankClerk__SimpleAudit" "bck" :=
    acquire_two (struct.loadF BankClerk "lck" "bck") (struct.loadF BankClerk "acc1" "bck") (struct.loadF BankClerk "acc2" "bck");;
    let: "sum" := memkv.DecodeUint64 (memkv.MemKVClerk__Get (struct.loadF BankClerk "kvck" "bck") (struct.loadF BankClerk "acc1" "bck")) + memkv.DecodeUint64 (memkv.MemKVClerk__Get (struct.loadF BankClerk "kvck" "bck") (struct.loadF BankClerk "acc2" "bck")) in
    release_two (struct.loadF BankClerk "lck" "bck") (struct.loadF BankClerk "acc1" "bck") (struct.loadF BankClerk "acc2" "bck");;
    "sum".

Definition MakeBankClerk: val :=
  rec: "MakeBankClerk" "lockhost" "kvhost" "cm" "acc1" "acc2" "cid" :=
    let: "bck" := struct.alloc BankClerk (zero_val (struct.t BankClerk)) in
    struct.storeF BankClerk "lck" "bck" (lockservice.MakeLockClerk "lockhost" "cm");;
    struct.storeF BankClerk "kvck" "bck" (memkv.MakeMemKVClerk "kvhost" "cm");;
    struct.storeF BankClerk "acc1" "bck" "acc1";;
    struct.storeF BankClerk "acc2" "bck" "acc2";;
    "bck".
