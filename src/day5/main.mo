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
import Option "mo:base/Option";

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
    // if (Principal.isAnonymous(caller)) {
    //   return #err "You must be Logged In"
    // };
   
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
  //public type CanisterId = IC.CanisterId;
  //public type CanisterSettings = IC.CanisterSettings;

  public func test(canisterId : Principal) : async TestResult {

    let pid = Principal.toText(canisterId);    
    let calculator = actor(pid) : actor {
      add : shared(n : Int) -> async Int;
      sub : shared(n : Int) -> async Int;
      reset: shared() -> async Int;
    };

    try{     

      let resetResult = await calculator.reset();
      if(resetResult != 0){
        return #err(#UnexpectedValue("reset should be 0 "));          
      };

      let addedResult = await calculator.add(1);
      if(addedResult != 1){
        return #err(#UnexpectedValue("added should be 1"));
      };
     
      let subResult = await calculator.sub(1);
      if(subResult != 0){
        return #err(#UnexpectedValue("sub should yield -1"));
      };

      return #ok; 

    }catch(e : Error){      
      //var msg = Error.message(e);
      let err_msg = Error.message(e);
      return #err(#UnexpectedError("An error occured when calling canister calculator " #err_msg));
    };

  };  
  
   private let IC_CANISTER = actor "aaaaa-aa" : actor { canister_status : { canister_id : Principal } -> async { controllers : [Principal] }; };

  // STEP 3 - BEGIN
  // NOTE: Not possible to develop locally,
  // as actor "aaaa-aa" (aka the IC itself, exposed as an interface) does not exist locally
  public func verifyOwnership(canisterId : Principal, p : Principal) : async Bool {

    //let management_controller_principal : Text = "aaaaa-aa";
    // let canister_controller : actor {
    //   canister_status : ( canister_id: CanisterId ) -> async ({
    //     status : { #running; #stopping; #stopped };
    //     settings: CanisterSettings;
    //     module_hash: ?Blob;
    //     memory_size: Nat;
    //     cycles: Nat;
    //     idle_cycles_burned_per_day: Nat;
    //   })} = actor(management_controller_principal);

    // let canister_controller = actor(management_controller_principal) : actor {
    //   canister_status : ( canister_id: CanisterId ) -> async ({
    //     status : { #running; #stopping; #stopped };
    //     settings: CanisterSettings;
    //     module_hash: ?Blob;
    //     memory_size: Nat;
    //     cycles: Nat;
    //     idle_cycles_burned_per_day: Nat;
    //   });
    // };

    try{
      let status = await IC_CANISTER.canister_status({ canister_id = canisterId; });
      //let status = await canister_controller.canister_status(canisterId);
      for(owner in status.controllers.vals()){
        if(owner == p){
            return true;
        };
      };
      return false;

    }catch(e: Error){
      let msg = Error.message(e);
      let parsed_controllers = parseControllersFromCanisterStatusErrorIfCallerNotController(msg);
      var isOwner : ?Principal = Array.find<Principal>(parsed_controllers, func x = x == p);
      if (isOwner != null) {
        return true;
      };      
      // for(parsed_controller in parsed_controllers.vals()){
      //   if(parsed_controller == p){
      //     return true;
      //   }
      // };
      return false;
    };
    
  };
  
 
  // STEP 4 - BEGIN
  public shared ({ caller }) func verifyWork(canisterId : Principal, p : Principal) : async Result.Result<(), Text> {

    //get student profile
    let student_clone = { var team = ""; var graduate = false; var name = "" };

    let student = await seeAProfile(caller);
    switch(student){      
      case (#ok(dude)){        
        student_clone.team := dude.team;
        student_clone.name := dude.name;
        student_clone.graduate := dude.graduate;
        Debug.print("found the student, proceeding the next step...");
      };       
      case (_)        
        return #err("student not found, please add first");
    };  
    
    //test canister
    let test_result = await test(canisterId); //async TestResult {
    switch(test_result){
      case(#err(#UnexpectedValue(err_msg))){
        Debug.print("canister test failed calculator logic");
        return #err err_msg;
      };
      case(#err(#UnexpectedError(err_msg))){
        Debug.print("canister test failed for unknown reason");
        return #err err_msg;
      };    
      case(#ok)
        Debug.print("canister test PASSED");
    };
    
    //verify ownership of canister
    let verify_result = await verifyOwnership(canisterId, p); //Result.Result<Bool, Text>
    switch(verify_result){
      case (false)
        return #err("verifyOwnership failed");
      case (true)
        Debug.print("verifyOwnership PASSED");        
    };

    let update : StudentProfile = { 
      graduate = true;
      name = student_clone.name;
      team = student_clone.team;
    };

    let update_result = await updateMyProfile(update);
    switch(?update_result){
      case(null){
        return #ok;
      };
      case(_){
        return #err "verifyWork failed at final update step";
      };
    };

  };


  //https://forum.dfinity.org/t/getting-a-canisters-controller-on-chain/7531/17
  private func parseControllersFromCanisterStatusErrorIfCallerNotController(errorMessage : Text) : [Principal] {
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
