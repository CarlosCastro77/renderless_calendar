import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'custom_flutter_date_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        localizationsDelegates: [
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate
        ],
        debugShowCheckedModeBanner: false,
        supportedLocales: [const Locale('pt', 'BR')],
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
            body: Center(
                child:
                    Container(width: 360, child: CustomFlutterDatePicker()))));
  }
}
