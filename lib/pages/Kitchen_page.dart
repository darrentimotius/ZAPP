import 'package:flutter/material.dart';
import 'add_new_device.dart';

class KitchenPage extends StatefulWidget {
  const KitchenPage({super.key});

  @override
  State<KitchenPage> createState() => _KitchenPageState();
}

class _KitchenPageState extends State<KitchenPage> {
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

  // Variabel untuk menyimpan device yang dipilih
  String selectedDevice = "Air Conditioner"; // default aktif

  // Energy Usage
  double energyUsage = 1.0; // default 1 kWh
  late TextEditingController energyController;

  @override
  void initState() {
    super.initState();
    energyController = TextEditingController(text: energyUsage.toString());
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // HEADER IMAGE
            Stack(
              children: [
                Image.asset(
                  'assets/images/kitchen.jpg', // gambar kitchen
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
                    "Kitchen",
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
                          ),
                          const SizedBox(width: 12),
                          _timeBox(
                            "End Time",
                            endTime.format(context),
                                () => pickTime(false),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // USAGE DAYS
                      const Text(
                        "Usage Days",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 10,
                        children: days.keys.map((day) {
                          return SizedBox(
                            width: 120,
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(day, style: const TextStyle(fontSize: 12)),
                              value: days[day],
                              onChanged: (val) {
                                setState(() => days[day] = val!);
                              },
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // ENERGY USAGE (Bisa diketik)
                      Card(
                        color: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.bolt, color: Colors.orange),
                          title: const Text("Energy Usage"),
                          subtitle: const Text("Update manually"),
                          trailing: SizedBox(
                            width: 80,
                            child: TextField(
                              controller: energyController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  energyUsage = double.tryParse(val) ?? 0;
                                });
                              },
                            ),
                          ),
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
                    print("Energy Usage: $energyUsage kWh");
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

  // Device chip
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

  // Time box
  Widget _timeBox(String title, String time, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
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