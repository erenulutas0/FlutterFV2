import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import 'package:flutter/gestures.dart';
import '../utils/app_colors.dart';
import '../utils/login_spacing.dart';
import '../widgets/raindrop.dart';
import '../widgets/floating_orb.dart';
import 'login_page_helper.dart'; // Helper import
import 'home_page.dart';  // Or wherever we navigate after login
import '../main.dart'; // For MainScreen navigation
import '../services/auth_service.dart'; // Explicit import

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginPage({Key? key, this.onLoginSuccess}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  // Controllers
  late AnimationController _glowController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  // State
  bool isSignUp = false;
  bool _showPassword = false;
  bool _isButtonPressed = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  
  // Animation for Glow
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameController = TextEditingController();
    
    _glowController = AnimationController(
        vsync: this, 
        duration: Duration(seconds: 2)
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    // final authService = getIt<AuthService?>(); 
    // AuthService singleton olduğu için:
    final auth = AuthService();
    
    Map<String, dynamic> result;
    
    if (isSignUp) {
      result = await auth.register(
        _nameController.text.trim(),
        _emailController.text.trim(), 
        _passwordController.text.trim()
      );
    } else {
      result = await auth.login(
        _emailController.text.trim(), 
        _passwordController.text.trim(),
        rememberMe: _rememberMe // AuthService'e rememberMe parametresi ekledik
      );
    }

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        // Provider'a kullanıcı verisini hemen set et (Anında güncel veri görünsün)
        if (result['user'] != null) {
          Provider.of<AppStateProvider>(context, listen: false).setUser(result['user']);
        }

        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => MainScreen())
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Bir hata oluştu'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final auth = AuthService();
    final result = await auth.googleLogin();
    setState(() => _isLoading = false);
    
    if (result['success'] == true) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => MainScreen())
        );
      }
    } else {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Google girişi başarısız'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  void _handleFacebookLogin() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Facebook Login Clicked")));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by stack
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
          ),
          
          // 2. Orbs (Background layer)
          ...List.generate(6, (index) => FloatingOrb()),

          // 3. Raindrops
          ...List.generate(40, (index) => RaindropWidget(screenWidth: size.width, screenHeight: size.height)),

          // 4. Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: LoginSpacing.mainPaddingH, 
                  vertical: LoginSpacing.mainPaddingV
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 448),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogoSection(),
                      SizedBox(height: LoginSpacing.sectionSpacing),
                      _buildFormContainer(),
                      SizedBox(height: LoginSpacing.infoMarginTop),
                      _buildAdditionalInfo(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: 80, // Keeping outer container slightly larger for glow effect
              height: 80,
              alignment: Alignment.center,
              child: Container(
                width: LoginSpacing.logoSize,
                height: LoginSpacing.logoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.cyan400.withOpacity(0.3),
                      AppColors.blue500.withOpacity(0.3),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.cyan500.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan500.withOpacity(_glowAnimation.value),
                      blurRadius: 30 * _glowAnimation.value + 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: LoginSpacing.logoIconSize,
                  color: AppColors.cyan400,
                ),
              ),
            );
          }
        ),
        SizedBox(height: LoginSpacing.logoMarginBottom),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.cyan400,
              AppColors.blue400,
              AppColors.cyan400,
            ],
          ).createShader(bounds),
          child: Text(
            'VocabMaster',
            style: TextStyle(
              fontSize: LoginSpacing.titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: LoginSpacing.titleMarginBottom),
        Text(
          'Kelime öğrenme yolculuğunuza başlayın',
          style: TextStyle(
            fontSize: 12, // Keeping subtitle small
            color: Color(0xFF67E8F9).withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContainer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(LoginSpacing.formPadding),
          decoration: BoxDecoration(
            color: AppColors.slate900.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.cyan500.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 32,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: AnimatedSize(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                children: [
                  _buildTabToggle(),
                  SizedBox(height: LoginSpacing.tabMarginBottom),
                  if (isSignUp) ...[
                     _buildInputField(
                       label: 'İsim Soyisim',
                       placeholder: 'Adınız Soyadınız',
                       icon: Icons.person_outline,
                       controller: _nameController,
                     ),
                     SizedBox(height: LoginSpacing.fieldSpacing),
                  ],
                  _buildInputField(
                    label: 'E-posta',
                    placeholder: 'ornek@email.com',
                    icon: Icons.mail_outline,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: LoginSpacing.fieldSpacing),
                  _buildInputField(
                    label: 'Şifre',
                    placeholder: '••••••••',
                    icon: Icons.lock_outline,
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: AppColors.cyan400.withOpacity(0.5),
                      ),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  if (!isSignUp) ...[
                    SizedBox(height: 10),
                    LoginPageHelper(
                      isSignUp: isSignUp,
                      rememberMe: _rememberMe,
                      onRememberMeChanged: (val) => setState(() => _rememberMe = val ?? false),
                    ).buildRememberMe(context),
                  ],
                  SizedBox(height: isSignUp ? LoginSpacing.fieldSpacing + 4 : LoginSpacing.fieldSpacing + 10),
                  _buildSubmitButton(),
                  SizedBox(height: LoginSpacing.buttonMarginBottom),
                  _buildDivider(),
                  SizedBox(height: LoginSpacing.dividerMarginV),
                  _buildSocialButtons(),
                   if (isSignUp) ...[
                    SizedBox(height: LoginSpacing.termsMarginTop),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(fontSize: LoginSpacing.termsFontSize, color: Color(0xFF64748B)),
                        children: [
                          TextSpan(text: 'Kayıt olarak '),
                          TextSpan(
                            text: 'Kullanım Koşulları',
                            style: TextStyle(color: Color(0xFF22D3EE).withOpacity(0.7)),
                          ),
                          TextSpan(text: ' ve '),
                          TextSpan(
                            text: 'Gizlilik Politikası',
                            style: TextStyle(color: Color(0xFF22D3EE).withOpacity(0.7)),
                          ),
                          TextSpan(text: '\'nı kabul etmiş olursunuz.'),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      padding: EdgeInsets.all(LoginSpacing.tabPadding),
      decoration: BoxDecoration(
        color: AppColors.slate900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleItem("Giriş Yap", !isSignUp, () => setState(() => isSignUp = false))),
          Expanded(child: _buildToggleItem("Kayıt Ol", isSignUp, () => setState(() => isSignUp = true))),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(vertical: LoginSpacing.tabButtonVertical),
        decoration: isActive ? BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.cyan500.withOpacity(0.2),
              AppColors.blue500.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.cyan400.withOpacity(0.3),
            width: 1,
          ),
        ) : null,
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.slate400,
              fontWeight: FontWeight.w600,
              fontSize: LoginSpacing.tabFontSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String placeholder,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: LoginSpacing.labelFontSize, color: Color(0xFF67E8F9).withOpacity(0.9)),
        ),
        SizedBox(height: LoginSpacing.labelMarginBottom),
        Container(
          decoration: BoxDecoration(
            color: AppColors.slate900.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: TextStyle(color: Colors.white, fontSize: LoginSpacing.inputFontSize),
            cursorColor: AppColors.cyan400,
             validator: (value) {
                if (value == null || value.isEmpty) return 'Zorunlu';
                return null;
            },
            decoration: InputDecoration(
              isDense: true,
              hintText: placeholder,
              hintStyle: TextStyle(color: AppColors.slate500, fontSize: LoginSpacing.inputFontSize),
              prefixIcon: Padding(
                padding: EdgeInsets.symmetric(horizontal: LoginSpacing.iconPadding),
                child: Icon(icon, color: AppColors.cyan400.withOpacity(0.5), size: LoginSpacing.iconSize),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 40),
              suffixIcon: suffixIcon,
              suffixIconConstraints: BoxConstraints(minWidth: 40, maxHeight: 40),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: LoginSpacing.inputPaddingH, 
                vertical: LoginSpacing.inputPaddingV
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isButtonPressed = true),
      onTapUp: (_) {
         setState(() => _isButtonPressed = false);
         _handleSubmit();
      },
      onTapCancel: () => setState(() => _isButtonPressed = false),
      child: AnimatedScale(
        scale: _isButtonPressed ? 0.98 : 1.0,
        duration: Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 100),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: LoginSpacing.buttonPaddingV),
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan500.withOpacity(_isButtonPressed ? 0.6 : 0.4),
                blurRadius: _isButtonPressed ? 30 : 20,
              ),
            ],
          ),
          child: Center(
            child: Text(
              isSignUp ? 'Hesap Oluştur' : 'Giriş Yap',
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: LoginSpacing.buttonFontSize
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.slate500.withOpacity(0.3))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("veya", style: TextStyle(color: AppColors.slate500, fontSize: LoginSpacing.dividerFontSize)),
        ),
        Expanded(child: Container(height: 1, color: AppColors.slate500.withOpacity(0.3))),
      ],
    );
  }
  
  Widget _buildSocialButtons() {
    return Column(
      children: [
        _buildSocialBtn("Google ile devam et", Icons.g_mobiledata, _handleGoogleLogin),
        SizedBox(height: LoginSpacing.socialSpacing),
        _buildSocialBtn("Facebook ile devam et", Icons.facebook, _handleFacebookLogin),
      ],
    );
  }
  
  Widget _buildSocialBtn(String text, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: LoginSpacing.socialPaddingV),
          decoration: BoxDecoration(
            color: AppColors.slate900.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: LoginSpacing.socialIconSize),
              SizedBox(width: LoginSpacing.socialIconSpacing),
              Text(
                text, 
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.w500, 
                  fontSize: LoginSpacing.socialFontSize
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Padding(
      padding: EdgeInsets.only(
        top: LoginSpacing.infoMarginTop,
        bottom: LoginSpacing.infoMarginBottom,
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: AppColors.slate400, fontSize: LoginSpacing.infoFontSize),
          children: [
            TextSpan(text: isSignUp ? 'Zaten hesabınız var mı? ' : 'Henüz hesabınız yok mu? '),
            TextSpan(
              text: isSignUp ? 'Giriş yapın' : 'Kayıt olun',
              style: TextStyle(color: AppColors.cyan400, fontWeight: FontWeight.bold),
              recognizer: TapGestureRecognizer()..onTap = () => setState(() => isSignUp = !isSignUp),
            ),
          ],
        ),
      ),
    );
  }
}
