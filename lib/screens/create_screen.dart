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

import 'scan_screen.dart';
import 'upload_screen.dart';
import 'ai_screen.dart';

import '../constants.dart';
import '../flashcard_deck.dart';
import '../gradient_button.dart';

class CreateScreen extends StatelessWidget {
  final List<FlashcardDeck> decks = [];
  static final double buttonHeight = 128;

  CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGrey6,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: CupertinoColors.activeBlue,
            size: 40
          ),
          onPressed: () {
            Navigator.of(context).pop();
          }
        ),
        border: null
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Constants.createDeckTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.activeBlue
                    )
                  ),
                  SizedBox(height: 8),
                  Text(
                    Constants.createDeckSubtitle,
                    style: TextStyle(
                      fontSize: 20,
                      color: CupertinoColors.systemBackground
                    )
                  ),
                  SizedBox(height: 25)
                ]
              )
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  GradientButton(
                    icon: CupertinoIcons.camera,
                    title: Constants.scanTitle,
                    description: Constants.scanSubtitle,
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const ScanScreen()
                        )
                      );
                    }
                  ),
                  SizedBox(height: 20),
                  GradientButton(
                    icon: CupertinoIcons.doc,
                    title: Constants.uploadTitle,
                    description: Constants.uploadSubtitle,
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const UploadScreen()
                        )
                      );
                    }
                  ),
                  SizedBox(height: 20),
                  GradientButton(
                    icon: CupertinoIcons.lightbulb,
                    title: Constants.aiTitle,
                    description: Constants.aiSubtitle,
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const AIScreen()
                        )
                      );
                    }
                  )
                ]
              )
            )
          ]
        )
      )
    );
  }
}