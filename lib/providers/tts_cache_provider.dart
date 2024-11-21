import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:kana_kit/kana_kit.dart';

const burpHeader = {
  "Sec-Ch-Ua":
      "\"Chromium\";v=\"104\", \" Not A;Brand\";v=\"99\", \"Google Chrome\";v=\"104\"",
  "Dnt": "1",
  "Sec-Ch-Ua-Mobile": "?0",
  "User-Agent":
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36",
  "Sec-Ch-Ua-Platform": "\"Windows\"",
  "Content-Type": "application/x-www-form-urlencoded",
  "Accept": "*/*",
  "Sec-Fetch-Site": "none",
  "Sec-Fetch-Mode": "cors",
  "Sec-Fetch-Dest": "empty",
  "Accept-Encoding": "gzip, deflate",
  "Accept-Language": "en-US,en;q=0.9,zh-TW;q=0.8,zh-CN;q=0.7,zh;q=0.6,ja;q=0.5",
  "Connection": "close"
};

class TtsCacheProvider {
  static const KanaKit _kanaKit = KanaKit();
  final Map<int, String?> _cache = {};

  Future<String?> hatsuon(
      {required String word,
      required int idex,
      required String yomikata}) async {
    if (_cache.containsKey(idex)) {
      return _cache[idex];
    }
    String? url;

    try {
      var resp = await http.post(
        Uri.parse(
            'https://www.japanesepod101.com/learningcenter/reference/dictionary_post'),
        headers: burpHeader,
        body: {
          "post": "dictionary_reference",
          "match_type": "exact",
          "search_query": word,
          "vulgar": "true"
        },
      );
      var dom = parse(resp.body);
      for (var row in dom.getElementsByClassName('dc-result-row')) {
        try {
          var audio = row.getElementsByTagName('audio')[0];
          var kana = row.getElementsByClassName('dc-vocab_kana')[0].text;
          if (_kanaKit.toKatakana(yomikata) == _kanaKit.toKatakana(kana) ||
              _kanaKit.toHiragana(kana) == yomikata) {
            url =
                "https://assets.languagepod101.com/dictionary/japanese/audiomp3.php?kanji=${word}&kana=$kana";
            // setState(() => hatsuonLoading = true);
            try {
              var file = await DefaultCacheManager()
                  .getSingleFile(url, headers: burpHeader);
              var hash = await sha256.bind(file.openRead()).first;
              if (hash.toString() ==
                  'ae6398b5a27bc8c0a771df6c907ade794be15518174773c58c7c7ddd17098906') {
                throw const FormatException("NOT IMPLEMENTED");
              }
            } catch (_) {
              url = audio.getElementsByTagName('source')[0].attributes['src'];
            }
            break;
          }
        } catch (_) {
          return null;
        }
      }
    } catch (_) {
      return null;
    }
    // setState(() => hatsuonLoading = false);
    if (url != null) {
      _cache[idex] = url;
      return url;
    }
    try {
      var resp = await http.get(Uri.parse("https://forvo.com/word/${word}/#ja"),
          headers: burpHeader);
      var dom = parse(resp.body);
      var ja = dom.getElementById('language-container-ja');
      var pronunciation = ja!.getElementsByClassName('pronunciations-list')[0];
      String play = pronunciation
          .getElementsByClassName('play')[0]
          .attributes['onclick']!;
      RegExp exp = RegExp(r"Play\(\d+,'.+','.+',\w+,'([^']+)");
      String? match = exp.firstMatch(play)?.group(1);
      if (match != null && match.isNotEmpty) {
        match = utf8.decode(base64.decode(match));
        url = 'https://audio00.forvo.com/audios/mp3/$match';
      } else {
        exp = RegExp(r"Play\(\d+,'[^']+','([^']+)");
        match = exp.firstMatch(play)?.group(1);
        if (match != null) {
          match = utf8.decode(base64.decode(match));
          url = 'https://audio00.forvo.com/ogg/$match';
        }
      }
    } catch (_) {
      return null;
    }
    if (url != null) {
      _cache[idex] = url;
      return url;
    }

    if (url != null && url.isNotEmpty) {
      // setState(() => hatsuonLoading = true);
      try {
        return url;
      } catch (_) {
        url = null;
      }
    }
    _cache[idex] = url;
    return url;
    // setState(() {
    //   _cache[idex] = url;
    //   hatsuonLoading = false;
    // });
  }
}
