import 'package:flutter/material.dart';
import 'utils/date_utils.dart' as utils;

class FocusedDate extends InheritedWidget {
  const FocusedDate({Key key, Widget child, this.date})
      : super(key: key, child: child);

  final DateTime date;

  @override
  bool updateShouldNotify(FocusedDate oldWidget) {
    return !utils.isSameDay(date, oldWidget.date);
  }

  static DateTime of(BuildContext context) {
    final FocusedDate focusedDate =
        context.dependOnInheritedWidgetOfExactType<FocusedDate>();
    return focusedDate?.date;
  }
}
