import 'package:Meetcha/constants/app_colors.dart';
import 'package:Meetcha/controllers/profile_controller.dart';
import 'package:flutter/material.dart';

String _normalize(String value) => value.trim().toLowerCase();

/// Membandingkan minat sebuah profil dengan minat user yang sedang login.
///
/// [ordered] berisi minat yang SAMA lebih dulu, baru sisanya, supaya minat
/// yang sama tetap terlihat walau tampilan hanya memuat beberapa chip.
class InterestMatch {
  final List<String> ordered;
  final int sharedCount;
  final Set<String> _shared;

  InterestMatch._(this.ordered, this._shared) : sharedCount = _shared.length;

  factory InterestMatch.between({
    required List<String> theirs,
    required List<String> mine,
  }) {
    final mineSet = mine.map(_normalize).where((e) => e.isNotEmpty).toSet();

    final shared = <String>{};
    final common = <String>[];
    final others = <String>[];

    for (final item in theirs) {
      final key = _normalize(item);
      if (key.isEmpty) continue;

      if (mineSet.contains(key)) {
        shared.add(key);
        common.add(item);
      } else {
        others.add(item);
      }
    }

    return InterestMatch._([...common, ...others], shared);
  }

  /// Dibandingkan dengan minat user yang sedang login.
  factory InterestMatch.forProfile(List<String> theirs) {
    return InterestMatch.between(
      theirs: theirs,
      mine: ProfileController.to.me?.interests ?? const [],
    );
  }

  bool isShared(String label) => _shared.contains(_normalize(label));
}

/// Chip minat. [highlighted] = minat yang sama dengan user.
class InterestChip extends StatelessWidget {
  final String label;
  final bool highlighted;
  final bool compact;

  const InterestChip({
    super.key,
    required this.label,
    this.highlighted = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 11.5 : 12.5;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 11 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.matchaDeep
            : AppColors.matchaSoft.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? AppColors.matchaDeep
              : AppColors.primaryBorder.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (highlighted) ...[
            Icon(Icons.check_rounded, size: fontSize + 1.5, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: highlighted ? Colors.white : AppColors.matchaDeep,
              fontSize: fontSize,
              height: 1,
              fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Label kecil "N minat yang sama".
class SharedInterestsLabel extends StatelessWidget {
  final int count;

  const SharedInterestsLabel({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.auto_awesome_rounded,
          size: 15,
          color: AppColors.matchaDeep,
        ),
        const SizedBox(width: 6),
        Text(
          '$count minat yang sama',
          style: const TextStyle(
            color: AppColors.matchaDeep,
            fontSize: 12.5,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}