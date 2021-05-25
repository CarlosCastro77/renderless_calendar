import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'focused_date.dart';
import 'utils/layout_values.dart';

import 'dart:math' as math;
import 'utils/date_utils.dart' as utils;

class CustomDayPicker extends StatefulWidget {
  CustomDayPicker({
    Key key,
    @required this.currentDate,
    @required this.displayedMonth,
    @required this.firstDate,
    @required this.lastDate,
    @required this.selectedDate,
    @required this.onChanged,
    this.selectableDayPredicate,
  })  : assert(currentDate != null),
        assert(displayedMonth != null),
        assert(firstDate != null),
        assert(lastDate != null),
        assert(selectedDate != null),
        assert(onChanged != null),
        assert(!firstDate.isAfter(lastDate)),
        assert(!selectedDate.isBefore(firstDate)),
        assert(!selectedDate.isAfter(lastDate)),
        super(key: key);

  final DateTime selectedDate;

  final DateTime currentDate;

  final ValueChanged<DateTime> onChanged;

  final DateTime firstDate;

  final DateTime lastDate;

  final DateTime displayedMonth;

  final SelectableDayPredicate selectableDayPredicate;

  @override
  CustomDayPickerState createState() => CustomDayPickerState();
}

class CustomDayPickerState extends State<CustomDayPicker> {
  List<FocusNode> _dayFocusNodes;

  @override
  void initState() {
    super.initState();
    final int daysInMonth = utils.getDaysInMonth(
        widget.displayedMonth.year, widget.displayedMonth.month);
    _dayFocusNodes = List<FocusNode>.generate(
        daysInMonth,
        (int index) =>
            FocusNode(skipTraversal: true, debugLabel: 'Day ${index + 1}'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final DateTime focusedDate = FocusedDate.of(context);
    if (focusedDate != null &&
        utils.isSameMonth(widget.displayedMonth, focusedDate)) {
      _dayFocusNodes[focusedDate.day - 1].requestFocus();
    }
  }

  @override
  void dispose() {
    for (final FocusNode node in _dayFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  List<Widget> _dayHeaders(
      TextStyle headerStyle, MaterialLocalizations localizations) {
    final List<Widget> result = <Widget>[];
    for (int i = localizations.firstDayOfWeekIndex; true; i = (i + 1) % 7) {
      final String weekday = localizations.narrowWeekdays[i];
      result.add(ExcludeSemantics(
        child: Center(child: Text(weekday, style: headerStyle)),
      ));
      if (i == (localizations.firstDayOfWeekIndex - 1) % 7) break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle headerStyle = textTheme.caption?.apply(
      fontSizeDelta: 3,
      fontWeightDelta: 3,
      color: colorScheme.onSurface.withOpacity(0.30),
    );
    final TextStyle dayStyle = textTheme.caption;
    final Color enabledDayColor = colorScheme.onSurface.withOpacity(0.87);
    final Color disabledDayColor = colorScheme.onSurface.withOpacity(0.38);
    final Color selectedDayColor = colorScheme.onPrimary;
    final Color selectedDayBackground = colorScheme.primary;
    final Color todayColor = colorScheme.primary;

    final int year = widget.displayedMonth.year;
    final int month = widget.displayedMonth.month;

    final int daysInMonth = utils.getDaysInMonth(year, month);
    final int dayOffset = utils.firstDayOffset(year, month, localizations);

    final List<Widget> dayItems = _dayHeaders(headerStyle, localizations);
    int day = -dayOffset;
    while (day < daysInMonth) {
      day++;
      if (day < 1) {
        dayItems.add(Container());
      } else {
        final DateTime dayToBuild = DateTime(year, month, day);
        final bool isDisabled = dayToBuild.isAfter(widget.lastDate) ||
            dayToBuild.isBefore(widget.firstDate) ||
            (widget.selectableDayPredicate != null &&
                !widget.selectableDayPredicate(dayToBuild));
        final bool isSelectedDay =
            utils.isSameDay(widget.selectedDate, dayToBuild);
        final bool isToday = utils.isSameDay(widget.currentDate, dayToBuild);

        BoxDecoration decoration;
        Color dayColor = enabledDayColor;
        if (isSelectedDay) {
          dayColor = selectedDayColor;
          decoration = BoxDecoration(
            color: selectedDayBackground,
            shape: BoxShape.circle,
          );
        } else if (isDisabled) {
          dayColor = disabledDayColor;
        } else if (isToday) {
          dayColor = todayColor;
          decoration = BoxDecoration(
            border: Border.all(color: todayColor, width: 1),
            shape: BoxShape.circle,
          );
        }

        Widget dayWidget = Container(
          width: 2,
          height: 2,
          decoration: decoration,
          child: Center(
            child: Text(localizations.formatDecimal(day),
                style: dayStyle.apply(color: dayColor, fontSizeDelta: 2)),
          ),
        );

        if (isDisabled) {
          dayWidget = ExcludeSemantics(
            child: dayWidget,
          );
        } else {
          dayWidget = InkResponse(
            focusNode: _dayFocusNodes[day - 1],
            onTap: () => widget.onChanged(dayToBuild),
            radius: dayPickerRowHeight / 2.5,
            splashColor: selectedDayBackground.withOpacity(0.38),
            child: Semantics(
              label:
                  '${localizations.formatDecimal(day)}, ${localizations.formatFullDate(dayToBuild)}',
              selected: isSelectedDay,
              excludeSemantics: true,
              child: dayWidget,
            ),
          );
        }

        dayItems.add(dayWidget);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: monthPickerHorizontalPadding,
      ),
      child: GridView.custom(
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: _dayPickerGridDelegate,
        childrenDelegate: SliverChildListDelegate(
          dayItems,
          addRepaintBoundaries: false,
        ),
      ),
    );
  }
}

class _DayPickerGridDelegate extends SliverGridDelegate {
  const _DayPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const int columnCount = DateTime.daysPerWeek;
    final double tileWidth = constraints.crossAxisExtent / columnCount;
    final double tileHeight = math.min(dayPickerRowHeight,
        constraints.viewportMainAxisExtent / (maxDayPickerRowCount + 1));
    return SliverGridRegularTileLayout(
      childCrossAxisExtent: tileWidth - 12,
      childMainAxisExtent: tileHeight - 12,
      crossAxisCount: columnCount,
      crossAxisStride: tileWidth,
      mainAxisStride: tileHeight,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_DayPickerGridDelegate oldDelegate) => false;
}

const _DayPickerGridDelegate _dayPickerGridDelegate = _DayPickerGridDelegate();
