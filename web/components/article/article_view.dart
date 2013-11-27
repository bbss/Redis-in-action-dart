import 'package:polymer/polymer.dart';
import 'dart:html';
import '../../model/model.dart';

@CustomTag('article-element')
class ArticleView extends LIElement with Polymer, Observable {
  @published Article article;
  
  ArticleView.created() : super.created();
}