import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hngstage4/models.dart';

class PriceHistory {
  final List<double> prices;
  PriceHistory({required this.prices});

  factory PriceHistory.fromJson(Map<String, dynamic> json) {
    List<double> parsedPrices = [];
    if (json['data']?['history'] != null) {
      for (var item in json['data']['history']) {
        final price = double.tryParse(item['price'] ?? '0.0');
        if (price != null) {
          parsedPrices.add(price);
        }
      }
    }
    return PriceHistory(prices: parsedPrices.reversed.toList());
  }
}

class ApiService {
  static const String _baseUrl = 'https://api.coinranking.com/v2/';
  static const String _apiKey = 'coinranking609400de1d81eea13e31cd5c6e4e2f6d102facaed615bda0';


  static Future<List<Coin>> getCoins() async {
    final url = Uri.parse('${_baseUrl}coins');
    try {
      final response = await http.get(
        url,
        headers: {'x-access-token': _apiKey},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success' && data['data']?['coins'] != null) {
          final List<dynamic> coinList = data['data']['coins'];
          return coinList.map((json) => Coin.fromJson(json)).toList();
        } else {
          throw Exception('API response was not successful.');
        }
      } else {
        throw Exception('Failed to load coins: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getCoins: $e');
      throw Exception('Failed to connect to the server. Please check your internet connection.');
    }
  }


  static Future<List<double>> getCoinHistory(String coinUuid, String timePeriod) async {

    final Map<String, String> timeFrameMapping = {
      '24H': '24h', '1W': '7d', '1M': '30d', '1Y': '1y', 'All': '5y'
    };
    final apiTimePeriod = timeFrameMapping[timePeriod] ?? '24h';
    final url = Uri.parse('${_baseUrl}coin/$coinUuid/history?timePeriod=$apiTimePeriod');
    try {
      final response = await http.get(url, headers: {'x-access-token': _apiKey}).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          return PriceHistory.fromJson(data).prices;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error in getCoinHistory: $e');
      return [];
    }
  }

  static Future<CoinDetail> getCoinDetails(String uuid) async {
    // ... (implementation is correct)
    final String url = '${_baseUrl}coin/$uuid';
    try {
      final response = await http.get(Uri.parse(url), headers: {'x-access-token': _apiKey});
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success' && responseData['data']?['coin'] != null) {
          return CoinDetail.fromJson(responseData['data']['coin']);
        } else {
          throw Exception('API response was not successful for coin details.');
        }
      } else {
        throw Exception('Failed to load coin details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getCoinDetails: $e');
      throw Exception('Failed to load coin details: $e');
    }
  }

  static Future<String> fetchAndCleanSvg(String url) async {
    try {
      if (!url.toLowerCase().endsWith('.svg')) {
        return '';
      }
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = response.body;
        final contentType = response.headers['content-type'];

        if ((contentType != null && contentType.contains('image/svg+xml')) || (body.trim().startsWith('<svg'))) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('Could not fetch SVG from $url: $e');
    }
    return '';
  }
}
