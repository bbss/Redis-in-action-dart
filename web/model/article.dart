part of client_model;


class Article extends Observable {
  int id;
  int votes;
  num score;
  num time;
  @observable
  String link;
  @observable
  String title;
  
  Article([this.id, this.votes, this.score, this.time, this.link, this.title]);
  
  factory Article.fromJson(String articleString) {
    var articleMap = JSON.decode(articleString);
    return new Article.fromMap(articleMap);
  }

  Article.fromMap(Map articleMap) {
    id = articleMap['id'];
    votes = articleMap['votes'];
    time = articleMap['time'];
    link = articleMap['link'];
    title = articleMap['title'];
  }
  
  bool operator ==(Article other) {
    return (other.id) == id;
  }
  
  clear() {
    link = "";
    title = "";
  }
}