import 'dart:collection';
import 'dart:convert';

class PolicyAxis {
  String name;
  List<String> attributes;
  bool hierarchical;

  PolicyAxis(this.name, this.attributes, this.hierarchical);

  int getLen() {
    return attributes.length;
  }

  PolicyAxis.fromJson(MapEntry<String, dynamic> json)
      : name = json.key,
        attributes = json.value[0].cast<String>(),
        hierarchical = json.value[1];

  Set<Object> toJson() => {attributes, hierarchical};
}

class PolicyAttributeUid {
  String axis;
  String name;

  PolicyAttributeUid(this.axis, this.name);

  PolicyAttributeUid.fromList(List<String> args)
      : axis = args[0],
        name = args[1];

  Map<String, dynamic> toJson() => {'axis': axis, 'name': name};

  @override
  String toString() {
    return "$axis::$name";
  }
}

class Policy {
  int maxAttributeCreations;
  int lastAttributeValue;
  Map<String, PolicyAxis> axes;
  Map<PolicyAttributeUid, SplayTreeSet<int>> attributeToInt;

  Policy(this.maxAttributeCreations, this.lastAttributeValue, this.axes,
      this.attributeToInt);

  Policy.empty()
      : this(defaultMaxAttributeCreations, defaultLastAttributeValue,
            defaultAxes, defaultAttributeToInt);

  Policy.withMaxAttributeCreations(int maxAttributeCreations)
      : this(maxAttributeCreations, defaultLastAttributeValue, defaultAxes,
            defaultAttributeToInt);

  static int get defaultMaxAttributeCreations => 2 ^ 32 - 1;
  static int get defaultLastAttributeValue => 0;
  static Map<String, PolicyAxis> get defaultAxes => {};
  static Map<PolicyAttributeUid, SplayTreeSet<int>> get defaultAttributeToInt =>
      {};

  Policy addAxis(String name, List<String> attributes, bool hierarchical) {
    final axis = PolicyAxis(name, attributes, hierarchical);
    if (axis.getLen() + lastAttributeValue > maxAttributeCreations) {
      throw Exception("Attribute capacity overflow");
    }
    if (axes.containsKey(axis.name)) {
      throw Exception("Policy ${axis.name} already exists");
    }
    axes[axis.name] = axis;
    for (final attribute in axis.attributes) {
      lastAttributeValue += 1;
      attributeToInt[PolicyAttributeUid(axis.name, attribute)] =
          SplayTreeSet<int>.from([lastAttributeValue]);
    }
    return this;
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Policy.fromJson(Map<String, dynamic> json)
      : lastAttributeValue = json['last_attribute_value'],
        maxAttributeCreations = json['max_attribute_creations'],
        axes = fromAxes(json['axes']),
        attributeToInt = fromAttributeToInt(json['attribute_to_int']);

  Map<String, dynamic> toJson() => {
        'last_attribute_value': lastAttributeValue,
        'max_attribute_creations': maxAttributeCreations,
        'axes':
            axes.map((key, value) => MapEntry(key, value.toJson().toList())),
        'attribute_to_int': attributeToInt
            .map((key, value) => MapEntry(key.toString(), value.toList()))
      };

  // Custom deserializer for non standard json
  static Map<String, PolicyAxis> fromAxes(Map<String, dynamic> json) {
    Map<String, PolicyAxis> output = {};

    for (final entry in json.entries) {
      output[entry.key] = PolicyAxis.fromJson(entry);
    }
    return output;
  }

  // Custom deserializer for non standard json
  static Map<PolicyAttributeUid, SplayTreeSet<int>> fromAttributeToInt(
      Map<String, dynamic> json) {
    Map<PolicyAttributeUid, SplayTreeSet<int>> output = {};

    for (final entry in json.entries) {
      final policyAttributeUid =
          PolicyAttributeUid.fromList(entry.key.split("::"));
      SplayTreeSet<int> tree = SplayTreeSet();
      for (final i in entry.value) {
        tree.add(i);
      }
      output[policyAttributeUid] = tree;
    }

    return output;
  }
}
