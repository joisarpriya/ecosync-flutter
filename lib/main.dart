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
import 'theme/theme_config.dart';
import 'state/map_state.dart';
import 'widgets/map_widget.dart';
import 'widgets/glass_card.dart';
import 'widgets/skeleton.dart';

import 'firebase_options.dart';

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
        debugShowCheckedModeBanner: false,
        theme: ThemeConfig.lightTheme(),
        darkTheme: ThemeConfig.darkTheme(),
        themeMode: ThemeMode.system,
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
          elevation: 8,
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("EcoSync Login", style: TextStyle(fontSize: 22)),
                TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),
                TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: loading ? null : login,
                  child: loading ? const CircularProgressIndicator() : const Text("Login"),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GlassCard(
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                const Text('EcoSync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: generatePdf),
                const SizedBox(width: 6),
                IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut()),
              ]),
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: 1.0,
          child: GlassCard(
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(gradient: ThemeConfig.primaryGradient, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(blurRadius: 18, color: Theme.of(context).colorScheme.primary.withOpacity(0.14), offset: const Offset(0, 8))]),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
                  const SizedBox(height: 8),
                  heroTag != null ? Hero(tag: heroTag, child: DefaultTextStyle(style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700), child: materialWrap(metric))) : materialWrap(metric),
                  if (subtitle != null) ...[const SizedBox(height: 6), Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)))],
                ]),
              )
            ]),
          ),
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

        final raw = snap.data?.data();
        final data = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};

        final energy = _parseDouble(data['energy'], 0.0);
        final aqi = _parseInt(data['aqi'], 50);
        final bill = energy * 8;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Expanded(child: _metricCard(context, icon: Icons.bolt, title: 'Energy (kWh)', metric: TweenAnimationBuilder<double>(tween: Tween(begin: 0.0, end: energy), duration: const Duration(milliseconds: 700), builder: (_, value, __) => Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))), subtitle: 'Today')),
              const SizedBox(width: 12),
              Expanded(child: _metricCard(context, icon: Icons.air, title: 'AQI', metric: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: aqi.toDouble()), duration: const Duration(milliseconds: 700), builder: (_, value, __) => Row(children: [Text(value.toInt().toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(width: 8), CircleAvatar(radius: 10, backgroundColor: Provider.of<MapState>(context, listen: false).colorForAqi(aqi))])), subtitle: 'City average')),
            ]),

            const SizedBox(height: 12),

            Row(children: [
              Expanded(child: _metricCard(context, icon: Icons.receipt_long, title: 'Estimated Bill (₹)', metric: TweenAnimationBuilder<double>(tween: Tween(begin: 0.0, end: bill), duration: const Duration(milliseconds: 700), builder: (_, value, __) => Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))), subtitle: 'Est. this month')),
              const SizedBox(width: 12),
              Expanded(child: _metricCard(context, icon: Icons.devices, title: 'Connected Devices', metric: Text('${data['devicesOnline'] ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)), subtitle: 'Active')),
            ]),

            const SizedBox(height: 18),

            // Chart card
            GlassCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Energy & AQI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                SizedBox(height: 180, child: _DashboardChart()),
              ]),
            )
          ]),
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
        if (!snap.hasData) return const Center(child: SizedBox.shrink());

        final energy = <FlSpot>[];
        final aqi = <FlSpot>[];

        for (int i = 0; i < snap.data!.docs.length; i++) {
          final d = snap.data!.docs[i];
          final raw = d.data();
          final map = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
          energy.add(FlSpot(i.toDouble(), (map['energy'] ?? 0).toDouble()));
          aqi.add(FlSpot(i.toDouble(), (map['aqi'] ?? 0).toDouble()));
        }

        return Column(children: [
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(enabled: true),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  if (showEnergy)
                    LineChartBarData(
                      isCurved: true,
                      spots: energy,
                      gradient: LinearGradient(colors: [Colors.orange.shade300, Colors.orange.shade700]),
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [Colors.orange.shade200.withOpacity(0.3), Colors.orange.shade200.withOpacity(0.0)])),
                    ),
                  if (showAqi)
                    LineChartBarData(
                      isCurved: true,
                      spots: aqi,
                      gradient: LinearGradient(colors: [Colors.green.shade300, Colors.green.shade700]),
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [Colors.green.shade200.withOpacity(0.3), Colors.green.shade200.withOpacity(0.0)])),
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
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Cloud Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: SizedBox(
            height: 220,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('devices').snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('No devices found'));

                return ListView(
                  children: snap.data!.docs.map((d) {
                    final raw = d.data();
                    final map = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
                    final name = map['name']?.toString() ?? 'Device';
                    final power = map['power']?.toString() ?? '0';
                    final stateRaw = map['state'];
                    final state = (stateRaw is bool) ? stateRaw : (stateRaw?.toString().toLowerCase() == 'true');

                    return ListTile(
                      title: Text(name),
                      subtitle: Text('$power W'),
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

        const SizedBox(height: 12),
        const Text('Bluetooth Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(child: BluetoothSection()),
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
        padding: EdgeInsets.all(12),
        child: Text('Bluetooth is not available on web. Please use Android or Windows for native Bluetooth.'),
      );
    }

    final items = _found.values.toList();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(children: [
            ElevatedButton.icon(
              icon: Icon(_scanning ? Icons.stop : Icons.search),
              label: Text(_scanning ? 'Scanning...' : 'Scan'),
              onPressed: _scanning ? null : _startScan,
            ),
            const SizedBox(width: 12),
            if (_connected != null)
              ElevatedButton.icon(icon: const Icon(Icons.link_off), label: const Text('Disconnect'), onPressed: _disconnect),
          ]),
          const SizedBox(height: 8),
          if (items.isEmpty) const Text('No nearby devices — try scanning'),
          ...items.map((r) => ListTile(
                title: Text(r.device.name.isNotEmpty ? r.device.name : (r.device.remoteId?.toString() ?? r.device.id.toString())), 
                subtitle: Text('RSSI: ${r.rssi}'),
                trailing: ElevatedButton(
                  child: const Text('Connect'),
                  onPressed: () => _connect(r.device),
                ),
              )), 
          if (_connected != null) Padding(
            padding: const EdgeInsets.only(top:12.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Connected to: ${_connected!.name.isNotEmpty ? _connected!.name : (_connected!.remoteId?.toString() ?? _connected!.id.toString())}'),
              const SizedBox(height: 8),
              ElevatedButton(
                child: const Text('Read Mock Data'),
                onPressed: () async {
                  // Try reading a characteristic, fall back to mock
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

/* ===========================================================
                        DEVICE DETAIL
=========================================================== */

class DeviceDetailPage extends StatelessWidget {
  final DocumentSnapshot doc;
  const DeviceDetailPage({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final raw = doc.data();
    final map = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
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
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(child: ListTile(title: const Text('Power'), subtitle: Text('$power W'))),
          const SizedBox(height: 8),
          Card(child: ListTile(title: const Text('State'), subtitle: Text(state ? 'On' : 'Off'), trailing: ElevatedButton(onPressed: () {
            doc.reference.update({'state': !state, 'lastUpdated': Timestamp.now()});
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toggled device state')));
          }, child: Text(state ? 'Turn Off' : 'Turn On')))),
          const SizedBox(height: 8),
          Card(child: ListTile(title: const Text('Last Updated'), subtitle: Text(lastStr))),
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ping sent (mock)'))), icon: const Icon(Icons.wifi_tethering), label: const Text('Ping Device')),
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
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('No analytics history available'));

        final energy = <FlSpot>[];
        final aqi = <FlSpot>[];

        for (int i = 0; i < snap.data!.docs.length; i++) {
          final d = snap.data!.docs[i];
          final raw = d.data();
          final map = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
          energy.add(FlSpot(i.toDouble(), _toDouble(map['energy'])));
          aqi.add(FlSpot(i.toDouble(), _toDouble(map['aqi'])));
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(children: [
                  IconButton(icon: Icon(showEnergy ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => showEnergy = !showEnergy)),
                  IconButton(icon: Icon(showAqi ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => showAqi = !showAqi)),
                ])
              ]),
              const SizedBox(height: 12),
              SizedBox(height: 320, child: LineChart(LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true))),
                lineBarsData: [
                  if (showEnergy) LineChartBarData(isCurved: true, spots: energy, gradient: LinearGradient(colors: [Colors.orange.shade300, Colors.orange.shade700]), barWidth: 3, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [Colors.orange.shade200.withOpacity(0.3), Colors.orange.shade200.withOpacity(0.0)]))),
                  if (showAqi) LineChartBarData(isCurved: true, spots: aqi, gradient: LinearGradient(colors: [Colors.green.shade300, Colors.green.shade700]), barWidth: 3, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [Colors.green.shade200.withOpacity(0.3), Colors.green.shade200.withOpacity(0.0)]))),
                ],
              ))),
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
      Positioned.fill(child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.02)], begin: Alignment.topCenter, end: Alignment.bottomCenter))))),

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
              const Text('Using OpenStreetMap (web fallback)'),
              const SizedBox(width: 8),
              TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enable Google Maps billing in GCP and add your API key to web/index.html.'))), child: const Text('How?'))
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
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(mainAxisSize: MainAxisSize.min, children: entries.map((e) {
          final aqi = e['aqi'] as int;
          final color = mapState.colorForAqi(aqi);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 32, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 6),
              Text(e['label'] as String, style: const TextStyle(fontSize: 10)),
            ]),
          );
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

    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: sel == null
            ? SizedBox(key: const ValueKey('empty'), width: 300, child: Column(mainAxisSize: MainAxisSize.min, children: const [Text('Select a location on the map to see AQI and weather details')] ))
            : SizedBox(
                key: ValueKey(sel.id),
                width: 300,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(sel.id.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Chip(label: Text('AQI ${sel.aqi}'), backgroundColor: mapState.colorForAqi(sel.aqi))
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.thermostat, color: sel.weather == 'sunny' ? Colors.orange : (sel.weather == 'rainy' ? Colors.blue : Colors.grey)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${sel.temp.toStringAsFixed(1)} °C • ${sel.humidity}% • ${sel.weather}')),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (sel.aqi / 500).clamp(0.0, 1.0), color: mapState.colorForAqi(sel.aqi), backgroundColor: Theme.of(context).dividerColor)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, children: [
                    ElevatedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Centering map...'))), icon: const Icon(Icons.center_focus_strong), label: const Text('Center')),
                    OutlinedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('More analytics coming soon'))), child: const Text('Analytics')),
                  ])
                ]),
              ),
      ),
    );
  }
}


class _RoundedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundedIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary))),
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
        const Text('Location Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (sel != null) ...[
          GlassCard(child: ListTile(leading: const Icon(Icons.air), title: const Text('AQI'), subtitle: Text('${sel.aqi}'), trailing: CircleAvatar(backgroundColor: mapState.colorForAqi(sel.aqi)))),
          const SizedBox(height: 8),
          GlassCard(child: ListTile(leading: const Icon(Icons.thermostat), title: const Text('Weather'), subtitle: Text('${sel.weather} • ${sel.temp} °C'))),
          const SizedBox(height: 8),
          GlassCard(child: ListTile(leading: const Icon(Icons.water_damage), title: const Text('Humidity'), subtitle: Text('${sel.humidity}%'))),
        ] else GlassCard(child: Padding(padding: const EdgeInsets.all(12.0), child: const Text('Select a location on the map to populate insights'))),
        const SizedBox(height: 12),
        const Text('Legend', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(child: ListTile(title: Text("Turn off idle devices to save ₹500/month"))),
        Card(child: ListTile(title: Text("High AQI detected — keep windows closed"))),
        Card(child: ListTile(title: Text("Use energy-efficient appliances"))),
      ],
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
