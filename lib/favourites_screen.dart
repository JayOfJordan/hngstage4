import 'package:flutter/material.dart';
import 'package:hngstage4/adaptive_utils.dart';
import 'package:hngstage4/favourites.dart';
import 'package:hngstage4/homepage.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  final VoidCallback onAddFavoritesTapped;

  const FavoritesScreen({super.key, required this.onAddFavoritesTapped});

  @override
  Widget build(BuildContext context) {
    final adaptive = AdaptiveUtils(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: Text(
          'Favorites',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: adaptive.responsiveFontSize(22),
          ),
        ),
      ),
      body: Consumer<Favorites>(
        builder: (context, favoritesProvider, child) {
          final favoriteCoins = favoritesProvider.favoriteCoins;

          if (favoriteCoins.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/nosaved.png',
                      width: adaptive.widthPercent(50),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nothing Saved',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: adaptive.responsiveFontSize(20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Let's add some coin for close monitoring.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: adaptive.responsiveFontSize(14),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: onAddFavoritesTapped,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        'Add Favorites',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: adaptive.responsiveFontSize(16),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E64FF),
                        padding: EdgeInsets.symmetric(
                          horizontal: adaptive.widthPercent(8),
                          vertical: adaptive.heightPercent(1.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.all(adaptive.widthPercent(4)),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: adaptive.widthPercent(4),
              mainAxisSpacing: adaptive.heightPercent(2),
              childAspectRatio: 0.8,
            ),
            itemCount: favoriteCoins.length,
            itemBuilder: (context, index) {
              final coin = favoriteCoins[index];
              return FeaturedCoinCard(
                coin: coin,
                conversionRate: 1500.0,
                currencySymbol: '₦',
              );
            },
          );
        },
      ),
    );
  }
}
