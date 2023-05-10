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
import BootcampLocalActor "BootcampLocalActor";

actor class MotoCoin() {
  
  public type Account = Account.Account;

  let ledger = TrieMap.TrieMap<Account, Nat>(Account.accountsEqual, Account.accountsHash);

  public query func name() : async Text {
    return "MotoCoin";
  };

  public query func symbol() : async Text {
    return "MOC";
  };

  public func totalSupply() : async Nat {
    return 9;
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
    return #ok;
  };

  public func airdrop() : async () {
    return ();
  };
};
