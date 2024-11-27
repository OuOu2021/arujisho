import 'package:flutter/cupertino.dart';

class ExceptionTerm extends StatelessWidget {
  final Exception e;

  const ExceptionTerm({super.key, required this.e});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("LIKE 検索:\n"
            "    _  任意の1文字\n"
            "    %  任意の0文字以上の文字列\n"
            "\n"
            "REGEX 検索:\n"
            "    .  任意の1文字\n"
            "    .*  任意の0文字以上の文字列\n"
            "    .+  任意の1文字以上の文字列\n"
            "    \\pc	任意漢字\n"
            "    \\ph	任意平仮名\n"
            "    \\pk	任意片仮名\n"
            "    []	候補。[]で括られた中の文字は、その中のどれか１つに合致する訳です\n"
            "\n"
            "例えば：\n"
            " \"ta%_eru\" は、食べる、訪ねる、立ち上げる 等\n"
            " \"[\\pc][\\pc\\ph]+る\" は、出来る、聞こえる、取り入れる 等\n"),
        Text(e.toString())
      ],
    );
  }
}
