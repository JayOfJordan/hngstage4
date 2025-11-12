import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hngstage4/adaptive_utils.dart';
import 'package:hngstage4/api_service.dart';
import 'package:hngstage4/models.dart';
import 'package:hngstage4/storage_service.dart'; 


class Transaction {
  final String coinSymbol;
  final String coinName;
  final String transactionType;
  final double amountCrypto;
  final double amountFiat;
  final DateTime date;

  Transaction({
    required this.coinSymbol,
    required this.coinName,
    required this.transactionType,
    required this.amountCrypto,
    required this.amountFiat,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'coinSymbol': coinSymbol,
    'coinName': coinName,
    'transactionType': transactionType,
    'amountCrypto': amountCrypto,
    'amountFiat': amountFiat,
    'date': date.toIso8601String(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    coinSymbol: json['coinSymbol'],
    coinName: json['coinName'],
    transactionType: json['transactionType'],
    amountCrypto: json['amountCrypto'],
    amountFiat: json['amountFiat'],
    date: DateTime.parse(json['date']),
  );
}

class PortfolioAsset {
  final String uuid;
  final String symbol;
  final String name;
  double amount;

  PortfolioAsset({
    required this.uuid,
    required this.symbol,
    required this.name,
    required this.amount,
  });
}



class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {

  bool _isBuyMode = true;
  Coin? _selectedCoin;
  List<Coin> _availableCoins = [];
  bool _isLoading = true;

  final TextEditingController _fiatController = TextEditingController();
  final TextEditingController _cryptoController = TextEditingController();


  final double _fiatBalance = 2500000.00;
  final double _usdToNgnRate = 1500.0;
  final String _currencySymbol = '₦';
  final List<PortfolioAsset> _portfolio = [
    PortfolioAsset(uuid: 'Qwsogvtv82FCd', symbol: 'BTC', name: 'Bitcoin', amount: 0.15),
    PortfolioAsset(uuid: 'razxDUgYGNAdQ', symbol: 'ETH', name: 'Ethereum', amount: 2.5),
  ];
  List<Transaction> _transactionHistory = [];

  Transaction? _lastDeletedTransaction;
  int? _lastDeletedIndex;
  Timer? _deleteTimer;
  int _countdownSeconds = 10;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _fiatController.addListener(_onFiatAmountChanged);
    _cryptoController.addListener(_onCryptoAmountChanged);
  }


  Future<void> _loadInitialData() async {
    final loadedTransactions = await StorageService.loadTransactions();
    if (mounted) {
      setState(() {
        _transactionHistory = loadedTransactions;
      });
    }
    await _fetchAvailableCoins();
  }

  Future<void> _fetchAvailableCoins() async {
    try {
      final coins = await ApiService.getCoins();
      if (mounted) {
        setState(() {
          _availableCoins = coins;
          if (_availableCoins.isNotEmpty) {
            _selectedCoin = _availableCoins.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load coins: $e")),
        );
      }
    }
  }

  void _onFiatAmountChanged() {
    if (_fiatController.text.isEmpty || _selectedCoin == null) {
      if (_cryptoController.text.isNotEmpty) _cryptoController.clear();
      return;
    }
    final fiatAmount = double.tryParse(_fiatController.text) ?? 0;
    final coinPriceNgn = _selectedCoin!.price * _usdToNgnRate;
    if (coinPriceNgn > 0) {
      final cryptoAmount = fiatAmount / coinPriceNgn;
      _cryptoController.removeListener(_onCryptoAmountChanged);
      _cryptoController.text = cryptoAmount.toStringAsFixed(8);
      _cryptoController.addListener(_onCryptoAmountChanged);
    }
  }

  void _onCryptoAmountChanged() {
    if (_cryptoController.text.isEmpty || _selectedCoin == null) {
      if (_fiatController.text.isNotEmpty) _fiatController.clear();
      return;
    }
    final cryptoAmount = double.tryParse(_cryptoController.text) ?? 0;
    final coinPriceNgn = _selectedCoin!.price * _usdToNgnRate;
    final fiatAmount = cryptoAmount * coinPriceNgn;
    _fiatController.removeListener(_onFiatAmountChanged);
    _fiatController.text = fiatAmount.toStringAsFixed(2);
    _fiatController.addListener(_onFiatAmountChanged);
  }

  void _executeTrade() {
    final fiatAmount = double.tryParse(_fiatController.text);
    final cryptoAmount = double.tryParse(_cryptoController.text);

    if (fiatAmount == null || cryptoAmount == null || fiatAmount <= 0 || _selectedCoin == null) {
      _showErrorSnackBar("Please enter a valid amount.");
      return;
    }

    if (_isBuyMode) {
      if (fiatAmount > _fiatBalance) {
        _showErrorSnackBar("Insufficient NGN balance.");
        return;
      }
      final existingAsset = _portfolio.where((a) => a.uuid == _selectedCoin!.uuid).firstOrNull;
      if (existingAsset != null) {
        existingAsset.amount += cryptoAmount;
      } else {
        _portfolio.add(PortfolioAsset(
          uuid: _selectedCoin!.uuid,
          symbol: _selectedCoin!.symbol,
          name: _selectedCoin!.name,
          amount: cryptoAmount,
        ));
      }
    } else {
      final assetToSell = _portfolio.where((a) => a.uuid == _selectedCoin!.uuid).firstOrNull;
      if (assetToSell == null || cryptoAmount > assetToSell.amount) {
        _showErrorSnackBar("Insufficient ${_selectedCoin!.symbol} balance.");
        return;
      }
      assetToSell.amount -= cryptoAmount;
    }

    final newTransaction = Transaction(
      coinSymbol: _selectedCoin!.symbol,
      coinName: _selectedCoin!.name,
      transactionType: _isBuyMode ? "Buy" : "Sell",
      amountCrypto: cryptoAmount,
      amountFiat: fiatAmount,
      date: DateTime.now(),
    );

    setState(() {
      _transactionHistory.insert(0, newTransaction);
      _fiatController.clear();
      _cryptoController.clear();
    });
    StorageService.saveTransactions(_transactionHistory);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Trade successful!"), backgroundColor: Colors.green),
    );
  }

  void _deleteTransaction(int index) {
    setState(() {
      _lastDeletedTransaction = _transactionHistory[index];
      _lastDeletedIndex = index;
      _transactionHistory.removeAt(index);
    });
    _showUndoSnackBar();
  }

  void _showUndoSnackBar() {
    _deleteTimer?.cancel();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    setState(() {
      _countdownSeconds = 10;
    });

    final snackBar = SnackBar(
      duration: const Duration(seconds: 10),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setSnackState) {
          _deleteTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            setSnackState(() {
              if (_countdownSeconds > 0) {
                _countdownSeconds--;
              } else {
                timer.cancel();
              }
            });
          });

          return Text("Transaction deleted. (${_countdownSeconds}s)");
        },
      ),
      action: SnackBarAction(
        label: "Restore",
        textColor: Colors.yellow,
        onPressed: _restoreTransaction,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((reason) {
      _deleteTimer?.cancel();
      if (_lastDeletedTransaction != null) {
        StorageService.saveTransactions(_transactionHistory);
        _lastDeletedTransaction = null;
        _lastDeletedIndex = null;
      }
    });
  }

  void _restoreTransaction() {
    _deleteTimer?.cancel();
    if (_lastDeletedTransaction != null && _lastDeletedIndex != null) {
      setState(() {
        _transactionHistory.insert(_lastDeletedIndex!, _lastDeletedTransaction!);
      });
      _lastDeletedTransaction = null;
      _lastDeletedIndex = null;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _fiatController.dispose();
    _cryptoController.dispose();
    _deleteTimer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final adaptive = AdaptiveUtils(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: Text(
          'Buy & Sell Crypto',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: adaptive.responsiveFontSize(22),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
        padding: EdgeInsets.all(adaptive.widthPercent(5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTradeTypeToggle(adaptive),
            const SizedBox(height: 24),
            _buildCoinSelector(adaptive),
            const SizedBox(height: 24),
            _buildAmountInput(
              adaptive: adaptive,
              controller: _fiatController,
              label: "Amount in NGN",
              currencySymbol: _currencySymbol,
            ),
            const SizedBox(height: 16),
            _buildAmountInput(
              adaptive: adaptive,
              controller: _cryptoController,
              label: "Amount in ${_selectedCoin?.symbol ?? 'COIN'}",
              currencySymbol: _selectedCoin?.symbol ?? '',
              isCrypto: true,
            ),
            const SizedBox(height: 24),
            _buildConfirmButton(adaptive),
            const SizedBox(height: 32),
            Text(
              "Transaction History",
              style: TextStyle(
                color: Colors.white,
                fontSize: adaptive.responsiveFontSize(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTransactionHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeTypeToggle(AdaptiveUtils adaptive) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isBuyMode = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isBuyMode ? const Color(0xFF3E64FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "Buy",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: adaptive.responsiveFontSize(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isBuyMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isBuyMode ? const Color(0xFF3E64FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "Sell",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: adaptive.responsiveFontSize(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinSelector(AdaptiveUtils adaptive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Coin>(
          value: _selectedCoin,
          isExpanded: true,
          dropdownColor: const Color(0xFF161B22),
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          onChanged: (Coin? newCoin) {
            setState(() {
              _selectedCoin = newCoin;
              if (_fiatController.text.isNotEmpty) {
                _onFiatAmountChanged();
              } else if (_cryptoController.text.isNotEmpty) {
                _onCryptoAmountChanged();
              }
            });
          },
          items: _availableCoins.map<DropdownMenuItem<Coin>>((Coin coin) {
            return DropdownMenuItem<Coin>(
              value: coin,
              child: Text("${coin.name} (${coin.symbol})"),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAmountInput({
    required AdaptiveUtils adaptive,
    required TextEditingController controller,
    required String label,
    required String currencySymbol,
    bool isCrypto = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
              color: Colors.white, fontSize: adaptive.responsiveFontSize(18), fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF161B22),
            prefixText: isCrypto ? null : "$currencySymbol ",
            prefixStyle: TextStyle(
                color: Colors.white, fontSize: adaptive.responsiveFontSize(18), fontWeight: FontWeight.bold),
            suffixText: isCrypto ? " $currencySymbol" : null,
            suffixStyle: TextStyle(
                color: Colors.grey, fontSize: adaptive.responsiveFontSize(14), fontWeight: FontWeight.normal),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(AdaptiveUtils adaptive) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _executeTrade,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isBuyMode ? Colors.green : Colors.red,
          padding: EdgeInsets.symmetric(vertical: adaptive.heightPercent(2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          _isBuyMode ? "Confirm Buy" : "Confirm Sell",
          style: TextStyle(
            color: Colors.white,
            fontSize: adaptive.responsiveFontSize(16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHistoryList() {
    if (_transactionHistory.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Text("You have no transactions yet.", style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactionHistory.length,
      separatorBuilder: (_, __) => const Divider(color: Color(0xFF161B22)),
      itemBuilder: (context, index) {
        final tx = _transactionHistory[index];
        final isBuy = tx.transactionType == "Buy";
        final color = isBuy ? Colors.green : Colors.red;

        return Dismissible(
          key: Key(tx.date.toIso8601String() + tx.amountFiat.toString()),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            _deleteTransaction(index);
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              "${tx.transactionType} ${tx.coinSymbol}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              tx.date.toLocal().toString().substring(0, 16),
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${isBuy ? '+' : '-'} $_currencySymbol${tx.amountFiat.toStringAsFixed(2)}",
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${isBuy ? '+' : '-'} ${tx.amountCrypto.toStringAsFixed(6)} ${tx.coinSymbol}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
