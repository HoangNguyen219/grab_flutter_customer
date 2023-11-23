import 'package:flutter/cupertino.dart';
import 'register_textfield_widget.dart';

Widget grabRegisterPageBody(
    TextEditingController name,
    TextEditingController maxDistance) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(10.0),
        child: const Text(
          "Let's start with creating your account",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w400),
        ),
      ),
      TextFieldWidget(
        labelText: 'Full Name',
        textType: 'Enter your name',
        inputType: TextInputType.text,
        controller: name,
      ),
      //Spacer(),
      const SizedBox(
        height: 10,
      ),
      TextFieldWidget(
        labelText: 'Maximum distance (km)',
        textType: 'Enter the maximum distance you can drive (km)',
        inputType: TextInputType.number,
        controller: maxDistance,
      ),
      const SizedBox(
        height: 20,
      ),
    ],
  );
}
