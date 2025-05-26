import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/feed_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/decrypt_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/messaging_screen.dart';
import 'screens/splash_screen.dart';
import 'services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/sandbox_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService().initialize();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TruthCast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF004AAD),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF004AAD),
          secondary: const Color(0xFF004AAD),
          background: Colors.white,
          surface: Colors.grey[100]!,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF004AAD)),
          titleTextStyle: TextStyle(
            color: Color(0xFF004AAD),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF004AAD),
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainNavigationScreen(),
        '/feed': (context) => const FeedScreen(),
        '/camera': (context) => const CameraScreen(),
        '/messaging': (context) => const MessagingScreen(),
        '/sandbox': (context) => const SandboxScreen(),
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _SwipeTabWrapper extends StatefulWidget {
  final int selectedIndex;
  final List<Widget> screens;
  final void Function(dynamic videoFile) onVideoRecorded;
  final VoidCallback? onNextTab;
  const _SwipeTabWrapper({
    Key? key,
    required this.selectedIndex,
    required this.screens,
    required this.onVideoRecorded,
    this.onNextTab,
  }) : super(key: key);

  @override
  State<_SwipeTabWrapper> createState() => _SwipeTabWrapperState();
}

class _SwipeTabWrapperState extends State<_SwipeTabWrapper>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _isDragging = false;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(
        -MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.width,
      );
      _isDragging = true;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    double width = MediaQuery.of(context).size.width;
    if (_dragOffset > width * 0.3) {
      // Right swipe: Snap open camera
      _animController.reset();
      _animation =
          Tween<double>(begin: _dragOffset, end: width).animate(_animController)
            ..addListener(() {
              setState(() {
                _dragOffset = _animation.value;
              });
            })
            ..addStatusListener((status) {
              if (status == AnimationStatus.completed) {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder:
                            (context) => CameraScreen(
                              onVideoRecorded: widget.onVideoRecorded,
                            ),
                        fullscreenDialog: true,
                      ),
                    )
                    .then((result) {
                      setState(() {
                        _dragOffset = 0;
                        _isDragging = false;
                      });
                      if (result == 'nextTab' && widget.onNextTab != null) {
                        widget.onNextTab!();
                      }
                    });
              }
            });
      _animController.forward();
    } else if (_dragOffset < -width * 0.3) {
      // Left swipe: Snap to next tab
      if (widget.onNextTab != null) {
        widget.onNextTab!();
      }
      setState(() {
        _dragOffset = 0;
        _isDragging = false;
      });
    } else {
      // Snap back to tab
      _animController.reset();
      _animation =
          Tween<double>(begin: _dragOffset, end: 0).animate(_animController)
            ..addListener(() {
              setState(() {
                _dragOffset = _animation.value;
              });
            })
            ..addStatusListener((status) {
              if (status == AnimationStatus.completed) {
                setState(() {
                  _dragOffset = 0;
                  _isDragging = false;
                });
              }
            });
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        // Camera preview sliding in from the left (only show if swiping right)
        if (_dragOffset > 0 || _isDragging)
          Positioned(
            left: -width + _dragOffset,
            top: 0,
            bottom: 0,
            width: width,
            child: IgnorePointer(
              ignoring: !_isDragging,
              child: CameraScreen(onVideoRecorded: widget.onVideoRecorded),
            ),
          ),
        // Current Tab Screen
        Positioned(
          left: _dragOffset,
          top: 0,
          bottom: 0,
          width: width,
          child: GestureDetector(
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: widget.screens[widget.selectedIndex],
          ),
        ),
      ],
    );
  }
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const DecryptScreen(),
    const CreatePostScreen(),
    const SandboxScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _SwipeTabWrapper(
        selectedIndex: _selectedIndex,
        screens: _screens,
        onVideoRecorded: (videoFile) {
          debugPrint('Video recorded: \\${videoFile.path}');
        },
        onNextTab: () {
          setState(() {
            _selectedIndex = (_selectedIndex + 1) % _screens.length;
          });
        },
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: const Color.fromARGB(255, 0, 0, 0),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 0, 0, 0),
              blurRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Feed'),
                _buildNavItem(1, Icons.lock_outline, Icons.lock, 'Decrypt'),
                _buildNavItem(
                  2,
                  Icons.add_circle_outline,
                  Icons.add_circle,
                  'Create',
                ),
                _buildNavItem(
                  3,
                  Icons.science_outlined,
                  Icons.science,
                  'Sandbox',
                ),
                _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: isSelected ? 12 : 8,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF004AAD).withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border:
              isSelected
                  ? Border.all(color: const Color(0xFF004AAD), width: 2)
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF004AAD) : Colors.grey[600],
              size: 28,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF004AAD),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
