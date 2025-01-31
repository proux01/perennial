(* autogenerated from github.com/mit-pdos/gokv/tutorial *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.mit_pdos.gokv.urpc.

From Perennial.goose_lang Require Import ffi.grove_prelude.

Definition Decision: ty := byteT.

Definition Unknown : expr := #(U8 0).

Definition Commit : expr := #(U8 1).

Definition Abort : expr := #(U8 2).

Definition ParticipantServer := struct.decl [
  "m" :: ptrT;
  "preference" :: boolT
].

Definition ParticipantServer__GetPreference: val :=
  rec: "ParticipantServer__GetPreference" "s" :=
    lock.acquire (struct.loadF ParticipantServer "m" "s");;
    let: "pref" := struct.loadF ParticipantServer "preference" "s" in
    lock.release (struct.loadF ParticipantServer "m" "s");;
    "pref".

Definition MakeParticipant: val :=
  rec: "MakeParticipant" "pref" :=
    struct.new ParticipantServer [
      "m" ::= lock.new #();
      "preference" ::= "pref"
    ].

Definition ParticipantClerk := struct.decl [
  "client" :: ptrT
].

Definition CoordinatorServer := struct.decl [
  "m" :: ptrT;
  "decision" :: Decision;
  "preferences" :: slice.T Decision;
  "participants" :: slice.T ptrT
].

Definition CoordinatorClerk := struct.decl [
  "client" :: ptrT
].

Definition Yes : expr := #true.

Definition No : expr := #false.

Definition GetPreferenceId : expr := #0.

Definition prefToByte: val :=
  rec: "prefToByte" "pref" :=
    (if: "pref"
    then #(U8 1)
    else #(U8 0)).

Definition byteToPref: val :=
  rec: "byteToPref" "b" :=
    ("b" = #(U8 1)).

Definition ParticipantClerk__GetPreference: val :=
  rec: "ParticipantClerk__GetPreference" "ck" :=
    let: "req" := NewSlice byteT #0 in
    let: "reply" := ref_to (slice.T byteT) (NewSlice byteT #0) in
    let: "err" := urpc.Client__Call (struct.loadF ParticipantClerk "client" "ck") GetPreferenceId "req" "reply" #1000 in
    control.impl.Assume ("err" = #0);;
    let: "b" := SliceGet byteT (![slice.T byteT] "reply") #0 in
    byteToPref "b".

(* make a decision once we have all the preferences

   assumes we have all preferences (ie, no Unknown) *)
Definition CoordinatorServer__makeDecision: val :=
  rec: "CoordinatorServer__makeDecision" "s" :=
    lock.acquire (struct.loadF CoordinatorServer "m" "s");;
    ForSlice byteT <> "pref" (struct.loadF CoordinatorServer "preferences" "s")
      ((if: ("pref" = Abort)
      then struct.storeF CoordinatorServer "decision" "s" Abort
      else #()));;
    (if: (struct.loadF CoordinatorServer "decision" "s" = Unknown)
    then struct.storeF CoordinatorServer "decision" "s" Commit
    else #());;
    lock.release (struct.loadF CoordinatorServer "m" "s");;
    #().

Definition prefToDecision: val :=
  rec: "prefToDecision" "pref" :=
    (if: "pref"
    then Commit
    else Abort).

Definition CoordinatorServer__backgroundLoop: val :=
  rec: "CoordinatorServer__backgroundLoop" "s" :=
    ForSlice ptrT "i" "h" (struct.loadF CoordinatorServer "participants" "s")
      (let: "pref" := ParticipantClerk__GetPreference "h" in
      lock.acquire (struct.loadF CoordinatorServer "m" "s");;
      SliceSet byteT (struct.loadF CoordinatorServer "preferences" "s") "i" (prefToDecision "pref");;
      lock.release (struct.loadF CoordinatorServer "m" "s"));;
    CoordinatorServer__makeDecision "s";;
    #().

Definition MakeCoordinator: val :=
  rec: "MakeCoordinator" "participants" :=
    let: "decision" := Unknown in
    let: "m" := lock.new #() in
    let: "preferences" := NewSlice Decision (slice.len "participants") in
    let: "clerks" := ref_to (slice.T ptrT) (NewSlice ptrT #0) in
    ForSlice uint64T <> "a" "participants"
      (let: "client" := urpc.MakeClient "a" in
      "clerks" <-[slice.T ptrT] SliceAppend ptrT (![slice.T ptrT] "clerks") (struct.new ParticipantClerk [
        "client" ::= "client"
      ]));;
    struct.new CoordinatorServer [
      "m" ::= "m";
      "decision" ::= "decision";
      "preferences" ::= "preferences";
      "participants" ::= ![slice.T ptrT] "clerks"
    ].

Definition CoordinatorClerk__GetDecision: val :=
  rec: "CoordinatorClerk__GetDecision" "ck" :=
    let: "req" := NewSlice byteT #0 in
    let: "reply" := ref_to (slice.T byteT) (NewSlice byteT #1) in
    let: "err" := urpc.Client__Call (struct.loadF CoordinatorClerk "client" "ck") "GetDecisionId" "req" "reply" #1000 in
    control.impl.Assume ("err" = #0);;
    SliceGet byteT (![slice.T byteT] "reply") #0.

Definition CoordinatorServer__GetDecision: val :=
  rec: "CoordinatorServer__GetDecision" "s" :=
    lock.acquire (struct.loadF CoordinatorServer "m" "s");;
    let: "decision" := struct.loadF CoordinatorServer "decision" "s" in
    lock.release (struct.loadF CoordinatorServer "m" "s");;
    "decision".

Definition GetDecisionId : expr := #1.

Definition CoordinatorMain: val :=
  rec: "CoordinatorMain" "me" "participants" :=
    let: "coordinator" := MakeCoordinator "participants" in
    let: "handlers" := NewMap ((slice.T byteT -> ptrT -> unitT)%ht) #() in
    MapInsert "handlers" GetDecisionId ((λ: "_req" "reply",
      let: "decision" := CoordinatorServer__GetDecision "coordinator" in
      let: "replyData" := NewSlice byteT #1 in
      SliceSet byteT "replyData" #0 "decision";;
      "reply" <-[slice.T byteT] "replyData";;
      #()
      ));;
    let: "server" := urpc.MakeServer "handlers" in
    urpc.Server__Serve "server" "me";;
    Fork (CoordinatorServer__backgroundLoop "coordinator");;
    #().

Definition ParticipantMain: val :=
  rec: "ParticipantMain" "me" "pref" :=
    let: "participant" := MakeParticipant "pref" in
    let: "handlers" := NewMap ((slice.T byteT -> ptrT -> unitT)%ht) #() in
    MapInsert "handlers" GetPreferenceId ((λ: "_req" "reply",
      let: "pref" := ParticipantServer__GetPreference "participant" in
      let: "replyData" := NewSlice byteT #1 in
      SliceSet byteT "replyData" #0 (prefToByte "pref");;
      "reply" <-[slice.T byteT] "replyData";;
      #()
      ));;
    let: "server" := urpc.MakeServer "handlers" in
    urpc.Server__Serve "server" "me";;
    #().
