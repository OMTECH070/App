import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../config/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedDeviceId;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    final deviceProvider = context.read<DeviceProvider>();
    final sensorProvider = context.read<SensorProvider>();

    await deviceProvider.fetchDevices();

    if (deviceProvider.devices.isNotEmpty) {
      _selectedDeviceId = deviceProvider.devices.first['device_id'];
      await sensorProvider.fetchLatestReading(_selectedDeviceId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final deviceProvider = context.watch<DeviceProvider>();
    final sensorProvider = context.watch<SensorProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('dashboard') ?? 'Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: deviceProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _initializeDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Connection Status Indicator
                    _buildConnectionIndicator(context, loc),
                    const SizedBox(height: 16),

                    // Device Selector
                    if (deviceProvider.devices.isNotEmpty)
                      _buildDeviceSelector(context, deviceProvider, loc)
                    else
                      _buildNoDevicesMessage(context, loc),
                    const SizedBox(height: 16),

                    // Sensor Data Cards
                    if (sensorProvider.latestReading != null)
                      _buildSensorCards(context, sensorProvider, loc)
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(context, loc),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/device_control'),
        tooltip: loc?.translate('device_control'),
        child: const Icon(Icons.devices),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: loc?.translate('dashboard') ?? 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications),
            label: loc?.translate('notifications') ?? 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: loc?.translate('settings') ?? 'Settings',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.of(context).pushNamed('/notifications');
              break;
            case 2:
              Navigator.of(context).pushNamed('/settings');
              break;
          }
        },
      ),
    );
  }

  Widget _buildConnectionIndicator(BuildContext context, AppLocalizations? loc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.successGreen),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.successGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc?.translate('connected') ?? 'Connected',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSelector(
      BuildContext context, DeviceProvider deviceProvider, AppLocalizations? loc) {
    return DropdownButton<String>(
      isExpanded: true,
      value: _selectedDeviceId ?? deviceProvider.devices.first['device_id'],
      items: deviceProvider.devices.map((device) {
        return DropdownMenuItem<String>(
          value: device['device_id'],
          child: Text(device['field_name'] ?? device['device_id']),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedDeviceId = newValue;
          });
          context.read<SensorProvider>().fetchLatestReading(newValue);
        }
      },
    );
  }

  Widget _buildNoDevicesMessage(BuildContext context, AppLocalizations? loc) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.devices_other,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No devices paired yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/device_control'),
            icon: const Icon(Icons.add),
            label: Text(loc?.translate('pair_device') ?? 'Pair Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCards(
      BuildContext context, SensorProvider sensorProvider, AppLocalizations? loc) {
    final reading = sensorProvider.latestReading!;
    final moisture = reading['moisture'] ?? 0.0 as double;
    final temperature = reading['temperature'] ?? 0.0 as double;
    final humidity = reading['humidity'] ?? 0.0 as double;

    return Column(
      children: [
        // Main Moisture Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  loc?.translate('soil_moisture') ?? 'Soil Moisture',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '${moisture.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _getMoistureColor(moisture),
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: moisture / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getMoistureColor(moisture),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Temperature & Humidity Cards
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc?.translate('temperature') ?? 'Temperature',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${temperature.toStringAsFixed(1)}°C',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc?.translate('humidity') ?? 'Humidity',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${humidity.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations? loc) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showWaterNowDialog(context, loc),
            icon: const Icon(Icons.water_drop),
            label: Text(loc?.translate('water_now') ?? 'Water Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/device_control'),
            icon: const Icon(Icons.settings),
            label: Text(loc?.translate('device_control') ?? 'Control'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showWaterNowDialog(BuildContext context, AppLocalizations? loc) {
    showDialog(
      context: context,
      builder: (context) {
        int duration = 30;
        return AlertDialog(
          title: Text(loc?.translate('water_now') ?? 'Water Now'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc?.translate('duration') ?? 'Duration (minutes)'),
                  const SizedBox(height: 16),
                  Slider(
                    value: duration.toDouble(),
                    min: 5,
                    max: 180,
                    divisions: 35,
                    label: '$duration min',
                    onChanged: (value) {
                      setState(() {
                        duration = value.toInt();
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc?.translate('cancel') ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Call irrigation API
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Irrigation started for $duration minutes'),
                  ),
                );
              },
              child: Text(loc?.translate('confirm') ?? 'Confirm'),
            ),
          ],
        );
      },
    );
  }

  Color _getMoistureColor(double moisture) {
    if (moisture < 20) return AppTheme.criticalRed;
    if (moisture < 50) return AppTheme.warningOrange;
    return AppTheme.successGreen;
  }
}
