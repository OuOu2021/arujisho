import 'package:arujisho/ffi.io.dart';
import 'package:arujisho/main.dart';
import 'package:arujisho/ruby_text/ruby_text.dart';
import 'package:arujisho/ruby_text/ruby_text_data.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// List里的一项
class DictionaryTerm extends StatefulWidget {
  final String dictName;
  final String imi;
  final Function(String)? queryWord;
  final bool initialExpanded;

  const DictionaryTerm({
    super.key,
    required this.dictName,
    required this.imi,
    this.queryWord,
    this.initialExpanded = false,
  });

  @override
  DictionaryTermState createState() => DictionaryTermState();
}

class DictionaryTermState extends State<DictionaryTerm> {
  late final ExpandableController _expandControl;
  List<List<Map<String, String>>>? tokens;
  bool showFurigana = false;
  static const _kanaKit = KanaKit();

  @override
  void initState() {
    super.initState();
    _expandControl =
        ExpandableController(initialExpanded: widget.initialExpanded);
  }

  @override
  void dispose() {
    _expandControl.dispose();
    super.dispose();
  }

  Future<void> _doMorphAnalyze() async {
    final sp = path.join(
        (await getApplicationSupportDirectory()).path, "sudachi.json");
    final t = <List<Map<String, String>>>[];
    for (final row in widget.imi.split('\n')) {
      if (row.isNotEmpty) {
        final tt = <Map<String, String>>[];
        if (!_kanaKit.isRomaji(row)) {
          final lls = await sudachiAPI.parse(data: row, configPath: sp);
          for (final token in lls) {
            tt.add({
              "begin": token[0],
              "end": token[1],
              "POS": token[2],
              "surface": token[3],
              "norm": token[4],
              "reading": _kanaKit.toHiragana(token[5])
            });
          }
        } else {
          tt.add({
            "begin": '0',
            "end": (row.length - 1).toString(),
            "POS": "",
            "surface": row,
            "norm": ""
          });
        }
        t.add(tt);
      }
    }
    setState(() => tokens = t);
  }

  void _switchFurigana() {
    if (tokens == null) {
      _doMorphAnalyze();
    }
    setState(() => showFurigana = !showFurigana);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 10),
      child: ExpandablePanel(
        theme: const ExpandableThemeData(
          iconPadding: EdgeInsets.zero,
          // iconSize: Theme.of(context).textTheme.titleLarge?.fontSize,
          expandIcon: Icons.arrow_drop_down,
          collapseIcon: Icons.arrow_drop_up,
          // iconColor: Theme.of(context).unselectedWidgetColor,
          headerAlignment: ExpandablePanelHeaderAlignment.center,
        ),
        controller: _expandControl,
        header: Wrap(children: [
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: InkWell(
              onTap: _switchFurigana,
              child: Container(
                decoration: BoxDecoration(
                  color: (MyApp.isRelease ^ (showFurigana && tokens == null))
                      ? Colors.red[600]
                      : Colors.blue[400],
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                  child: Text(
                    widget.dictName,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ]),
        collapsed: const SizedBox.shrink(),
        expanded: Padding(
          padding: const EdgeInsets.only(top: 2, left: 10, bottom: 4),
          child: showFurigana && tokens != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tokens!
                      .map<RubyText>((sentence) => RubyText(
                            style: const TextStyle(fontSize: 13.5),
                            sentence.map<RubyTextData>((token) {
                              if (token['POS']!.contains('記号') ||
                                  token['POS']!.contains('空白') ||
                                  _kanaKit.isRomaji(token['surface']!)) {
                                return RubyTextData(token['surface']!);
                              } else if (_kanaKit.isKana(token['surface']!)) {
                                return RubyTextData(token['surface']!,
                                    onTap: () {
                                  if (widget.queryWord != null) {
                                    widget.queryWord!(token['norm']!);
                                  }
                                });
                              }
                              return RubyTextData(token['surface']!,
                                  ruby: token['reading'], onTap: () {
                                if (widget.queryWord != null) {
                                  widget.queryWord!(token['norm']!);
                                }
                              });
                            }).toList(),
                          ))
                      .toList(),
                )
              : SelectableText(
                  widget.imi,
                  style: const TextStyle(fontSize: 12),

                  // toolbarOptions:
                  //     const ToolbarOptions(copy: true, selectAll: false),
                  // contextMenuBuilder:(context, editableTextState) {
                  //   return
                  // },
                ),
        ),
      ),
    );
  }
}
