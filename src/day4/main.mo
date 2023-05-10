import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";

import Account "Account";
// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
//import BootcampLocalActor "BootcampLocalActor";

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

    //ensure caller has enough $ to send
    let fromBalance = ledger.get(from);
    switch(fromBalance){
      case null
        return #err "from account has no balance";
      case (?fromBalance){        
        if(fromBalance < amount){
          return #err "from account does not have enough funds to transfer";
        };
        //decrement sender
        let new_from_balance : Nat = fromBalance - amount;
        ledger.put(from, new_from_balance);
        //award receiver        
        ledger.put(to, amount);
        return #ok;
      };
    };  

  };

  public func airdrop() : async () {

    let bootcampPeople = actor("rww3b-zqaaa-aaaam-abioa-cai") : actor {
      getAllStudentsPrincipal : shared() -> async [Principal];
    };
    var stuff = await bootcampPeople.getAllStudentsPrincipal();    

    return ();
  };
};
