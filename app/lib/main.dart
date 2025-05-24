import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/feed_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/decrypt_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/messaging_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TruthCast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF004AAD),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF004AAD),
          secondary: const Color(0xFF004AAD),
          background: Colors.black,
          surface: const Color(0xFF121212),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {
        '/main': (context) => const MainNavigationScreen(),
        '/feed': (context) => const FeedScreen(),
        '/camera': (context) => const CameraScreen(),
        '/messaging': (context) => const MessagingScreen(),
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
  const _SwipeTabWrapper({Key? key, required this.selectedIndex, required this.screens, required this.onVideoRecorded, this.onNextTab}) : super(key: key);

  @override
  State<_SwipeTabWrapper> createState() => _SwipeTabWrapperState();
}

class _SwipeTabWrapperState extends State<_SwipeTabWrapper> with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _isDragging = false;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
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
      _dragOffset = _dragOffset.clamp(-MediaQuery.of(context).size.width, MediaQuery.of(context).size.width);
      _isDragging = true;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    double width = MediaQuery.of(context).size.width;
    if (_dragOffset > width * 0.3) {
      // Right swipe: Snap open camera
      _animController.reset();
      _animation = Tween<double>(begin: _dragOffset, end: width).animate(_animController)
        ..addListener(() {
          setState(() {
            _dragOffset = _animation.value;
          });
        })
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CameraScreen(onVideoRecorded: widget.onVideoRecorded),
                fullscreenDialog: true,
              ),
            ).then((result) {
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
      _animation = Tween<double>(begin: _dragOffset, end: 0).animate(_animController)
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
              child: CameraScreen(
                onVideoRecorded: widget.onVideoRecorded,
              ),
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
    const CreatePostScreen(),
    const DecryptScreen(),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Color(0xFF004AAD),
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_outline),
            activeIcon: Icon(Icons.lock),
            label: 'Decrypt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}