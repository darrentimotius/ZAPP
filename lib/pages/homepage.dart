import 'dart:async';

import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zapp/cache/user_cache.dart';
import 'package:zapp/pages/notifications.dart';
import 'package:zapp/pages/profile_page.dart';
import 'package:zapp/routes/route_observer.dart';

import '../components/carousel.dart';
import '../components/room_cart.dart';
import 'calculate.dart';
import 'history.dart';
import 'news.dart';
import 'addroom.dart';
import 'Home_Office_page.dart';
import 'Kitchen_page.dart';
import 'Bedroom_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeContent(),
    CalculatePage(),
    HistoryPage(),
    NewsPage(),
  ];

  Widget _navItem(IconData icon, String label, int index) {
    final bool isActive = _currentIndex == index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 3,
          width: isActive ? 70 : 0,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 6),
        Icon(
          icon,
          color: isActive ? Colors.blue : Colors.grey,
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: isActive
              ? Text(
            label,
            key: ValueKey(label),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: _navItem(Icons.home, 'Home', 0),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _navItem(Icons.calculate, 'Calculate', 1),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _navItem(Icons.history, 'History', 2),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _navItem(Icons.newspaper, 'News', 3),
            label: '',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with RouteAware {
  String? username;
  User? user;
  Timer? _retryTimer;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _loadUsername(),
    );
  }

  void _stopRetryTimer() {
    _retryTimer?.cancel();
  }

  @override
  void didPush() {
    _startRetryTimer();
  }

  @override
  void didPopNext() {
    _startRetryTimer();
  }

  @override
  void didPushNext() {
    _stopRetryTimer();
  }

  Future<void> _loadUsername() async {
    if (UserCache.isReady) {
      setState(() {
        user = UserCache.user;
        username = UserCache.username;
      });
      return;
    }

    if (_isFetching) return;

    _isFetching = true;

    try {
      final supabase = Supabase.instance.client;

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final response = await supabase
          .from('profiles')
          .select('username')
          .eq('user_id', currentUser.id)
          .single();

      UserCache.user = currentUser;
      UserCache.email = currentUser.email;
      UserCache.username = response['username'];

      if (!mounted) return;
      setState(() {
        user = currentUser;
        username = response['username'];
      });

      _retryTimer?.cancel();
    } catch (e) {
      debugPrint('Homepage: fetch failed, will retry...');
    } finally {
      _isFetching = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            _header(context),
            const SizedBox(height: 16),
            const TopCarousel(),
            const SizedBox(height: 24),
            _usageHeader(context),
            const SizedBox(height: 12),
            _roomGrid(),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfilePage(),
              ),
            );
          },
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade300,
            child: ClipOval(
              child: Image.asset(
                "assets/icon/profile.jpg",
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person, color: Colors.white);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 180,
                child: AnimatedTextKit(
                  repeatForever: true,
                  pause: const Duration(milliseconds: 1000),
                  animatedTexts: [
                    TyperAnimatedText("Hi",
                        textStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Halo",
                        textStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Bonjour",
                        textStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Hola",
                        textStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Aloha",
                        textStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("您好",
                        textStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("こんにちは",
                        textStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("안녕하세요",
                        textStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Zdravstvuyte",
                        textStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Sàwàtdee",
                        textStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Guten Tag",
                        textStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Ciao",
                        textStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("مرحبا",
                        textStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Olá",
                        textStyle:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                username ?? '-',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
          },
        )
      ],
    );
  }

  Widget _usageHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Usage by room",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        OutlinedButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddRoom(),
              ),
            );
          },
          child: const Text("+ Add room"),
        ),
      ],
    );
  }

  Widget _roomGrid() {
    final items = [
      {
        "percent": 12,
        "name": "Kitchen",
        "image": "assets/images/kitchen.jpg",
      },
      {
        "percent": 24,
        "name": "Home Office",
        "image": "assets/images/home_office.jpg",
      },
      {
        "percent": 9,
        "name": "Bedroom",
        "image": "assets/images/bedroom.jpg",
      },
      {
        "percent": 11,
        "name": "Bathroom",
        "image": "assets/images/bathroom.jpg",
      },
      {
        "percent": 100,
        "name": "Gaming room",
        "image": "assets/images/gaming_room.jpg",
      },
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((e) {
        return GestureDetector(
          onTap: () {
            if (e["name"] == "Home Office") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeOfficePage(),
                ),
              );
            } else if (e["name"] == "Kitchen") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KitchenPage(),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${e["name"]} clicked')),
              );
            }
          },

          child: RoomUsageCard(
            percentage: e["percent"] as int,
            label: e["name"] as String,
            imagePath: e["image"] as String,
          ),
        );
      }).toList(),
    );
  }
}
