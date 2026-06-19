/**
 classes = ID, title, description, status, timestamp
 */

void main(){
  User userOne = User('Alice', 25);
  print(userOne.username);
  userOne.login();

  superUser userTwo = superUser('Safa', 21);
  print(userTwo.username);
  userTwo.login();
  userTwo.publish();
}

class User {
  dynamic username;
  dynamic age;

  User(dynamic username, dynamic age){
    this.username = username;
    this.age = age;
  }

  void login(){
    print('User logged in');
  }
}

class superUser extends User {
  superUser(dynamic username, dynamic age): super(username, age);

  void publish(){
    print('User published a post');
  }
}