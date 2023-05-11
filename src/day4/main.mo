import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";

import Account "Account";
// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
import BootcampLocalActor "BootcampLocalActor";

actor class MotoCoin() {

  private type Account = Account.Account;  

  let ledger = TrieMap.TrieMap<Account, Nat>(Account.accountsEqual, Account.accountsHash); 

  public query func name() : async Text {
    return "MotoCoin";
  };

  public query func symbol() : async Text {
    return "MOC";
  };

  public func totalSupply() : async Nat {
    var sum = 0;
    for(key in ledger.vals()){
      sum += key;
    };
    return sum;
  };

  public query func balanceOf(account : Account) : async (Nat) {
    let balance = ledger.get(account);
    switch(balance){
      case null
        return 0;
      case(?balance){
        return balance;
      };
    };    
  };

  public shared ({ caller }) func transfer(
    from : Account,
    to : Account,
    amount : Nat,
  ) : async Result.Result<(), Text> {

    //check to see if caller owns the the account
    let is_owner = Account.accountBelongsToPrincipal(from, caller);
    if(is_owner == false){
      return #err "no permission to send funds";
    };
    
    let fromBalance = ledger.get(from);  
    switch(fromBalance){
      case null
        return #err "from account has no balance";
      case (?fromBalance){         
        //ensure caller has enough $ to send
        if(fromBalance < amount){
          return #err "from account does not have enough funds to transfer";
        };
        //decrement from
        let new_from_balance : Nat = fromBalance - amount;
        ledger.put(from, new_from_balance);

        //increment to
        var toBalance = ledger.get(to);
        //var toBalance = Option.unwrap(ledger.get(to));
        var toBalanceNotNull : Nat = switch toBalance {
          case null 0;
          case (?Nat) Nat;
        };

        toBalanceNotNull := toBalanceNotNull + amount;
        ledger.put(to, toBalanceNotNull);
        return #ok;
      };
    };  
    return #err "nope";
  };

  public func airdrop() : async Result.Result<(), Text> {  
    
    //local
    // let bootcampTestActor = await BootcampLocalActor.BootcampLocalActor();
    // var students = await bootcampTestActor.getAllStudentsPrincipal();
    //var students = await getAllStudentsPrincipalTest();

    //prod
    let bootcampPeople = actor("rww3b-zqaaa-aaaam-abioa-cai") : actor {
      getAllStudentsPrincipal : shared() -> async [Principal];
    };
    var students = await bootcampPeople.getAllStudentsPrincipal();

    if(students.size() == 0){
      return #err "no students registered";
    };
   
    for(student in students.vals()){
      let a : Account = {
        owner = student;
        subaccount = null;
      };
      ledger.put(a, 100);
    };
    return #ok;
  };

  // public func getAllHolders() : async [Principal] {
  //   // let bootcampTestActor = await BootcampLocalActor.BootcampLocalActor();
  //   // var students = await bootcampTestActor.getAllStudentsPrincipal();

  //   let bootcampPeople = actor("rww3b-zqaaa-aaaam-abioa-cai") : actor {
  //     getAllStudentsPrincipal : shared() -> async [Principal];
  //   };
    
  //   var students = await bootcampPeople.getAllStudentsPrincipal();
  //   return students;

  // };



    // let textPrincipals: [Text] = [
    //     "un4fu-tqaaa-aaaab-qadjq-cai",
    //     "un4fu-tqaaa-aaaac-qadjr-cai",
    //     "un4fu-tqaaa-aaaad-qadjs-cai",
    //     "un4fu-tqaaa-aaaae-qadjt-cai",
    //     "un4fu-tqaaa-aaaaf-qadjv-cai",
    //     "un4fu-tqaaa-aaaag-qadjw-cai",
    //     "un4fu-tqaaa-aaaah-qadjx-cai",
    //     "un4fu-tqaaa-aaaai-qadjy-cai",
    //     "un4fu-tqaaa-aaaaj-qadjz-cai",
    //     "un4fu-tqaaa-aaaak-qadk1-cai",
    // ];


    // public shared func getAllStudentsPrincipalTest():async[Principal]{
    //   let principalsText:Buffer.Buffer<Text> = Buffer.fromArray(textPrincipals);
    //   var index:Nat = 0;
    //   var principalsReady = Buffer.Buffer<Principal>(10);

    //   Buffer.iterate<Text>(principalsText, func (x) {
    //     let newPrincipal = Principal.fromText(principalsText.get(index));
    //     principalsReady.add(newPrincipal);
    //   });      
    //   return Buffer.toArray(principalsReady);

    // };

};
