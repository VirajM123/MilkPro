import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_widgets.dart';

const Color modulePrimary = AppColors.primary;
const Color moduleDark = AppColors.textPrimary;
const Color moduleMuted = AppColors.textSecondary;
const Color moduleBackground = AppColors.background;
const Color moduleGreen = AppColors.success;
const Color moduleOrange = AppColors.warning;

class SimpleModuleScaffold extends StatelessWidget {
  const SimpleModuleScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.action,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: moduleBackground,
      appBar: PremiumAppBar(
        title: title,
        subtitle: subtitle,
        actions: action == null ? null : <Widget>[action!],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: <Widget>[...children],
      ),
    );
  }
}

class SimpleSection extends StatelessWidget {
  const SimpleSection({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(15),
  });

  final String? title;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Text(
              title!,
              style: const TextStyle(
                color: moduleDark,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 13),
          ],
          child,
        ],
      ),
    );
  }
}

class SimpleStat extends StatelessWidget {
  const SimpleStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE1E7F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: moduleDark,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: moduleMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration simpleInput(String label, IconData icon, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: modulePrimary, size: 21),
    labelStyle: const TextStyle(
      color: moduleMuted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
    filled: true,
    fillColor: const Color(0xFFF8FAFD),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE1E7F0)),
    ),
  );
}

void showSavedMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: moduleGreen,
    ),
  );
}
