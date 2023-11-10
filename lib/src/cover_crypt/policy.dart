import 'dart:convert';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';

import 'cover_crypt.dart';

class PolicyAxis {
  String name;
  List<Tuple2<String, bool>> attributes;
  bool hierarchical;

  PolicyAxis(this.name, this.attributes, this.hierarchical);

  int getLen() {
    return attributes.length;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'attributes_properties': attributes
            .map((e) => {
                  'name': e.item1,
                  'encryption_hint': e.item2 == false ? 'Classic' : 'Hybridized'
                })
            .toList(),
        'hierarchical': hierarchical
      };

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

class Policy {
  Uint8List rawPolicy;
  Map<String, PolicyAxis> axes;

  Policy(this.rawPolicy, this.axes) {
    rawPolicy = CoverCrypt.generatePolicy();
  }

  Policy.init()
      : this(
          defaultRawPolicy,
          defaultAxes,
        );

  static Uint8List get defaultRawPolicy => Uint8List.fromList([]);
  static Map<String, PolicyAxis> get defaultAxes => {};

  Policy addAxis(
      String name, List<Tuple2<String, bool>> attributes, bool hierarchical) {
    final axis = PolicyAxis(name, attributes, hierarchical);
    if (axes.containsKey(axis.name)) {
      throw Exception("Policy ${axis.name} already exists");
    }
    axes[axis.name] = axis;
    if (rawPolicy.isEmpty) {
      throw Exception("Policy not initialized");
    }
    rawPolicy = CoverCrypt.addPolicyAxis(this, axis);
    return this;
  }

  Uint8List toBytes() {
    return rawPolicy;
  }
}
