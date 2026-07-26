import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../gps_tracking/gps_tracking_service.dart';

/// GPS tracking page with live position, waypoint list, and plot conversion.
class GpsTrackingPage extends StatefulWidget {
  const GpsTrackingPage({super.key});

  @override
  State<GpsTrackingPage> createState() => _GpsTrackingPageState();
}

class _GpsTrackingPageState extends State<GpsTrackingPage> {
  late final GpsTrackingProvider _gpsProvider;

  @override
  void initState() {
    super.initState();
    _gpsProvider = GpsTrackingProvider();
    _gpsProvider.initialize();
  }

  @override
  void dispose() {
    _gpsProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Land Survey'),
        actions: [
          ListenableBuilder(
            listenable: _gpsProvider,
            builder: (context, _) => IconButton(
              icon: Icon(
                _gpsProvider.isTracking
                    ? Icons.stop_circle_rounded
                    : Icons.play_circle_rounded,
                color: _gpsProvider.isTracking
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              onPressed: () {
                if (_gpsProvider.isTracking) {
                  _gpsProvider.stopTracking();
                } else {
                  _gpsProvider.startTracking();
                }
              },
              tooltip:
                  _gpsProvider.isTracking ? 'Stop Tracking' : 'Start Tracking',
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _gpsProvider,
        builder: (context, _) {
          return Column(
            children: [
              _buildStatusCard(theme),
              _buildStatsRow(theme),
              if (_gpsProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _gpsProvider.errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              Expanded(child: _buildWaypointList(theme)),
            ],
          );
        },
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _gpsProvider,
        builder: (context, _) {
          if (_gpsProvider.waypoints.length < 3) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: _convertToPlot,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Convert to Plot'),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final pos = _gpsProvider.currentPosition;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _gpsProvider.isTracking
                        ? const Color(0xFF10B981)
                        : theme.colorScheme.outline,
                    shape: BoxShape.circle,
                    boxShadow: _gpsProvider.isTracking
                        ? [
                            BoxShadow(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                            )
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _gpsProvider.isTracking
                      ? 'Tracking Active'
                      : 'Tracking Inactive',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _gpsProvider.isTracking
                        ? const Color(0xFF10B981)
                        : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            if (pos != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _posField(theme, 'Lat', pos.latitude.toStringAsFixed(6)),
                  const SizedBox(width: 12),
                  _posField(theme, 'Lng', pos.longitude.toStringAsFixed(6)),
                  const SizedBox(width: 12),
                  _posField(
                      theme, 'Alt', '${pos.altitude.toStringAsFixed(1)} m'),
                  const SizedBox(width: 12),
                  _posField(
                      theme, 'Acc', '±${pos.accuracy.toStringAsFixed(1)} m'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _posField(ThemeData theme, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              )),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statChip(
            theme,
            Icons.place_rounded,
            '${_gpsProvider.waypoints.length}',
            'Points',
          ),
          const SizedBox(width: 8),
          _statChip(
            theme,
            Icons.straighten_rounded,
            '${_gpsProvider.totalDistanceMeters.toStringAsFixed(1)} m',
            'Distance',
          ),
          const SizedBox(width: 8),
          _statChip(
            theme,
            Icons.speed_rounded,
            '${_gpsProvider.currentPosition?.speed.toStringAsFixed(1) ?? '0'} m/s',
            'Speed',
          ),
        ],
      ),
    );
  }

  Widget _statChip(ThemeData theme, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(height: 2),
            Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildWaypointList(ThemeData theme) {
    final waypoints = _gpsProvider.waypoints;
    if (waypoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gps_off_rounded,
                size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'Start tracking to collect GPS waypoints',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: waypoints.length,
      itemBuilder: (ctx, i) {
        final wp = waypoints[i];
        return Semantics(
          label:
              'Waypoint ${i + 1}: ${wp.latitude.toStringAsFixed(4)}, ${wp.longitude.toStringAsFixed(4)}',
          child: Card(
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
              title: Text(
                '${wp.latitude.toStringAsFixed(6)}, ${wp.longitude.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              ),
              subtitle: Text(
                'Alt: ${wp.altitude.toStringAsFixed(1)}m • Acc: ±${wp.accuracy.toStringAsFixed(1)}m',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _convertToPlot() {
    final plot = _gpsProvider.toPlotShape();
    if (plot != null) {
      sl.measurementProvider.calculateMeasurement(
        shape: plot,
        profile: sl.capabilityProvider.profile,
        shapeName: 'GPS Survey ${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Plot created with ${_gpsProvider.waypoints.length} waypoints • '
              '${sl.measurementProvider.lastResult?.area.toStringAsFixed(2)} m²',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
}
