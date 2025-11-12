import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import 'package:hngstage4/adaptive_utils.dart';
import 'package:hngstage4/api_service.dart';
import 'package:hngstage4/favourites.dart';
import 'package:hngstage4/models.dart';
import 'package:hngstage4/chart_painter.dart';
import 'package:provider/provider.dart';

class CoinDetailScreen extends StatefulWidget {
  final Coin coin;
  final double conversionRate;
  final String currencySymbol;

  const CoinDetailScreen({
    super.key,
    required this.coin,
    required this.conversionRate,
    required this.currencySymbol,
  });

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  late StreamController<CoinDetail> _streamController;
  late Timer _timer;
  String _selectedTimeFrame = '24H';
  bool _isChartLoading = false;
  late List<double> _currentChartData;

  @override
  void initState() {
    super.initState();
    _currentChartData = widget.coin.chartData;
    _streamController = StreamController<CoinDetail>.broadcast();

    _fetchCoinDetails();
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchCoinDetails();
    });
  }

  Future<void> _fetchCoinDetails() async {
    try {
      final details = await ApiService.getCoinDetails(widget.coin.uuid);
      if (!_streamController.isClosed) {
        _streamController.add(details);
        if (mounted && _selectedTimeFrame == '24H') {
          setState(() {
            _currentChartData = details.sparkline;
          });
        }
      }
    } catch (e) {
      if (!_streamController.isClosed) {
        _streamController.addError('Failed to fetch real-time data.');
      }
      debugPrint("Error fetching coin details: $e");
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _streamController.close();
    super.dispose();
  }

  Future<void> _onTimeFrameSelected(String timeFrame) async {
    if (_isChartLoading) return;
    setState(() {
      _selectedTimeFrame = timeFrame;
      _isChartLoading = true;
    });

    try {
      if (timeFrame == '24H' && _streamController.hasListener) {
        final latestDetails = await ApiService.getCoinDetails(widget.coin.uuid);
        if (mounted) {
          setState(() {
            _currentChartData = latestDetails.sparkline;
            _isChartLoading = false;
          });
        }
      } else {
        final newChartData =
        await ApiService.getCoinHistory(widget.coin.uuid, timeFrame);
        if (mounted) {
          setState(() {
            _currentChartData = newChartData;
            _isChartLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChartLoading = false;
        });
      }
    }
  }

  String _formatNumber(double number) {
    if (number >= 1.0e12) return '${(number / 1.0e12).toStringAsFixed(2)}T';
    if (number >= 1.0e9) return '${(number / 1.0e9).toStringAsFixed(2)}B';
    if (number >= 1.0e6) return '${(number / 1.0e6).toStringAsFixed(2)}M';
    return number
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = AdaptiveUtils(context);
    return Consumer<Favorites>(
      builder: (context, favoritesProvider, child) {
        final isFavorited = favoritesProvider.isFavorite(widget.coin);
        return Scaffold(
          backgroundColor: const Color(0xFF0D1117),
          body: StreamBuilder<CoinDetail>(
            stream: _streamController.stream,
            builder: (context, snapshot) {
              final coinDetail = snapshot.data;
              final iconUrl = coinDetail?.iconUrl ?? widget.coin.iconUrl;
              final symbol = coinDetail?.symbol ?? widget.coin.symbol;
              final price = coinDetail?.price ?? widget.coin.price;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: const Color(0xFF0D1117),
                    pinned: true,
                    elevation: 0,
                    leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop()),
                    title: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: iconUrl.toLowerCase().endsWith('.svg')
                              ? FutureBuilder<String>(
                            future: ApiService.fetchAndCleanSvg(iconUrl),
                            builder: (context, svgSnapshot) {
                              if (svgSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey);
                              }
                              if (svgSnapshot.hasData &&
                                  svgSnapshot.data!.isNotEmpty) {
                                try {
                                  return SvgPicture.string(svgSnapshot.data!,
                                      placeholderBuilder: (_) =>
                                      const CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.grey));
                                } catch (e) {
                                  return const CircleAvatar(
                                      radius: 16,
                                      child: Icon(Icons.error, size: 18));
                                }
                              }
                              return const CircleAvatar(
                                  radius: 16,
                                  child: Icon(Icons.error, size: 18));
                            },
                          )
                              : Image.network(iconUrl,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                              const CircleAvatar(
                                  radius: 16,
                                  child: Icon(Icons.error)),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2));
                              }),
                        ),
                        SizedBox(width: adaptive.widthPercent(3)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$symbol / NGN',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: adaptive.responsiveFontSize(18),
                                    fontWeight: FontWeight.bold)),
                            Text(
                                '${widget.currencySymbol}${_formatNumber(price * widget.conversionRate)}',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize:
                                    adaptive.responsiveFontSize(14))),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                          onPressed: () =>
                              favoritesProvider.toggleFavorite(widget.coin),
                          icon: Icon(
                              isFavorited ? Icons.star : Icons.star_border,
                              color: isFavorited
                                  ? Colors.yellow[700]
                                  : Colors.grey,
                              size: 28)),
                      SizedBox(width: adaptive.widthPercent(2)),
                    ],
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData)
                    const SliverFillRemaining(
                      child: Center(
                          child: CircularProgressIndicator(color: Colors.white)),
                    )
                  else if (snapshot.hasError)
                    SliverFillRemaining(
                      child: Center(
                          child: Text('${snapshot.error}',
                              style: const TextStyle(color: Colors.red))),
                    )
                  else if (!snapshot.hasData)
                      const SliverFillRemaining(
                        child: Center(
                            child: Text('Awaiting real-time data...',
                                style: TextStyle(color: Colors.grey))),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(adaptive.widthPercent(5)),
                          child: Column(
                            children: [
                              _buildPriceHeader(adaptive, coinDetail!),
                              SizedBox(height: adaptive.heightPercent(3)),
                              _buildChartSection(adaptive, coinDetail),
                              SizedBox(height: adaptive.heightPercent(3)),
                              _buildMarketStats(adaptive, coinDetail), // Pass detail for conversion
                              SizedBox(height: adaptive.heightPercent(3)),
                              _buildKeyData(adaptive, coinDetail),
                              SizedBox(height: adaptive.heightPercent(4)),
                            ],
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
          bottomNavigationBar: _buildBottomButtons(adaptive),
        );
      },
    );
  }

  Widget _buildPriceHeader(AdaptiveUtils adaptive, CoinDetail coin) {
    final color = coin.change >= 0 ? Colors.green : Colors.red;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 30,
          width: adaptive.widthPercent(20),
          child: CustomPaint(
            painter: LineChartPainter(data: coin.sparkline, color: color),
            size: const Size(80, 30),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
                '${widget.currencySymbol}${_formatNumber(coin.price * widget.conversionRate)}',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: adaptive.responsiveFontSize(20))),
            Text('${coin.change >= 0 ? '+' : ''}${coin.change.toStringAsFixed(2)}%',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: adaptive.responsiveFontSize(16))),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection(AdaptiveUtils adaptive, CoinDetail coin) {
    final color = coin.change >= 0 ? Colors.green : Colors.red;
    final List<String> timeFrames = ['24H', '1W', '1M', '1Y', 'All'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: timeFrames
              .map((frame) => TimeFrameButton(
              label: frame,
              isActive: _selectedTimeFrame == frame,
              onTap: () => _onTimeFrameSelected(frame)))
              .toList(),
        ),
        SizedBox(height: adaptive.heightPercent(4)),
        SizedBox(
          height: adaptive.heightPercent(25),
          child: _isChartLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : CustomPaint(
              painter: LineChartPainter(
                  data: _currentChartData,
                  color: color,
                  isDetailed: true),
              size: const Size(double.infinity, 200)),
        ),
      ],
    );
  }

  Widget _buildMarketStats(AdaptiveUtils adaptive, CoinDetail coin) {
    if (_currentChartData.isEmpty) {
      return const SizedBox.shrink();
    }

    final double openUsd = _currentChartData.first;
    final double highUsd = _currentChartData.reduce(max);
    final double lowUsd = _currentChartData.reduce(min);
    final double closeUsd = _currentChartData.last;

    final double conversionRate = widget.conversionRate;
    final double openNgn = openUsd * conversionRate;
    final double highNgn = highUsd * conversionRate;
    final double lowNgn = lowUsd * conversionRate;
    final double closeNgn = closeUsd * conversionRate;

    return Container(
      padding: EdgeInsets.all(adaptive.widthPercent(5)),
      decoration:
      BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatColumn('Open', _formatNumber(openNgn), adaptive),
          _buildStatColumn('High', _formatNumber(highNgn), adaptive),
          _buildStatColumn('Low', _formatNumber(lowNgn), adaptive),
          _buildStatColumn('Close', _formatNumber(closeNgn), adaptive),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, AdaptiveUtils adaptive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        Text('${widget.currencySymbol}$value',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildKeyData(AdaptiveUtils adaptive, CoinDetail coin) {
    return Column(
      children: [
        KeyDataRow(
            label: 'Market Cap',
            value:
            '${widget.currencySymbol}${_formatNumber(coin.marketCap * widget.conversionRate)}'),
        const Divider(color: Color(0xFF161B22)),
        KeyDataRow(
            label: '24h Volume',
            value:
            '${widget.currencySymbol}${_formatNumber(coin.volume24h * widget.conversionRate)}'),
        const Divider(color: Color(0xFF161B22)),
        KeyDataRow(
            label: 'All-Time High',
            value:
            '${widget.currencySymbol}${_formatNumber(coin.allTimeHigh * widget.conversionRate)}'),
        const Divider(color: Color(0xFF161B22)),
        KeyDataRow(
            label: 'Circulating Supply',
            value: '${_formatNumber(coin.circulatingSupply)} ${coin.symbol}'),
      ],
    );
  }

  Widget _buildBottomButtons(AdaptiveUtils adaptive) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(adaptive.widthPercent(5)),
        child: Row(children: [
          Expanded(
              child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF161B22),
                      padding: EdgeInsets.symmetric(
                          vertical: adaptive.heightPercent(2)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text('Sell',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: adaptive.responsiveFontSize(16))))),
          const SizedBox(width: 16),
          Expanded(
              child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E64FF),
                      padding: EdgeInsets.symmetric(
                          vertical: adaptive.heightPercent(2)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text('Buy',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: adaptive.responsiveFontSize(16))))),
        ]),
      ),
    );
  }
}

class TimeFrameButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const TimeFrameButton(
      {super.key,
        required this.label,
        this.isActive = false,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final adaptive = AdaptiveUtils(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: adaptive.widthPercent(4),
            vertical: adaptive.heightPercent(1)),
        decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: adaptive.responsiveFontSize(14))),
      ),
    );
  }
}

class KeyDataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const KeyDataRow(
      {super.key,
        required this.label,
        required this.value,
        this.valueColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    final adaptive = AdaptiveUtils(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: adaptive.heightPercent(1.5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey, fontSize: adaptive.responsiveFontSize(16))),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: adaptive.responsiveFontSize(16),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
