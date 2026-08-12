import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared/presentation/location/cubit/location_picker_cubit.dart';
import 'package:shared/presentation/location/cubit/location_picker_state.dart';

/// Production-grade Bottom Sheet for Selecting / Viewing Address GPS Location.
/// Uses flutter_map (OpenStreetMap) — no API key required.
class AddressLocationPickerSheet extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String title;

  const AddressLocationPickerSheet({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.title = 'تحديد الموقع على الخريطة',
  });

  static Future<({double latitude, double longitude})?> show(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
    String title = 'تحديد الموقع على الخريطة',
  }) {
    return showModalBottomSheet<({double latitude, double longitude})?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider(
        create: (_) => LocationPickerCubit(
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
        ),
        child: AddressLocationPickerSheet(
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
          title: title,
        ),
      ),
    );
  }

  @override
  State<AddressLocationPickerSheet> createState() =>
      _AddressLocationPickerSheetState();
}

class _AddressLocationPickerSheetState
    extends State<AddressLocationPickerSheet> {
  late final MapController _mapController;
  late final LocationPickerCubit _cubit;

  // Default center: Cairo, Egypt (used only as last-resort fallback)
  static const double _defaultLat = 30.0444;
  static const double _defaultLng = 31.2357;
  static const double _defaultZoom = 13.0;
  static const double _gpsZoom = 16.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _cubit = context.read<LocationPickerCubit>();

    // If no initial coordinates were provided, auto-detect current location
    if (widget.initialLatitude == null && widget.initialLongitude == null) {
      _autoDetectLocation();
    }
  }

  /// Called once on open — fetches real GPS and moves camera to it.
  Future<void> _autoDetectLocation() async {
    await _cubit.requestCurrentLocation();
    final s = _cubit.state;
    if (mounted && s.hasCoordinates) {
      // Small delay to let the map finish initial render before moving
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _mapController.move(
          LatLng(s.latitude!, s.longitude!),
          _gpsZoom,
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _currentCenter(LocationPickerState state) {
    return LatLng(
      state.latitude ?? widget.initialLatitude ?? _defaultLat,
      state.longitude ?? widget.initialLongitude ?? _defaultLng,
    );
  }


  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Sheet Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Interactive Map Area
          Expanded(
            child: BlocBuilder<LocationPickerCubit, LocationPickerState>(
              builder: (context, state) {
                final cubit = context.read<LocationPickerCubit>();
                final center = _currentCenter(state);

                return Stack(
                  children: [
                    // ── Real OpenStreetMap ──────────────────────────────────
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: _defaultZoom,
                        minZoom: 5,
                        maxZoom: 19,
                        onTap: (tapPosition, point) {
                          cubit.selectLocation(
                            latitude: double.parse(
                                point.latitude.toStringAsFixed(6)),
                            longitude: double.parse(
                                point.longitude.toStringAsFixed(6)),
                          );
                        },
                      ),
                      children: [
                        // OpenStreetMap Tile Layer — no API key needed
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.freshhome.app',
                          maxZoom: 19,
                        ),

                        // Selected Location Marker
                        if (state.hasCoordinates)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  state.latitude!,
                                  state.longitude!,
                                ),
                                width: 60,
                                height: 70,
                                alignment: Alignment.topCenter,
                                child: const _LocationPin(),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // ── Coordinates Badge ───────────────────────────────────
                    if (state.hasCoordinates)
                      Positioned(
                        top: 12,
                        left: 16,
                        right: 16,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 14, color: Colors.redAccent),
                                const SizedBox(width: 6),
                                Text(
                                  '${state.latitude?.toStringAsFixed(5)},  ${state.longitude?.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // ── Tap Hint (when no location selected) ───────────────
                    if (!state.hasCoordinates)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app_rounded,
                                    size: 16, color: Colors.blue),
                                SizedBox(width: 6),
                                Text(
                                  'انقر على الخريطة لتحديد موقعك',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // ── GPS Button ──────────────────────────────────────────
                    Positioned(
                      bottom: 20,
                      right: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Zoom In
                          _MapControlButton(
                            icon: Icons.add_rounded,
                            onTap: () {
                              final current = _mapController.camera.zoom;
                              _mapController.move(
                                  _mapController.camera.center,
                                  (current + 1).clamp(5, 19));
                            },
                          ),
                          const SizedBox(height: 8),
                          // Zoom Out
                          _MapControlButton(
                            icon: Icons.remove_rounded,
                            onTap: () {
                              final current = _mapController.camera.zoom;
                              _mapController.move(
                                  _mapController.camera.center,
                                  (current - 1).clamp(5, 19));
                            },
                          ),
                          const SizedBox(height: 8),
                          // Current GPS Location
                          FloatingActionButton.small(
                            heroTag: 'gps_btn_map',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            elevation: 4,
                            onPressed: () async {
                              await cubit.requestCurrentLocation();
                              if (mounted) {
                                final s = cubit.state;
                                if (s.hasCoordinates) {
                                  _mapController.move(
                                    LatLng(s.latitude!, s.longitude!),
                                    16.0,
                                  );
                                }
                              }
                            },
                            child: state.isLoadingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location_rounded),
                          ),
                        ],
                      ),
                    ),

                    // ── Error Banner ────────────────────────────────────────
                    if (state.errorMessage != null)
                      Positioned(
                        bottom: 80,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // ── Bottom Action Bar ─────────────────────────────────────────────
          BlocBuilder<LocationPickerCubit, LocationPickerState>(
            builder: (context, state) {
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (state.hasCoordinates)
                      TextButton.icon(
                        onPressed: () {
                          context.read<LocationPickerCubit>().clearLocation();
                        },
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: Colors.red),
                        label: const Text('إلغاء',
                            style: TextStyle(color: Colors.red)),
                      ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor:
                            state.hasCoordinates ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: state.hasCoordinates
                          ? () {
                              Navigator.of(context).pop((
                                latitude: state.latitude!,
                                longitude: state.longitude!,
                              ));
                            }
                          : null,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('تأكيد الموقع'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LocationPin extends StatelessWidget {
  const _LocationPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
            ],
          ),
          child: const Icon(Icons.location_on_rounded,
              color: Colors.white, size: 18),
        ),
        CustomPaint(
          size: const Size(2, 14),
          painter: _PinTailPainter(),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
      ),
    );
  }
}
