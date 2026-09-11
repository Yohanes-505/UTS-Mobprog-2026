import 'package:flutter/material.dart';
import 'package:bumble/models/profile_model.dart';
import 'package:bumble/constants/app_colors.dart';

class ProfileCardWidget extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback onLike;
  final VoidCallback onPass;

  const ProfileCardWidget({
    super.key,
    required this.profile,
    required this.onLike,
    required this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              profile.photoUrl ?? '{profile.id}', //placeholder
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 260,
                color: Colors.grey.shade200,
                child: const Icon(Icons.person, size: 80, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${profile.name}${profile.age != null ? ', ${profile.age}' : ''}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    profile.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton(
                      icon: Icons.close,
                      color: Colors.grey.shade400,
                      onTap: onPass,
                    ),
                    _actionButton(
                      icon: Icons.favorite,
                      color: AppColors.primary,
                      onTap: onLike,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}