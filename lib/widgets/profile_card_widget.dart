import 'package:flutter/material.dart';
import 'package:bumble/models/profile_model.dart';
import 'package:bumble/constants/app_colors.dart';

class ProfileCardWidget extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final bool isFullCard;

  const ProfileCardWidget({
    super.key,
    required this.profile,
    required this.onLike,
    required this.onPass,
    this.isFullCard = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: isFullCard
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isFullCard)
            Expanded(child: _buildImage())
          else
            _buildImage(fixedHeight: 260),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${profile.name}${profile.age != null ? ', ${profile.age}' : ''}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (profile.city != null && profile.city!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            profile.city!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                  ],
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
                if (profile.interests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: profile.interests.take(3).map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          interest,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton(
                      icon: Icons.close,
                      color: Colors.grey.shade500,
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

  Widget _buildImage({double? fixedHeight}) {
    final photo = profile.photoUrl;
    final hasValidPhoto =
        photo != null && photo.isNotEmpty && photo.startsWith('http');

    return SizedBox(
      height: fixedHeight,
      width: double.infinity,
      child: hasValidPhoto
          ? Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.person, size: 80, color: Colors.grey),
              ),
            )
          : Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.person, size: 80, color: Colors.grey),
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