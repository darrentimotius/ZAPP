import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zapp/core/cache/user_cache.dart';
import 'package:zapp/features/profile/profile_page.dart';
import 'package:zapp/routes/route_observer.dart';
import 'package:zapp/core/components/carousel.dart';
import 'package:zapp/core/components/room_cart.dart';

import 'simulation.dart';
import 'history.dart';
import 'news.dart';

import 'package:zapp/features/detail/addroom.dart';
import 'package:zapp/features/detail/detail_room.dart';
import 'package:zapp/features/detail/apiclient.dart';
import 'package:zapp/features/detail/delroom.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final GlobalKey<SimulationState> simulationKey = GlobalKey();
  final GlobalKey<HistoryState> historyKey = GlobalKey();

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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeContent(),
          SimulationPage(key: simulationKey),
          HistoryPage(key: historyKey),
          NewsPage(),
        ],
      ),
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

          if (index == 1) {
            simulationKey.currentState?.resetToAll();
          }

          if (index == 2) {
            historyKey.currentState?.resetToAll();
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: _navItem(Icons.home, 'Home', 0),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _navItem(Icons.calculate, 'Simulation', 1),
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
  bool _isFetchingUser = false;
  bool _isLoadingRooms = true;

  List<dynamic> _rooms = [];

  bool _isSelectionMode = false;
  final Set<String> _selectedRoomIds = {};

  Map<String, double> _roomWattMap = {};
  double _totalAllWatt = 0;
  bool _isLoadingUsage = true;

  

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _fetchRooms();
    _fetchUsageHistory();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _retryTimer?.cancel();
    super.dispose();
  }

  // ================= USER =================

  Future<void> _loadUsername() async {
    if (UserCache.isReady) {
      setState(() {
        user = UserCache.user;
        username = UserCache.username;
      });
      return;
    }

    if (_isFetchingUser) return;
    _isFetchingUser = true;

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final response = await supabase
          .from('profiles')
          .select('username, fullname, avatar_url')
          .eq('user_id', currentUser.id)
          .single();

      UserCache.user = currentUser;
      UserCache.email = currentUser.email;
      UserCache.username = response['username'];
      UserCache.fullname = response['fullname'];
      UserCache.avatarUrl = response['avatar_url'];

      if (!mounted) return;

      setState(() {
        user = currentUser;
        username = response['username'];
      });

      _retryTimer?.cancel();
    } catch (e) {
      debugPrint("Fetch user error: $e");
    } finally {
      _isFetchingUser = false;
    }
  }

  // ================= ROOMS =================

  Future<void> _fetchRooms() async {
    try {
      final res = await ApiClient.dio.get('/rooms');
      final data = res.data;

      if (data is List) {
        _rooms = data;
      } else if (data is Map && data['data'] is List) {
        _rooms = data['data'];
      }
    } catch (e) {
      debugPrint("Fetch rooms error: $e");
    }

    if (!mounted) return;
    setState(() => _isLoadingRooms = false);
  }

  Future<void> _fetchUsageHistory() async {
    try {
      setState(() {
        _isLoadingUsage = true;
      });

      final now = DateTime.now();

      final response = await ApiClient.dio.get(
        '/usage',
        queryParameters: {
          "mode": "history",
          "range": "day", // bisa day/month sesuai kebutuhan
          "date": now.toIso8601String().split('T').first,
        },
      );

      final data = response.data;

      final List rooms = data["rooms"] ?? [];

      double total = 0;
      final Map<String, double> map = {};

      for (var room in rooms) {
        final roomId = room["roomId"].toString();
        final watt = (room["totalWatt"] ?? 0).toDouble();

        map[roomId] = watt;
        total += watt;
      }

      setState(() {
        _roomWattMap = map;
        _totalAllWatt = total;
      });

    } catch (e) {
      debugPrint("Fetch usage error: $e");
    } finally {
      setState(() {
        _isLoadingUsage = false;
      });
    }
  }

  Future<void> _refreshRooms() async {
    setState(() {
      _isLoadingRooms = true;
      _isSelectionMode = false;
      _selectedRoomIds.clear();
    });

    try {
      final res = await ApiClient.dio.get('/rooms');
      final data = res.data;

      if (data is List) {
        _rooms = data;
      } else if (data is Map && data['data'] is List) {
        _rooms = data['data'];
      }
    } catch (e) {
      debugPrint("Refresh rooms error: $e");
    }

    for (final room in _rooms) {
      final roomMap = room is Map ? room : {};
      final url = (roomMap['image_url'] ?? '').toString();
      if (url.isNotEmpty) {
        await NetworkImage(url).evict();
      }
    }

    await _fetchUsageHistory();

    if (!mounted) return;
    setState(() => _isLoadingRooms = false);
  }

  Future<void> _deleteSelectedRooms() async {
    if (_selectedRoomIds.isEmpty) return;

    final selectedRooms = _rooms.where((room) {
      final map = room is Map ? room: {};
      final id = (map['id'] ?? map['room_id'] ?? '').toString();
      return _selectedRoomIds.contains(id);
    }).toList();

    if (selectedRooms.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        title: const Text("Delete room?",
        style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
        ),
        content: Text(
            "You are about to delete ${selectedRooms.length} rooms. This action cannot be undone.",
            style: const TextStyle(color: Colors.black),
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel",
            style: TextStyle(color: Color(0xFF838383)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete",
                style: TextStyle(color: Color.fromARGB(255, 255, 0, 0)),
                ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    for (final room in selectedRooms) {
      final id = (room['id'] ?? room['room_id'] ?? '').toString();
      if (id.isEmpty) continue;
      await ApiClient.dio.delete('/rooms/$id');
    }

    await _refreshRooms();
  }

  // ================= UI =================

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
            _usageHeader(),
            const SizedBox(height: 12),
            _roomGrid(),
          ],
        ),
      ),
    );
  }

  Widget _usageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _isSelectionMode
            ? Text("${_selectedRoomIds.length} selected",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18))
            : const Text("Usage by room",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
        Row(
          children: [
            if (_isSelectionMode && _selectedRoomIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete, color:Color(0xFFFF0000)),
                onPressed: _deleteSelectedRooms,
              ),
            if (!_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const AddRoom()),
                  );

                  if (result == true) {
                    await _refreshRooms();
                  }
                },
              ),
            IconButton(
              icon: Icon(
                  _isSelectionMode ? Icons.close : Icons.more_vert),
              onPressed: () {
                setState(() {
                  _isSelectionMode = !_isSelectionMode;
                  _selectedRoomIds.clear();
                });
              },
            )
          ],
        )
      ],
    );
  }

  Widget _roomGrid() {
    if (_isLoadingRooms || _isLoadingUsage) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_rooms.isEmpty) {
      return const Text("No rooms yet. Add your first room.");
    }

    final sortedRooms = List.from(_rooms);

    sortedRooms.sort((a, b) {
      final mapA = a is Map ? a : {};
      final mapB = b is Map ? b : {};

      final idA = (mapA['id'] ?? mapA['room_id'] ?? '').toString();
      final idB = (mapB['id'] ?? mapB['room_id'] ?? '').toString();

      final wattA = _roomWattMap[idA] ?? 0;
      final wattB = _roomWattMap[idB] ?? 0;

      return wattB.compareTo(wattA); // descending
    });

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: sortedRooms.asMap().entries.map((entry) {
        final index = entry.key;
        final room = entry.value;

        final roomMap = room is Map ? room : <String, dynamic>{};
        final roomName = (roomMap['name'] ?? '-').toString();
        final roomId =
            (roomMap['id'] ?? roomMap['room_id'] ?? '').toString();
        final roomImageUrl = (roomMap['image_url'] ?? '').toString();

        final roomWatt = _roomWattMap[roomId] ?? 0;

        final percentage = _totalAllWatt == 0
          ? 0
          : ((roomWatt / _totalAllWatt) * 100).round();

        return GestureDetector(
          onTap: () async {
            if (_isSelectionMode) {
              setState(() {
                _selectedRoomIds.contains(roomId)
                    ? _selectedRoomIds.remove(roomId)
                    : _selectedRoomIds.add(roomId);
              });
            } else {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeOfficePage(
                    roomId: roomId,
                    roomName: roomName,
                    imageUrl: roomImageUrl,
                  ),
                ),
              );

              if (result == true) {
                await _refreshRooms();
              }
            }
          },
          child: Stack(
            children: [
              RoomUsageCard(
                percentage: percentage,
                label: roomName,
                imagePath: roomImageUrl.isNotEmpty
                  ? roomImageUrl
                  : "assets/images/home.jpeg",
              ),
              if (_isSelectionMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor:
                        _selectedRoomIds.contains(roomId)
                            ? Colors.blue
                            : Colors.white,
                    child: _selectedRoomIds.contains(roomId)
                        ? const Icon(Icons.check,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: UserCache.avatarUrl != null &&
                    UserCache.avatarUrl!.isNotEmpty
                ? NetworkImage(UserCache.avatarUrl!)
                : const AssetImage("assets/icon/profile.jpg")
                    as ImageProvider,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 18,
                child: AnimatedTextKit(
                  repeatForever: true,
                  pause: const Duration(milliseconds: 1000),
                  animatedTexts: [
                    TyperAnimatedText("Hi",
                        textStyle:
                            TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Halo",
                        textStyle:
                            TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Bonjour",
                        textStyle:
                            TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Hola",
                        textStyle:
                            TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Aloha",
                        textStyle:
                            TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("您好",
                        textStyle:
                            TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("こんにちは",
                        textStyle:
                            TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("안녕하세요",
                        textStyle:
                            TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Zdravstvuyte",
                        textStyle:
                            TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Sàwàtdee",
                        textStyle:
                            TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Guten Tag",
                        textStyle:
                            TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Ciao",
                        textStyle:
                            TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("مرحبا",
                        textStyle:
                            TextStyle(fontSize: 14, color: Colors.grey)),
                    TyperAnimatedText("Olá",
                        textStyle:
                            TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                username ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}