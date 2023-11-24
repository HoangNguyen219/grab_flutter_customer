import 'package:flutter/cupertino.dart';
import 'register_textfield_widget.dart';

Widget grabRegisterPageBody(
    TextEditingController name) {
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
      const SizedBox(
        height: 20,
      ),
    ],
  );
}
