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
  static const _bg = Color(0xFF0F2044);
  static const _surface = Color(0xFF1A2E55);
  static const _accent = Color(0xFF4A9EFF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFB0C4DE);
  static const _textTertiary = Color(0xFF7A97C0);

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
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
      barrierColor: Colors.black45,
      builder: (c) => const Center(
        child: CircularProgressIndicator(
          color: _accent,
          strokeWidth: 2,
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
          transitionDuration: const Duration(milliseconds: 280),
        ),
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Lỗi tải dữ liệu. Vui lòng thử lại!"),
            backgroundColor: _surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ── Map description to gradient ──────────────────────────────────────
  List<Color> _getGradient(String? description) {
    if (description == null) {
      return [const Color(0xFF2C5F8A), const Color(0xFF1A3A6E)];
    }
    final desc = description.toLowerCase();
    if (desc.contains('mưa') || desc.contains('rain')) {
      return [const Color(0xFF3A78C9), const Color(0xFF1B3F6E)];
    } else if (desc.contains('nắng') ||
        desc.contains('sunny') ||
        desc.contains('clear')) {
      return [const Color(0xFFFF8C42), const Color(0xFFD4500A)];
    } else if (desc.contains('mây') || desc.contains('cloud')) {
      return [const Color(0xFF4A6FA5), const Color(0xFF2A4070)];
    } else if (desc.contains('bão') ||
        desc.contains('storm') ||
        desc.contains('thunder')) {
      return [const Color(0xFF4B3A7A), const Color(0xFF1A1040)];
    } else if (desc.contains('tuyết') || desc.contains('snow')) {
      return [const Color(0xFF5B8DB8), const Color(0xFF2C5F8A)];
    } else if (desc.contains('sương') ||
        desc.contains('fog') ||
        desc.contains('mist')) {
      return [const Color(0xFF4A6080), const Color(0xFF2A3A50)];
    }
    return [const Color(0xFF2B5FA8), const Color(0xFF1A3A6E)];
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background gradient mesh
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F2044),
                    Color(0xFF7A97C0),
                    Color(0xFFF7F8FC),
                  ],
                ),
              ),
            ),
          ),
          // Decorative glow blob top-right
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4A9EFF).withOpacity(0.08),
              ),
            ),
          ),
          // Decorative glow blob bottom-left
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C5CFC).withOpacity(0.07),
              ),
            ),
          ),

          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Consumer<WeatherProvider>(
                    builder: (context, weatherProvider, child) {
                      final currentLoc = weatherProvider.currentLocation;
                      final savedLocs = weatherProvider.savedLocations;
                      // Try to get today's weather data if available
                      final forecastData = weatherProvider.forecastData;
                      Map<String, dynamic>? todayWeather;
                      if (forecastData != null) {
                        final grouped = forecastData.groupDataByDate();
                        if (grouped.isNotEmpty) {
                          final todayItems = grouped.values.first;
                          if (todayItems.isNotEmpty) {
                            final rep = todayItems[todayItems.length ~/ 2];
                            todayWeather = {
                              'description': rep.description,
                              'iconUrl': rep.iconUrl,
                              'tempMax': todayItems
                                  .map((e) => e.tempMax)
                                  .reduce((a, b) => a > b ? a : b),
                              'tempMin': todayItems
                                  .map((e) => e.tempMin)
                                  .reduce((a, b) => a < b ? a : b),
                              'humidity': rep.humidity,
                              'windSpeed': rep.windSpeed,
                            };
                          }
                        }
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // ── Current location ──────────────────────
                          _SectionLabel(label: "VỊ TRÍ HIỆN TẠI"),
                          const SizedBox(height: 12),
                          _CurrentLocationCard(
                            name: currentLoc['name'],
                            todayWeather: todayWeather,
                            gradient: todayWeather != null
                                ? _getGradient(todayWeather['description'])
                                : [
                              const Color(0xFF2B5FA8),
                              const Color(0xFF1A3A6E)
                            ],
                            onTap: () => _onLocationTapped(
                              context,
                              currentLoc['name'],
                              currentLoc['lat'],
                              currentLoc['lon'],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Saved locations ────────────────────────
                          Row(
                            children: [
                              const _SectionLabel(label: "ĐỊA ĐIỂM ĐÃ LƯU"),
                              const Spacer(),
                              if (savedLocs.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                    const Color(0xFFF7F8FC).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFF7F8FC)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    "${savedLocs.length} nơi",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFF7F8FC),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (savedLocs.isEmpty)
                            const _EmptyState()
                          else
                          // ── Horizontal scrollable vertical cards ──
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: savedLocs.length,
                              itemBuilder: (context, index) {
                                final loc = savedLocs[index];
                                final gradients = [
                                  [const Color(0xFF7C5CFC), const Color(0xFF4B3A7A)],
                                  [const Color(0xFF3A78C9), const Color(0xFF1B3F6E)],
                                  [const Color(0xFF1DAB87), const Color(0xFF0D6B55)],
                                  [const Color(0xFFE05C3A), const Color(0xFF8B3220)],
                                  [const Color(0xFF4A6FA5), const Color(0xFF2A4070)],
                                ];
                                final grad = gradients[index % gradients.length];
                                return _SavedLocationCard(
                                  name: loc['name'],
                                  lat: loc['lat'],
                                  lon: loc['lon'],
                                  gradient: grad,
                                  index: index,
                                  onTap: () => _onLocationTapped(
                                    context,
                                    loc['name'],
                                    loc['lat'],
                                    loc['lon'],
                                  ),
                                  onDelete: () => weatherProvider.removeLocation(index),
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
        ],
      ),
    );
  }

  // ── Custom header ──────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.07),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 14),
          child: Row(
            children: [
              // Back button
              // GestureDetector(
              //   onTap: () => Navigator.maybePop(context),
              //   child: Container(
              //     width: 40,
              //     height: 40,
              //     decoration: BoxDecoration(
              //       color: Colors.white.withOpacity(0.08),
              //       borderRadius: BorderRadius.circular(12),
              //       border: Border.all(
              //           color: Colors.white.withOpacity(0.12), width: 1),
              //     ),
              //     child: const Icon(
              //       Icons.arrow_back_ios_new_rounded,
              //       size: 16,
              //       color: Colors.white70,
              //     ),
              //   ),
              // ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quản lý vị trí",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      "Theo dõi thời tiết nhiều nơi",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A97C0),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A9EFF), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_location_alt_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
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
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: const Color(0xFF4A9EFF),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: Color(0xFF7A97C0),
          ),
        ),
      ],
    );
  }
}

// ─── Current location card (wide horizontal) ───────────────────────────────
class _CurrentLocationCard extends StatefulWidget {
  final String name;
  final Map<String, dynamic>? todayWeather;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _CurrentLocationCard({
    required this.name,
    this.todayWeather,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_CurrentLocationCard> createState() => _CurrentLocationCardState();
}

class _CurrentLocationCardState extends State<_CurrentLocationCard> {
  bool _pressed = false;

  Widget _buildWeatherIcon(String iconUrl, double size) {
    final isSunny = iconUrl.contains('01d') || iconUrl.contains('01n');

    if (isSunny) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Icon(
          Icons.wb_sunny_rounded,
          color: const Color(0xFFFF9500),
          size: size * 0.75,
        ),
      );
    }

    return Image.network(
      iconUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Icon(
        Icons.wb_cloudy_rounded,
        size: size * 0.6,
        color: Colors.white70,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tw = widget.todayWeather;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border:
            Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.last.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -40,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              // Content
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    // Left: location info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Badge + name
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.my_location_rounded,
                                        size: 10,
                                        color: Colors.white.withOpacity(0.9)),
                                    const SizedBox(width: 4),
                                    const Text(
                                      "VỊ TRÍ HIỆN TẠI",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          // Weather info row
                          if (tw != null)
                            Row(
                              children: [
                                _WeatherPill(
                                  icon: Icons.water_drop_outlined,
                                  value: "${tw['humidity']?.round() ?? '--'}%",
                                  label: "Độ ẩm",
                                ),
                                const SizedBox(width: 8),
                                _WeatherPill(
                                  icon: Icons.air_rounded,
                                  value:
                                  "${tw['windSpeed']?.toStringAsFixed(1) ?? '--'} m/s",
                                  label: "Gió",
                                ),
                              ],
                            )
                          else
                            Text(
                              "Nhấn để xem thời tiết",
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right: weather icon + temp
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (tw != null) ...[
                          ClipOval(
                            child: _buildWeatherIcon(tw['iconUrl'], 58),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${tw['tempMax']?.round()}°/${tw['tempMin']?.round()}°",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 80,
                            child: Text(
                              tw['description'] ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.12),
                            ),
                            child: const Icon(Icons.wb_sunny_outlined,
                                color: Colors.white54, size: 30),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.white.withOpacity(0.4), size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Saved location card (vertical, for horizontal scroll) ─────────────────
class _SavedLocationCard extends StatefulWidget {
  final String name;
  final double lat;
  final double lon;
  final List<Color> gradient;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedLocationCard({
    required this.name,
    required this.lat,
    required this.lon,
    required this.gradient,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_SavedLocationCard> createState() => _SavedLocationCardState();
}

class _SavedLocationCardState extends State<_SavedLocationCard> {
  bool _pressed = false;

  // Weather icons for placeholder variety
  static const _icons = [
    Icons.wb_sunny_rounded,
    Icons.cloud_rounded,
    Icons.grain_rounded,
    Icons.thunderstorm_rounded,
    Icons.ac_unit_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final icon = _icons[widget.index % _icons.length];

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border:
            Border.all(color: Colors.white.withOpacity(0.14), width: 1),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.last.withOpacity(0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative blob
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              Positioned(
                left: -15,
                bottom: -15,
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),

              // Delete button
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weather icon placeholder
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const Spacer(),
                    // Location name
                    Text(
                      widget.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Coordinates
                    Text(
                      "${widget.lat.toStringAsFixed(1)}°N  ${widget.lon.toStringAsFixed(1)}°E",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tap hint
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Xem chi tiết",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white70, size: 11),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Weather info pill ──────────────────────────────────────────────────────
class _WeatherPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _WeatherPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 11),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4A9EFF), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_location_alt_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Chưa có địa điểm nào",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Nhấn nút + để thêm vị trí theo dõi.",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}