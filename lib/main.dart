import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:telephony/telephony.dart';

onBackgroundMessageOut(SmsMessage message) {
  debugPrint("onBackgroundMessage called");
  var parsedMsg = message.body ?? "Error reading message body."; //todo

  var credited = parsedMsg.toLowerCase().contains("credited");

  RegExp regExp = new RegExp(
      // r"(?:(?:RS|INR|MRP)\.?\s?)(\d+(:?\,\d+)?(\,\d+)?(\.\d{1,2})?)",
      r"(?:(?:Rs|INR|MRP)\.?\s?)(\d+(:?\,\d+)?(\,\d+)?)",
      caseSensitive: false);
  var match = regExp.hasMatch(parsedMsg);

  if (match && credited) {
    var match = regExp.firstMatch(parsedMsg);
    var extractedMsg = match?.group(0).toString();
    if (extractedMsg != null) {
      _speakBack(extractedMsg);
    }
  }
}

Future _speakBack(String parsedMsg) async {
  late FlutterTts flutterTts = FlutterTts();
  double volume = 1.0;
  double pitch = 1.0;
  double rate = 0.4;

  await flutterTts.setVolume(volume);
  await flutterTts.setSpeechRate(rate);
  await flutterTts.setPitch(pitch);

  var marathi = await flutterTts.isLanguageInstalled("mr-IN");
  if (marathi) {
    await flutterTts.setLanguage("mr-IN");
    parsedMsg = parsedMsg + " मिळाले.";
  } else {
    await flutterTts.setLanguage("en-US");
    parsedMsg = parsedMsg + " Received.";
  }

  if (parsedMsg.isNotEmpty) {
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(parsedMsg);
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _message = "";
  final telephony = Telephony.instance;
  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double volume = 1.0;
  double pitch = 1.0;
  double rate = 0.4;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  String amountMsg = "Rs.0";

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initTts();
  }

  initTts() {
    flutterTts = FlutterTts();
    if (isAndroid) {
      _getDefaultEngine();
    }
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  Future _speak(String parsedMsg) async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    var marathi = await flutterTts.isLanguageInstalled("mr-IN");
    if (marathi) {
      await flutterTts.setLanguage("mr-IN");
      parsedMsg = parsedMsg + " मिळाले.";
    } else {
      await flutterTts.setLanguage("en-US");
      parsedMsg = parsedMsg + " Received.";
    }

    if (parsedMsg.isNotEmpty) {
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.speak(parsedMsg);
    }
  }

  onMessage(SmsMessage message) async {
    setState(() {
      var parsedMsg = message.body ?? "Error reading message body.";;
      var credited = parsedMsg.toLowerCase().contains("credited");

      RegExp regExp = new RegExp(
          //     r"(?:(?:RS|INR|MRP)\.?\s?)(\d+(:?\,\d+)?(\,\d+)?(\.\d{1,2})?)", //Rs.1234.12
          r"(?:(?:Rs|INR|MRP)\.?\s?)(\d+(:?\,\d+)?(\,\d+)?)", //Rs.1234
          caseSensitive: false);
      var match = regExp.hasMatch(parsedMsg);

      if (match && credited) {
        var match = regExp.firstMatch(parsedMsg);
        var extractedMsg = match?.group(0).toString();
        if (extractedMsg != null) {
          amountMsg = extractedMsg;
          _speak(amountMsg);
        }
      }
    });
  }

  onBackgroundMessage(SmsMessage message) {
    debugPrint("onBackgroundMessage called");
    _message = message.body ?? "Error reading message body.";
    var parsedMsg = _message;
    _speak(parsedMsg);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    final bool? result = await telephony.requestPhoneAndSmsPermissions;

    if (result != null && result) {
      telephony.listenIncomingSms(
          onNewMessage: onMessage, onBackgroundMessage: onBackgroundMessageOut);
    }

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('Loud UPI'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Center(
              child: Text("तुम्हाला येथे UPI रक्कम दिसेल.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.blue,
                    fontWeight: FontWeight.w700,
                  ))),
          Center(
              child: Text("$amountMsg",
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.blue,
                    fontWeight: FontWeight.w700,
                  ))),
          Spacer(),
          Center(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyText1,
                children: [
                  TextSpan(text: 'Created with '),
                  WidgetSpan(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Icon(Icons.favorite, color: Colors.red),
                    ),
                  ),
                  TextSpan(text: ' by Narendra Kalekar.'),
                ],
              ),
            ),
          )
        ],
      ),
    ));
  }
}
