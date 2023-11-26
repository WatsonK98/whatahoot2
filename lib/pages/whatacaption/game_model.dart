import 'package:flutter/material.dart';

class GameModel extends ChangeNotifier {
  String _gameId = '';
  String _hostNickname = '';
  String _imageUrl = '';
  List<String> _playerNicknames = [];

  String get gameId => _gameId;
  String get hostNickname => _hostNickname;
  String get imageUrl => _imageUrl;
  List<String> get playerNicknames => _playerNicknames;

  void setGameId(String gameId) {
    _gameId = gameId;
    notifyListeners();
  }

  void setHostNickname(String hostNickname) {
    _hostNickname = hostNickname;
    notifyListeners();
  }

  void addPlayerNickname(String playerNickname) {
    _playerNicknames.add(playerNickname);
    notifyListeners();
  }

  void setImageUrl(String imageUrl) {
    _imageUrl = imageUrl;
    notifyListeners();
  }
}