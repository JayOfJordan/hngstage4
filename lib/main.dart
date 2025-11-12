import 'package:flutter/material.dart';
import 'package:hngstage4/favourites.dart';
import 'package:hngstage4/homepage.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => Favorites(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'RethinkSans',
      ),
      debugShowCheckedModeBanner: false,
      home: const CryptoHomePage(),
    );
  }
}
