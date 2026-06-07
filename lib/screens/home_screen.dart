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

import '../constants.dart';
import '../flashcard_deck.dart';
import '../flashcard_tile.dart';

import 'create_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<FlashcardDeck> decks = [];

  HomeScreen({super.key});

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return Constants.morningGreeting;
    }
    else if (hour >= 12 && hour < 18) {
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
                Text(
                  getGreeting(),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.activeBlue
                  )
                ),
                SizedBox(height: 50),
                Text(
                  Constants.mainSubtitle,
                  style: TextStyle(
                    fontSize: 23,
                    color: CupertinoColors.systemBackground
                  )
                ),
                SizedBox(height: 24),
                if (decks.isEmpty)
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
                  ...decks.map((deck) => FlashcardTile(deck: deck)),
                SizedBox(height: 80)
              ]
            )
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              backgroundColor: CupertinoColors.systemTeal,
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => CreateScreen()
                  )
                );
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
