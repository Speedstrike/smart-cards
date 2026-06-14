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

import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:math';

import '../constants.dart';
import '../services/openrouter.dart';

class FlashcardView extends StatefulWidget {
  final Flashcard flashcard;
  final int index;
  final int total;

  const FlashcardView({
    super.key,
    required this.flashcard,
    required this.index,
    required this.total
  });

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFlipped) {
      _controller.reverse();
    }
    else {
      _controller.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isBack = _animation.value > 0.5;
          final angle = _animation.value * pi;
          final transform = Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle);

          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: Transform(
              alignment: Alignment.center,
              transform: isBack? (Matrix4.identity()..rotateY(pi)) : Matrix4.identity(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isBack? [
                      CupertinoColors.systemOrange, 
                      CupertinoColors.systemPink
                    ] : [
                      CupertinoColors.activeBlue,
                      CupertinoColors.systemPurple
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4)
                    )
                  ]
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isBack ? 'Answer' : 'Question',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.white,
                        letterSpacing: 1
                      )
                    ),
                    Center(
                      child: Text(
                        isBack? widget.flashcard.answer : widget.flashcard.question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.white,
                          height: 1.5
                        )
                      )
                    ),
                    Text(
                      '${widget.index + 1}/${widget.total}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.white
                      )
                    )
                  ]
                )
              )
            )
          );
        }
      )
    );
  }
}

class ResultsScreen extends StatefulWidget {
  final List<Flashcard> flashcards;
  final String title;
  final bool readOnly;

  const ResultsScreen({
    super.key,
    required this.flashcards,
    required this.title,
    this.readOnly = false
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveDeck() async {
    setState(() => _isSaving = true);
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Failed to Save'),
          content: const Text(Constants.saveErrorExplanationText),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')
            )
          ]
        )
      );
      setState(() => _isSaving = false);
      return;
    }
    try {
      final deck = await client
        .from('decks')
        .insert({
          'user_id': userId,
          'title': widget.title,
          'card_count': widget.flashcards.length
        }).select().single();

      await client
        .from('flashcards')
        .insert(
          widget.flashcards.map((f) => {
            'deck_id': deck['id'],
            'user_id': userId,
            'question': f.question,
            'answer': f.answer
          }).toList(),
        );

      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
    on AuthException catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Failed to Save'),
          content: Text(e.message),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')
            )
          ]
        )
      );
    }
    catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Failed to Save'),
          content: Text(e.toString()),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')
            )
          ]
        )
      );
    }
    finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGrey6,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.activeBlue
                )
              ),
              Text(
                '${widget.flashcards.length} cards',
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey
                )
              ),
              const SizedBox(height: 24),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemCount: widget.flashcards.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: FlashcardView(
                        flashcard: widget.flashcards[index],
                        index: index,
                        total: widget.flashcards.length
                      )
                    );
                  }
                )
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: _currentIndex > 0? () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut
                      );
                    } : null,
                    child: const Text('Previous')
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${widget.flashcards.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.activeBlue
                      )
                    )
                  ),
                  CupertinoButton(
                    onPressed: _currentIndex < widget.flashcards.length - 1? () {
                       _pageController.nextPage(
                         duration: const Duration(milliseconds: 300),
                         curve: Curves.easeInOut
                       );
                    } : null,
                    child: const Text('Next')
                  )
                ]
              ),
              if (!widget.readOnly) ...[
                const SizedBox(height: 12),
                CupertinoButton.filled(
                  onPressed: _isSaving ? null : _saveDeck,
                  child: _isSaving? const CupertinoActivityIndicator(color: CupertinoColors.white) : const Text('Save Deck')
                )
              ]
            ]
          )
        )
      )
    );
  }
}