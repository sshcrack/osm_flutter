import 'package:flutter/material.dart';

import '../controller/picker_map_controller.dart';
import '../osm_flutter.dart';

/// CustomPickerLocation
///
/// used to create customizable search location widget using OSMFlutter : to pick location from address
///
/// [controller] : controller for custom picker location
///
/// [appBarPicker] : toolbar widget for CustomPickerLocation
///
/// [topWidgetPicker] :  widget above of osm flutter widget to show list of address suggestion
///
/// [bottomWidgetPicker] :  widget on bottom of screen and above the osm flutter widget to show another information or action widget for the picker
class CustomPickerLocation extends StatefulWidget {
  final AppBar? appBarPicker;
  final Widget? topWidgetPicker;
  final Widget? bottomWidgetPicker;
  final PickerMapController controller;

  CustomPickerLocation({
    required this.controller,
    this.appBarPicker,
    this.bottomWidgetPicker,
    this.topWidgetPicker,
    Key? key,
  }) : super(key: key);

  static PickerMapController of<T>(
    BuildContext context, {
    bool nullOk = false,
  }) {
    final _CustomPickerLocationState? result =
        context.findAncestorStateOfType<_CustomPickerLocationState>();
    if (nullOk || result != null) return result!.widget.controller;
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary(
          'CustomPickerLocation.of() called with a context that does not contain an MapController.'),
      ErrorDescription(
          'No CustomPickerLocation ancestor could be found starting from the context that was passed to CustomPickerLocation.of().'),
      context.describeElement('The context used was')
    ]);
  }

  @override
  _CustomPickerLocationState createState() => _CustomPickerLocationState();
}

class _CustomPickerLocationState extends State<CustomPickerLocation> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: widget.appBarPicker,
          body: Stack(
            children: [
              Positioned.fill(
                child: OSMFlutter(
                  controller: widget.controller,
                  isPicker: true,
                ),
              ),
              if (widget.topWidgetPicker != null) ...[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: widget.topWidgetPicker!,
                ),
              ],
              if (widget.bottomWidgetPicker != null) ...[
                widget.bottomWidgetPicker!,
              ],
            ],
          ),
        );
      },
    );
  }
}
