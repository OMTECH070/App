import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../l10n/app_localizations.dart';

class DeviceControlScreen extends StatefulWidget {
  const DeviceControlScreen({Key? key}) : super(key: key);

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DeviceProvider>().fetchDevices();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final deviceProvider = context.watch<DeviceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('device_control') ?? 'Device Control'),
      ),
      body: deviceProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: deviceProvider.devices.length + 1,
              itemBuilder: (context, index) {
                if (index == deviceProvider.devices.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: ElevatedButton.icon(
                      onPressed: () => _showPairDeviceDialog(context, loc),
                      icon: const Icon(Icons.add),
                      label: Text(loc?.translate('pair_device') ?? 'Pair New Device'),
                    ),
                  );
                }

                final device = deviceProvider.devices[index];
                return _buildDeviceCard(context, device, loc);
              },
            ),
    );
  }

  Widget _buildDeviceCard(
      BuildContext context, Map<String, dynamic> device, AppLocalizations? loc) {
    final isConnected = device['status'] == 'connected';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device['field_name'] ?? 'Unknown Device',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device['device_id'] ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected
                      ? loc?.translate('connected') ?? 'Connected'
                      : loc?.translate('offline') ?? 'Offline',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Device Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Battery',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${device['battery_level'] ?? 0}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WiFi Signal',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${device['wifi_signal'] ?? 0} dBm',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Manual Irrigation Section
            Text(
              loc?.translate('manual_mode') ?? 'Manual Irrigation',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: loc?.translate('duration') ?? 'Duration (min)',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isConnected ? () {} : null,
                  child: Text(loc?.translate('start_irrigation') ?? 'Start'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Automation Toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc?.translate('automation_mode') ?? 'Automation Mode',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Switch(
                  value: device['automation_enabled'] ?? false,
                  onChanged: isConnected ? (_) {} : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stop & Unpair Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isConnected ? () {} : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text(
                      loc?.translate('stop_irrigation') ?? 'Stop All',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _showUnpairDialog(context, device, loc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text(loc?.translate('delete') ?? 'Unpair'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPairDeviceDialog(BuildContext context, AppLocalizations? loc) {
    final deviceIdController = TextEditingController();
    final fieldNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc?.translate('pair_device') ?? 'Pair New Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: deviceIdController,
                decoration: InputDecoration(
                  labelText: loc?.translate('device_id') ?? 'Device ID',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: fieldNameController,
                decoration: InputDecoration(
                  labelText: loc?.translate('field_name') ?? 'Field Name',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc?.translate('cancel') ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<DeviceProvider>().pairDevice(
                  deviceId: deviceIdController.text,
                  fieldName: fieldNameController.text,
                );
                Navigator.pop(context);
              },
              child: Text(loc?.translate('confirm') ?? 'Pair'),
            ),
          ],
        );
      },
    );
  }

  void _showUnpairDialog(BuildContext context, Map<String, dynamic> device,
      AppLocalizations? loc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc?.translate('unpair_device') ?? 'Unpair Device'),
          content: Text(loc?.translate('are_you_sure') ?? 'Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc?.translate('cancel') ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<DeviceProvider>().deleteDevice(device['device_id']);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(loc?.translate('delete') ?? 'Delete'),
            ),
          ],
        );
      },
    );
  }
}
