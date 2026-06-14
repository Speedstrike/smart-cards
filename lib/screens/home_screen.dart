// MIT License
//
// Copyright (c) 2026 Aaryan Karlapalem
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'create_screen.dart';
import 'results_screen.dart';
import 'account_screen.dart';

import '../constants.dart';
import '../flashcard_deck.dart';
import '../flashcard_tile.dart';
import '../services/openrouter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  List<FlashcardDeck> _decks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDecks();
  }

  Future<void> _fetchDecks() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
        .from('decks')
        .select()
        .order('created_at', ascending: false);
      setState(() => _decks = (data as List).map((e) => FlashcardDeck.fromMap(e)).toList());
    }
    catch (_) {
      setState(() => _decks = []);
    }
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openDeck(FlashcardDeck deck) async {
    final data = await _supabase
      .from('flashcards')
      .select()
      .eq('deck_id', deck.id)
      .order('id');

    final cards = (data as List).map((e) => Flashcard(
      question: e['question'] as String,
      answer: e['answer'] as String
    )).toList();

    if (!mounted) return;

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ResultsScreen(
          flashcards: cards,
          title: deck.title,
          readOnly: true
        )
      )
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return Constants.morningGreeting;
    }
    else if (hour >= 11 && hour < 17) {
      return Constants.afternoonGreeting;
    }
    else if (hour >= 17 && hour < 21) {
      return Constants.eveningGreeting;
    }
    else {
      return Constants.nightGreeting;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      child: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        getGreeting(),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.activeBlue
                        )
                      )
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        await Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const AccountScreen()
                          )
                        );
                        _fetchDecks();
                      },
                      child: const Icon(
                        CupertinoIcons.person_circle,
                        color: CupertinoColors.systemGrey,
                        size: 28
                      )
                    )
                  ]
                ),
                SizedBox(height: 50),
                Text(
                  Constants.mainSubtitle,
                  style: TextStyle(
                    fontSize: 23,
                    color: CupertinoColors.systemBackground
                  )
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 100),
                    child: Center(child: CupertinoActivityIndicator(radius: 16))
                  )
                else if (_decks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 100),
                      child: Text(
                        Constants.noRecentDecks,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: CupertinoColors.systemGrey2
                        )
                      )
                    )
                  )
                else
                  ..._decks.map((deck) => FlashcardTile(
                    deck: deck,
                    onTap: () => _openDeck(deck)
                  )),
                SizedBox(height: 80)
              ]
            )
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              backgroundColor: CupertinoColors.systemTeal,
              onPressed: () async {
                await Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => CreateScreen()
                  )
                );
                _fetchDecks();
              },
              child: Icon(
                CupertinoIcons.add,
                color: CupertinoColors.lightBackgroundGray
              )
            )
          )
        ]
      )
    );
  }
}