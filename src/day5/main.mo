import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Timer "mo:base/Timer";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

import IC "Ic";
import HTTP "Http";
import Type "Types";
import Calculator "Calculator";


actor class Verifier() {

  type StudentProfile = Type.StudentProfile;  
  
  stable var data_backup : [(Principal, StudentProfile)] = [];  
  let studentProfileStore = HashMap.fromIter<Principal,StudentProfile>(data_backup.vals(), 10, Principal.equal, Principal.hash);

  system func preupgrade() {
    data_backup := Iter.toArray(studentProfileStore.entries());
  };

  system func postupgrade() {
    data_backup := [];
  };
  
  // STEP 1 - BEGIN
  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    studentProfileStore.put(caller, profile);
    return #ok;    
  };

  public shared ({ caller }) func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
    var match = studentProfileStore.get(caller);
    switch(match){
      case null
        return #err("not found");
      case (?match){
        return #ok match;
      };
    };
  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    var match = studentProfileStore.get(caller);
    switch(match){
      case null
        return #err("not found");
      case (?match){
        studentProfileStore.put(caller, profile);
        return #ok;
      };
    };    
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    var removed = studentProfileStore.remove(caller);
    switch(removed){
      case null
        return #err("not found");
      case(?removed){
        return #ok;
      };
    }    
  };

  

  // STEP 2 - BEGIN  
  public type TestResult = Type.TestResult;
  public type TestError = Type.TestError;

  //public type ManagementCanister = IC.ManagementCanister;
  public type CanisterId = IC.CanisterId;
  public type CanisterSettings = IC.CanisterSettings;

  public func test(canisterId : Principal) : async TestResult {

    var pid = Principal.toText(canisterId);
    let calculator = actor(pid) : actor {
      add : shared(n : Int) -> async Int;
      sub : shared(n : Int) -> async Int;
      reset: shared() -> async Int;
    };

    try{

      var resetResult = await calculator.reset();
      if(resetResult != 0){
        return #err(#UnexpectedValue("reset should be 0 "));          
      };

      var addedResult = await calculator.add(1);
      if(addedResult != 1){
        return #err(#UnexpectedValue("added should be 1"));
      };

      var sub = await calculator.sub(1);
      if(addedResult != 0){
        return #err(#UnexpectedValue("sub should be back to 0"));
      };

      return #ok; 

    }catch(e : Error){      
      //var msg = Error.message(e);
      return #err(#UnexpectedError("An error occured when calling canister calculator"));
    };

  };  
  

  // STEP 3 - BEGIN
  // NOTE: Not possible to develop locally,
  // as actor "aaaa-aa" (aka the IC itself, exposed as an interface) does not exist locally
  public func verifyOwnership(canisterId : Principal, p : Principal) : async Result.Result<Bool, Text> {

    let management_controller_principal : Text = "";

    let canister_controller = actor(management_controller_principal) : actor {
      canister_status : ( canister_id: CanisterId ) -> async ({
        status : { #running; #stopping; #stopped };
        settings: CanisterSettings;
        module_hash: ?Blob;
        memory_size: Nat;
        cycles: Nat;
        idle_cycles_burned_per_day: Nat;
      });
    };

    try{

      let status = await canister_controller.canister_status(canisterId);
      for(owner in status.settings.controllers.vals()){
        if(owner == p){
            return #ok true;
        };
      };

    }catch(e: Error){

      var msg = Error.message(e);
      var parsed_controllers = await parseControllersFromCanisterStatusErrorIfCallerNotController(msg);
      for(parsed_controller in parsed_controllers.vals()){
          if(parsed_controller == p){
            return #ok true;
          }
      };
      return #err("owner not found on controller");
      
    };    
    
    return #err("owner not found on controller");

  };
  

  // STEP 4 - BEGIN
  public shared ({ caller }) func verifyWork(canisterId : Principal, p : Principal) : async Result.Result<Bool, Text> {
    return #err("not implemented");
  };
  // STEP 4 - END

  // STEP 5 - BEGIN
  public type HttpRequest = HTTP.HttpRequest;
  public type HttpResponse = HTTP.HttpResponse;

  // NOTE: Not possible to develop locally,
  // as Timer is not running on a local replica
  public func activateGraduation() : async () {
    return ();
  };

  public func deactivateGraduation() : async () {
    return ();
  };

  public query func http_request(request : HttpRequest) : async HttpResponse {
    return ({
      status_code = 200;
      headers = [];
      body = Text.encodeUtf8("");
      streaming_strategy = null;
    });
  };
  // STEP 5 - END


  /// Parses the controllers from the error returned by canister status when the caller is not the controller
  /// Of the canister it is calling
  ///
  /// TODO: This is a temporary solution until the IC exposes this information.
  /// TODO: Note that this is a pretty fragile text parsing solution (check back in periodically for better solution)
  ///
  /// Example error message:
  ///
  /// "Only the controllers of the canister r7inp-6aaaa-aaaaa-aaabq-cai can control it.
  /// Canister's controllers: rwlgt-iiaaa-aaaaa-aaaaa-cai 7ynmh-argba-5k6vi-75frw-kfqpa-3xtca-nmzk3-hrmvb-fydxk-w4a4k-2ae
  /// Sender's ID: rkp4c-7iaaa-aaaaa-aaaca-cai"
  public func parseControllersFromCanisterStatusErrorIfCallerNotController(errorMessage : Text) : async [Principal] {
    let lines = Iter.toArray(Text.split(errorMessage, #text("\n")));
    let words = Iter.toArray(Text.split(lines[1], #text(" ")));
    var i = 2;
    let controllers = Buffer.Buffer<Principal>(0);
    while (i < words.size()) {
      controllers.add(Principal.fromText(words[i]));
      i += 1;
    };
    Buffer.toArray<Principal>(controllers);
  };


};
