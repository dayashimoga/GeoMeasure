import 'package:flutter/material.dart';
import '../../capability_detection/domain/entities/capability_profile.dart';

class CapabilityCard extends StatelessWidget {
  final CapabilityProfile profile;

  const CapabilityCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hardware Capability Matrix',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSensorRow('LiDAR Sensor', profile.hasLidar),
            _buildSensorRow('ToF Depth Sensor', profile.hasDepthSensor),
            _buildSensorRow('ARCore / ARKit Support', profile.hasArCore || profile.hasArKit),
            _buildSensorRow('GPS / Magnetometer', profile.hasGps && profile.hasCompass),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Memory: ${profile.ramMb} MB'),
                Text('CPU Cores: ${profile.cpuCores}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorRow(String label, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }
}
