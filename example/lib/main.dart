import 'package:flutter/material.dart';

import 'scan.dart';

import 'package:flutter/cupertino.dart';

void main() {
  runApp(EdgeDetectionApp());
}

class EdgeDetectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: Text('สแกนเนอร์'),
        ),
        body: Container(
          margin: EdgeInsets.all(36),
          child: ListView(
            children: [
              Image(
                height: 120,
                image: AssetImage('assets/dzcard.png'),
              ),
              FittedBox(
                fit: BoxFit.fitWidth,
                child: Text(
                  'จัดทำโดย DZ Solutions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Builder(
                builder: (context) => ElevatedButton(
                    child: Text('เริ่มกระบวนการ'),
                    onPressed: () {
                      Navigator.of(context).push(new MaterialPageRoute(
                          builder: (BuildContext context) => new Scan()));
                    }),
              ),
              // Builder(
              //   builder: (context) => ElevatedButton(
              //       child: Text('QR SCAN'),
              //       onPressed: () {
              //         Navigator.of(context).push(new MaterialPageRoute(
              //             builder: (BuildContext context) => new HomeScreen()));
              //       }),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
