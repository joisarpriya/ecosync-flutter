import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EcoSyncApp());
}

class EcoSyncApp extends StatelessWidget {
  const EcoSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoSync',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const AuthGate(),
    );
  }
}

//// ================= AUTH =================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.hasData) return const HomePage();
        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool isLogin = true;

  Future<void> submit() async {
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email.text, password: pass.text);
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email.text, password: pass.text);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 320,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text("EcoSync Login",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),
                TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: submit, child: Text(isLogin ? "Login" : "Register")),
                TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(isLogin
                        ? "Create Account"
                        : "Already have account? Login")),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

//// ================= HOME =================

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  Timer? simTimer;

  final pages = const [
    DashboardPage(),
    HistoryPage(),
    InsightsPage(),
    SmartMapPage(),
    BluetoothPage(),
  ];

  @override
  void initState() {
    super.initState();
    startSimulation();
  }

  void startSimulation() {
    final devices = FirebaseFirestore.instance.collection('devices').doc('room1');
    final history = FirebaseFirestore.instance.collection('history');
    final tips = FirebaseFirestore.instance.collection('ai_tips').doc('latest');

    simTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final r = Random();
      final energy = 40 + r.nextDouble() * 60;
      final aqi = 50 + r.nextInt(120);

      await devices.set({
        'energy': energy,
        'aqi': aqi,
      }, SetOptions(merge: true));

      await history.add({'energy': energy, 'aqi': aqi, 'time': Timestamp.now()});

      String tip = "All systems normal.";
      if (energy > 90) tip = "High power usage detected. Turn off unused devices.";
      if (aqi > 140) tip = "Air quality is poor. Avoid outdoor exposure.";

      await tips.set({'tip': tip});
    });
  }

  @override
  void dispose() {
    simTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'History'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.bluetooth), label: 'Bluetooth'),
        ],
      ),
    );
  }
}

//// ================= DASHBOARD =================

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final doc = FirebaseFirestore.instance.collection('devices').doc('room1');

    return StreamBuilder<DocumentSnapshot>(
      stream: doc.snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final d = (snap.data!.data() as Map?) ?? {};

        final energy = (d['energy'] ?? 0).toDouble();
        final aqi = (d['aqi'] ?? 0).toInt();

        bool light = d['light'] ?? false;
        bool fan = d['fan'] ?? false;
        bool ac = d['ac'] ?? false;
        bool tv = d['tv'] ?? false;

        double bill = energy * 0.12;

        return Scaffold(
          appBar: AppBar(
            title: const Text("EcoSync Dashboard"),
            actions: [
              IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () => generatePdf(context)),
              IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => FirebaseAuth.instance.signOut()),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Row(children: [
                  infoCard("Energy", "${energy.toStringAsFixed(1)} W", Icons.bolt),
                  const SizedBox(width: 10),
                  infoCard("AQI", "$aqi", Icons.air),
                ]),
                const SizedBox(height: 12),
                Text("Estimated Bill: ₹${bill.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  deviceSwitch("Light", light, (v) => doc.update({'light': v})),
                  deviceSwitch("Fan", fan, (v) => doc.update({'fan': v})),
                  deviceSwitch("AC", ac, (v) => doc.update({'ac': v})),
                  deviceSwitch("TV", tv, (v) => doc.update({'tv': v})),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget infoCard(String t, String v, IconData i) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Icon(i, size: 32),
            const SizedBox(height: 8),
            Text(t),
            Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  Widget deviceSwitch(String t, bool v, Function(bool) f) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Column(children: [
          Text(t),
          Switch(value: v, onChanged: f),
        ]),
      ),
    );
  }
}

//// ================= HISTORY =================

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('history')
        .orderBy('time', descending: true)
        .limit(25);

    return Scaffold(
      appBar: AppBar(title: const Text("Energy vs AQI Trends")),
      body: StreamBuilder<QuerySnapshot>(
        stream: q.snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.reversed.toList();

          final energy = <FlSpot>[];
          final aqi = <FlSpot>[];

          for (int i = 0; i < docs.length; i++) {
            final d = docs[i].data() as Map;
            energy.add(FlSpot(i.toDouble(), (d['energy'] ?? 0).toDouble()));
            aqi.add(FlSpot(i.toDouble(), (d['aqi'] ?? 0).toDouble()));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(LineChartData(
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true)),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true)),
              ),
              lineBarsData: [
                LineChartBarData(spots: energy, color: Colors.orange, barWidth: 3),
                LineChartBarData(spots: aqi, color: Colors.blue, barWidth: 3),
              ],
            )),
          );
        },
      ),
    );
  }
}

//// ================= INSIGHTS =================

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final doc = FirebaseFirestore.instance.collection('ai_tips').doc('latest');

    return Scaffold(
      appBar: AppBar(title: const Text("AI Energy Insights")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: doc.snapshots(),
        builder: (_, snap) {
          final tip = (snap.data?.get('tip')) ?? "Loading...";
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(tip, style: const TextStyle(fontSize: 18)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

//// ================= MAP (SIMULATED) =================

class SmartMapPage extends StatelessWidget {
  const SmartMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pollution Heat Map (Demo)")),
      body: const Center(child: Text("Map API can be integrated here")),
    );
  }
}


//// ================= BLUETOOTH =================

class BluetoothPage extends StatelessWidget {
  const BluetoothPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Device Pairing")),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth, size: 80),
            SizedBox(height: 12),
            Text("Scan & Pair Devices (Demo UI)"),
          ],
        ),
      ),
    );
  }
}


//// ================= PDF =================

Future<void> generatePdf(BuildContext context) async {
  final pdf = pw.Document();

  final snap = await FirebaseFirestore.instance
      .collection('history')
      .orderBy('time', descending: true)
      .limit(20)
      .get();

  pdf.addPage(pw.Page(
      build: (_) => pw.Column(children: [
            pw.Text("EcoSync Energy Report",
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...snap.docs.map((d) {
              final m = d.data() as Map;
              return pw.Text(
                  "Energy: ${m['energy']?.toStringAsFixed(1)}  AQI: ${m['aqi']}");
            })
          ])));

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
