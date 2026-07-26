import 'package:flutter/material.dart';
import '../../capability_detection/domain/entities/capability_profile.dart';

class CapabilityCard extends StatelessWidget {
  final CapabilityProfile profile;

  const CapabilityCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.developer_board_rounded,
            color: theme.colorScheme.primary),
        title: const Text(
          'Hardware Capabilities',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${_countAvailable()} sensors detected',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        initiallyExpanded: false,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(context, 'LiDAR', profile.hasLidar),
              _chip(context, 'Depth', profile.hasDepthSensor),
              _chip(context, 'ARCore', profile.hasArCore),
              _chip(context, 'ARKit', profile.hasArKit),
              _chip(context, 'Camera', profile.hasCamera),
              _chip(context, 'GPS', profile.hasGps),
              _chip(context, 'Compass', profile.hasCompass),
              _chip(context, 'Gyro', profile.hasGyroscope),
              _chip(context, 'Accel', profile.hasAccelerometer),
              _chip(context, 'Baro', profile.hasBarometer),
              _chip(context, 'BT', profile.hasBluetooth),
              _chip(context, 'NFC', profile.hasNfc),
              _chip(context, 'AI', profile.hasAiAccelerator),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip(
                context,
                Icons.memory_rounded,
                '${profile.ramMb} MB',
              ),
              const SizedBox(width: 8),
              _infoChip(
                context,
                Icons.developer_board_rounded,
                '${profile.cpuCores} cores',
              ),
              const SizedBox(width: 8),
              _infoChip(
                context,
                Icons.battery_charging_full_rounded,
                '${(profile.batteryLevel * 100).toInt()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _countAvailable() {
    int count = 0;
    if (profile.hasLidar) count++;
    if (profile.hasDepthSensor) count++;
    if (profile.hasArCore) count++;
    if (profile.hasArKit) count++;
    if (profile.hasCamera) count++;
    if (profile.hasGps) count++;
    if (profile.hasCompass) count++;
    if (profile.hasGyroscope) count++;
    if (profile.hasAccelerometer) count++;
    if (profile.hasBarometer) count++;
    if (profile.hasBluetooth) count++;
    if (profile.hasNfc) count++;
    if (profile.hasAiAccelerator) count++;
    return count;
  }

  Widget _chip(BuildContext context, String label, bool available) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label sensor ${available ? "available" : "unavailable"}',
      child: Chip(
        avatar: Icon(
          available ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 16,
          color:
              available ? const Color(0xFF10B981) : theme.colorScheme.outline,
        ),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        side: BorderSide(
          color: available
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant,
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(text,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
