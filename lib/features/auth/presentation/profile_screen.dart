/// View and edit the signed-in Enjoy profile.
library;

import 'package:material_ui/material_ui.dart';

import 'package:enjoy_player/features/auth/presentation/widgets/profile_content.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileContent();
  }
}
