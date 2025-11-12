class Coin {
  final String uuid;
  final String name;
  final String symbol;
  final String iconUrl;
  final double price;
  final double change;
  List<double> chartData;

  Coin({
    required this.uuid,
    required this.name,
    required this.symbol,
    required this.iconUrl,
    required this.price,
    required this.change,
    required this.chartData,
  });

  factory Coin.fromJson(Map<String, dynamic> json) {
    List<double> parsedChartData = (json['sparkline'] as List?)
        ?.map((e) => e == null ? 0.0 : double.tryParse(e.toString()) ?? 0.0)
        .toList() ??
        [];

    return Coin(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? 'Unknown',
      symbol: json['symbol'] ?? 'N/A',
      iconUrl: json['iconUrl'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      change: double.tryParse(json['change']?.toString() ?? '0.0') ?? 0.0,
      chartData: parsedChartData,
    );
  }
}

class CoinDetail {
  final String uuid;
  final String name;
  final String symbol;
  final String iconUrl;
  final double price;
  final double change;
  final List<double> sparkline;
  final double marketCap;
  final double volume24h;
  final double allTimeHigh;
  final double circulatingSupply;
  final int numberOfMarkets;

  CoinDetail({
    required this.uuid,
    required this.name,
    required this.symbol,
    required this.iconUrl,
    required this.price,
    required this.change,
    required this.sparkline,
    required this.marketCap,
    required this.volume24h,
    required this.allTimeHigh,
    required this.circulatingSupply,
    required this.numberOfMarkets,
  });

  factory CoinDetail.fromJson(Map<String, dynamic> json) {
    List<double> parsedSparkline = (json['sparkline'] as List?)
        ?.map((e) => e == null ? 0.0 : double.tryParse(e.toString()) ?? 0.0)
        .toList() ??
        [];

    return CoinDetail(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? 'Unknown',
      symbol: json['symbol'] ?? 'N/A',
      iconUrl: json['iconUrl'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      change: double.tryParse(json['change']?.toString() ?? '0.0') ?? 0.0,
      marketCap: double.tryParse(json['marketCap']?.toString() ?? '0.0') ?? 0.0,
      volume24h: double.tryParse(json['24hVolume']?.toString() ?? '0.0') ?? 0.0,
      allTimeHigh:
      double.tryParse(json['allTimeHigh']?['price']?.toString() ?? '0.0') ??
          0.0,
      circulatingSupply: double.tryParse(
          json['supply']?['circulating']?.toString() ?? '0.0') ??
          0.0,
      numberOfMarkets: json['numberOfMarkets'] ?? 0,
      sparkline: parsedSparkline,
    );
  }
}
