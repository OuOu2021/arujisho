import 'package:flutter/material.dart';

class SearchHelpCard extends StatelessWidget {
  const SearchHelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      // color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyLarge,
                children: [
                  const TextSpan(
                    text: "LIKE 検索:\n",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  _buildIndentedText("_  任意の1文字\n"),
                  _buildIndentedText("%  任意の0文字以上の文字列\n"),
                  const TextSpan(text: "\n"),
                  const TextSpan(
                    text: "REGEX 検索:\n",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  _buildIndentedText(".  任意の1文字\n"),
                  _buildIndentedText(".*  任意の0文字以上の文字列\n"),
                  _buildIndentedText(".+  任意の1文字以上の文字列\n"),
                  _buildIndentedText("\\\\pc 任意漢字\n"),
                  _buildIndentedText("\\\\ph 任意平仮名\n"),
                  _buildIndentedText("\\\\pk 任意片仮名\n"),
                  _buildIndentedText("[] 候補。[]で括られた中の文字は、その中のどれか１つに合致する訳です\n"),
                  const TextSpan(text: "\n"),
                  const TextSpan(
                    text: "例えば：\n",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  _buildIndentedText("\"ta%_eru\" は、食べる、訪ねる、立ち上げる 等\n"),
                  _buildIndentedText(
                      "\"[\\\\pc][\\\\pc\\\\ph]+る\" は、出来る、聞こえる、取り入れる 等\n"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _buildIndentedText(String text) {
    return TextSpan(
      text: "    $text",
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }
}
