import 'package:flutter/material.dart';
import 'custom_calendar_date_picker/custom_calendar_date_picker.dart';

MaterialColor claroColor = const MaterialColor(0xffFF3A47, {
  50: Color.fromRGBO(255, 58, 71, .1),
  400: Color.fromRGBO(255, 58, 71, .5),
  100: Color.fromRGBO(255, 58, 71, .2),
  500: Color.fromRGBO(255, 58, 71, .6),
  600: Color.fromRGBO(255, 58, 71, .7),
  700: Color.fromRGBO(255, 58, 71, .8),
  900: Color.fromRGBO(255, 58, 71, 1),
  300: Color.fromRGBO(255, 58, 71, .4),
  800: Color.fromRGBO(255, 58, 71, .9),
  200: Color.fromRGBO(255, 58, 71, .3),
});

class CustomFlutterDatePicker extends StatelessWidget {
  const CustomFlutterDatePicker({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primarySwatch: claroColor,
        splashColor: claroColor.shade300,
      ),
      child: CustomCalendarDatePicker(
          initialDate: DateTime.now(),
          firstDate: DateTime.now().subtract(Duration(days: 10)),
          lastDate: DateTime.now().add(Duration(days: 10)),
          onDateChanged: (DateTime date) {}),
    );
  }
}
