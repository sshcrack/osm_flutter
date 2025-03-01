import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../flutter_osm_plugin.dart';
import '../interface_osm/osm_interface.dart';
import '../types/geo_point.dart';

abstract class EventOSM<T> {
  /// The ID of the Map this event is associated to.
  final int mapId;

  /// The value wrapped by this event
  final T value;

  /// Build a Map Event, that relates a mapId with a given value.
  ///
  /// The `mapId` is the id of the map that triggered the event.
  /// `value` may be `null` in events that don't transport any meaningful data.
  EventOSM(this.mapId, this.value);
}

class GeoPointEvent extends EventOSM<GeoPoint> {
  GeoPointEvent(int mapId, GeoPoint position) : super(mapId, position);
}

class UserLocationEvent extends EventOSM<GeoPoint> {
  UserLocationEvent(int mapId, GeoPoint position) : super(mapId, position);
}

class MethodChannelOSM extends OSMPlatform {
  final Map<int, MethodChannel> _channels = {};

  //final Map<int, List<EventChannel>> _eventsChannels = {};
  StreamController _streamController = StreamController<EventOSM>.broadcast();

  // Returns a filtered view of the events in the _controller, by mapId.
  Stream<EventOSM> _events(int mapId) =>
      _streamController.stream.where((event) => event.mapId == mapId)
          as Stream<EventOSM>;

  @override
  Future<void> init(int idOSMMap) async {
    locationService = Location();
    if (!_channels.containsKey(idOSMMap)) {
      _channels[idOSMMap] =
          MethodChannel('plugins.dali.hamza/osmview_$idOSMMap');
      setGeoPointHandler(idOSMMap);
    }
    /*if (!_eventsChannels.containsKey(idOSMMap)) {
      _eventsChannels[idOSMMap] = [
       // EventChannel("plugins.dali.hamza/osmview_stream_$idOSMMap"),
        EventChannel("plugins.dali.hamza/osmview_stream_location_$idOSMMap"),
      ];
    }*/
  }

  @override
  Stream<GeoPointEvent> onGeoPointClickListener(int idMap) {
    return _events(idMap).whereType<GeoPointEvent>();
  }

  @override
  Stream<UserLocationEvent> onUserPositionListener(int idMap) {
    return _events(idMap).whereType<UserLocationEvent>();
  }

  void setGeoPointHandler(int idMap) async {
    _channels[idMap]!.setMethodCallHandler((call) async {
      switch (call.method) {
        case "receiveGeoPoint":
          final result = call.arguments;
          _streamController.add(GeoPointEvent(idMap, GeoPoint.fromMap(result)));
          break;
        case "receiveUserLocation":
          final result = call.arguments;
          _streamController
              .add(UserLocationEvent(idMap, GeoPoint.fromMap(result)));
          break;
      }
      return true;
    });
  }

  @override
  void close() {
    _streamController.close();
  }

  @override
  Future<void> currentLocation(int? idOSM) async {
    try {
      await _channels[idOSM]!.invokeMethod("currentLocation", null);
    } on PlatformException catch (e) {
      throw GeoPointException(msg: e.message);
    }
  }

  @override
  Future<GeoPoint> myLocation(int idMap) async {
    try {
      Map<String, dynamic> map =
          (await (_channels[idMap]!.invokeMapMethod("user#position")))!;
      return GeoPoint(latitude: map["lat"], longitude: map["lon"]);
    } on PlatformException catch (e) {
      throw GeoPointException(msg: e.message);
    }
  }

  @override
  Future<void> addPosition(int idOSM, GeoPoint p) async {
    Map requestData = {"lon": p.longitude, "lat": p.latitude};
    await _channels[idOSM]!.invokeListMethod(
      "initPosition",
      requestData,
    );
  }

  @override
  Future<void> customMarker(int idOSM, GlobalKey? globalKey) async {
    Uint8List icon = await _capturePng(globalKey!);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      var base64Str = base64.encode(icon);
      await _channels[idOSM]!.invokeMethod("marker#icon", base64Str);
    } else
      await _channels[idOSM]!.invokeMethod("marker#icon", icon);
  }

  @override
  Future<void> customMarkerStaticPosition(
      int idOSM, GlobalKey? globalKey, String id) async {
    Uint8List icon = await _capturePng(globalKey!);

    await _channels[idOSM]!.invokeMethod(
      "staticPosition#IconMarker",
      {
        "id": id,
        "bitmap": icon,
      },
    );
  }

  @override
  Future<void> disableTracking(int idOSM) async {
    await _channels[idOSM]!.invokeMethod('deactivateTrackMe', null);
  }

  @override
  Future<RoadInfo> drawRoad(
    int idOSM,
    GeoPoint start,
    GeoPoint end, {
    Color? roadColor,
    double? roadWidth,
  }) async {
    final Map args = {
      "wayPoints": [
        start.toMap(),
        end.toMap(),
      ]
    };
    if (roadColor != null) {
      args.addAll(roadColor.toMap("roadColor"));
    }
    if (roadWidth != null) {
      args.addAll({"roadWidth": roadWidth});
    }
    try {
      Map map = (await (_channels[idOSM]!.invokeMethod(
        "road",
        args,
      )))!;
      return RoadInfo.fromMap(map);
    } on PlatformException catch (e) {
      throw RoadException(msg: e.message);
    }
  }

  @override
  Future<void> enableTracking(int idOSM) async {
    await _channels[idOSM]!.invokeMethod('trackMe', null);
  }

  /// select position and show marker on it
  @override
  Future<GeoPoint> pickLocation(int idOSM) async {
    try {
      Map<String, dynamic> map = (await (_channels[idOSM]!
          .invokeMapMethod("user#pickPosition", null)))!;
      return GeoPoint(latitude: map["lat"], longitude: map["lon"]);
    } on PlatformException catch (e) {
      throw GeoPointException(msg: e.message);
    }
  }

  @override
  Future<void> removeLastRoad(int idOSM) async {
    await _channels[idOSM]!.invokeListMethod("user#removeroad");
  }

  @override
  Future<void> removePosition(int idOSM, GeoPoint p) async {
    await _channels[idOSM]!
        .invokeListMethod("user#removeMarkerPosition", p.toMap());
  }

  @override
  Future<void> setColorRoad(int idOSM, Color color) async {
    await _channels[idOSM]!
        .invokeMethod("road#color", [color.red, color.green, color.blue]);
  }

  @override
  Future<void> setDefaultZoom(int idOSM, double defaultZoom) async {
    try {
      await _channels[idOSM]!.invokeMethod("defaultZoom", defaultZoom);
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  /// change marker of road
  /// [keys]   :(List of GlobalKey) keys of widget of start,middle and end custom marker in road
  /// [idOSM]     : (int) osm id native
  @override
  Future<void> setMarkersRoad(int idOSM, List<GlobalKey?> keys) async {
    final startKey = keys.first!;
    final middleKey = keys[1]!;
    final endKey = keys.last!;
    Map<String, Uint8List> bitmaps = {};
    if (startKey.currentContext != null) {
      Uint8List marker = await _capturePng(startKey);
      bitmaps.putIfAbsent("START", () => marker);
    }
    if (endKey.currentContext != null) {
      Uint8List marker = await _capturePng(endKey);
      bitmaps.putIfAbsent("END", () => marker);
    }
    if (middleKey.currentContext != null) {
      Uint8List marker = await _capturePng(middleKey);
      bitmaps.putIfAbsent("MIDDLE", () => marker);
    }
    await _channels[idOSM]!.invokeMethod("road#markers", bitmaps);
  }

  @override
  Future<void> setSecureURL(int idOSM, bool secure) async {
    await _channels[idOSM]!.invokeMethod('use#secure', secure);
  }

  @override
  Future<void> staticPosition(
      int idOSM, List<GeoPoint> pList, String id) async {
    try {
      List<Map<String, double?>> listGeos = [];
      for (GeoPoint p in pList) {
        listGeos.add({"lon": p.longitude, "lat": p.latitude});
      }
      await _channels[idOSM]!
          .invokeMethod("staticPosition", {"id": id, "point": listGeos});
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  @override
  Future<void> zoom(int idOSM, double zoom) async {
    await _channels[idOSM]!.invokeMethod('Zoom', zoom);
  }

  Future<Uint8List> _capturePng(GlobalKey globalKey) async {
    RenderRepaintBoundary boundary =
        globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData byteData =
        (await (image.toByteData(format: ui.ImageByteFormat.png)))!;
    Uint8List pngBytes = byteData.buffer.asUint8List();
    return pngBytes;
  }

  @override
  Future<void> visibilityInfoWindow(int idOSM, bool visible) async {
    await _channels[idOSM]!.invokeMethod("use#visiblityInfoWindow", visible);
  }

  @override
  Future<void> drawCircle(int idOSM, CircleOSM circleOSM) async {
    Map requestData = {
      "lon": circleOSM.centerPoint.longitude,
      "lat": circleOSM.centerPoint.latitude,
      "key": circleOSM.key,
      "radius": circleOSM.radius,
      "stokeWidth": circleOSM.strokeWidth,
      "color": [
        circleOSM.color.red,
        circleOSM.color.blue,
        circleOSM.color.green,
      ],
    };
    await _channels[idOSM]!.invokeMethod("draw#circle", requestData);
  }

  @override
  Future<void> removeAllCircle(int idOSM) async {
    await _channels[idOSM]!.invokeMethod("remove#circle", null);
  }

  @override
  Future<void> removeCircle(int idOSM, String key) async {
    await _channels[idOSM]!.invokeMethod("remove#circle", key);
  }

  @override
  Future<void> advancedPositionPicker(int idOSM) async {
    await _channels[idOSM]!.invokeMethod("advanced#selection");
  }

  @override
  Future<void> cancelAdvancedPositionPicker(int idOSM) async {
    await _channels[idOSM]!.invokeMethod(
      "cancel#advanced#selection",
    );
  }

  @override
  Future<GeoPoint> selectAdvancedPositionPicker(int idOSM) async {
    Map mGeoPoint = (await (_channels[idOSM]!
        .invokeMapMethod("confirm#advanced#selection")))!;
    return GeoPoint.fromMap(mGeoPoint);
  }

  @override
  Future<void> drawRect(int idOSM, RectOSM rectOSM) async {
    Map requestData = {
      "lon": rectOSM.centerPoint.longitude,
      "lat": rectOSM.centerPoint.latitude,
      "key": rectOSM.key,
      "distance": rectOSM.distance,
      "stokeWidth": rectOSM.strokeWidth,
      "color": [
        rectOSM.color.red,
        rectOSM.color.blue,
        rectOSM.color.green,
      ],
    };
    await _channels[idOSM]!.invokeMethod("draw#rect", requestData);
  }

  @override
  Future<void> removeRect(int idOSM, String key) async {
    await _channels[idOSM]!.invokeMethod("remove#rect", key);
  }

  @override
  Future<void> removeAllRect(int idOSM) async {
    await _channels[idOSM]!.invokeMethod("remove#rect", null);
  }

  @override
  Future<void> removeAllShapes(int idOSM) async {
    await _channels[idOSM]!.invokeMethod("clear#shapes");
  }

  /// get position without finish advanced picker
  @override
  Future<GeoPoint> getPositionOnlyAdvancedPositionPicker(int idOSM) async {
    Map mGeoPoint = (await (_channels[idOSM]!
        .invokeMapMethod("get#position#advanced#selection")))!;
    return GeoPoint.fromMap(mGeoPoint);
  }

  @override
  Future<void> goToPosition(int idOSM, GeoPoint p) async {
    Map requestData = {"lon": p.longitude, "lat": p.latitude};
    await _channels[idOSM]!.invokeListMethod(
      "goto#position",
      requestData,
    );
  }

  @override
  Future<void> drawRoadManually(
    int idOSM,
    List<GeoPoint> road,
  ) async {
    final listMapRoad = road.map((e) => e.toMap());
    await _channels[idOSM]!.invokeListMethod(
      "drawRoad#manually",
      [
        {"road": listMapRoad}
      ],
    );
  }
}
