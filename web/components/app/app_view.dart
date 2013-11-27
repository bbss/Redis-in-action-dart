import 'package:polymer/polymer.dart';
import 'dart:html';
import 'dart:convert';
import '../../model/model.dart';

const SERVER_ADDRESS = 'http://192.168.0.100:8000';

@CustomTag('app-element')
class AppView extends HtmlElement with Polymer, Observable {
  final List<Article> articles = toObservable([]);
  @observable 
  User user = new User(3);

  @observable 
  Article newArticle = new Article();
  
  AppView.created() : super.created();
  
  void enteredView() {
    getArticles();
    super.enteredView();
  }
  
  getArticles() {
    HttpRequest.getString('articles/').then((getResult) {            
      JSON.decode(getResult).forEach((hash) {
        //hacky because articles is final and toSet wont use compare operator
        var article = new Article.fromMap(hash);
        if (!articles.contains(article)) articles.add(article);
      });
    });
  }
  
  submit(Event e, var detail, Node target) {
    e.preventDefault();
    
    FormElement form = target as FormElement;
    
    HttpRequest.request(
        SERVER_ADDRESS+ '/article/', 
        method: form.method,
        sendData: JSON.encode(
                    {'title' : newArticle.title,
                     'link' : newArticle.link,
                     'user' : user.id.toString()}))
        .then((_) => getArticles())
        .catchError((e) => print(e));
    newArticle.clear();
  }
}