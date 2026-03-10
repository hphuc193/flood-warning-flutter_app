import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/weather_provider.dart';
import 'location_picker_screen.dart';
import 'weather_main_screen.dart';

class WeatherLocationListScreen extends StatefulWidget {
  const WeatherLocationListScreen({super.key});

  @override
  State<WeatherLocationListScreen> createState() =>
      _WeatherLocationListScreenState();
}

class _WeatherLocationListScreenState extends State<WeatherLocationListScreen>
    with SingleTickerProviderStateMixin {
  // ─── Design tokens ────────────────────────────────────────────────────
  static const _bg = Color(0xFFF7F8FC);
  static const _surface = Color(0xFFFFFFFF);
  static const _surfaceSecondary = Color(0xFFF0F2F8);
  static const _accent = Color(0xFF2563EB);
  static const _accentLight = Color(0xFFEFF4FF);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _textTertiary = Color(0xFF94A3B8);
  static const _divider = Color(0xFFF1F5F9);
  static const _border = Color(0xFFE2E8F0);

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeatherProvider>(context, listen: false).loadSavedLocations();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onLocationTapped(
      BuildContext context, String name, double lat, double lon) async {
    final provider = Provider.of<WeatherProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (c) => const Center(
        child: CircularProgressIndicator(
          color: _accent,
          strokeWidth: 1.5,
        ),
      ),
    );

    await provider.fetchForecast(lat, lon, cityName: name);

    if (context.mounted) Navigator.pop(context);

    if (provider.forecastData != null && context.mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              WeatherMainScreen(forecastData: provider.forecastData!),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 220),
        ),
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Lỗi tải dữ liệu. Vui lòng thử lại!"),
            backgroundColor: _surface,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Consumer<WeatherProvider>(
                builder: (context, weatherProvider, child) {
                  final currentLoc = weatherProvider.currentLocation;
                  final savedLocs = weatherProvider.savedLocations;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // ── Current location ────────────────────────────
                      _SectionLabel(label: "VỊ TRÍ HIỆN TẠI"),
                      const SizedBox(height: 10),
                      _LocationCard(
                        name: currentLoc['name'],
                        icon: Icons.my_location_rounded,
                        iconColor: _accent,
                        iconBg: _accentLight,
                        isCurrent: true,
                        onTap: () => _onLocationTapped(
                          context,
                          currentLoc['name'],
                          currentLoc['lat'],
                          currentLoc['lon'],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Saved locations ──────────────────────────────
                      Row(
                        children: [
                          const _SectionLabel(label: "VỊ TRÍ ĐÃ LƯU"),
                          const Spacer(),
                          if (savedLocs.isNotEmpty)
                            Text(
                              "${savedLocs.length} địa điểm",
                              style: const TextStyle(
                                fontSize: 11,
                                color: _textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (savedLocs.isEmpty)
                        _EmptyState()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: savedLocs.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final loc = savedLocs[index];
                            return _LocationCard(
                              name: loc['name'],
                              subtitle:
                              "${loc['lat'].toStringAsFixed(2)}°N  ${loc['lon'].toStringAsFixed(2)}°E",
                              icon: Icons.location_city_rounded,
                              iconColor: const Color(0xFF7C3AED),
                              iconBg: const Color(0xFFFDF4FF),
                              onTap: () => _onLocationTapped(
                                context,
                                loc['name'],
                                loc['lat'],
                                loc['lon'],
                              ),
                              onDelete: () =>
                                  weatherProvider.removeLocation(index),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Custom header ──────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _surface,
      child: Stack(
        children: [
          // Top accent bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Quản lý vị trí",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          "Theo dõi thời tiết nhiều nơi",
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Add button
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LocationPickerScreen()),
                      );
                      if (result != null &&
                          result is Map<String, dynamic> &&
                          context.mounted) {
                        Provider.of<WeatherProvider>(context, listen: false)
                            .addLocation(
                          result['name'] ?? 'Vị trí tùy chọn',
                          result['lat'],
                          result['long'],
                        );
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _accentLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_location_alt_rounded,
                        size: 18,
                        color: _accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}

// ─── Location card ──────────────────────────────────────────────────────────
class _LocationCard extends StatefulWidget {
  final String name;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _LocationCard({
    required this.name,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isCurrent = false,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> {
  bool _pressed = false;

  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _textTertiary = Color(0xFF94A3B8);
  static const _accent = Color(0xFF2563EB);
  static const _accentLight = Color(0xFFEFF4FF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFF8FAFF) : _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isCurrent ? const Color(0xFFBFD7FF) : _border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                              letterSpacing: -0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.isCurrent) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _accentLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Hiện tại",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _accent,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Trailing
              if (widget.onDelete != null)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFE11D48),
                      size: 17,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _textTertiary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE2E8F0);
  static const _textSecondary = Color(0xFF64748B);
  static const _textTertiary = Color(0xFF94A3B8);
  static const _accentLight = Color(0xFFEFF4FF);
  static const _accent = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _accentLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.add_location_alt_outlined,
              color: _accent,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Chưa có địa điểm nào",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Nhấn nút + ở góc trên bên phải\nđể thêm vị trí theo dõi.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: _textTertiary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}