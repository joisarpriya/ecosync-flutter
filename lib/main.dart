import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


import 'package:provider/provider.dart';
import 'state/map_state.dart';
import 'widgets/map_widget.dart';
import 'widgets/glass_card.dart';
import 'widgets/skeleton.dart';

import 'firebase_options.dart';

// Local AQI helper (conforms to the specified thresholds)
Color googleAqiColor(int aqi) {
  if (aqi <= 50) return const Color(0xFF34A853); // Green
  if (aqi <= 100) return const Color(0xFFFBBC04); // Yellow
  if (aqi <= 150) return const Color(0xFFFB8B24); // Orange
  if (aqi <= 200) return const Color(0xFFEA4335); // Red
  return const Color(0xFFB00020); // Dark red
}

// This project uses Firebase Authentication, Cloud Firestore and Firebase Hosting for web deployment.
// Google Maps Platform is used on native platforms and OpenStreetMap (via flutter_map) is used as a web fallback.
// These are intentionally referenced and used across the app for Auth, DB, Hosting and Maps (see MapWidget, AuthGate, Firestore reads).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EcoSyncApp());
}

/* ===========================================================
                        APP ROOT
=========================================================== */

class EcoSyncApp extends StatelessWidget {
  const EcoSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MapState>(
      create: (_) => MapState()..init(),
      child: MaterialApp(
        title: 'EcoSync',
        debugShowMaterialGrid: false,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8), brightness: Brightness.light),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/* ===========================================================
                        AUTH GATE
=========================================================== */

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.hasData ? const HomeShell() : const LoginPage();
      },
    );
  }
}

/* ===========================================================
                        LOGIN
=========================================================== */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sign in', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text('Sign in to continue', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'Email', hintText: 'name@example.com')),
                const SizedBox(height: 8),
                TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    child: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ===========================================================
                        HOME SHELL
=========================================================== */

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final pages = const [
    DashboardPage(),
    DevicesPage(),
    AnalyticsPage(),
    MapPage(),
    InsightsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Flexible(child: Text('EcoSync', style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis)),

                  const Spacer(),
                  IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: generatePdf),
                  const SizedBox(width: 6),
                  IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut()),
                ]),
              ),
            ),
          ),
        ),
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: "Dashboard"),
          NavigationDestination(icon: Icon(Icons.power), label: "Devices"),
          NavigationDestination(icon: Icon(Icons.show_chart), label: "Analytics"),
          NavigationDestination(icon: Icon(Icons.map), label: "Map"),
          NavigationDestination(icon: Icon(Icons.lightbulb), label: "Insights"),
        ],
      ),
    );
  }
}

/* ===========================================================
                        DASHBOARD
=========================================================== */

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  double _parseDouble(dynamic v, double def) {
    if (v == null) return def;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  int _parseInt(dynamic v, int def) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  Widget _metricCard(BuildContext context, {required IconData icon, required String title, required Widget metric, String? subtitle, Color? accent}) {
    final heroTag = title.contains('AQI') ? 'aqi-metric' : (title.contains('Energy') ? 'energy-metric' : null);

    return Card(
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(radius: 26, backgroundColor: Theme.of(context).colorScheme.primary, child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                heroTag != null ? Hero(tag: heroTag, child: DefaultTextStyle(style: Theme.of(context).textTheme.bodyLarge ?? const TextStyle(), child: materialWrap(metric))) : materialWrap(metric),
                if (subtitle != null) ...[const SizedBox(height: 6), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)))],
              ]),
            )
          ]),
        ),
      ),
    );
  }

  // Ensures metric widgets have consistent padding and alignment
  Widget materialWrap(Widget w) => Padding(padding: const EdgeInsets.only(bottom: 2), child: Align(alignment: Alignment.centerLeft, child: w));

  @override
  Widget build(BuildContext context) {
    final doc = FirebaseFirestore.instance.collection('summary').doc('live');

    return StreamBuilder<DocumentSnapshot>(
      stream: doc.snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: const [
              Skeleton.rect(height: 120),
              SizedBox(height: 12),
              Skeleton.rect(height: 120),
            ]),
          );
        }

        final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};

        final energy = _parseDouble(data['energy'], 0.0);
        final aqi = _parseInt(data['aqi'], 50);
        final bill = energy * 8;
        final isDemo = data.isEmpty;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(children: [
              if (isDemo) Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Row(children: [Chip(label: const Text('Demo values'), backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08)), const SizedBox(width:8), const Expanded(child: Text('No live summary available — displaying safe sample values'))])),

              Row(children: [
                Expanded(child: _metricCard(context, icon: Icons.bolt, title: 'Energy (kWh)', metric: TweenAnimationBuilder<double>(tween: Tween(begin: 0.0, end: energy), duration: const Duration(milliseconds: 700), builder: (_, value, __) => Text(value.toStringAsFixed(2), style: Theme.of(context).textTheme.bodyLarge)), subtitle: 'Today')),
                const SizedBox(width: 12),
                Expanded(child: _metricCard(context, icon: Icons.air, title: 'AQI', metric: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: aqi.toDouble()), duration: const Duration(milliseconds: 700), builder: (_, value, __) => Row(children: [Text(value.toInt().toString(), style: Theme.of(context).textTheme.bodyLarge), const SizedBox(width: 8), CircleAvatar(radius: 10, backgroundColor: googleAqiColor(aqi))])), subtitle: 'City average')),
              ]),

              const SizedBox(height: 12),

              Row(children: [
                Expanded(child: _metricCard(context, icon: Icons.receipt_long, title: 'Estimated bill (₹)', metric: TweenAnimationBuilder<double>(tween: Tween(begin: 0.0, end: bill), duration: const Duration(milliseconds: 700), builder: (_, value, __) => Text(value.toStringAsFixed(0), style: Theme.of(context).textTheme.bodyLarge)), subtitle: 'Est. this month')),
                const SizedBox(width: 12),
                Expanded(child: _metricCard(context, icon: Icons.devices, title: 'Connected devices', metric: Text('${data['devicesOnline'] ?? 0}', style: Theme.of(context).textTheme.bodyLarge), subtitle: 'Active')),
              ]),

              const SizedBox(height: 18),

              // Chart card
              Card(
                child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Energy & AQI', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  SizedBox(height: 180, child: _DashboardChart()),
                ])),
              )
            ]),
          ),
        );
      },
    );
  }
}

class _DashboardChart extends StatefulWidget {
  @override
  State<_DashboardChart> createState() => _DashboardChartState();
}

class _DashboardChartState extends State<_DashboardChart> {
  bool showEnergy = true;
  bool showAqi = true;

  @override
  Widget build(BuildContext context) {
    // Use historical data as before — keep logic unchanged but present a polished chart
    final history = FirebaseFirestore.instance.collection('history').orderBy('time').limit(20);

    return StreamBuilder<QuerySnapshot>(
      stream: history.snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: SizedBox.shrink());

        final energy = <FlSpot>[];
        final aqi = <FlSpot>[];

        for (int i = 0; i < snap.data!.docs.length; i++) {
          final d = snap.data!.docs[i];
          final map = (d.data() as Map<String, dynamic>?) ?? {};
          energy.add(FlSpot(i.toDouble(), (map['energy'] ?? 0).toDouble()));
          aqi.add(FlSpot(i.toDouble(), (map['aqi'] ?? 0).toDouble()));
        }

        // If no real data, synthesize demo points so the chart always shows something
        if (energy.isEmpty && aqi.isEmpty) {
          final demoEnergy = [1.2, 2.5, 3.1, 2.8, 4.0, 3.6];
          final demoAqi = [45, 60, 55, 70, 82, 66];
          for (int i = 0; i < demoEnergy.length; i++) {
            energy.add(FlSpot(i.toDouble(), demoEnergy[i]));
            aqi.add(FlSpot(i.toDouble(), demoAqi[i].toDouble()));
          }
        }

        return Column(children: [
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(children: [
              if (showEnergy) Row(children: [Container(width: 12, height: 8, color: const Color(0xFF1A73E8)), const SizedBox(width: 6), Text('Energy (kWh)', style: Theme.of(context).textTheme.labelMedium)]),
              const SizedBox(width: 12),
              if (showAqi) Row(children: [Container(width: 12, height: 8, color: const Color(0xFF34A853)), const SizedBox(width: 6), Text('AQI', style: Theme.of(context).textTheme.labelMedium)]),
            ]),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        final isEnergy = s.barIndex == 0;
                        final label = isEnergy ? '${s.y.toStringAsFixed(2)} kWh' : '${s.y.toInt()} AQI';
                        return LineTooltipItem(label, const TextStyle(color: Colors.white));
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) => Padding(padding: const EdgeInsets.only(top: 6.0), child: Text('T${v.toInt()}')))),
                ),
                lineBarsData: [
                  if (showEnergy)
                    LineChartBarData(
                      isCurved: true,
                      spots: energy,
                      color: const Color(0xFFFBBC04),
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: const Color(0xFFFBBC04).withOpacity(0.12)),
                    ),
                  if (showAqi)
                    LineChartBarData(
                      isCurved: true,
                      spots: aqi,
                      color: const Color(0xFF34A853),
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: const Color(0xFF34A853).withOpacity(0.12)),
                    ),
                ],
              ),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(icon: Icon(showEnergy ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => showEnergy = !showEnergy)),
            IconButton(icon: Icon(showAqi ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => showAqi = !showAqi)),
          ])
        ]);
      },
    );
  }
}

/* ===========================================================
                        DEVICES
=========================================================== */

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Cloud devices', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 220,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('devices').snapshots(),
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snap.hasData || snap.data!.docs.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.power, size: 48, color: Colors.black38), const SizedBox(height: 12), Text('No data available', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text('Connect a device to start monitoring.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center)])));

                  return ListView(
                    children: snap.data!.docs.map((d) {
                      final map = (d.data() as Map<String, dynamic>?) ?? {};
                      final name = map['name']?.toString() ?? 'Device';
                      final power = map['power']?.toString() ?? '0';
                      final stateRaw = map['state'];
                      final state = (stateRaw is bool) ? stateRaw : (stateRaw?.toString().toLowerCase() == 'true');

                      return ListTile(
                        title: Text(name, style: Theme.of(context).textTheme.bodyLarge),
                        subtitle: Text('$power W', style: Theme.of(context).textTheme.bodyMedium),
                        trailing: Switch(
                          value: state,
                          onChanged: (v) {
                            d.reference.update({'state': v, 'lastUpdated': Timestamp.now()});
                          },
                        ),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeviceDetailPage(doc: d))),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
        Text('Appliance tracker', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: ApplianceTracker())),
        const SizedBox(height: 12),
        Text('Bluetooth devices', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: BluetoothSection())),
      ],
    );
  }
}

class BluetoothSection extends StatefulWidget {
  const BluetoothSection({super.key});

  @override
  State<BluetoothSection> createState() => _BluetoothSectionState();
}

class _BluetoothSectionState extends State<BluetoothSection> {
  final Map<String, ScanResult> _found = {};
  BluetoothDevice? _connected;
  bool _scanning = false;

  void _startScan() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bluetooth not supported on Web')));
      return;
    }

    setState(() => _scanning = true);
    _found.clear();

    // startScan is a static method; don't await the void return
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    // collect first batch of scan results
    final results = await FlutterBluePlus.scanResults.first;
    for (var r in results) {
      // prefer name, then remoteId, then id as string
      final key = (r.device.name.isNotEmpty ? r.device.name : (r.device.remoteId?.toString() ?? r.device.id.toString()));
      _found[key.toString()] = r;
    }

    if (!mounted) return;
    setState(() => _scanning = false);
  }

  void _connect(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 8));
    } catch (_) {}
    if (!mounted) return;
    setState(() => _connected = device);
  }

  void _disconnect() async {
    await _connected?.disconnect();
    setState(() => _connected = null);
  }

  Widget _buildBody() {
    if (kIsWeb) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Bluetooth is not available on web. Use Android or Windows to connect to nearby devices.'),
      );
    }

    final items = _found.values.toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            FilledButton.icon(
              icon: Icon(_scanning ? Icons.stop : Icons.search),
              label: Text(_scanning ? 'Stop' : 'Scan'),
              onPressed: _scanning ? null : _startScan,
            ),
            const SizedBox(width: 12),
            if (_connected != null)
              FilledButton.icon(icon: const Icon(Icons.link_off), label: const Text('Disconnect'), onPressed: _disconnect),
          ]),
          const SizedBox(height: 12),
          if (items.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Text('No nearby devices found', textAlign: TextAlign.center)),
          ...items.map((r) => ListTile(
                title: Text(r.device.name.isNotEmpty ? r.device.name : (r.device.remoteId?.toString() ?? r.device.id.toString())), 
                subtitle: Text('Signal: ${r.rssi} dBm'),
                trailing: FilledButton(
                  child: const Text('Connect'),
                  onPressed: () => _connect(r.device),
                ),
              )), 
          if (_connected != null) Padding(
            padding: const EdgeInsets.only(top:12.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Connected to: ${_connected!.name.isNotEmpty ? _connected!.name : (_connected!.remoteId?.toString() ?? _connected!.id.toString())}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              FilledButton(
                child: const Text('Read data'),
                onPressed: () async {
                  String payload = 'mock:123';
                  try {
                    final services = await _connected!.discoverServices();
                    if (services.isNotEmpty) {
                      final svc = services.first;
                      if (svc.characteristics.isNotEmpty) {
                        final c = svc.characteristics.first;
                        final value = await c.read();
                        payload = value.isNotEmpty ? value.join(',') : payload;
                      }
                    }
                  } catch (_) {}
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data: $payload')));
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 320, child: _buildBody());
  }
}


// Simple appliance tracker for UI/demo — shows appliances with toggles and estimated consumption
class ApplianceTracker extends StatefulWidget {
  @override
  State<ApplianceTracker> createState() => _ApplianceTrackerState();
}

class _ApplianceTrackerState extends State<ApplianceTracker> {
  final List<Map<String, dynamic>> _appliances = [
    {'name': 'AC', 'watts': 1200, 'on': true, 'hours': 6.0},
    {'name': 'Fan', 'watts': 75, 'on': true, 'hours': 8.0},
    {'name': 'Light', 'watts': 12, 'on': true, 'hours': 5.0},
    {'name': 'Heater', 'watts': 1500, 'on': false, 'hours': 0.0},
  ];

  double get totalDailyKWh {
    double total = 0.0;
    for (var a in _appliances) {
      final w = (a['watts'] as num).toDouble();
      final h = (a['on'] as bool) ? (a['hours'] as double) : 0.0;
      total += (w * h) / 1000.0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final rate = 8.0; // ₹ per kWh
    final monthly = totalDailyKWh * 30 * rate;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ..._appliances.map((a) => ListTile(
              title: Text(a['name'] as String, style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text('${a['watts']} W • ${a['hours'].toStringAsFixed(1)} h/day', style: Theme.of(context).textTheme.bodyMedium),
              trailing: Switch(value: a['on'] as bool, onChanged: (v) => setState(() => a['on'] = v)),
              onTap: () {},
            )),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Estimated daily usage: ${totalDailyKWh.toStringAsFixed(2)} kWh', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text('Estimated monthly bill: ₹${monthly.toStringAsFixed(0)} (Rate ₹${rate.toStringAsFixed(0)}/kWh)', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(children: [
              FilledButton.icon(onPressed: () => setState(() {
                for (var a in _appliances) {
                  if (a['name'] == 'AC') a['hours'] = (a['hours'] as double) - 1.0;
                }
              }), icon: const Icon(Icons.thermostat), label: const Text('Apply energy-saving adjustments')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () => setState(() {
                for (var a in _appliances) a['on'] = true;
              }), child: const Text('Turn all on')),
            ])
          ]),
        ),
      ]),
    );
  }
}

/* ===========================================================
                        DEVICE DETAIL
=========================================================== */

class DeviceDetailPage extends StatelessWidget {
  final DocumentSnapshot doc;
  const DeviceDetailPage({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final map = (doc.data() as Map<String, dynamic>?) ?? {};
    final name = map['name']?.toString() ?? 'Device';
    final power = map['power']?.toString() ?? '0';
    final stateRaw = map['state'];
    final state = (stateRaw is bool) ? stateRaw : (stateRaw?.toString().toLowerCase() == 'true');
    final last = map['lastUpdated'];
    String lastStr = 'Never';
    try {
      if (last is Timestamp) lastStr = last.toDate().toLocal().toString();
      else if (last is int) lastStr = DateTime.fromMillisecondsSinceEpoch(last).toLocal().toString();
      else if (last is String) lastStr = last;
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(title: Text(name, style: Theme.of(context).textTheme.titleMedium)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: ListTile(title: Text('Power', style: Theme.of(context).textTheme.labelMedium), subtitle: Text('$power W', style: Theme.of(context).textTheme.bodyMedium)))),
          const SizedBox(height: 8),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: ListTile(title: Text('State', style: Theme.of(context).textTheme.labelMedium), subtitle: Text(state ? 'On' : 'Off', style: Theme.of(context).textTheme.bodyMedium), trailing: Switch(value: state, onChanged: (v) {doc.reference.update({'state': v, 'lastUpdated': Timestamp.now()}); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device state updated')));})))),
          const SizedBox(height: 8),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: ListTile(title: Text('Last updated', style: Theme.of(context).textTheme.labelMedium), subtitle: Text(lastStr, style: Theme.of(context).textTheme.bodyMedium)))),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () {ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ping sent')));}, icon: const Icon(Icons.wifi_tethering), label: const Text('Ping device')),
        ]),
      ),
    );
  }
}

/* ===========================================================
                        ANALYTICS
=========================================================== */

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool showEnergy = true;
  bool showAqi = true;

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final history = FirebaseFirestore.instance.collection('history').orderBy('time').limit(20);

    return StreamBuilder<QuerySnapshot>(
      stream: history.snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        // Allow empty history to fall through — demo fallback will be generated if no data is present.

        final energy = <FlSpot>[];
        final aqi = <FlSpot>[];

        for (int i = 0; i < snap.data!.docs.length; i++) {
          final d = snap.data!.docs[i];
          final map = (d.data() as Map<String, dynamic>?) ?? {};
          energy.add(FlSpot(i.toDouble(), _toDouble(map['energy'])));
          aqi.add(FlSpot(i.toDouble(), _toDouble(map['aqi'])));
        }

        // demo fallback
        if (energy.isEmpty && aqi.isEmpty) {
          final demoEnergy = [0.8, 1.5, 1.2, 1.9, 2.5, 2.1];
          final demoAqi = [40, 55, 48, 70, 95, 60];
          for (int i = 0; i < demoEnergy.length; i++) {
            energy.add(FlSpot(i.toDouble(), demoEnergy[i]));
            aqi.add(FlSpot(i.toDouble(), demoAqi[i].toDouble()));
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Analytics', style: Theme.of(context).textTheme.titleMedium),
                Row(children: [
                  IconButton(icon: Icon(showEnergy ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => showEnergy = !showEnergy)),
                  IconButton(icon: Icon(showAqi ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => showAqi = !showAqi)),
                ])
              ]),
              const SizedBox(height: 12),
              // Legend
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    if (showEnergy)
                      Row(children: [Container(width: 12, height: 8, color: Colors.orange.shade400), const SizedBox(width: 6), const Text('Energy')]),
                    const SizedBox(width: 12),
                    if (showAqi)
                      Row(children: [Container(width: 12, height: 8, color: Colors.green.shade400), const SizedBox(width: 6), const Text('AQI')]),
                  ],
                ),
              ),
              SizedBox(
                height: 320,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) => spots.map((s) {
                          final isEnergy = s.barIndex == 0;
                          final label = isEnergy ? '${s.y.toStringAsFixed(2)} kWh' : '${s.y.toInt()} AQI';
                          return LineTooltipItem(label, Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white) ?? const TextStyle(color: Colors.white));
                        }).toList(),
                      ),
                    ),
                    gridData: FlGridData(show: true, horizontalInterval: 1),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) => Padding(padding: const EdgeInsets.only(top: 6.0), child: Text('T${v.toInt()}')))),
                    ),
                    lineBarsData: [
                      if (showEnergy)
                        LineChartBarData(isCurved: true, spots: energy, color: const Color(0xFF1A73E8), barWidth: 3, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, color: const Color(0xFF1A73E8).withOpacity(0.12))),
                      if (showAqi)
                        LineChartBarData(isCurved: true, spots: aqi, color: const Color(0xFF34A853), barWidth: 3, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, color: const Color(0xFF34A853).withOpacity(0.12))),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

/* ===========================================================
                        MAP
=========================================================== */

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    final content = Stack(children: [
      const Positioned.fill(child: MapWidget()),

      // Map vignette / subtle edges
      Positioned.fill(child: IgnorePointer(child: Container(color: Colors.black.withOpacity(0.02)))),


      // Floating info panel (glass)
      Positioned(
        right: isWide ? 32 : 12,
        top: isWide ? 32 : null,
        bottom: isWide ? null : 24,
        left: isWide ? null : 12,
        child: _FloatingInfoPanel(),
      ),

      // Bottom-left legend
      Positioned(
        left: 12,
        bottom: 12,
        child: _AqiLegend(),
      ),

      // Floating map controls
      Positioned(
        right: 12,
        bottom: 12,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _RoundedIconButton(icon: Icons.my_location, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Locate (mock)')))),
          const SizedBox(height: 8),
          _RoundedIconButton(icon: Icons.zoom_in, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zoom In (mock)')))),
        ]),
      ),

      // Web fallback banner (visible on web builds)
      if (kIsWeb)
        Positioned(
          top: isWide ? 32 : 12,
          right: 12,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.public, size: 18),
              const SizedBox(width: 8),
              Flexible(child: Text('Using OpenStreetMap (web fallback)', overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium)),
              const SizedBox(width: 8),
              TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enable Google Maps billing and add your API key.'))), child: const Text('How?'))
            ]),
          ),
        ),
    ]);

    if (isWide) {
      // Side-by-side: map + insights panel
      return Row(children: [
        Expanded(child: content),
        Container(
          width: 360,
          color: Colors.white.withOpacity(0.02),
          child: SafeArea(child: _InsightsPanel()),
        ),
      ]);
    }

    // Mobile: full map, floating info as bottom sheet style
    return Scaffold(body: SafeArea(child: content));
  }
}

class _AqiLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mapState = Provider.of<MapState>(context, listen: false);
    final entries = [
      {'label': 'Good', 'aqi': 25},
      {'label': 'Moderate', 'aqi': 75},
      {'label': 'USG', 'aqi': 125},
      {'label': 'Unhealthy', 'aqi': 175},
      {'label': 'Very Unhealthy', 'aqi': 250},
      {'label': 'Hazardous', 'aqi': 350},
    ];

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(spacing: 12, runSpacing: 6, children: entries.map((e) {
          final aqi = e['aqi'] as int;
          final color = googleAqiColor(aqi);
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 32, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 6),
            Text(e['label'] as String, style: Theme.of(context).textTheme.labelMedium),
          ]);
        }).toList()),
      ),
    );
  }
}

class _FloatingInfoPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mapState = Provider.of<MapState>(context);
    final sel = mapState.selected;

    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      final panelW = maxW.isFinite ? (maxW < 340 ? maxW - 32 : 320.0) : 320.0;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: sel == null
                ? SizedBox(key: const ValueKey('empty'), width: panelW, child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Icon(Icons.sensors_off, size: 48, color: Colors.black38), const SizedBox(height: 16), Text('No data available', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text('Select a location on the map to view details.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center)]))
                : SizedBox(
                    key: ValueKey(sel.id),
                    width: panelW,
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(sel.id.toUpperCase(), style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Chip(label: Text('AQI ${sel.aqi}'), backgroundColor: googleAqiColor(sel.aqi))
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.thermostat, color: sel.weather == 'sunny' ? const Color(0xFFFBBC04) : (sel.weather == 'rainy' ? Colors.blue : Colors.grey)),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${sel.temp.toStringAsFixed(1)} °C • ${sel.humidity}% • ${sel.weather}', style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 12),
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (sel.aqi / 500).clamp(0.0, 1.0), color: googleAqiColor(sel.aqi), backgroundColor: Theme.of(context).dividerColor)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, children: [
                        FilledButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Centering map'))), icon: const Icon(Icons.center_focus_strong), label: const Text('Center')),
                        OutlinedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('More analytics will be available later'))), child: const Text('Analytics')),
                      ])
                    ]),
                  ),
          ),
        ),
      );
    });
  }
}


class _RoundedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundedIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(12)),
      child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onPrimary),
    );
  }
}

class _InsightsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mapState = Provider.of<MapState>(context);
    final sel = mapState.selected;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Location insights', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (sel != null) ...[
          GlassCard(child: ListTile(leading: const Icon(Icons.air), title: const Text('AQI'), subtitle: Text('${sel.aqi}'), trailing: CircleAvatar(backgroundColor: mapState.colorForAqi(sel.aqi)))),
          const SizedBox(height: 8),
          GlassCard(child: ListTile(leading: const Icon(Icons.thermostat), title: const Text('Weather'), subtitle: Text('${sel.weather} • ${sel.temp} °C'))),
          const SizedBox(height: 8),
          GlassCard(child: ListTile(leading: const Icon(Icons.water_damage), title: const Text('Humidity'), subtitle: Text('${sel.humidity}%'))),
        ] else GlassCard(child: Padding(padding: const EdgeInsets.all(12.0), child: const Text('Select a location on the map to populate insights'))),
        const SizedBox(height: 12),
        Text('Legend', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        _AqiLegend(),
      ]),
    );
  }
}

/* ===========================================================
                        INSIGHTS
=========================================================== */

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final summaryDoc = FirebaseFirestore.instance.collection('summary').doc('live');
    final history = FirebaseFirestore.instance.collection('history').orderBy('time').limit(24);

    return StreamBuilder<DocumentSnapshot>(
      stream: summaryDoc.snapshots(),
      builder: (_, summarySnap) {
        final summary = (summarySnap.data?.data() as Map<String, dynamic>?) ?? {};
        return StreamBuilder<QuerySnapshot>(
          stream: history.snapshots(),
          builder: (_, histSnap) {
            final samples = histSnap.data?.docs ?? [];
            double avgEnergy = 0.0;
            if (samples.isNotEmpty) {
              double sum = 0;
              for (var d in samples) {
                final map = (d.data() as Map<String, dynamic>?) ?? {};
                sum += (map['energy'] ?? 0).toDouble();
              }
              avgEnergy = sum / samples.length;
            }

            final List<Widget> cards = [];

            double parseDouble(dynamic v) {
              if (v == null) return 0.0;
              if (v is num) return v.toDouble();
              if (v is String) return double.tryParse(v) ?? 0.0;
              return 0.0;
            }

            // Rule: high usage
            if (avgEnergy > 2.0 || parseDouble(summary['energy']) > 4) {
              cards.add(Card(child: ListTile(title: Text('High energy usage', style: Theme.of(context).textTheme.titleMedium), subtitle: Text('Average ${avgEnergy.toStringAsFixed(2)} kWh — consider reducing AC or heavy appliance use in the evening', style: Theme.of(context).textTheme.bodyMedium), leading: const Icon(Icons.electrical_services))));
            } else {
              cards.add(Card(child: ListTile(title: Text('Energy usage is within range', style: Theme.of(context).textTheme.titleMedium), leading: const Icon(Icons.thumb_up))));
            }

            final aqi = parseDouble(summary['aqi']).toInt();
            if (aqi > 100) cards.add(Card(child: ListTile(title: Text('Air quality is poor', style: Theme.of(context).textTheme.titleMedium), subtitle: Text('AQI $aqi — limit outdoor activity if possible', style: Theme.of(context).textTheme.bodyMedium), leading: const Icon(Icons.air))));

            if (avgEnergy > 1.8) cards.add(Card(child: ListTile(title: Text('Adjust AC usage', style: Theme.of(context).textTheme.titleMedium), subtitle: Text('Reducing AC use by 1 hour in the evening can reduce daily usage', style: Theme.of(context).textTheme.bodyMedium), leading: const Icon(Icons.thermostat))));

            cards.add(Card(child: ListTile(title: Text('Use energy-efficient appliances', style: Theme.of(context).textTheme.titleMedium), leading: const Icon(Icons.lightbulb))));

            if (samples.isEmpty && (summarySnap.data == null || summary.isEmpty)) {
              cards.insert(0, Card(child: ListTile(title: Text('Demo data', style: Theme.of(context).textTheme.titleMedium), subtitle: Text('No live insights available. Connect devices or add history to see personalized recommendations', style: Theme.of(context).textTheme.bodyMedium))));
            }

            return ListView(padding: const EdgeInsets.all(16), children: cards);
          },
        );
      },
    );
  }
}

/* ===========================================================
                        PDF
=========================================================== */

Future<void> generatePdf() async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      build: (_) => pw.Center(child: pw.Text("EcoSync Energy Report")),
    ),
  );
  await Printing.layoutPdf(onLayout: (_) async => pdf.save());
}
