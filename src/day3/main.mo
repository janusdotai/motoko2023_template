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
  type Survey = Type.Survey;
  type Answer = Type.Answer;

  stable var messageId : Nat = 0;  
  var wall = HashMap.HashMap<Nat, Message>(1, Nat.equal, Hash.hash);

  public shared ({ caller }) func writeMessage(c : Content) : async Nat {
    messageId := wall.size();

    Debug.print(debug_show(messageId));

    var message : Message = 
    { 
      vote = 0;    
      content = c;
      creator = caller;
    };
    
    wall.put(messageId, message);    
    return messageId;
  };

  public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    var message : ?Message = wall.get(messageId);
    switch(message){
      case null
        return #err "not found";
      case (?message){
        return #ok message;
      };
    };

    // switch(found){
    //   case null
    //     return #err "not found";
    //   case (?found){
    //     var clone : StudentHomework = { 
    //       title = found.title; 
    //       description = found.description; 
    //       dueDate = found.dueDate; 
    //       completed = true 
    //     };
    //     homeworkDiary.put(id, clone);
    //     return #ok;
    //   };        
    // };

    return #err("not implemented");
  };

  public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {
    
    var message : ?Message = wall.get(messageId);
    switch(message){
      case null
        return #err "not found";
      case (?message){
        if(message.creator != caller){
          return #err "permission denied";
        };        
        var clone : Message = { 
           vote = message.vote;
           content = message.content;
           creator = caller;
        };
        wall.put(messageId, clone);
        return #ok;
      };
    };

  };

  public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    var message : ?Message = wall.get(messageId);
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
    var message : ?Message = wall.get(messageId);
    switch(message){
      case null
        return #err "not found";
      case (?message){
        var clone : Message = { 
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
    var message : ?Message = wall.get(messageId);
    switch(message){
      case null
        return #err "not found";
      case (?message){
        var clone : Message = { 
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
    var posts : Iter.Iter<Message> = wall.vals();
    return Iter.toArray(posts);
  };

  private func isGreaterVote(x : Int, y : Int) : { #less; #equal; #greater } {
    return Int.compare(x, y);
  };

  // private func isGreaterVote2(x : Int, y : Int) : Order {
  //   return Int.compare(x, y);
  // };

  public func getAllMessagesRanked() : async [Message] {
    
    var posts : Iter.Iter<Message> = wall.vals();
    var post_array = Iter.toArray(posts);
    //Array.sort(post_array, isGreaterVote);

    //Array.sort(post_array, isGreaterVote(a, b));
    //Array.sortInPlace<Message>(post_array, isGreaterVote);
    // let sortedPosts = Iter.sort()
    // let sortedPosts = Iter.sort(post_array, isGreaterVote(a,b));    
    //let sortedPosts = Iter.Array.sort(post_array, (a, b) => Int.compare(b.vote, a.vote));    
    //Iter.Array.sort<>(array, func (a : , b : ) { #equal })
    //return Iter.toArray(posts);

    return post_array;

    
    //return [];

  };
};
