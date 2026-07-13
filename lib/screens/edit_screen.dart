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

import '../constants.dart';
import '../flashcard_deck.dart';

class _EditableCard {
  final dynamic id;
  final TextEditingController questionController;
  final TextEditingController answerController;

  _EditableCard({
    this.id,
    String question = '',
    String answer = ''
  }) :
    questionController = TextEditingController(text: question),
    answerController = TextEditingController(text: answer);

  void dispose() {
    questionController.dispose();
    answerController.dispose();
  }
}

class EditScreen extends StatefulWidget {
  final FlashcardDeck deck;

  const EditScreen({super.key, required this.deck});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _supabase = Supabase.instance.client;
  late final TextEditingController _titleController;
  final List<_EditableCard> _cards = [];
  final List<dynamic> _deletedCardIds = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.deck.title);
    _fetchCards();
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final card in _cards) {
      card.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchCards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _supabase
        .from('flashcards')
        .select()
        .eq('deck_id', widget.deck.id)
        .order('id');

      setState(() {
        _cards.clear();
        _cards.addAll((data as List).map((e) => _EditableCard(
          id: e['id'],
          question: e['question'] as String,
          answer: e['answer'] as String
        )));
      });
    }
    catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addCard() {
    setState(() {
      _cards.add(_EditableCard());
    });
  }

  void _removeCard(int index) {
    setState(() {
      final card = _cards.removeAt(index);
      if (card.id != null) {
        _deletedCardIds.add(card.id!);
      }
      card.dispose();
    });
  }

  Future<void> _saveChanges() async {
    final title = _titleController.text.trim();
    final remainingCards = _cards.where((c) =>
      c.questionController.text.trim().isNotEmpty &&
      c.answerController.text.trim().isNotEmpty
    ).toList();

    if (title.isEmpty || remainingCards.isEmpty) {
      setState(() {
        _errorMessage = Constants.editEmptyFieldsError;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;

      await _supabase
        .from('decks')
        .update({
          'title': title,
          'card_count': remainingCards.length
        })
        .eq('id', widget.deck.id);

      if (_deletedCardIds.isNotEmpty) {
        await _supabase
          .from('flashcards')
          .delete()
          .inFilter('id', _deletedCardIds);
      }

      for (final card in remainingCards) {
        if (card.id == null) {
          await _supabase.from('flashcards').insert({
            'deck_id': widget.deck.id,
            'user_id': userId,
            'question': card.questionController.text.trim(),
            'answer': card.answerController.text.trim()
          });
        }
        else {
          await _supabase
            .from('flashcards')
            .update({
              'question': card.questionController.text.trim(),
              'answer': card.answerController.text.trim()
            })
            .eq('id', card.id);
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    }
    catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
    finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmDeleteDeck() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text(Constants.editDeleteDeckDialogTitle),
        content: const Text(Constants.editDeleteDeckDialogContent),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteDeck();
            },
            child: const Text(Constants.accountDeleteButtonText)
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Constants.accountCancelButtonText)
          )
        ]
      )
    );
  }

  Future<void> _deleteDeck() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await _supabase
        .from('decks')
        .delete()
        .eq('id', widget.deck.id);

      if (mounted) Navigator.of(context).pop(true);
    }
    catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
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
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving? null : _confirmDeleteDeck,
          child: const Icon(
            CupertinoIcons.delete,
            color: CupertinoColors.destructiveRed,
            size: 26
          )
        ),
        border: null
      ),
      child: SafeArea(
        child: _isLoading? const Center(child: CupertinoActivityIndicator(radius: 16)) : Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                Constants.editDeckTitle,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.activeBlue
                )
              ),
              const SizedBox(height: 8),
              Text(
                Constants.editDeckSubtitle,
                style: const TextStyle(
                  fontSize: 20,
                  color: CupertinoColors.systemBackground
                )
              ),
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: _titleController,
                placeholder: Constants.editTitlePlaceholder,
                placeholderStyle: const TextStyle(
                  color: CupertinoColors.inactiveGray
                ),
                style: const TextStyle(color: CupertinoColors.white),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Constants.inputBackground,
                  borderRadius: BorderRadius.circular(8)
                )
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CupertinoColors.systemRed)
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 14
                    )
                  )
                ),
                const SizedBox(height: 16)
              ],
              Expanded(
                child: ListView.separated(
                  itemCount: _cards.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Constants.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Constants.border)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Card ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.systemGrey
                                )
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0.0, 0.0),
                                onPressed: () => _removeCard(index),
                                child: const Icon(
                                  CupertinoIcons.minus_circle,
                                  color: CupertinoColors.systemRed,
                                  size: 22
                                )
                              )
                            ]
                          ),
                          const SizedBox(height: 8),
                          CupertinoTextField(
                            controller: card.questionController,
                            placeholder: 'Question',
                            placeholderStyle: const TextStyle(
                              color: CupertinoColors.inactiveGray
                            ),
                            style: const TextStyle(color: CupertinoColors.white),
                            padding: const EdgeInsets.all(10),
                            maxLines: null,
                            decoration: BoxDecoration(
                              color: Constants.cardSubBackground,
                              borderRadius: BorderRadius.circular(8)
                            )
                          ),
                          const SizedBox(height: 8),
                          CupertinoTextField(
                            controller: card.answerController,
                            placeholder: 'Answer',
                            placeholderStyle: const TextStyle(
                              color: CupertinoColors.inactiveGray
                            ),
                            style: const TextStyle(color: CupertinoColors.white),
                            padding: const EdgeInsets.all(10),
                            maxLines: null,
                            decoration: BoxDecoration(
                              color: Constants.cardSubBackground,
                              borderRadius: BorderRadius.circular(8)
                            )
                          )
                        ]
                      )
                    );
                  }
                )
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: _addCard,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.add_circled,
                      color: CupertinoColors.activeBlue
                    ),
                    SizedBox(width: 6),
                    Text(Constants.editAddCardButtonText)
                  ]
                )
              ),
              const SizedBox(height: 8),
              CupertinoButton.filled(
                onPressed: _isSaving? null : _saveChanges,
                child: _isSaving? const CupertinoActivityIndicator(color: CupertinoColors.white) : const Text(Constants.editSaveButtonText)
              )
            ]
          )
        )
      )
    );
  }
}