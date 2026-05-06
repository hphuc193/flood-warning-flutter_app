// lib/data/services/map_offline_service.dart
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class MapOfflineService {
  static const String storeName = 'fws_offline_map';

  static Future<void> init() async {
    // Khởi tạo thư viện FMTC
    await FMTCObjectBoxBackend().initialise();
    final store = FMTCStore(storeName);
    await store.manage.create();
  }

  // Hàm tải ngầm bản đồ bán kính 20km
  static Future<void> downloadMapRegion(double lat, double lon) async {
    final store = FMTCStore(storeName);

    final region = CircleRegion(
      LatLng(lat, lon),
      20.0, // 20 km
    );

    // Cấu hình tải từ mức Zoom 8 đến 15
    final downloadableRegion = region.toDownloadable(
      minZoom: 8,
      maxZoom: 15,
      options: TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      ),
    );

    final _ = store.download.startForeground(
      region: downloadableRegion,
      parallelThreads: 4,
      skipExistingTiles: true,
    );
  }
}