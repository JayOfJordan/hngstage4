import 'package:flutter/material.dart';import 'package:hngstage4/models.dart';

class Favorites with ChangeNotifier {
  final List<Coin> _favoriteCoins = [];
  bool _didChange = false;

  List<Coin> get favoriteCoins => _favoriteCoins;
  bool get didChange => _didChange;

  bool isFavorite(Coin coin) {
    return _favoriteCoins.any((favCoin) => favCoin.uuid == coin.uuid);
  }

  void resetChangeFlag() {
    _didChange = false;
  }

  void toggleFavorite(Coin coin) {
    if (isFavorite(coin)) {
      _favoriteCoins.removeWhere((favCoin) => favCoin.uuid == coin.uuid);
    } else {
      _favoriteCoins.add(coin);
    }
    _didChange = true;
    notifyListeners();
  }
}
