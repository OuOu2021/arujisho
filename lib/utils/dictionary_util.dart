import 'package:arujisho/cjconvert.dart';
import 'package:arujisho/models/word.dart';
import 'package:sqflite/sqflite.dart';

class DictionaryUtil {
  static Future<List<Word>> getWords(Database db, String query, int nextIndex,
      int pageSize, int minRank) async {
    if (nextIndex % pageSize != 0) return [];
    final searchData = handleQuery(query);

    String searchField = 'word';
    String method = "MATCH";
    List<Word> result = [];
    final searchQuery = searchData.toLowerCase();

    if (RegExp(r'^[a-z]+$').hasMatch(searchQuery)) {
      searchField = 'romaji';
    } else if (RegExp(r'^[ぁ-ゖー]+$').hasMatch(searchQuery)) {
      searchField = 'yomikata';
    } else if (RegExp(r'[\.\+\[\]\*\^\$\?]').hasMatch(searchQuery)) {
      method = 'REGEXP';
    } else if (RegExp(r'[_%]').hasMatch(searchQuery)) {
      method = 'LIKE';
    }

    result = switch (method) {
      "MATCH" => (await db.rawQuery(
          'SELECT tt.word,tt.yomikata,tt.pitchData,'
          'tt.origForm,tt.freqRank,tt.idex,tt.romaji,imis.imi,imis.orig '
          'FROM (imis JOIN (SELECT * FROM jpdc '
          'WHERE ($searchField MATCH "$searchQuery*" OR r$searchField '
          'MATCH "${String.fromCharCodes(searchQuery.runes.toList().reversed)}*") '
          '${(minRank > 0 ? "AND _rowid_ >=$minRank" : "")} '
          'ORDER BY _rowid_ LIMIT $nextIndex, $pageSize'
          ') AS tt ON tt.idex=imis._rowid_)',
        ))
            .map((x) => Word.fromJson(x))
            .toList(),
      "LIKE" || "REGEXP" => (await db.rawQuery(
          'SELECT tt.word,tt.yomikata,tt.pitchData,'
          'tt.origForm,tt.freqRank,tt.idex,tt.romaji,imis.imi,imis.orig '
          'FROM (imis JOIN (SELECT * FROM jpdc '
          'WHERE (word $method "$searchQuery" '
          'OR yomikata $method "$searchQuery" '
          'OR romaji $method "$searchQuery") '
          '${(minRank > 0 ? "AND _rowid_ >=$minRank" : "")} '
          'ORDER BY _rowid_ LIMIT $nextIndex,$pageSize'
          ') AS tt ON tt.idex=imis._rowid_)',
        ))
            .map((x) => Word.fromJson(x))
            .toList(),
      _ => throw UnimplementedError(),
    };

    int bLen = 1 << 31;
    for (var w in result) {
      if (w.yomikata.length < bLen) {
        bLen = w.yomikata.length;
      }
    }
    result.sort((a, b) => a
        .balancedWeight(bLen, searchField, searchQuery, minRank)
        .compareTo(b.balancedWeight(bLen, searchField, searchQuery, minRank)));
    return result;
  }

  static String handleQuery(String q) {
    return q
        .replaceAll("\\pc", "\\p{Han}")
        .replaceAll("\\ph", "\\p{Hiragana}")
        .replaceAll("\\pk", "\\p{Katakana}")
        .split('')
        .map<String>((c) => cjdc.containsKey(c) ? cjdc[c]! : c)
        .join();
  }
}
