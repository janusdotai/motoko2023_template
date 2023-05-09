import Type "Types";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Time "mo:base/Time";

actor class HomeworkManager() {

  type StudentHomework = Type.Homework;

  var homeworkDiary = Buffer.Buffer<StudentHomework>(0);

  private func _isHomeworkEqual(x : StudentHomework, y : StudentHomework) : Bool {    
    if(x.title == y.title 
    and x.description == y.description 
    and x.dueDate == y.dueDate 
    and x.completed == y.completed)
    {
      return true;
    };
    return false;
  };

  private func isPending(x : Nat, y : StudentHomework) : Bool {
    if(y.completed){
      return false;
    }else{
      return true;
    };
  };

  public shared func addHomework(homework : StudentHomework) : async Nat {    
    homeworkDiary.add(homework);
    var index = Buffer.indexOf<StudentHomework>(homework, homeworkDiary, _isHomeworkEqual);
    switch(index){
      case null 
        return 0;
      case (?Nat) 
        return Option.get(index, 0);
    };
  };

  public shared query func getHomework(id : Nat) : async Result.Result<StudentHomework, Text> {    
    var found = homeworkDiary.getOpt(id);
    switch(found){
      case null
        return #err "not found";
      case (?found) 
        return #ok found;
    };
  };

  public shared func updateHomework(id : Nat, homework : StudentHomework) : async Result.Result<(), Text> {
    var found = homeworkDiary.getOpt(id);
    switch(found){
      case null
        return #err "not found";
      case (?found) 
        homeworkDiary.put(id, homework);
    };  
    return #ok ();
  };

  public shared func deleteHomework(id : Nat) : async Result.Result<(), Text> {
    var found = homeworkDiary.getOpt(id);
    switch(found){
      case null
        return #err "not found";
      case (?found){        
        let x = homeworkDiary.remove(id);
        return #ok ();
      };
    };    
  };

  public shared query func getAllHomework() : async [StudentHomework] {
    return Buffer.toArray(homeworkDiary);    
  };

  public shared func markAsCompleted(id : Nat) : async Result.Result<(), Text> {
    var found = homeworkDiary.getOpt(id);
    switch(found){
      case null
        return #err "not found";
      case (?found){
        var clone : StudentHomework = { 
          title = found.title; 
          description = found.description; 
          dueDate = found.dueDate; 
          completed = true 
        };
        homeworkDiary.put(id, clone);
        return #ok;
      };        
    };
  };
  
  public shared query func getPendingHomework() : async [StudentHomework] {
    var clone = homeworkDiary;
    clone.filterEntries(isPending);
    return Buffer.toArray(clone);
  };

  public shared query func searchHomework(searchTerm : Text) : async [StudentHomework] {    
    var filtered = Buffer.Buffer<StudentHomework>(0);
    for(homework in homeworkDiary.vals()){     
      if(Text.contains(homework.title, #text searchTerm) 
      or Text.contains(homework.description, #text searchTerm)){
         filtered.add(homework);
      };
    };
    return Buffer.toArray(filtered);
  };

};
