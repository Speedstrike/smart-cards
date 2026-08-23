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

import 'dart:io';
import 'dart:math';

import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                    ]
                    : [
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
                        isBack
                            ? widget.flashcard.answer
                            : widget.flashcard.question,
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

  const ResultsScreen({super.key, required this.flashcards, required this.title, this.readOnly = false});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late PageController _pageController;
  late List<Flashcard> _flashcards;
  int _currentIndex = 0;
  bool _isSaving = false;
  bool _isSharing = false;
  bool _isReviewSaving = false;
  String? _reviewMessage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _flashcards = widget.flashcards.toList();
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
            'card_count': _flashcards.length
          })
          .select()
          .single();

      await client
          .from('flashcards')
          .insert(
            _flashcards
                .map(
                  (f) => {
                    'deck_id': deck['id'],
                    'user_id': userId,
                    'question': f.question,
                    'answer': f.answer,
                    'repetitions': 0,
                    'interval_days': 0,
                    'ease_factor': 2.5,
                    'due_at': DateTime.now().toUtc().toIso8601String()
                  }
                )
                .toList()
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

  bool _isDue(Flashcard card) {
    final dueAt = card.dueAt;
    if (dueAt == null) return true;
    return !dueAt.isAfter(DateTime.now());
  }

  int get _dueCount {
    return _flashcards.where(_isDue).length;
  }

  String _nextReviewLabel(Flashcard card) {
    final dueAt = card.dueAt;
    if (dueAt == null || _isDue(card)) return Constants.reviewDueTodayText;

    final difference = dueAt.difference(DateTime.now()).inDays + 1;
    if (difference <= 1) return 'Next review: tomorrow';
    return 'Next review: in $difference days';
  }

  Flashcard _scheduleReview(Flashcard card, int quality) {
    var repetitions = card.repetitions;
    var easeFactor = card.easeFactor;
    final intervalDays = switch (quality) {
      1 => 0,
      3 => 1,
      4 => 5,
      5 => 7,
      _ => 1
    };

    if (quality < 3) {
      repetitions = 0;
    }
    else {
      repetitions += 1;
      easeFactor += 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
      if (easeFactor < 1.3) easeFactor = 1.3;
    }

    final now = DateTime.now();
    return card.copyWith(
      repetitions: repetitions,
      intervalDays: intervalDays,
      easeFactor: easeFactor,
      dueAt: now.add(Duration(days: intervalDays)),
      lastReviewedAt: now
    );
  }

  Future<void> _markReview(int quality) async {
    final reviewIndex = _currentIndex;
    final card = _flashcards[reviewIndex];
    if (card.id == null) {
      setState(() => _reviewMessage = Constants.reviewUnsavedText);
      return;
    }

    final updated = _scheduleReview(card, quality);
    setState(() {
      _isReviewSaving = true;
      _reviewMessage = null;
      _flashcards[reviewIndex] = updated;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      var query = Supabase.instance.client
        .from('flashcards')
        .update({
          'repetitions': updated.repetitions,
          'interval_days': updated.intervalDays,
          'ease_factor': updated.easeFactor,
          'due_at': updated.dueAt?.toUtc().toIso8601String(),
          'last_reviewed_at': updated.lastReviewedAt?.toUtc().toIso8601String()
        }).eq('id', card.id);

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      await query;

      if (_currentIndex < _flashcards.length - 1) {
        await _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut
        );
      }

      if (mounted) setState(() => _reviewMessage = Constants.reviewSavedText);
    }
    catch (e) {
      if (mounted) {
        setState(() {
          _flashcards[reviewIndex] = card;
          _reviewMessage = '${Constants.reviewErrorText} ${e.toString().replaceFirst('Exception: ', '')}';
        });
      }
    }
    finally {
      if (mounted) setState(() => _isReviewSaving = false);
    }
  }

  Widget _reviewButton(String label, Color color, int quality) {
    return Expanded(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: color.withValues(alpha: 0.18),
        onPressed: _isReviewSaving ? null : () => _markReview(quality),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700
          )
        )
      )
    );
  }

  String _escapeCsvField(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _buildShareText() {
    final buffer = StringBuffer();
    buffer.writeln(widget.title);
    buffer.writeln('${_flashcards.length} cards');
    buffer.writeln();

    for (var i = 0; i < _flashcards.length; i++) {
      final card = _flashcards[i];
      buffer.writeln('${i + 1}. Q: ${card.question}');
      buffer.writeln('   A: ${card.answer}');
      if (i < _flashcards.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  String _buildCsv() {
    final buffer = StringBuffer();
    buffer.writeln('question,answer');

    for (final card in _flashcards) {
      buffer.writeln(
        '${_escapeCsvField(card.question)},${_escapeCsvField(card.answer)}'
      );
    }

    return buffer.toString();
  }

  Future<void> _shareDeck() async {
    setState(() => _isSharing = true);

    try {
      await SharePlus.instance.share(
        ShareParams(text: _buildShareText(), subject: widget.title)
      );
    }
    finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _exportDeckCsv() async {
    setState(() => _isSharing = true);

    try {
      final fileName = widget.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
      final safeFileName = fileName.isEmpty ? 'flashcards' : fileName;
      final exportPath = '${Directory.systemTemp.path}/$safeFileName-flashcards.csv';
      final exportFile = File(exportPath);

      await exportFile.writeAsString(_buildCsv(), flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(exportFile.path, mimeType: 'text/csv')],
          subject: widget.title,
          text: 'Exported flashcards from ${widget.title}'
        )
      );
    }
    finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _showExportOptions() async {
    if (_isSharing) return;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(widget.title),
        message: const Text(Constants.shareInstructions),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              await _shareDeck();
            },
            child: const Text(Constants.shareExportInstructions)
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              await _exportDeckCsv();
            },
            child: const Text(Constants.shareCSVInstructions)
          )
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Constants.shareCancel)
        )
      )
    );
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
                widget.readOnly ? '${_flashcards.length} cards - $_dueCount due' : '${_flashcards.length} cards',
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
                  itemCount: _flashcards.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: FlashcardView(
                        flashcard: _flashcards[index],
                        index: index,
                        total: _flashcards.length
                      )
                    );
                  }
                )
              ),
              const SizedBox(height: 16),
              if (widget.readOnly) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Constants.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Constants.border)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        Constants.reviewTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                        )
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        Constants.reviewSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 12
                        )
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _nextReviewLabel(_flashcards[_currentIndex]),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600
                        )
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _reviewButton(Constants.reviewAgainButtonText, CupertinoColors.systemRed, 1),
                          const SizedBox(width: 8),
                          _reviewButton(Constants.reviewHardButtonText, CupertinoColors.systemOrange, 3),
                          const SizedBox(width: 8),
                          _reviewButton(Constants.reviewGoodButtonText, CupertinoColors.activeBlue, 4),
                          const SizedBox(width: 8),
                          _reviewButton(Constants.reviewEasyButtonText, CupertinoColors.systemGreen, 5)
                        ]
                      ),
                      if (_reviewMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _reviewMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _reviewMessage!.startsWith(Constants.reviewErrorText) ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
                            fontSize: 12
                          )
                        )
                      ]
                    ]
                  )
                ),
                const SizedBox(height: 8)
              ],
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
                    child: const Text(Constants.previousCardButtonText)
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
                      '${_currentIndex + 1}/${_flashcards.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.activeBlue
                      )
                    )
                  ),
                  CupertinoButton(
                    onPressed: _currentIndex < _flashcards.length - 1? () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut
                      );
                    } : null,
                    child: const Text(Constants.nextCardButtonText)
                  )
                ]
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed: _isSharing ? null : _showExportOptions,
                child: _isSharing? const CupertinoActivityIndicator(radius: 12) : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(CupertinoIcons.square_arrow_up, size: 20),
                    SizedBox(width: 8),
                    Text(Constants.shareTite)
                  ]
                )
              ),
              if (!widget.readOnly) ...[
                const SizedBox(height: 12),
                CupertinoButton.filled(
                  onPressed: _isSaving ? null : _saveDeck,
                  child: _isSaving? const CupertinoActivityIndicator(
                    color: CupertinoColors.white
                  ) : const Text('Save Deck')
                )
              ]
            ]
          )
        )
      )
    );
  }
}