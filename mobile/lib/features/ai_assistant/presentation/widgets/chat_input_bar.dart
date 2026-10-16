import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onVoiceTap;
  final bool isLoading;
  final String? placeholder;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onVoiceTap,
    this.isLoading = false,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF131D2D),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.softBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: placeholder ?? 'Ask me anything...',
                hintStyle: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          if (onVoiceTap != null)
            IconButton(
              icon: const Icon(
                Icons.mic_none_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
              onPressed: onVoiceTap,
              splashRadius: 20,
            ),
          const SizedBox(width: 4),
          // Glowing blue circular send button with up-right arrow
          GestureDetector(
            onTap: isLoading ? null : onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.5),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(
                        Icons.arrow_outward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
