import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_osm_plugin/src/channel/osm_method_channel.dart';
import 'package:location/location.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class OSMPlatform extends PlatformInterface {
  OSMPlatform() : super(token: _token);
  late Location locationService;

  static final Object _token = Object();

  static OSMPlatform _instance = MethodChannelOSM();

  static OSMPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [OSMPlatformInterface] when they register themselves.
  static set instance(OSMPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> init(
    int idOSM,
  );

  void close();

  Stream<GeoPointEvent> onGeoPointClickListener(int idMap);

  Stream<UserLocationEvent> onUserPositionListener(int idMap);

  Future<void> setSecureURL(
    int idOSM,
    bool secure,
  );

  Future<void> currentLocation(
    int idOSM,
  );

  Future<GeoPoint> myLocation(
    int idMap,
  );

  Future<void> zoom(
    int idOSM,
    double zoom,
  );

  Future<GeoPoint> pickLocation(
    int idOSM,
  );

  Future<void> customMarker(
    int idOSM,
    GlobalKey? globalKey,
  );

  Future<void> setColorRoad(
    int idOSM,
    Color color,
  );

  Future<void> setMarkersRoad(
    int idOSM,
    List<GlobalKey?> keys,
  );

  Future<void> enableTracking(
    int idOSM,
  );

  Future<void> addPosition(
    int idOSM,
    GeoPoint p,
  );

  Future<void> goToPosition(
    int idOSM,
    GeoPoint p,
  );

  Future<void> removePosition(
    int idOSM,
    GeoPoint p,
  );

  Future<void> removeLastRoad(
    int idOSM,
  );

  Future<RoadInfo> drawRoad(
    int idOSM,
    GeoPoint start,
    GeoPoint end, {
    Color? roadColor,
    double? roadWidth,
  });

  Future<void> drawCircle(
    int idOSM,
    CircleOSM circleOSM,
  );

  Future<void> removeCircle(
    int idOSM,
    String key,
  );

  Future<void> drawRect(
    int idOSM,
    RectOSM rectOSM,
  );

  Future<void> removeRect(
    int idOSM,
    String key,
  );

  Future<void> removeAllRect(
    int idOSM,
  );

  Future<void> removeAllCircle(
    int idOSM,
  );

  Future<void> removeAllShapes(
    int idOSM,
  );

  Future<void> customMarkerStaticPosition(
    int idOSM,
    GlobalKey? globalKey,
    String id,
  );

  Future<void> staticPosition(
    int idOSM,
    List<GeoPoint> pList,
    String id,
  );

  Future<void> setDefaultZoom(
    int idOSM,
    double defaultZoom,
  );

  Future<void> disableTracking(
    int idOSM,
  );

  Future<void> visibilityInfoWindow(
    int idOSM,
    bool visible,
  );

  Future<void> advancedPositionPicker(
    int idOSM,
  );

  Future<GeoPoint> getPositionOnlyAdvancedPositionPicker(
    int idOSM,
  );

  Future<GeoPoint> selectAdvancedPositionPicker(
    int idOSM,
  );

  Future<void> cancelAdvancedPositionPicker(
    int idOSM,
  );

  Future<void> drawRoadManually(
    int idOSM,
    List<GeoPoint> road,
  );
}
