import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class HolographicBankCard extends StatelessWidget {
  final String bankName;
  final String cardType;
  final String maskedPan;
  final String balanceFormatted;
  final String cardholderName;
  final List<Color> gradientColors;

  const HolographicBankCard({
    super.key,
    required this.bankName,
    required this.cardType,
    required this.maskedPan,
    required this.balanceFormatted,
    this.cardholderName = 'ALEX MERCER',
    this.gradientColors = const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF020617)],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 195,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top: Bank and Card Type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bankName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  cardType.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          // Chip & Contactless
          Row(
            children: [
              Container(
                width: 38,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFFEF08A), Color(0xFFCA8A04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.wifi_rounded, color: Colors.white70, size: 20),
            ],
          ),

          // Number & Bottom row
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                maskedPan,
                style: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  color: Colors.white,
                  fontSize: 17,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ДЕРЖАТЕЛЬ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        cardholderName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    balanceFormatted,
                    style: const TextStyle(
                      color: AppColors.cyanAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
