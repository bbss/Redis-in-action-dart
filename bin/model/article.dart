part of server_model;

const ONE_WEEK_IN_SECONDS = 7 * 86400;
const SINGLE_VOTE_SCORE = 432;
const ARTICLES_PER_PAGE = 25;


class Article {
  int id;
  int votes;
  num score;
  num time;
  String poster;
  String link;
  String title;
  
  
  Future<bool> receiveVote(RedisClient client) {
    Completer<bool> receiveVoteCompleter = new Completer<bool>();
    
    var cutoff = new DateTime.now().millisecondsSinceEpoch - ONE_WEEK_IN_SECONDS;
    client.zscore('time:', 'article:$id')    
    .then((zscoreResult) {
      if (zscoreResult < cutoff) receiveVoteCompleter.complete(false);
    });
    
    client.sadd('voted:$id', poster)
      .then((saddResult) {
      if (saddResult > 0) {
        Future.wait([client.zincrby('score:', SINGLE_VOTE_SCORE, this),
                     client.hincrby(this.toString(), 'votes', 1)])
        .then((_) => receiveVoteCompleter.complete(true));
      }
    });
    
    return receiveVoteCompleter.future;
  }

  Future<bool> post(RedisClient client) {
    Completer<bool> postCompleter = new Completer<bool>();
    
    client.sadd('voted:$id', poster)
    .then((_) => client.hmset('article:$id', this.toJson())
    .then((_) {
      var defaultScoreEntry = new ZSetEntry('article:$id', 
                                            score + SINGLE_VOTE_SCORE);
      
      var defaultTimeEntry = new ZSetEntry('article:$id', time);
      
      Future.wait([client.zadd('score:', [ defaultScoreEntry ]),
                   client.zadd('time:', [ defaultTimeEntry ])])
                   .then((_) => postCompleter.complete(true));
    }));
    
    return postCompleter.future;
  }
  
  toJson() 
    => {'id' : id.toString(),
        'votes' : votes.toString(),
        'score' : score.toString(),
        'time' : time.toString(),
        'link' : link.toString(),
        'title' : title.toString(),
        'poster' : poster.toString()};
        
  toString() => toJson().toString();
  
  
  factory Article.fromJson(String articleString) {
    var articleMap = JSON.decode(articleString);
    return new Article.fromMap(articleMap);
  }
  
  factory Article.fromWebRequest(User poster, int id, int votes, int score, int time, String link, String title) {
    var articleMap = new Map();
    articleMap['poster'] = 'user:${poster.id}';
    articleMap['id'] = id;
    articleMap['votes'] = votes;
    articleMap['score'] = score;
    articleMap['time'] = time;
    articleMap['link'] = link;
    articleMap['title'] = title;
    return new Article.fromMap(articleMap);
  }

  Article.fromMap(Map articleMap) {
    id = articleMap['id'];
    votes = articleMap['votes'];
    score = articleMap['score'];
    time = articleMap['time'];
    link = articleMap['link'];
    title = articleMap['title'];
    poster = articleMap['poster'];
  }
  
  Article(this.poster, this.id, this.votes, this.score, this.time, this.link, this.title);
  
  bool operator ==(Article other) {
    return (other.id) == id;
  }
}

