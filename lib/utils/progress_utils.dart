
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class Progress extends StatefulWidget {
  const Progress({super.key});

  @override
  State<Progress> createState() => _ProgressState();
}

class _ProgressState extends State<Progress> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(15.0),
      child: LinearPercentIndicator(
        width: MediaQuery.of(context).size.width - 50,
        animation: true,
        lineHeight: 20.0,
        percent: 0.9,
        center: Text("90.0%"),
        barRadius: Radius.circular(10.0),
        progressColor: Colors.greenAccent,
      ),
    );
  }
}
