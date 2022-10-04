import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

class RubyTextData extends Equatable {
  const RubyTextData(
    this.text, {
    this.ruby,
    this.style,
    this.rubyStyle,
    this.onTap,
    this.textDirection = TextDirection.rtl,
  });

  final String text;
  final String? ruby;
  final TextStyle? style;
  final TextStyle? rubyStyle;
  final GestureTapCallback? onTap;
  final TextDirection textDirection;

  @override
  List<Object?> get props => [
        text,
        ruby,
        style,
        rubyStyle,
        onTap,
        textDirection,
      ];

  RubyTextData copyWith({
    String? text,
    String? ruby,
    TextStyle? style,
    TextStyle? rubyStyle,
    GestureTapCallback? onTap,
    TextDirection? textDirection,
  }) =>
      RubyTextData(
        text ?? this.text,
        ruby: ruby ?? this.ruby,
        style: style ?? this.style,
        rubyStyle: rubyStyle ?? this.rubyStyle,
        onTap: onTap ?? this.onTap,
        textDirection: textDirection ?? this.textDirection,
      );
}
