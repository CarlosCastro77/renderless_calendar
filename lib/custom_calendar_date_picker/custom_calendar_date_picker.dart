import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'custom_month_picker.dart';
import 'custom_year_picker.dart';
import 'utils/commons.dart';
import 'utils/layout_values.dart';
import 'utils/date_utils.dart' as utils;

class CustomCalendarDatePicker extends StatefulWidget {
  CustomCalendarDatePicker({
    Key key,
    @required DateTime initialDate,
    @required DateTime firstDate,
    @required DateTime lastDate,
    DateTime currentDate,
    @required this.onDateChanged,
    this.onDisplayedMonthChanged,
    this.initialCalendarMode = DatePickerMode.day,
    this.selectableDayPredicate,
  })  : assert(initialDate != null),
        assert(firstDate != null),
        assert(lastDate != null),
        initialDate = utils.dateOnly(initialDate),
        firstDate = utils.dateOnly(firstDate),
        lastDate = utils.dateOnly(lastDate),
        currentDate = utils.dateOnly(currentDate ?? DateTime.now()),
        assert(onDateChanged != null),
        assert(initialCalendarMode != null),
        super(key: key) {
    assert(!this.lastDate.isBefore(this.firstDate),
        'lastDate ${this.lastDate} must be on or after firstDate ${this.firstDate}.');
    assert(!this.initialDate.isBefore(this.firstDate),
        'initialDate ${this.initialDate} must be on or after firstDate ${this.firstDate}.');
    assert(!this.initialDate.isAfter(this.lastDate),
        'initialDate ${this.initialDate} must be on or before lastDate ${this.lastDate}.');
    assert(
        selectableDayPredicate == null ||
            selectableDayPredicate(this.initialDate),
        'Provided initialDate ${this.initialDate} must satisfy provided selectableDayPredicate.');
  }

  final DateTime initialDate;

  final DateTime firstDate;

  final DateTime lastDate;

  final DateTime currentDate;

  final ValueChanged<DateTime> onDateChanged;

  final ValueChanged<DateTime> onDisplayedMonthChanged;

  final DatePickerMode initialCalendarMode;

  final SelectableDayPredicate selectableDayPredicate;

  @override
  _CustomCalendarDatePickerState createState() =>
      _CustomCalendarDatePickerState();
}

class _CustomCalendarDatePickerState extends State<CustomCalendarDatePicker> {
  bool _announcedInitialDate = false;
  DatePickerMode _mode;
  DateTime _currentDisplayedMonthDate;
  DateTime _selectedDate;
  final GlobalKey _monthPickerKey = GlobalKey();
  final GlobalKey _yearPickerKey = GlobalKey();
  MaterialLocalizations _localizations;
  TextDirection _textDirection;

  @override
  void initState() {
    super.initState();
    _initWidgetState();
  }

  @override
  void didUpdateWidget(CustomCalendarDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initWidgetState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasDirectionality(context));
    _localizations = MaterialLocalizations.of(context);
    _textDirection = Directionality.of(context);
    if (!_announcedInitialDate) {
      _announcedInitialDate = true;
      SemanticsService.announce(
        _localizations.formatFullDate(_selectedDate),
        _textDirection,
      );
    }
  }

  void _initWidgetState() {
    _mode = widget.initialCalendarMode;
    _currentDisplayedMonthDate =
        DateTime(widget.initialDate.year, widget.initialDate.month);
    _selectedDate = widget.initialDate;
  }

  void _handleModeChanged(DatePickerMode mode) {
    Commons().vibrate(context);
    setState(() {
      _mode = mode;
      if (_mode == DatePickerMode.day) {
        SemanticsService.announce(
          _localizations.formatMonthYear(_selectedDate),
          _textDirection,
        );
      } else {
        SemanticsService.announce(
          _localizations.formatYear(_selectedDate),
          _textDirection,
        );
      }
    });
  }

  void _handleMonthChanged(DateTime date) {
    setState(() {
      if (_currentDisplayedMonthDate.year != date.year ||
          _currentDisplayedMonthDate.month != date.month) {
        _currentDisplayedMonthDate = DateTime(date.year, date.month);
        widget.onDisplayedMonthChanged?.call(_currentDisplayedMonthDate);
      }
    });
  }

  void _handleYearChanged(DateTime value) {
    Commons().vibrate(context);

    if (value.isBefore(widget.firstDate)) {
      value = widget.firstDate;
    } else if (value.isAfter(widget.lastDate)) {
      value = widget.lastDate;
    }

    setState(() {
      _mode = DatePickerMode.day;
      _handleMonthChanged(value);
    });
  }

  void _handleDayChanged(DateTime value) {
    Commons().vibrate(context);
    setState(() {
      _selectedDate = value;
      widget.onDateChanged?.call(_selectedDate);
    });
  }

  Widget _buildPicker() {
    assert(_mode != null);
    switch (_mode) {
      case DatePickerMode.day:
        return CustomMonthPicker(
          key: _monthPickerKey,
          initialMonth: _currentDisplayedMonthDate,
          currentDate: widget.currentDate,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          selectedDate: _selectedDate,
          onChanged: _handleDayChanged,
          onDisplayedMonthChanged: _handleMonthChanged,
          selectableDayPredicate: widget.selectableDayPredicate,
        );
      case DatePickerMode.year:
        return Padding(
          padding: const EdgeInsets.only(top: subHeaderHeight),
          child: CustomYearPicker(
            key: _yearPickerKey,
            currentDate: widget.currentDate,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            initialDate: _currentDisplayedMonthDate,
            selectedDate: _selectedDate,
            onChanged: _handleYearChanged,
          ),
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasDirectionality(context));
    return Stack(
      children: <Widget>[
        SizedBox(
          height: subHeaderHeight + maxDayPickerHeight,
          child: _buildPicker(),
        ),
        Positioned(
          top: -15,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 160,
              child: FlatButton(
                  onPressed: _mode == DatePickerMode.day
                      ? () {
                          _handleModeChanged(_mode == DatePickerMode.day
                              ? DatePickerMode.year
                              : DatePickerMode.day);
                        }
                      : null,
                  child: Container()),
            ),
          ),
        ),
      ],
    );
  }
}
