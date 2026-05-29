/// Enjoy brand mark — gradient SVG, no chrome.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EnjoyLogo extends StatelessWidget {
  const EnjoyLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset('assets/logo-light.svg', fit: BoxFit.contain),
    );
  }
}
