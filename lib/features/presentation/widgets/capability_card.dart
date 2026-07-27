import 'package:flutter/material.dart';
import '../../capability_detection/domain/entities/capability_profile.dart';

class CapabilityCard extends StatelessWidget {
  final CapabilityProfile profile;

  const CapabilityCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = profile.sensorCount;

    return Card(
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.15),
                theme.colorScheme.secondary.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.developer_board_rounded,
              color: theme.colorScheme.primary, size: 22),
        ),
        title: const Text(
          'Hardware Capabilities',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: count > 0
                    ? const Color(0xFF10B981)
                    : theme.colorScheme.outline,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                count > 0 ? '$count sensors detected' : 'No sensors detected',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: count > 0 ? FontWeight.w500 : FontWeight.normal,
                  color: count > 0
                      ? const Color(0xFF10B981)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
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
          if (profile.osVersion != 'unknown') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _infoChip(
                  context,
                  Icons.phone_android_rounded,
                  profile.osVersion,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool available) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label sensor ${available ? "available" : "unavailable"}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Chip(
          avatar: Icon(
            available ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: available
                ? const Color(0xFF10B981)
                : theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          label: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: available ? FontWeight.w600 : FontWeight.normal,
              color: available
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          backgroundColor: available
              ? const Color(0xFF10B981).withValues(alpha: 0.08)
              : null,
          side: BorderSide(
            color: available
                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
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
