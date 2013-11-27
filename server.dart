
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:route_hierarchical/server.dart';
import 'package:redis_client/redis_client.dart';
import 'bin/files.dart';
import 'bin/model/model.dart';


const REDIS_SERVER = '127.0.0.1:6379';
const SERVER_ADDRESS = '192.168.0.100';
const SERVER_PORT = 8000;

const ARTICLES_PER_PAGE = 25;

abstract class Urls {
  static final home = new UrlPattern(r'/');
  static final articles = new UrlPattern(r'/articles/');
  static final articlePage = new UrlPattern(r'/articles/page/(\d+)');
  static final article = new UrlPattern(r'/article/');
}



class RoutedRedisServer {
  Future<HttpServer> httpServerFuture;
  HttpServer _httpServer;
  Router _router;
  RedisClient _redisClient;
  
  static Future<RoutedRedisServer> bind(String address, int port, RedisClient _redis) {
    var scoreStoreServer = new RoutedRedisServer._(address, port, _redis);
    return scoreStoreServer.httpServerFuture.then((_) => scoreStoreServer);
  }
  
  RoutedRedisServer._(String address, int port, RedisClient _redis) {
    _redisClient = _redis;
    httpServerFuture = HttpServer.bind(address, port).then((server) {      
      _httpServer = server;
      _router = new Router(server)
      ..serve(Urls.home).listen(serveFile('web/index.html'))
      ..serve(Urls.articles, method: 'GET').listen(serveArticle)
      ..serve(Urls.articlePage, method: 'GET').listen(serveArticlePage)
      ..serve(Urls.article, method: 'POST').listen(serveArticlePost)
      ..defaultStream.listen(serveDirectory('web/', as: ''));
    });
  }
  
  Future close() => 
      Future.wait([_httpServer.close(), _redisClient.close()]);
  
  void serveArticle(HttpRequest req) {
    getTopArticles(_redisClient)
    .then((articles) => sendResponse(articles, req));
  }
  
  void serveArticlePage(HttpRequest req) {
    var articlePage = int.parse(Urls.articlePage.parse(req.uri.path)[0]);

    getArticlesByPage(_redisClient, articlePage)
    .then((articles) => sendResponse(articles.toList(), req));
  }
  
  void serveArticlePost(HttpRequest req) {  
    req.first.then((requestText) {
      var decodedRequest = JSON.decode(UTF8.decode(requestText)),      
      now = new DateTime.now().millisecondsSinceEpoch,
      score = now + SINGLE_VOTE_SCORE;
      
      _redisClient.incr('article:')
      .then((nextArticleId) {
      ///User and article will be dependency injected into the function once authentication/di framework is
      ///implemented
      User user = new User(int.parse(decodedRequest['user']));
      Article article = new Article.fromWebRequest(user, nextArticleId, 1, score, now, 
              decodedRequest['link'], decodedRequest['title']);
      
      article.post(_redisClient)
      .then((_) {
        req.response.statusCode = HttpStatus.CREATED;
        req.response.close();
      });
      });
    });
  }
  
  Future getTopArticles(RedisClient redisClient) {
    Completer topArticleCompleter = new Completer();
    var _topArticles = [];
    
    redisClient.zrevrange('score:', 0, 25)
    .then((Set topArticles) {
    Future.forEach(topArticles, (String article) =>
      redisClient.hgetall(article)
      .then((hgetallResult) 
          => _topArticles.add(hgetallResult)))
    .then((_) => topArticleCompleter.complete(_topArticles)); 
    });
     
    return topArticleCompleter.future;
  }
  
  Future<List> getArticlesByPage(RedisClient redisClient, int articlePage) {
    var start = (articlePage - 1) * ARTICLES_PER_PAGE,
    end = start + ARTICLES_PER_PAGE - 1; 
    
    return redisClient.zrevrange('score:', start, end);
  }
  
  void sendResponse(dynamic response, HttpRequest req) {
    req.response.add(UTF8.encode(JSON.encode(response)));
    req.response.close();
  }
}


void main() {  
  var redisFuture = RedisClient.connect(REDIS_SERVER);
  var serverFuture = redisFuture.then((_redis) => RoutedRedisServer.bind(SERVER_ADDRESS, SERVER_PORT, _redis));
}
