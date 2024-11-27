import 'dart:convert';
import 'dart:math';

import 'package:arujisho/pages/word_detail_page.dart';
import 'package:arujisho/providers/item_count_notifier.dart';
import 'package:arujisho/widgets/dictionary_term.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:provider/provider.dart';

part 'word.g.dart';

@JsonSerializable()
class Word {
  final String word;
  final String pitchData;
  final String origForm;
  final String orig;
  final int freqRank;
  final String romaji;

  /// 読み方
  final String yomikata;

  /// index
  final int idex;

  /// 意味
  @JsonKey(
    toJson: _toJson,
    fromJson: _fromJson,
  )
  final Map<String, dynamic> imi;

  Word({
    required this.romaji,
    required this.word,
    required this.pitchData,
    required this.origForm,
    required this.orig,
    required this.freqRank,
    required this.yomikata,
    required this.idex,
    required this.imi,
  });

  static String _toJson(Map<String, dynamic> value) => jsonEncode(value);
  static Map<String, dynamic> _fromJson(String value) => jsonDecode(value);

  /// Connect the generated [_$WordFromJson] function to the `fromJson`
  /// factory.
  factory Word.fromJson(Map<String, dynamic> json) => _$WordFromJson(json);

  /// Connect the generated [_$WordToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$WordToJson(this);

  int balancedWeight(
      int bLen, String searchField, String searchQuery, int minRank) {
    return (freqRank *
            (searchField.startsWith(searchQuery) && minRank == 0 ? 100 : 500) *
            pow(1.5 + yomikata.length / bLen, minRank == 0 ? 2.5 : 0.0))
        .round();
  }

  void showDetailedWordInModalBottomSheet(
    BuildContext context,
    Word word,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => WordDetailPage(
        wordTitle:
            word.word == word.orig ? word.word : '${word.word} →〔${word.orig}〕',
        originWord: word.word,
        idex: word.idex,
        yomikata: word.yomikata,
        freqRank: word.freqRank,
        details: List.from(word.imi.keys.take(
                Provider.of<ItemCountNotifier>(context, listen: false)
                    .displayItemCount))
            .asMap()
            .entries
            .map<List<Widget>>((s) {
          final index1 = s.key;
          final dictName = s.value;
          return List<List<Widget>>.from(
            word.imi[dictName].asMap().entries.map((entry) {
              // final index2 = entry.key;
              final simi = entry.value;
              return <Widget>[
                DictionaryTerm(
                  dictName: dictName,
                  imi: simi,
                  // queryWord: _setSearchContent,
                  initialExpanded: index1 <
                      Provider.of<ItemCountNotifier>(context, listen: false)
                          .expandedItemCount,
                )
              ];
            }),
          ).reduce((a, b) => a + b);
        }).reduce((a, b) => a + b),
      ),
    );
  }
}
