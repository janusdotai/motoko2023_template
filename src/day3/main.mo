import Type "Types";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Order "mo:base/Order";

actor class StudentWall() {
  type Message = Type.Message;
  type Content = Type.Content;

  stable var messageId : Nat = 0;
  let wall = HashMap.HashMap<Nat, Message>(1, Nat.equal, Hash.hash);

  public shared ({ caller }) func writeMessage(c : Content) : async Nat {
    messageId := wall.size();
    Debug.print(debug_show(messageId));
    let message : Message = 
    { 
      vote = 0;    
      content = c;
      creator = caller;
    };    
    wall.put(messageId, message);    
    return messageId;
  };

  public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    let message : ?Message = wall.get(messageId);
    switch(message){
      case null
        return #err "not found";
      case (?message){
        return #ok message;
      };
    };   
    return #err("not implemented");
  };

  public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {    
    let message : ?Message = wall.get(messageId);
    switch(message){
      case null
        return #err "not found";     
      case (?message){
        if(message.creator != caller){
          return #err "permission denied";
        };        
        let clone : Message = { 
           vote = message.vote;
           content = c;
           creator = message.creator;
        };
        wall.put(messageId, clone);
        return #ok;
      };
    };
  };

  public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    let message : ?Message = wall.get(messageId);
    switch(message){
      case null
        return #err "not found";
      case (?message){
        if(message.creator != caller){
          return #err "permission denied";
        };
        wall.delete(messageId);
        return #ok;
      };
    };
  };

  public func upVote(messageId : Nat) : async Result.Result<(), Text> {
    let message : ?Message = wall.get(messageId);
    switch(message){
      case null
        return #err "not found";
      case (?message){
        let clone : Message = { 
           vote = message.vote + 1;
           content = message.content;
           creator = message.creator;           
        };
        wall.put(messageId, clone);
        return #ok;
      };
    };
  };

  public func downVote(messageId : Nat) : async Result.Result<(), Text> {
    let message : ?Message = wall.get(messageId);
    switch(message){
      case null
        return #err "not found";
      case (?message){
        let clone : Message = { 
           vote = message.vote - 1;
           content = message.content;
           creator = message.creator;           
        };
        wall.put(messageId, clone);
        return #ok;
      };
    };
  };

  public func getAllMessages() : async [Message] {
    let posts : Iter.Iter<Message> = wall.vals();
    return Iter.toArray(posts);
  };

  private func isGreaterVote(x : Message, y : Message) : Order.Order {
    return Int.compare(y.vote, x.vote);
  }; 

  public func getAllMessagesRanked() : async [Message] {    
    let posts : Iter.Iter<Message> = wall.vals();
    let post_array = Iter.toArray(posts);
    let sorted = Array.sort(post_array, isGreaterVote);
    return sorted;
  };

};
