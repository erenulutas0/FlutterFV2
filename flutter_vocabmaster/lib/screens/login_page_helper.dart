import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/login_spacing.dart';

class LoginPageHelper extends StatelessWidget {
  final bool isSignUp;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;

  const LoginPageHelper({
    required this.isSignUp, 
    required this.rememberMe, 
    required this.onRememberMeChanged
  });

  @override
  Widget build(BuildContext context) {
    return buildRememberMe(context);
  }

  Widget buildRememberMe(BuildContext context) {
    if (isSignUp) return SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: rememberMe,
                onChanged: onRememberMeChanged,
                activeColor: AppColors.cyan400,
                side: BorderSide(color: AppColors.slate400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            SizedBox(width: 8),
            Text(
              "Beni Hatırla",
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Text(
          "Şifremi unuttum",
          style: TextStyle(
            color: AppColors.cyan400.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          )
        ),
      ],
    );
  }
}
