
import 'package:flutter/material.dart';

class AccountIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const AccountIconButton({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.account_circle),
      onPressed: onPressed,
      tooltip: 'Account',
    );
  }
}
