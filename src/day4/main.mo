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

  public func airdrop() : async () {  
    
    //local
    let bootcampTestActor = await BootcampLocalActor.BootcampLocalActor();
    var students = await bootcampTestActor.getAllStudentsPrincipal();

    //prod
    // let bootcampPeople = actor("rww3b-zqaaa-aaaam-abioa-cai") : actor {
    //   getAllStudentsPrincipal : shared() -> async [Principal];
    // };
    // var students = await bootcampPeople.getAllStudentsPrincipal();
   
    for(student in students.vals()){
      let a : Account = {
        owner = student;
        subaccount = null;
      };
      ledger.put(a, 100);
    };

  };
};
