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

import 'account_screen.dart';
import 'create_screen.dart';
import 'edit_screen.dart';
import 'results_screen.dart';

import '../constants.dart';
import '../flashcard_deck.dart';
import '../flashcard_tile.dart';
import '../services/openrouter.dart';

enum DeckFilter {
  all, small, medium, large
}

enum DeckSort {
  newest, oldest, titleAZ, cardsHighToLow, cardsLowToHigh
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  List<FlashcardDeck> _decks = [];
  bool _isLoading = true;
  bool _showControls = false;
  DeckFilter _selectedFilter = DeckFilter.all;
  DeckSort _selectedSort = DeckSort.newest;

  @override
  void initState() {
    super.initState();
    _fetchDecks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDecks() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase.from('decks').select().order('created_at', ascending: false);
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
    final data = await _supabase.from('flashcards').select().eq('deck_id', deck.id).order('id');

    final cards = (data as List).map((e) => Flashcard(
      question: e['question'] as String,
      answer: e['answer'] as String
    )).toList();

    if (!mounted) return;

    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => ResultsScreen(flashcards: cards, title: deck.title, readOnly: true)));
  }

  Future<void> _editDeck(FlashcardDeck deck) async {
    final changed = await Navigator.of(context).push(CupertinoPageRoute(builder: (context) => EditScreen(deck: deck)));

    if (changed == true) _fetchDecks();
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

  List<FlashcardDeck> get _visibleDecks {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _decks.where((deck) {
      final matchesSearch = query.isEmpty || deck.title.toLowerCase().contains(query);
      final matchesFilter = switch (_selectedFilter) {
        DeckFilter.all => true,
        DeckFilter.small => deck.cardCount <= 9,
        DeckFilter.medium => deck.cardCount >= 10 && deck.cardCount <= 24,
        DeckFilter.large => deck.cardCount >= 25
      };
      return matchesSearch && matchesFilter;
    }).toList();

    filtered.sort((a, b) {
      final unknownDate = DateTime.fromMillisecondsSinceEpoch(0);
      switch (_selectedSort) {
        case DeckSort.newest:
          return (b.createdAt ?? unknownDate).compareTo(
            a.createdAt ?? unknownDate
          );
        case DeckSort.oldest:
          return (a.createdAt ?? unknownDate).compareTo(
            b.createdAt ?? unknownDate
          );
        case DeckSort.titleAZ:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case DeckSort.cardsHighToLow:
          final countCompare = b.cardCount.compareTo(a.cardCount);
          return countCompare != 0? countCompare : a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case DeckSort.cardsLowToHigh:
          final countCompare = a.cardCount.compareTo(b.cardCount);
          return countCompare != 0? countCompare : a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return filtered;
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedFilter = DeckFilter.all;
      _selectedSort = DeckSort.newest;
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.systemGrey
      )
    );
  }

  Widget _searchField() {
    return CupertinoTextField(
      controller: _searchController,
      placeholder: Constants.deckSearchPlaceholder,
      placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey2),
      style: const TextStyle(color: CupertinoColors.white),
      prefix: const Padding(
        padding: EdgeInsets.only(left: 12),
        child: Icon(
          CupertinoIcons.search,
          color: CupertinoColors.systemGrey2,
          size: 18
        )
      ),
      suffix: _searchController.text.isNotEmpty? CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: _resetFilters,
        child: const Icon(
          CupertinoIcons.xmark_circle_fill,
          color: CupertinoColors.systemGrey2,
          size: 18
        )
      ) : null,
      onChanged: (_) => setState(() {}),
      decoration: BoxDecoration(
        color: CupertinoColors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14)
      )
    );
  }

  Widget _controlCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20)
      ),
      child: child
    );
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
                        style: const TextStyle(
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
                const SizedBox(height: 50),
                Text(
                  Constants.mainSubtitle,
                  style: const TextStyle(
                    fontSize: 23,
                    color: CupertinoColors.systemBackground
                  )
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _toggleControls,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showControls? CupertinoIcons.chevron_up : CupertinoIcons.slider_horizontal_3,
                          size: 18,
                          color: CupertinoColors.activeBlue
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showControls? 'Hide search, filters, and sort' : 'Show search, filters, and sort'
                        )
                      ]
                    )
                  )
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _controlCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _searchField(),
                          const SizedBox(height: 16),
                          _sectionLabel(Constants.deckFilterLabel),
                          const SizedBox(height: 10),
                          CupertinoSlidingSegmentedControl<DeckFilter>(
                            groupValue: _selectedFilter,
                            children: const {
                              DeckFilter.all: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Text(Constants.deckAllFilter, style: TextStyle(fontSize: 13))
                              ),
                              DeckFilter.small: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Text(Constants.deckSmallFilter, style: TextStyle(fontSize: 13))
                              ),
                              DeckFilter.medium: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Text(Constants.deckMediumFilter, style: TextStyle(fontSize: 13))
                              ),
                              DeckFilter.large: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Text(Constants.deckLargeFilter, style: TextStyle(fontSize: 13))
                              )
                            },
                            onValueChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedFilter = value);
                              }
                            }
                          ),
                          const SizedBox(height: 16),
                          _sectionLabel(Constants.deckSortLabel),
                          const SizedBox(height: 10),
                          CupertinoSlidingSegmentedControl<DeckSort>(
                            groupValue: _selectedSort,
                            children: const {
                              DeckSort.newest: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Text(Constants.deckNewestSort, style: TextStyle(fontSize: 13))
                              ),
                              DeckSort.oldest: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Text(Constants.deckOldestSort, style: TextStyle(fontSize: 13))
                              ),
                              DeckSort.titleAZ: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Text(Constants.deckAZSort, style: TextStyle(fontSize: 13))
                              ),
                              DeckSort.cardsHighToLow: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Text(Constants.deckCardsHighSort, style: TextStyle(fontSize: 13))
                              ),
                              DeckSort.cardsLowToHigh: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Text(Constants.deckCardsLowSort, style: TextStyle(fontSize: 13))
                              )
                            },
                            onValueChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedSort = value);
                              }
                            }
                          ),
                          const SizedBox(height: 14),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _resetFilters,
                            child: const Text(Constants.deckResetFilters)
                          )
                        ]
                      )
                    )
                  ),
                  crossFadeState: _showControls? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 180),
                  sizeCurve: Curves.easeOut
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 100),
                    child: Center(
                      child: CupertinoActivityIndicator(radius: 16)
                    )
                  )
                else if (_decks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 100),
                      child: Text(
                        Constants.noRecentDecks,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: CupertinoColors.systemGrey2
                        )
                      )
                    )
                  )
                else if (_visibleDecks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 100),
                      child: Column(
                        children: [
                          Text(
                            Constants.noMatchingDecks,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: CupertinoColors.systemGrey2
                            )
                          ),
                          const SizedBox(height: 12),
                          CupertinoButton(
                            onPressed: _resetFilters,
                            child: const Text(Constants.deckResetFilters)
                          )
                        ]
                      )
                    )
                  )
                else
                  ..._visibleDecks.map(
                    (deck) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: FlashcardTile(
                              deck: deck,
                              onTap: () => _openDeck(deck)
                            )
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            onPressed: () => _editDeck(deck),
                            child: const Icon(
                              CupertinoIcons.pencil_circle,
                              color: CupertinoColors.activeBlue,
                              size: 30
                            )
                          )
                        ]
                      )
                    )
                  ),
                const SizedBox(height: 80)
              ]
            )
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              backgroundColor: CupertinoColors.systemTeal,
              onPressed: () async {
                await Navigator.of(context).push(CupertinoPageRoute(builder: (context) => CreateScreen()));
                _fetchDecks();
              },
              child: const Icon(
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