import 'package:flutter/material.dart';

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool isSameDay(DateTime dateA, DateTime dateB) {
  return dateA?.year == dateB?.year &&
      dateA?.month == dateB?.month &&
      dateA?.day == dateB?.day;
}

bool isSameMonth(DateTime dateA, DateTime dateB) {
  return dateA?.year == dateB?.year && dateA?.month == dateB?.month;
}

int monthDelta(DateTime startDate, DateTime endDate) {
  return (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;
}

DateTime addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
  return DateTime(monthDate.year, monthDate.month + monthsToAdd);
}

DateTime addDaysToDate(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day + days);
}

int firstDayOffset(int year, int month, MaterialLocalizations localizations) {
  final int weekdayFromMonday = DateTime(year, month).weekday - 1;
  int firstDayOfWeekIndex = localizations.firstDayOfWeekIndex;
  firstDayOfWeekIndex = (firstDayOfWeekIndex - 1) % 7;
  return (weekdayFromMonday - firstDayOfWeekIndex) % 7;
}

int getDaysInMonth(int year, int month) {
  if (month == DateTime.february) {
    final bool isLeapYear =
        (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
    if (isLeapYear) return 29;
    return 28;
  }
  const List<int> daysInMonth = <int>[
    31,
    -1,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31
  ];
  return daysInMonth[month - 1];
}
