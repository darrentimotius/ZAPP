import 'package:flutter/material.dart';
import 'add_new_device.dart';

class HomeOfficePage extends StatefulWidget {
  const HomeOfficePage({super.key});

  @override
  State<HomeOfficePage> createState() => _HomeOfficePageState();
}

class _HomeOfficePageState extends State<HomeOfficePage> {
  TimeOfDay startTime = const TimeOfDay(hour: 21, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 6, minute: 0);

  Map<String, bool> days = {
    "Sunday": false,
    "Monday": false,
    "Tuesday": false,
    "Wednesday": false,
    "Thursday": false,
    "Friday": false,
    "Saturday": false,
  };

  String selectedDevice = "Air Conditioner"; // default aktif

  double? energyUsage; // mulai null
  late TextEditingController energyController;

  @override
  void initState() {
    super.initState();
    energyController = TextEditingController(text: ''); // kosong awal
  }

  @override
  void dispose() {
    energyController.dispose();
    super.dispose();
  }

  Future<void> pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxColor = Colors.white38; // abu seperti saat klik start time
    return Scaffold(
      backgroundColor: Colors.white, // halaman putih
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // HEADER IMAGE
            Stack(
              children: [
                Image.asset(
                  'assets/images/home_office.jpg',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 20,
                  left: 16,
                  child: Text(
                    "Home Office",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // DEVICE TABS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  _deviceChip("+"),
                  _deviceChip("Lamp"),
                  _deviceChip("Air Conditioner"),
                  _deviceChip("CCTV"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // MAIN CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // SCHEDULE
                      const Text(
                        "Schedule",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          _timeBox(
                            "Start Time",
                            startTime.format(context),
                                () => pickTime(true),
                            boxColor,
                          ),
                          const SizedBox(width: 12),
                          _timeBox(
                            "End Time",
                            endTime.format(context),
                                () => pickTime(false),
                            boxColor,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // USAGE DAYS 2 KOLom
                      const Text(
                        "Usage Days",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: days.keys.map((day) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: days[day],
                                onChanged: (val) {
                                  setState(() => days[day] = val!);
                                },
                              ),
                              Text(day, style: const TextStyle(fontSize: 12)),
                            ],
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // ENERGY USAGE (Container tipis, mirip start/end)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: boxColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Text("Energy Usage"),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: energyController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "0",
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    energyUsage = double.tryParse(val);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text("Watt"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // SAVE BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    print("Selected Device: $selectedDevice");
                    print("Start: ${startTime.format(context)}");
                    print("End: ${endTime.format(context)}");
                    print("Days: $days");
                    print("Energy Usage: ${energyUsage ?? 0} Watt");
                  },
                  child: const Text(
                      "Save",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white
                      )
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // DEVICE CHIP
  Widget _deviceChip(String text) {
    bool isSelected = selectedDevice == text;

    return GestureDetector(
      onTap: () {
        if (text == "+") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalculatePage()),
          );
        } else {
          setState(() {
            selectedDevice = text;
          });
        }
      },
      child: Chip(
        label: Text(text),
        backgroundColor: isSelected ? Colors.blue[700] : Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  // TIME BOX
  Widget _timeBox(String title, String time, VoidCallback onTap, Color? boxColor) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
