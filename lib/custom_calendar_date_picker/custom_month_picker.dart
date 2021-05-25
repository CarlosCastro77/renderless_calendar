import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'custom_day_picker.dart';
import 'focused_date.dart';
import 'utils/layout_values.dart';

import 'utils/date_utils.dart' as utils;

const Duration _monthScrollDuration = Duration(milliseconds: 200);

class CustomMonthPicker extends StatefulWidget {
  CustomMonthPicker({
    Key key,
    @required this.initialMonth,
    @required this.currentDate,
    @required this.firstDate,
    @required this.lastDate,
    @required this.selectedDate,
    @required this.onChanged,
    @required this.onDisplayedMonthChanged,
    this.selectableDayPredicate,
  })  : assert(selectedDate != null),
        assert(currentDate != null),
        assert(onChanged != null),
        assert(firstDate != null),
        assert(lastDate != null),
        assert(!firstDate.isAfter(lastDate)),
        assert(!selectedDate.isBefore(firstDate)),
        assert(!selectedDate.isAfter(lastDate)),
        super(key: key);

  final DateTime initialMonth;

  final DateTime currentDate;

  final DateTime firstDate;

  final DateTime lastDate;

  final DateTime selectedDate;

  final ValueChanged<DateTime> onChanged;

  final ValueChanged<DateTime> onDisplayedMonthChanged;

  final SelectableDayPredicate selectableDayPredicate;

  @override
  CustomMonthPickerState createState() => CustomMonthPickerState();
}

class CustomMonthPickerState extends State<CustomMonthPicker> {
  final GlobalKey _pageViewKey = GlobalKey();
  DateTime _currentMonth;
  DateTime _nextMonthDate;
  DateTime _previousMonthDate;
  PageController _pageController;
  MaterialLocalizations _localizations;
  TextDirection _textDirection;
  Map<LogicalKeySet, Intent> _shortcutMap;
  Map<Type, Action<Intent>> _actionMap;
  FocusNode _dayGridFocus;
  DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth;
    _previousMonthDate = utils.addMonthsToMonthDate(_currentMonth, -1);
    _nextMonthDate = utils.addMonthsToMonthDate(_currentMonth, 1);
    _pageController = PageController(
        initialPage: utils.monthDelta(widget.firstDate, _currentMonth));
    _shortcutMap = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.arrowLeft):
          const DirectionalFocusIntent(TraversalDirection.left),
      LogicalKeySet(LogicalKeyboardKey.arrowRight):
          const DirectionalFocusIntent(TraversalDirection.right),
      LogicalKeySet(LogicalKeyboardKey.arrowDown):
          const DirectionalFocusIntent(TraversalDirection.down),
      LogicalKeySet(LogicalKeyboardKey.arrowUp):
          const DirectionalFocusIntent(TraversalDirection.up),
    };
    _actionMap = <Type, Action<Intent>>{
      NextFocusIntent:
          CallbackAction<NextFocusIntent>(onInvoke: _handleGridNextFocus),
      PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
          onInvoke: _handleGridPreviousFocus),
      DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
          onInvoke: _handleDirectionFocus),
    };
    _dayGridFocus = FocusNode(debugLabel: 'Day Grid');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localizations = MaterialLocalizations.of(context);
    _textDirection = Directionality.of(context);
  }

  @override
  void didUpdateWidget(CustomMonthPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMonth != oldWidget.initialMonth) {
      _showMonth(widget.initialMonth);
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _dayGridFocus.dispose();
    super.dispose();
  }

  void _handleDateSelected(DateTime selectedDate) {
    _focusedDay = selectedDate;
    widget.onChanged?.call(selectedDate);
  }

  void _handleMonthPageChanged(int monthPage) {
    setState(() {
      final DateTime monthDate =
          utils.addMonthsToMonthDate(widget.firstDate, monthPage);
      if (!utils.isSameMonth(_currentMonth, monthDate)) {
        _currentMonth = DateTime(monthDate.year, monthDate.month);
        _previousMonthDate = utils.addMonthsToMonthDate(_currentMonth, -1);
        _nextMonthDate = utils.addMonthsToMonthDate(_currentMonth, 1);
        widget.onDisplayedMonthChanged?.call(_currentMonth);
        if (_focusedDay != null &&
            !utils.isSameMonth(_focusedDay, _currentMonth)) {
          _focusedDay = _focusableDayForMonth(_currentMonth, _focusedDay.day);
        }
      }
    });
  }

  DateTime _focusableDayForMonth(DateTime month, int preferredDay) {
    final int daysInMonth = utils.getDaysInMonth(month.year, month.month);

    if (preferredDay <= daysInMonth) {
      final DateTime newFocus = DateTime(month.year, month.month, preferredDay);
      if (_isSelectable(newFocus)) return newFocus;
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime newFocus = DateTime(month.year, month.month, day);
      if (_isSelectable(newFocus)) return newFocus;
    }
    return null;
  }

  void _handleNextMonth() {
    if (!_isDisplayingLastMonth) {
      SemanticsService.announce(
        _localizations.formatMonthYear(_nextMonthDate),
        _textDirection,
      );
      _pageController.nextPage(
        duration: _monthScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  void _handlePreviousMonth() {
    if (!_isDisplayingFirstMonth) {
      SemanticsService.announce(
        _localizations.formatMonthYear(_previousMonthDate),
        _textDirection,
      );
      _pageController.previousPage(
        duration: _monthScrollDuration,
        curve: Curves.ease,
      );
    }
  }

  void _showMonth(DateTime month) {
    final int monthPage = utils.monthDelta(widget.firstDate, month);
    _pageController.animateToPage(monthPage,
        duration: _monthScrollDuration, curve: Curves.ease);
  }

  bool get _isDisplayingFirstMonth {
    return !_currentMonth.isAfter(
      DateTime(widget.firstDate.year, widget.firstDate.month),
    );
  }

  bool get _isDisplayingLastMonth {
    return !_currentMonth.isBefore(
      DateTime(widget.lastDate.year, widget.lastDate.month),
    );
  }

  void _handleGridFocusChange(bool focused) {
    setState(() {
      if (focused && _focusedDay == null) {
        if (utils.isSameMonth(widget.selectedDate, _currentMonth)) {
          _focusedDay = widget.selectedDate;
        } else if (utils.isSameMonth(widget.currentDate, _currentMonth)) {
          _focusedDay =
              _focusableDayForMonth(_currentMonth, widget.currentDate.day);
        } else {
          _focusedDay = _focusableDayForMonth(_currentMonth, 1);
        }
      }
    });
  }

  void _handleGridNextFocus(NextFocusIntent intent) {
    _dayGridFocus.requestFocus();
    _dayGridFocus.nextFocus();
  }

  void _handleGridPreviousFocus(PreviousFocusIntent intent) {
    _dayGridFocus.requestFocus();
    _dayGridFocus.previousFocus();
  }

  void _handleDirectionFocus(DirectionalFocusIntent intent) {
    assert(_focusedDay != null);
    setState(() {
      final DateTime nextDate =
          _nextDateInDirection(_focusedDay, intent.direction);
      if (nextDate != null) {
        _focusedDay = nextDate;
        if (!utils.isSameMonth(_focusedDay, _currentMonth)) {
          _showMonth(_focusedDay);
        }
      }
    });
  }

  static const Map<TraversalDirection, int> _directionOffset =
      <TraversalDirection, int>{
    TraversalDirection.up: -DateTime.daysPerWeek,
    TraversalDirection.right: 1,
    TraversalDirection.down: DateTime.daysPerWeek,
    TraversalDirection.left: -1,
  };

  int _dayDirectionOffset(
      TraversalDirection traversalDirection, TextDirection textDirection) {
    if (textDirection == TextDirection.rtl) {
      if (traversalDirection == TraversalDirection.left)
        traversalDirection = TraversalDirection.right;
      else if (traversalDirection == TraversalDirection.right)
        traversalDirection = TraversalDirection.left;
    }
    return _directionOffset[traversalDirection];
  }

  DateTime _nextDateInDirection(DateTime date, TraversalDirection direction) {
    final TextDirection textDirection = Directionality.of(context);
    DateTime nextDate = utils.addDaysToDate(
        date, _dayDirectionOffset(direction, textDirection));
    while (!nextDate.isBefore(widget.firstDate) &&
        !nextDate.isAfter(widget.lastDate)) {
      if (_isSelectable(nextDate)) {
        return nextDate;
      }
      nextDate = utils.addDaysToDate(
          nextDate, _dayDirectionOffset(direction, textDirection));
    }
    return null;
  }

  bool _isSelectable(DateTime date) {
    return widget.selectableDayPredicate == null ||
        widget.selectableDayPredicate.call(date);
  }

  Widget _buildItems(BuildContext context, int index) {
    final DateTime month = utils.addMonthsToMonthDate(widget.firstDate, index);
    return CustomDayPicker(
      key: ValueKey<DateTime>(month),
      selectedDate: widget.selectedDate,
      currentDate: widget.currentDate,
      onChanged: _handleDateSelected,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      displayedMonth: month,
      selectableDayPredicate: widget.selectableDayPredicate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color controlColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.60);

    return Semantics(
      child: Column(
        children: <Widget>[
          Container(
            //padding: const EdgeInsetsDirectional.only(start: 0, end: 0),
            height: subHeaderHeight / 2.3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _isDisplayingFirstMonth ? null : _handlePreviousMonth,
                  child: Icon(
                    Icons.chevron_left,
                    color: _isDisplayingFirstMonth
                        ? controlColor.withOpacity(0.3)
                        : controlColor,
                  ),
                ),
                Container(
                  width: 200,
                  child: Text(_localizations.formatMonthYear(_currentMonth),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16)),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _isDisplayingLastMonth ? null : _handleNextMonth,
                  child: Icon(
                    Icons.chevron_right,
                    color: _isDisplayingLastMonth
                        ? controlColor.withOpacity(0.3)
                        : controlColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FocusableActionDetector(
              shortcuts: _shortcutMap,
              actions: _actionMap,
              focusNode: _dayGridFocus,
              onFocusChange: _handleGridFocusChange,
              child: FocusedDate(
                date: _dayGridFocus.hasFocus ? _focusedDay : null,
                child: PageView.builder(
                  key: _pageViewKey,
                  controller: _pageController,
                  itemBuilder: _buildItems,
                  itemCount:
                      utils.monthDelta(widget.firstDate, widget.lastDate) + 1,
                  scrollDirection: Axis.horizontal,
                  onPageChanged: _handleMonthPageChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
