import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:prefmon/model/prefmon_events.dart';

class PrefmonDataMapper {
  static const String startTag = 'prefmon:';
  static const String endTag = ':prefmon';

  static PrefMonDataEvent? parse(String messages) {
    LineSplitter ls = const LineSplitter();
    for (var message in ls.convert(messages)) {
      final start = message.indexOf(startTag);
      if (start >= 0) {
        final end = message.lastIndexOf(endTag);
        if (end >= 0) {
          final prefMonData = message.substring(start + startTag.length, end);
          final parts = prefMonData.split('->');
          final category = parts.first;
          final data = parts.last;
          return PrefMonDataEvent(category, data);
        }
      } else {
        debugPrint(messages);
      }
    }
    return null;
  }
}
