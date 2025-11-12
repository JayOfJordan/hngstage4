import 'dart:convert';
import 'package:hngstage4/trade_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _transactionsKey = 'transaction_history';

  static Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> transactionsJson =
    transactions.map((tx) => tx.toJson()).toList();
    await prefs.setString(_transactionsKey, json.encode(transactionsJson));
  }

  static Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsString = prefs.getString(_transactionsKey);

    if (transactionsString == null) {
      return [];
    }

    final List<dynamic> transactionsJson = json.decode(transactionsString);
    return transactionsJson
        .map((json) => Transaction.fromJson(json))
        .toList();
  }
}
