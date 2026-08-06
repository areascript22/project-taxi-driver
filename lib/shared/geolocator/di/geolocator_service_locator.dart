import 'package:get_it/get_it.dart';
import 'package:driver_app/shared/geolocator/service/geolocator/geolocator_service.dart';
import 'package:driver_app/shared/geolocator/service/geolocator/geolocator_service_impl.dart';

void initGeolocator(GetIt sl) {
  sl.registerFactory<GeolocatorService>(() => GeolocatorServiceServiceImpl());
}
