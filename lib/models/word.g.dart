// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Word _$WordFromJson(Map<String, dynamic> json) => Word(
      romaji: json['romaji'] as String,
      word: json['word'] as String,
      pitchData: json['pitchData'] as String,
      origForm: json['origForm'] as String,
      orig: json['orig'] as String,
      freqRank: (json['freqRank'] as num).toInt(),
      yomikata: json['yomikata'] as String,
      idex: (json['idex'] as num).toInt(),
      imi: Word._fromJson(json['imi'] as String),
    );

Map<String, dynamic> _$WordToJson(Word instance) => <String, dynamic>{
      'word': instance.word,
      'pitchData': instance.pitchData,
      'origForm': instance.origForm,
      'orig': instance.orig,
      'freqRank': instance.freqRank,
      'romaji': instance.romaji,
      'yomikata': instance.yomikata,
      'idex': instance.idex,
      'imi': Word._toJson(instance.imi),
    };
