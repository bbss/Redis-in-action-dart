library redis_dart_server_tests;

import 'dart:async';
import 'dart:math';
import 'package:redis_client/redis_client.dart';
import 'package:unittest/unittest.dart';
import '../server.dart';
import '../bin/model/model.dart';


const REDIS_SERVER = '127.0.0.1:6379';
const SERVER_ADDRESS = '192.168.0.100';
const SERVER_PORT = 8000;


Function async = (Future future) {
  future
      .then(expectAsync1((_) { })) // Making sure that all tests pass asynchronously
      .catchError((err) {
        throw err;
        print("Error: $err");
        expect(false, equals(err));
      }); // Catching errors
};

void fillDatabase(RedisClient c) {
  c.hmset('article:92617', {'title' : 'Go to statement considered harmful',
                            'link' : 'http://goo.gl/kZUSu',
                            'poster' : 'user:83271',
                            'time' : 1331382699.33,
                            'votes' : 528});
  
  c.hmset('article:100716', {'title' : 'Go to statement considered harmful',
                            'link' : 'http://goo.gl/kZUSu',
                            'poster' : 'user:83271',
                            'time' : 1331382699.33,
                            'votes' : 528});
  
  c.hmset('article:100635', {'title' : 'Go to statement considered harmful',
                            'link' : 'http://goo.gl/kZUSu',
                            'poster' : 'user:83271',
                            'time' : 1331382699.33,
                            'votes' : 528});
  
  c.zadd('time:', [new ZSetEntry('article:100408', new DateTime.now().millisecondsSinceEpoch),
                   new ZSetEntry('article:100635', 1332075503.49),
                   new ZSetEntry('article:100716', 1332082035.26)]);
  
  c.zadd('score:', [new ZSetEntry('article:100635', 1332164063.49),
                   new ZSetEntry('article:100716', 1332225027.26)]);
  
  var usersVoted = new List<String>(), random = new Random();
  
  for(int i = 0 ; i < 500 ; i++) usersVoted.add('user:${random.nextInt(999998)}');  

  c.sadd('voted:100408', usersVoted.toSet());
}

main() {
  group("Redis dart web servers' model", () {

    RedisClient client;
    RoutedRedisServer server;

    setUp(() {
      return RedisClient.connect(REDIS_SERVER)
          .then((_redis) {
            client = _redis;
            client.flushall();
            fillDatabase(_redis);
            return RoutedRedisServer.bind(SERVER_ADDRESS, SERVER_PORT, _redis)
                .then((_server) => server = _server);
          });
    });

    tearDown(() {
      try {
        client.close();
        server.close();
      }
      finally {

      }
    });
    
      // TODO(Baruch) Needs more expectations does not test all effects
    group('Article', () {
      test('should increase score when voted on.', () {
        var user = new User(null);
        var article = new Article('user:$user.id', 100408, null, null, null, null, null);
        async(
            article.receiveVote(client)
            .then((receiveVoteResult) => expect(receiveVoteResult, isTrue))
        );
      });
      // TODO(Baruch) Needs more expectations does not test all effects
      test('should be stored when posted.', () {
        var user = new User(999999);
        var article = new Article('user:$user.id', 1, 1, 1332075900, 1332075503, 'link', 'title');
        async(
            article.post(client)
            .then((postResult) => expect(postResult, isTrue))
            .then((_) => client.hgetall('article:${article.id}')
            .then((articleHashGet) {
              expect(new Article.fromMap(articleHashGet), equals(article));
            }))
        );
      });
    });
    
    // TODO(Baruch) Write test with Mock HttpRequest
    group('Server', () {
      test('should send the top scoring 25 articles', () {
        async(
            server.getTopArticles(client)
            .then((getTopArticlesResult) => expect(getTopArticlesResult, equals(
                [{"title":"Go to statement considered harmful",
                  "link":"http://goo.gl/kZUSu","poster":"user:83271",
                  "time":1331382699.33,"votes":528},
                  {"title":"Go to statement considered harmful",
                    "link":"http://goo.gl/kZUSu","poster":"user:83271",
                    "time":1331382699.33,"votes":528}]                                                                    
            )))
            );
      });
    });
  });
}

