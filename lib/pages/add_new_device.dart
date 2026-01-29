import 'package:flutter/material.dart';
import '../components/layout.dart';

class CalculatePage extends StatefulWidget {
  const CalculatePage({super.key});

  @override
  State<CalculatePage> createState() => _CalculatePageState();
}

class _CalculatePageState extends State<CalculatePage> {
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController usageController = TextEditingController();

  final Map<String, bool> usageDays = {
    'Sunday': false,
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
  };

  String selectedRoom = 'Select';

  Future<void> pickTime24({
    required BuildContext context,
    required TextEditingController controller,
  }) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text =
      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  void _onSave() {
    final selectedDays =
    usageDays.entries.where((e) => e.value).map((e) => e.key).toList();

    debugPrint('Item Name: ${itemNameController.text}');
    debugPrint('Room: $selectedRoom');
    debugPrint('Start Time: ${startTimeController.text}');
    debugPrint('End Time: ${endTimeController.text}');
    debugPrint('Usage (Watt): ${usageController.text}');
    debugPrint('Days: $selectedDays');
  }

  @override
  void dispose() {
    itemNameController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    usageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      buttonText: 'Save',
      onButtonPressed: _onSave,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter item name', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 6),

          TextField(
            controller: itemNameController,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text('Usage Days', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 6),

          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 3.2,
            children: usageDays.keys.map((day) {
              return InkWell(
                onTap: () {
                  setState(() {
                    usageDays[day] = !usageDays[day]!;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: usageDays[day],
                        visualDensity: VisualDensity.compact,
                        onChanged: (value) {
                          setState(() {
                            usageDays[day] = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(day, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          const Text('Start Time', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 6),

          TextField(
            controller: startTimeController,
            readOnly: true,
            onTap: () => pickTime24(
              context: context,
              controller: startTimeController,
            ),
            decoration: InputDecoration(
              hintText: 'HH:mm',
              suffixIcon: const Icon(Icons.access_time),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text('End Time', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 6),

          TextField(
            controller: endTimeController,
            readOnly: true,
            onTap: () => pickTime24(
              context: context,
              controller: endTimeController,
            ),
            decoration: InputDecoration(
              hintText: 'HH:mm',
              suffixIcon: const Icon(Icons.access_time),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text('Usage (Watt)', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 6),

          SizedBox(
            width: 120,
            child: TextField(
              controller: usageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),

                suffixIconConstraints: const BoxConstraints(
                  minHeight: 40,
                ),
                suffixIcon: SizedBox(
                  width: 60,
                  child: Center(
                    child: Text(
                      'Watt',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )

        ],
      ),
    );
  }
}
