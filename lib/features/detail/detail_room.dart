import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'apiclient.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class HomeOfficePage extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String imageUrl;

  const HomeOfficePage({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.imageUrl,
  });

  @override
  State<HomeOfficePage> createState() => _HomeOfficePageState();
}
class Item {
  final String id;
  final String name;
  final List<String> usageDays;
  final String startTime;
  final String endTime;
  final int usageWatt;
  bool isLocal;

  Item({
    required this.id,
    required this.name,
    required this.usageDays,
    required this.startTime,
    required this.endTime,
    required this.usageWatt,
    this.isLocal = false,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['item_id'],
      name: json['name'],
      usageDays: List<String>.from(json['usage_days']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      usageWatt: (json['usage_watt'] as num).toInt(),
    );
  }
}

final Map<String, List<Item>> _roomItemsCache = {};

class _HomeOfficePageState extends State<HomeOfficePage> {
  TimeOfDay startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 0, minute: 0);
  bool _isEditingTitle = false;
  late TextEditingController _titleController;
  late String roomTitle;
  Item? selectedItem;
  bool isSaving = false;
  bool isDeleting = false;
  bool isRenaming = false;
  File? headerImage;
  final ImagePicker _picker = ImagePicker();
  String? imageUrl;
  bool isUploadingImage = false;
  bool _hasChanged = false;

  final Map<String, bool> days = {
    "Sunday": false,
    "Monday": false,
    "Tuesday": false,
    "Wednesday": false,
    "Thursday": false,
    "Friday": false,
    "Saturday": false,
    "Every day": false,
  };

  final dayList = [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Every day",
  ];


  List<Item> items = [];
  bool isLoading = true;

  final TextEditingController energyController =
  TextEditingController(text: "0");

  double energyUsage = 0.0;

  @override
  void initState() {
    super.initState();
    roomTitle = widget.roomName;
    _titleController = TextEditingController(text: roomTitle);

    imageUrl = widget.imageUrl;

    if (_roomItemsCache.containsKey(widget.roomId)) {
      items = _roomItemsCache[widget.roomId]!;

      if (items.isNotEmpty) {
        _loadItemToUI(items.first);
      }

      isLoading = false;
    } else {
      fetchItems();
    }
  }

  Future<void> _pickHeaderImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    final file = File(picked.path);

    setState(() {
      headerImage = file;
      isUploadingImage = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      if (imageUrl != null && imageUrl!.isNotEmpty) {
      final uri = Uri.parse(imageUrl!);
      final oldPath = uri.pathSegments
          .skipWhile((segment) => segment != 'rooms-image')
          .skip(1)
          .join('/');

      if (oldPath.isNotEmpty) {
        await supabase.storage
            .from('rooms-image')
            .remove([oldPath]);
      }
    }

    final extension = file.path.split('.').last;
    final randomName =
        "${widget.roomId}_${DateTime.now().millisecondsSinceEpoch}.$extension";

    final newPath = "$userId/$randomName";


      await supabase.storage
        .from('rooms-image')
        .upload(newPath, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl =
        supabase.storage
          .from('rooms-image')
          .getPublicUrl(newPath);

      await ApiClient.dio.patch(
        '/rooms/${widget.roomId}',
        data: {
          "image_url": publicUrl,
        },
      );

      if (!mounted) return;

      setState(() {
        imageUrl = publicUrl;
        headerImage = null;
        _hasChanged = true;
      });
    } catch (e) {
      debugPrint("Upload header image error : $e");

      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to upload image")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploadingImage = false;
        });
      }
    }
  }

  void _loadItemToUI(Item item) {
    selectedItem = item;

    energyUsage = item.usageWatt.toDouble();
    energyController.text = item.usageWatt.toString();

    final start = item.startTime.split(":");
    startTime = TimeOfDay(
      hour: int.parse(start[0]),
      minute: int.parse(start[1]),
    );

    final end = item.endTime.split(":");
    endTime = TimeOfDay(
      hour: int.parse(end[0]),
      minute: int.parse(end[1]),
    );

    for (var key in days.keys) {
      days[key] = false;
    }

    for (var day in item.usageDays) {
      final formatted =
          day[0].toUpperCase() + day.substring(1).toLowerCase();
      if (days.containsKey(formatted)) {
        days[formatted] = true;
      }
    }

    final allChecked = days.entries
        .where((e) => e.key != "Every day")
        .every((e) => e.value);

    days["Every day"] = allChecked;
  }

  Future<void> fetchItems() async {
    try {
      final res = await ApiClient.dio
        .get('/rooms/${widget.roomId}/items');
      final data = res.data as List;

      items = data.map((e) => Item.fromJson(e)).toList();

      _roomItemsCache[widget.roomId] = items;

      if (items.isNotEmpty) {
        _loadItemToUI(items.first);
      }
    } catch (e) {
      debugPrint("Fetch items error: $e");
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    energyController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveTitle() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) return;

    setState(() => isRenaming = true);

    try {
      await ApiClient.dio.patch(
        '/rooms/${widget.roomId}',
        data: {"name": newTitle},
      );

      if (!mounted) return;

      setState(() {
        roomTitle = newTitle;
        _isEditingTitle = false;
        _hasChanged = true;
      });
    } finally {
      if (mounted) {
        setState(() => isRenaming = false);
      }
    }
  }

  void _showAddDeviceDialog() {
    final TextEditingController deviceController =
    TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add New Device",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: deviceController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Color(0xFF838383)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        final newDevice = deviceController.text.trim();
                        if (newDevice.isEmpty) return;

                        final tempItem = Item(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: newDevice,
                          usageDays: [],
                          startTime: "${startTime.hour.toString().padLeft(2,'0')}:${startTime.minute.toString().padLeft(2,'0')}:00",
                          endTime: "${endTime.hour.toString().padLeft(2,'0')}:${endTime.minute.toString().padLeft(2,'0')}:00",
                          usageWatt: 0,
                          isLocal: true,
                        );

                        setState(() {
                          items.add(tempItem);
                          selectedItem = tempItem;

                          startTime = const TimeOfDay(hour: 0, minute: 0);
                          endTime = const TimeOfDay(hour: 0, minute: 0);

                          for (var key in days.keys) {
                            days[key] = false;
                          }

                          energyUsage = 0;
                          energyController.text = "0";
                        });

                        Navigator.pop(context, true);
                      },
                      child: const Text(
                        "Add",
                        style: TextStyle(color: Color(0xFF2B599C)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _renameItem(String newName) async {
    setState(() => isRenaming = true);

    try {
      await ApiClient.dio.patch(
        '/rooms/${widget.roomId}/items/${selectedItem!.id}',
        data: {"name": newName},
      );

      setState(() {
        selectedItem = Item(
          id: selectedItem!.id,
          name: newName,
          usageDays: selectedItem!.usageDays,
          startTime: selectedItem!.startTime,
          endTime: selectedItem!.endTime,
          usageWatt: selectedItem!.usageWatt,
        );

        final index =
        items.indexWhere((e) => e.id == selectedItem!.id);

        if (index != -1) {
          items[index] = selectedItem!;
        }
      });
    } finally {
      if (mounted) {
        setState(() => isRenaming = false);
      }
    }
  }

  Future<void> pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: Colors.white,
              hourMinuteTextColor: Colors.black,
              dialHandColor: const Color(0xFFF2B599C),
              dialBackgroundColor: Colors.white,
              entryModeIconColor: Colors.blue,
              dayPeriodColor: Colors.blue.shade100,
              dayPeriodTextColor: Colors.blue.shade900,
            ),
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFF2B599C),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || picked == null) return;

    setState(() {
      if (isStart) {
        startTime = picked;
      } else {
        endTime = picked;
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanged);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F5F9),
        body: Stack(
          children: [
            Column(
              children: [
                _header(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _deviceTabs(),
                        const SizedBox(height: 12),
                        if (selectedItem != null) ...[
                          _mainCard(),
                          const SizedBox(height: 16),
                          _saveButton(),
                          const SizedBox(height: 24)
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (isDeleting || isRenaming)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(

                  ),
                ),
              ),

            if (isUploadingImage)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                  ),
                ),
              ),
          ],
        ),
      )
    );
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      child: Stack(
        children: [
          headerImage != null
              ? Image.file(
            headerImage!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          )
              : imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    "assets/images/home.jpeg",
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context, _hasChanged),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: _isEditingTitle
                      ? TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _saveTitle(),
                  )
                      : Text(
                    roomTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  icon: Icon(
                    _isEditingTitle ? Icons.check : Icons.edit,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    if (_isEditingTitle) {
                      await _saveTitle();
                    } else {
                      setState(() {
                        _isEditingTitle = true;
                      });
                    }
                  },
                ),

                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () {
                    _pickHeaderImage();
                  },
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _addDeviceChip() {
  return InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: _showAddDeviceDialog,
    child: Container(
      width: 40,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Icon(
          Icons.add,
          size: 20,
        ),
      ),
    ),
  );
}

  Widget _deviceTabs() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _addDeviceChip(),

          const SizedBox(width: 8),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _chip(item),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(Item item) {
    final isActive = selectedItem?.id == item.id;

    return ChoiceChip(
        label: Text(item.name),
        selected: isActive,
        showCheckmark: false,
        selectedColor: Colors.blue[700],
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isActive ? Colors.white : Colors.black,
        ),
        onSelected: (_) {
          final selectedItem =
          items.firstWhere((e) => e.id == item.id);

          setState(() {
            _loadItemToUI(selectedItem);
          });
        }
    );
  }

  Widget _mainCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _outerCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Schedule",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) async {
                    if (value == "delete") {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text("Delete Item"),
                            content: const Text(
                                "Are you sure you want to delete this item?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel", style: TextStyle(color: Color(0xFF838383)),),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Color(0xFFFF00000)),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                      if (confirm == true) {
                        setState(() => isDeleting = true);

                        try {
                          await ApiClient.dio.delete(
                            '/rooms/${widget.roomId}/items/${selectedItem!.id}',
                          );

                          setState(() {
                            items.removeWhere((e) => e.id == selectedItem!.id);

                            _roomItemsCache[widget.roomId] = items;

                            if (items.isNotEmpty) {
                              _loadItemToUI(items.first);
                            } else {
                              selectedItem = null;
                            }
                          });
                        } finally {
                          if (mounted) {
                            setState(() => isDeleting = false);
                          }
                        }
                      }
                    }
                    if (value == "rename") {
                      final item = selectedItem!;
                      final controller = TextEditingController(text: item.name);

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text("Rename Item"),
                            content: TextField(
                              controller: controller,
                              autofocus: true,
                              decoration: const InputDecoration(
                                labelText: "Item name",
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel", style: TextStyle(color: Color(0xFF838383)),),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Save", style: TextStyle(color: Color(0xFF092C4C)),),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true && controller.text.trim().isNotEmpty) {
                        await _renameItem(controller.text.trim());
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: "rename",
                      child: Text("Rename Items"),
                    ),
                    PopupMenuItem(
                      value: "delete",
                      child: Text("Delete Items"),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _timeBox(
                  "Start Time",
                  startTime.format(context),
                      () => pickTime(true),
                ),
                const SizedBox(width: 12),
                _timeBox(
                  "End Time",
                  endTime.format(context),
                      () => pickTime(false),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Usage Days",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: dayList.map((day) {
                    return SizedBox(
                      width: itemWidth,
                      child: Row(
                        children: [
                          Checkbox(
                            value: days[day],
                            activeColor: const Color(0xFF2B599C),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) {
                              setState(() {
                                days[day] = val!;

                                if (day == "Every day") {
                                  for (var key in days.keys) {
                                    days[key] = val;
                                  }
                                } else {
                                  final allChecked = days.entries
                                      .where((e) => e.key != "Every day")
                                      .every((e) => e.value == true);

                                  days["Every day"] = allChecked;
                                }
                              });
                            },

                          ),
                          Expanded(
                            child: Text(
                              day,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            const Text(
              "Energy Usage",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: _innerCardDecoration(),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Energy Usage"),
                        Text(
                          "Update manually",
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: energyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        suffixText: " Watt",
                        suffixStyle: TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          energyUsage = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeBox(String title, String time, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: _innerCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _saveButton() {
    final item = selectedItem!;

    final isUpdate = !item.isLocal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: isSaving
              ? null
              : () async {
            setState(() => isSaving = true);

            try {
              if (item.isLocal) {
                await ApiClient.dio.post(
                  '/rooms/${widget.roomId}/items',
                  data: {
                    "name": item.name,
                    "usage_days": days.entries
                        .where((e) =>
                    e.value && e.key != "Every day")
                        .map((e) => e.key.toLowerCase())
                        .toList(),
                    "start_time":
                    "${startTime.hour.toString().padLeft(2,'0')}:${startTime.minute.toString().padLeft(2,'0')}",
                    "end_time":
                    "${endTime.hour.toString().padLeft(2,'0')}:${endTime.minute.toString().padLeft(2,'0')}",
                    "usage_watt": energyUsage.toInt(),
                  },
                );
              } else {
                await ApiClient.dio.patch(
                  '/rooms/${widget.roomId}/items/${item.id}',
                  data: {
                    "usage_days": days.entries
                        .where((e) =>
                    e.value && e.key != "Every day")
                        .map((e) => e.key.toLowerCase())
                        .toList(),
                    "start_time":
                    "${startTime.hour.toString().padLeft(2,'0')}:${startTime.minute.toString().padLeft(2,'0')}",
                    "end_time":
                    "${endTime.hour.toString().padLeft(2,'0')}:${endTime.minute.toString().padLeft(2,'0')}",
                    "usage_watt": energyUsage.toInt(),
                  },
                );
              }

              await fetchItems();
              _roomItemsCache[widget.roomId] = items;

              _hasChanged = true;
            } finally {
              if (mounted) {
                setState(() => isSaving = false);
              }
            }
          },
          child: isSaving
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : Text(
            isUpdate ? "Update Schedule" : "Save",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _outerCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  BoxDecoration _innerCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
