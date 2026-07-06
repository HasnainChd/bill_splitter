import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/router/app_router.dart';

class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner>
    with TickerProviderStateMixin {
  bool _isOffline = false;
  bool _wasOffline = false;
  bool _showBackOnline = false;
  Timer? _onlineTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _onlineTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Check if we are on the splash screen
    bool isOnSplashScreen = false;
    try {
      final routeContext = AppRouter.navigatorKey.currentContext;
      if (routeContext != null && routeContext.mounted) {
        final router = GoRouter.of(routeContext);
        if (router.routeInformationProvider.value.uri.path == AppRouter.splash) {
          isOnSplashScreen = true;
        }
      }
    } catch (_) {}

    if (isOnSplashScreen) {
      return const SizedBox.shrink();
    }

    // Listen to the connectivity changes
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      next.whenData((isOnline) {
        if (!isOnline) {
          _onlineTimer?.cancel();
          setState(() {
            _isOffline = true;
            _wasOffline = true;
            _showBackOnline = false;
          });
        } else {
          if (_wasOffline) {
            setState(() {
              _isOffline = false;
              _showBackOnline = true;
            });
            // Show "Back online" banner briefly for 2 seconds, then hide
            _onlineTimer?.cancel();
            _onlineTimer = Timer(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _showBackOnline = false;
                  _wasOffline = false;
                });
              }
            });
          } else {
            setState(() {
              _isOffline = false;
              _showBackOnline = false;
            });
          }
        }
      });
    });

    final statusBarHeight = MediaQuery.of(context).padding.top;
    final isVisible = _isOffline || _showBackOnline;
    
    // Top position starts below the status bar with a 8px margin when visible,
    // and hides completely above the screen when not visible.
    final topPosition = isVisible ? (statusBarHeight + 8.h) : -100.h;
    final accentColor = _isOffline ? AppColors.coralRed : const Color(0xFF4CAF50);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: topPosition,
      left: 16.w,
      right: 16.w,
      child: IgnorePointer(
        ignoring: !isVisible,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isVisible ? 1.0 : 0.0,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
              decoration: BoxDecoration(
                color: AppColors.cardDark.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12.r),
                border: Border(
                  left: BorderSide(
                    color: accentColor,
                    width: 3.w,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                    color: accentColor,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    _isOffline ? 'No internet connection' : 'Back online',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _pulseAnimation,
                    child: Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
