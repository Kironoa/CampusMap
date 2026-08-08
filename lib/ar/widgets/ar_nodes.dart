// lib/ar/widgets/ar_nodes.dart
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart';

import '../ar_config.dart';
import '../services/ar_anchor_mapper.dart';

/// Creates the AR nodes (3D models) for the different scene elements.
class ArNodes {
  ArNodes._();

  /// A guide arrow pointing in the direction of travel.
  static ARNode arrow(ArAnchorPoint point) {
    return ARNode(
      type: NodeType.localGLTF2,
      uri: ArConfig.arrowModel,
      name: 'arrow',
      position: point.position,
      scale: Vector3.all(ArConfig.arrowSize),
      // Arrow model's forward is +Z; rotate about Y to face the segment.
      rotation: Vector4(0, 1, 0, point.yaw),
    );
  }

  /// The pulsing destination marker.
  static ARNode destination(ArAnchorPoint point) {
    return ARNode(
      type: NodeType.localGLTF2,
      uri: ArConfig.destinationModel,
      name: 'destination',
      position: point.position,
      scale: Vector3.all(ArConfig.destinationSize),
    );
  }

  /// A small marker over a nearby room.
  static ARNode roomMarker(ArAnchorPoint point) {
    return ARNode(
      type: NodeType.localGLTF2,
      uri: ArConfig.roomMarkerModel,
      name: point.nodeName ?? 'room',
      position: point.position,
      scale: Vector3.all(ArConfig.roomMarkerSize),
      data: point.roomId == null ? null : {'roomId': point.roomId},
    );
  }
}