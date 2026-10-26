import 'package:flutter/material.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/glowing_orb.dart';
import '../navigation/presentation/main_bottom_nav.dart';
import 'pin_setup_screen.dart';
import 'pin_unlock_screen.dart';
import 'registration_screen.dart';

/// Root of the app: shows sign-in, PIN setup, the lock screen or the app
/// itself depending on [AuthController.status], and re-locks after the app
/// has been in background longer than [lockAfter].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  static const lockAfter = Duration(minutes: 2);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final _auth = AuthController.instance;
  DateTime? _backgroundedAt;
  AuthStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_onAuthChanged);
    _auth.bootstrap();
    ApiClient.instance.warmUp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// Leaving the unlocked state must also close screens pushed over the app
  /// (profile, sheets), otherwise they would stay on top of the lock screen.
  void _onAuthChanged() {
    final status = _auth.status;
    if (_lastStatus == AuthStatus.unlocked && status != AuthStatus.unlocked) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
    _lastStatus = status;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      _backgroundedAt = null;
      ApiClient.instance.warmUp();
      if (since != null && DateTime.now().difference(since) >= AuthGate.lockAfter) _auth.lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _auth,
      builder: (context, _) {
        final Widget child = switch (_auth.status) {
          AuthStatus.loading => const _Splash(),
          AuthStatus.signedOut => const RegistrationScreen(),
          AuthStatus.needsPin => const PinSetupScreen(),
          AuthStatus.locked => const PinUnlockScreen(),
          AuthStatus.unlocked => const MainBottomNav(),
        };
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: KeyedSubtree(key: ValueKey(_auth.status), child: child),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: const Center(child: GlowingOrb(size: 72)),
    );
  }
}
