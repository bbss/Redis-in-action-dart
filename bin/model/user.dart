part of server_model;

class User {
  int id;
  User(this.id);
  
  toJson() => {'id' :id.toString()};
}