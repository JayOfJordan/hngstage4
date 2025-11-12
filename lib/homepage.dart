import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hngstage4/adaptive_utils.dart';
import 'package:hngstage4/api_service.dart';
import 'package:hngstage4/coin_detail_screen.dart';
import 'package:hngstage4/favourites_screen.dart';
import 'package:hngstage4/chart_painter.dart';
import 'package:hngstage4/models.dart';
import 'package:hngstage4/trade_screen.dart';

class CryptoHomePage extends StatefulWidget {
  const CryptoHomePage({super.key});

  @override
  State<CryptoHomePage> createState() => _CryptoHomePageState();
}

class _CryptoHomePageState extends State<CryptoHomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      CryptoHomePageBody(scaffoldKey: _scaffoldKey),
      const TradeScreen(),
      FavoritesScreen(onAddFavoritesTapped: () => _onItemTapped(0)),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: const Color(0xFF161B22),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1E229F),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF1E229F),
                    backgroundImage: AssetImage('assets/Jordan1.png'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Jordan-J',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.white),
              title: const Text('Fund Wallet', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            const Divider(color: Color(0xFF0D1117)),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Center(
        child: widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Swap'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favorites'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade600,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF0D1117),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}

class CryptoHomePageBody extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const CryptoHomePageBody({super.key, required this.scaffoldKey});

  @override
  State<CryptoHomePageBody> createState() => _CryptoHomePageBodyState();
}

class _CryptoHomePageBodyState extends State<CryptoHomePageBody> {
  late StreamController<List<Coin>> _coinStreamController;
  List<Coin> _allCoins = [];
  final TextEditingController _searchController = TextEditingController();
  List<Coin> _filteredCoins = [];
  String _searchQuery = '';

  Timer? _timer;

  double _walletBalanceUSD = 0.0;
  double _walletChange = 0.0;
  final double _btcOwned = 0.5;
  final String _btcUuid = 'Qwsogvtv82FCd';

  final double _usdToNgnRate = 1500.0;
  final String _currencySymbol = '₦';

  @override
  void initState() {
    super.initState();
    _coinStreamController = StreamController<List<Coin>>.broadcast();
    _setupCoinStream();
    _refreshData();
    _searchController.addListener(_filterCoins);
  }

  void _setupCoinStream() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    try {
      final coins = await ApiService.getCoins();
      if (mounted) {
        _allCoins = coins;
        _coinStreamController.add(coins);

        final btcCoin = coins.firstWhere((coin) => coin.uuid == _btcUuid,
            orElse: () => Coin(
                uuid: '',
                symbol: 'BTC',
                name: 'Bitcoin',
                iconUrl: '',
                price: 0,
                change: 0,
                chartData: []));

        setState(() {
          _walletBalanceUSD = btcCoin.price * _btcOwned;
          _walletChange = btcCoin.change;
        });

        if (_searchQuery.isNotEmpty) {
          _filterCoins();
        }
      }
    } catch (e) {
      if (mounted && !_coinStreamController.isClosed) {
        _coinStreamController.addError('Failed to load coin data.');
      }
    }
  }

  void _filterCoins() {
    final query = _searchController.text;
    setState(() {
      _searchQuery = query;
      if (query.isNotEmpty) {
        _filteredCoins = _allCoins.where((coin) {
          final coinName = coin.name.toLowerCase();
          final coinSymbol = coin.symbol.toLowerCase();
          final searchQuery = query.toLowerCase();
          return coinName.contains(searchQuery) ||
              coinSymbol.contains(searchQuery);
        }).toList();
      } else {
        _filteredCoins = [];
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _coinStreamController.close();
    _searchController.dispose();
    super.dispose();
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Coming Soon!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('This feature is currently under development.',
              style: TextStyle(color: Colors.grey)),
          actions: [
            TextButton(
              child: const Text('Back',
                  style: TextStyle(color: Color(0xFF3E64FF), fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adaptive = AdaptiveUtils(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E229F), Color(0xFF0D1117)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.4],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          backgroundColor: const Color(0xFF1E229F),
          color: Colors.white,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeader(adaptive),
                    SizedBox(height: adaptive.heightPercent(3)),
                    _buildActionButtons(adaptive),
                    SizedBox(height: adaptive.heightPercent(2)),
                    _buildSearchBar(adaptive),
                  ],
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: true,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D1117),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: StreamBuilder<List<Coin>>(
                    stream: _coinStreamController.stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          _allCoins.isEmpty) {
                        return const Center(
                            child: CircularProgressIndicator(color: Colors.white));
                      }
                      if (snapshot.hasError && _allCoins.isEmpty) {
                        return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                snapshot.error.toString(),
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ));
                      }
                      final coinsToShow = _searchQuery.isNotEmpty ? _filteredCoins : _allCoins;
                      if (coinsToShow.isEmpty && _searchQuery.isEmpty) {
                        return const Center(
                            child: Text('No coins available.',
                                style: TextStyle(color: Colors.grey)));
                      }

                      return _searchQuery.isNotEmpty
                          ? _buildSearchResults()
                          : _buildDefaultCoinList(_allCoins);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AdaptiveUtils adaptive) {
    return Padding(
      padding: EdgeInsets.only(
        left: adaptive.widthPercent(5),
        right: adaptive.widthPercent(5),
        bottom: adaptive.heightPercent(2),
      ),
      child: TextFormField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search Coins...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
          filled: true,
          fillColor: const Color(0xFF161B22),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () => _searchController.clear(),
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredCoins.isEmpty) {
      return Center(
        child: Text(
          'No coins found for "$_searchQuery"',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(
          horizontal: AdaptiveUtils(context).widthPercent(5),
          vertical: AdaptiveUtils(context).heightPercent(2)),
      itemCount: _filteredCoins.length,
      itemBuilder: (context, index) {
        final coin = _filteredCoins[index];
        return CoinListItem(
          coin: coin,
          conversionRate: _usdToNgnRate,
          currencySymbol: _currencySymbol,
        );
      },
    );
  }

  Widget _buildDefaultCoinList(List<Coin> coins) {
    if (coins.isEmpty) return const SizedBox.shrink();
    coins.sort((a, b) => b.price.compareTo(a.price));
    final featuredCoins = coins.take(4).toList();
    final otherCoins = coins.skip(4).toList();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: AdaptiveUtils(context).heightPercent(2)),
            child: SizedBox(
              height: AdaptiveUtils(context).heightPercent(22),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                    horizontal: AdaptiveUtils(context).widthPercent(5)),
                itemCount: featuredCoins.length,
                separatorBuilder: (context, index) =>
                    SizedBox(width: AdaptiveUtils(context).widthPercent(4)),
                itemBuilder: (context, idx) {
                  return FeaturedCoinCard(
                    coin: featuredCoins[idx],
                    conversionRate: _usdToNgnRate,
                    currencySymbol: _currencySymbol,
                  );
                },
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AdaptiveUtils(context).widthPercent(5)),
                child: CoinListItem(
                  coin: otherCoins[index],
                  conversionRate: _usdToNgnRate,
                  currencySymbol: _currencySymbol,
                ),
              );
            },
            childCount: otherCoins.length,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AdaptiveUtils adaptive) {
    final double walletBalanceNaira = _walletBalanceUSD * _usdToNgnRate;
    final changeColor = _walletChange >= 0 ? Colors.green : Colors.red;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: adaptive.widthPercent(5)),
      child: Column(
        children: [
          SizedBox(height: adaptive.heightPercent(2)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder<String>(
                      future: rootBundle.loadString('assets/btc.svg'),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          try {
                            return SvgPicture.string(
                              snapshot.data!,
                              width: 16,
                            );
                          } catch (e) {
                            return const Icon(Icons.error, color: Colors.red, size: 16);
                          }
                        }
                        return const SizedBox(width: 16);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text('0x2930...3904',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: adaptive.responsiveFontSize(14))),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white),
                onPressed: () {
                  widget.scaffoldKey.currentState?.openDrawer();
                },
              ),
            ],
          ),
          SizedBox(height: adaptive.heightPercent(3)),
          Text('Current Wallet Balance',
              style: TextStyle(
                  color: Colors.grey, fontSize: adaptive.responsiveFontSize(15))),
          SizedBox(height: adaptive.heightPercent(1)),
          Text(
            '$_currencySymbol${walletBalanceNaira.toStringAsFixed(2)}',
            style: TextStyle(
                color: Colors.white,
                fontSize: adaptive.responsiveFontSize(36),
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: adaptive.heightPercent(1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_walletChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: changeColor, size: 16),
              const SizedBox(width: 4),
              Text(
                '${_walletChange.toStringAsFixed(2)}%',
                style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: adaptive.responsiveFontSize(14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AdaptiveUtils adaptive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ActionButton(
          icon: Icons.arrow_upward,
          label: 'Send',
          onTap: _showComingSoonDialog,
        ),
        ActionButton(
          icon: Icons.add,
          label: 'Buy',
          isPrimary: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TradeScreen()),
            );
          },
        ),
        ActionButton(
          icon: Icons.arrow_downward,
          label: 'Receive',
          onTap: _showComingSoonDialog,
        ),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final adaptive = AdaptiveUtils(context);
    final double buttonSize = adaptive.widthPercent(16);
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
              color: isPrimary ? const Color(0xFF3E64FF) : Colors.black.withOpacity(0.3),
              shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: adaptive.responsiveFontSize(28)),
        ),
        SizedBox(height: adaptive.heightPercent(1)),
        Text(label, style: TextStyle(color: Colors.white, fontSize: adaptive.responsiveFontSize(14))),
      ]),
    );
  }
}

class FeaturedCoinCard extends StatelessWidget {
  final Coin coin;
  final double conversionRate;
  final String currencySymbol;

  const FeaturedCoinCard({
    super.key,
    required this.coin,
    required this.conversionRate,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final adaptive = AdaptiveUtils(context);
    final color = coin.change >= 0 ? Colors.green : Colors.red;
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CoinDetailScreen(
                    coin: coin,
                    conversionRate: conversionRate,
                    currencySymbol: currencySymbol)));
      },
      child: Container(
        width: adaptive.widthPercent(45),
        padding: EdgeInsets.all(adaptive.widthPercent(4)),
        decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              SizedBox(
                width: 32,
                height: 32,
                child: coin.iconUrl.toLowerCase().endsWith('.svg')
                    ? FutureBuilder<String>(
                  future: ApiService.fetchAndCleanSvg(coin.iconUrl),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircleAvatar(
                          radius: 16, backgroundColor: Colors.grey);
                    }
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      try {
                        return SvgPicture.string(snapshot.data!,
                            placeholderBuilder: (_) => const CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.grey));
                      } catch (e) {
                        return const CircleAvatar(
                            radius: 16,
                            child: Icon(Icons.error, size: 18));
                      }
                    }
                    return const CircleAvatar(
                        radius: 16, child: Icon(Icons.error, size: 18));
                  },
                )
                    : Image.network(coin.iconUrl,
                    errorBuilder: (context, error, stackTrace) {
                      return const CircleAvatar(
                          radius: 16, child: Icon(Icons.error));
                    }, loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2));
                    }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coin.symbol,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: adaptive.responsiveFontSize(18))),
                    Text(coin.name,
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: adaptive.responsiveFontSize(14)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                  ],
                ),
              ),
            ]),
            const Spacer(),
            Text('$currencySymbol${(coin.price * conversionRate).toStringAsFixed(2)}',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: adaptive.responsiveFontSize(18),
                    fontWeight: FontWeight.bold)),
            Text('${coin.change.toStringAsFixed(2)}%',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: adaptive.responsiveFontSize(14))),
            SizedBox(height: adaptive.heightPercent(1)),
            Expanded(
              child: coin.chartData.isEmpty
                  ? Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.grey.shade600, strokeWidth: 2.0)))
                  : CustomPaint(
                  painter: LineChartPainter(
                    data: coin.chartData,
                    color: color,
                  ),
                  size: const Size(double.infinity, double.infinity)),
            ),
          ],
        ),
      ),
    );
  }
}

class CoinListItem extends StatelessWidget {
  final Coin coin;
  final double conversionRate;
  final String currencySymbol;

  const CoinListItem({
    super.key,
    required this.coin,
    required this.conversionRate,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final adaptive = AdaptiveUtils(context);
    final color = coin.change >= 0 ? Colors.green : Colors.red;
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CoinDetailScreen(
                    coin: coin,
                    conversionRate: conversionRate,
                    currencySymbol: currencySymbol)));
      },
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(vertical: adaptive.heightPercent(1.5)),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: coin.iconUrl.toLowerCase().endsWith('.svg')
                  ? FutureBuilder<String>(
                future: ApiService.fetchAndCleanSvg(coin.iconUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const CircleAvatar(
                        radius: 16, backgroundColor: Colors.grey);
                  }
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    try {
                      return SvgPicture.string(snapshot.data!,
                          placeholderBuilder: (_) => const CircleAvatar(
                              radius: 16, backgroundColor: Colors.grey));
                    } catch (e) {
                      return const CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.error, size: 18));
                    }
                  }
                  return const CircleAvatar(
                      radius: 16, child: Icon(Icons.error, size: 18));
                },
              )
                  : Image.network(coin.iconUrl,
                  errorBuilder: (context, error, stackTrace) {
                    return const CircleAvatar(
                        radius: 16, child: Icon(Icons.error));
                  }, loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coin.symbol,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: adaptive.responsiveFontSize(18))),
                  Text(coin.name,
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: adaptive.responsiveFontSize(14)),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: adaptive.widthPercent(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      '$currencySymbol${(coin.price * conversionRate).toStringAsFixed(2)}',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: adaptive.responsiveFontSize(16))),
                  Text('${coin.change.toStringAsFixed(2)}%',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: adaptive.responsiveFontSize(14))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
