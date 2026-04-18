import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:limit_kuota/src/core/data/database_helper.dart';
import 'package:limit_kuota/src/core/services/intent_helper.dart';
import 'package:limit_kuota/src/features/monitoring/history_page.dart';

class Network extends StatefulWidget {
  const Network({super.key});

  @override
  State<Network> createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  static const platform = MethodChannel('limit_kuota/channel');

  String wifiUsage = "0.00 MB";
  String mobileUsage = "0.00 MB";

  // 🔥 TAMBAHAN BULANAN
  String wifiMonth = "0.00 MB";
  String mobileMonth = "0.00 MB";

  Future<void> fetchUsage() async {
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod(
        'getTodayUsage',
      );

      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      int wifiBytes = result['wifi'] ?? 0;
      int mobileBytes = result['mobile'] ?? 0;

      await DatabaseHelper.instance.insertOrUpdate(
        todayDate,
        wifiBytes,
        mobileBytes,
      );

      // 🔥 AMBIL DATA BULANAN
      String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

      final monthlyData = await DatabaseHelper.instance
          .getMonthlyUsage(currentMonth);

      setState(() {
        wifiUsage = _formatBytes(result['wifi']);
        mobileUsage = _formatBytes(result['mobile']);

        // 🔥 UPDATE BULANAN
        wifiMonth = _formatBytes(monthlyData["wifi"]!);
        mobileMonth = _formatBytes(monthlyData["mobile"]!);
      });
    } on PlatformException catch (e) {
      if (e.code == "PERMISSION_DENIED") {
        _showPermissionDialog();
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0.00 MB";
    double mb = bytes / (1024 * 1024);
    if (mb > 1024) {
      return "${(mb / 1024).toStringAsFixed(2)} GB";
    }
    return "${mb.toStringAsFixed(2)} MB";
  }

  Future<void> checkLimitAndWarn(int currentUsage) async {
    int limitInBytes = 1024 * 1024 * 1024;

    if (currentUsage >= limitInBytes) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Batas Kuota Tercapai!"),
          content: const Text(
            "Penggunaan data Anda sudah mencapai limit. "
            "Silakan aktifkan 'Set Data Limit' di pengaturan sistem.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Nanti"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                IntentHelper.openDataLimitSettings();
              },
              child: const Text("Buka Pengaturan"),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _usageCard("WiFi Today", wifiUsage, Icons.wifi),
            const SizedBox(height: 20),
            _usageCard("Mobile Today", mobileUsage, Icons.signal_cellular_alt),

            // 🔥 TAMBAHAN BULANAN
            const SizedBox(height: 30),
            _usageCard("WiFi This Month", wifiMonth, Icons.calendar_month),
            const SizedBox(height: 20),
            _usageCard("Mobile This Month", mobileMonth, Icons.date_range),

            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: fetchUsage,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _usageCard(String title, String value, IconData icon) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.blue),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                value,
                style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Izin Diperlukan"),
          content: const Text(
            "Aplikasi membutuhkan izin 'Akses Penggunaan' untuk membaca statistik data internet.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                fetchUsage();
              },
              child: const Text("Buka Pengaturan"),
            ),
          ],
        );
      },
    );
  }
}