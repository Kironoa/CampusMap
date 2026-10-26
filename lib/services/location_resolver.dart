// lib/services/location_resolver.dart
//
// Single source of truth for natural-language location resolution.
//
// Everything here is derived from existing project data:
//  - [NavigationGraph] nodes, edges, roomToNode, startingPoints, floorTransitions
//  - [RoomCatalog] room names/ids
//  - [StartingLocations] QR starting-point names
//
// The resolver never invents rooms, stairs, or connections. It only maps
// user text to node IDs / room IDs that already exist in the graph.

import 'navigation_graph.dart';
import 'room_catalog.dart';
import '../config/starting_locations.dart';

enum LocationKind { room, start }

class LocationCandidate {
  final LocationKind kind;
  final String label;
  final String nodeId;
  final int floor;
  final String? roomId;
  final Set<String> aliases;

  const LocationCandidate({
    required this.kind,
    required this.label,
    required this.nodeId,
    required this.floor,
    this.roomId,
    this.aliases = const {},
  });
}

enum ResolutionStatus { single, ambiguous, notFound }

class LocationResolution {
  final ResolutionStatus status;
  final LocationCandidate? location;
  final List<LocationCandidate> candidates;

  const LocationResolution.single(this.location)
    : status = ResolutionStatus.single,
      candidates = const [];

  const LocationResolution.ambiguous(this.candidates)
    : status = ResolutionStatus.ambiguous,
      location = null;

  const LocationResolution.notFound()
    : status = ResolutionStatus.notFound,
      location = null,
      candidates = const [];
}

class ParsedRouteRequest {
  final String? startRaw;
  final String? destRaw;
  const ParsedRouteRequest({this.startRaw, this.destRaw});
}

/// Normalizes user text for matching.
///
/// - lowercases
/// - splits compounds like "leftside" -> "left side"
/// - unifies stair/stairs/staircase -> "stair", elevators -> "elevator"
/// - strips punctuation, collapses whitespace
String normalizeLocationText(String input) {
  var t = input.toLowerCase();
  t = t.replaceAll('&', ' and ');
  t = t.replaceAll('leftside', 'left side');
  t = t.replaceAll('rightside', 'right side');
  // Keep alphanumerics and spaces only.
  t = t.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
  t = t.replaceAll(RegExp(r'\bstaircases?\b'), 'stair');
  t = t.replaceAll(RegExp(r'\bstairs\b'), 'stair');
  t = t.replaceAll(RegExp(r'\belevators\b'), 'elevator');
  t = t.replaceAll(RegExp(r'\bdoors\b'), 'door');
  t = t.replaceAll(RegExp(r'\brooms?\b'), 'room');
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t;
}

List<String> _tokens(String normalized) {
  if (normalized.isEmpty) return const [];
  return normalized.split(' ');
}

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  final prev = List<int>.generate(b.length + 1, (j) => j);
  final curr = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    curr[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var v = prev[j] + 1;
      final ins = curr[j - 1] + 1;
      if (ins < v) v = ins;
      final sub = prev[j - 1] + cost;
      if (sub < v) v = sub;
      curr[j] = v;
    }
    for (var j = 0; j <= b.length; j++) {
      prev[j] = curr[j];
    }
  }
  return prev[b.length];
}

const _typeWords = {
  'stair',
  'elevator',
  'door',
  'entrance',
  'lobby',
  'stage',
  'room',
  'office',
  'lab',
  'laboratory',
  'clinic',
  'lounge',
  'court',
  'center',
  'hall',
};

String? _dominantType(List<String> tokens) {
  for (final t in tokens) {
    if (_typeWords.contains(t)) return t;
  }
  // stair-related fallback: staircase already normalized to stair.
  return null;
}

/// Scores a normalized query against one normalized alias (0..100).
double _aliasScore(String query, String alias) {
  if (query.isEmpty || alias.isEmpty) return 0;
  if (query == alias) return 100;

  final qTokens = _tokens(query);
  final aTokens = _tokens(alias);
  if (qTokens.isEmpty || aTokens.isEmpty) return 0;

  // Single-token fuzzy: handles "libray" -> "library", "ciso" exact, etc.
  if (qTokens.length == 1 && aTokens.length == 1) {
    final dist = _levenshtein(qTokens.first, aTokens.first);
    if (dist == 0) return 100;
    if (dist == 1 && qTokens.first.length >= 4) return 90;
    if (dist == 2 && qTokens.first.length >= 6) return 80;
    // Short codes like "cr" must match exactly as a token elsewhere;
    // handled by the multi-token path below.
    return 0;
  }

  final qSet = qTokens.toSet();
  final aSet = aTokens.toSet();
  final common = qSet.intersection(aSet).length;
  if (common == 0) {
    if (qTokens.length == aTokens.length && qTokens.length <= 3) {
      var totalDist = 0;
      for (var i = 0; i < qTokens.length; i++) {
        totalDist += _levenshtein(qTokens[i], aTokens[i]);
      }
      if (totalDist <= 1) return 85;
      if (totalDist <= 2) return 70;
    }
    return 0;
  }

  // F1 over token sets.
  var score = 100.0 * (2 * common) / (qSet.length + aSet.length);

  // Type agreement matters: "stair" query should prefer stair candidates
  // over doors, and vice versa.
  final qType = _dominantType(qTokens);
  final aType = _dominantType(aTokens);
  if (qType != null && aType != null) {
    if (qType == aType) {
      score += 10;
    } else {
      score -= 12;
    }
  } else if (qType != null && aType == null) {
    score -= 4;
  }

  // Prefer candidates whose length is close to the query (avoids a tiny
  // query like "cr" scoring highly against a long unrelated name just
  // because one token matches).
  final lenDiff = (qSet.length - aSet.length).abs();
  score -= lenDiff * 2.0;

  // Short-code subset: every query token appears in the candidate
  // (e.g. "cr" in "cr left 1"). Lift to ambiguity range so the caller asks
  // which one instead of reporting not-found.
  if (qSet.difference(aSet).isEmpty && qSet.length <= 2) {
    final floor = 70.0 - lenDiff * 2.0;
    if (score < floor) score = floor;
  }

  if (score > 100) score = 100;
  if (score < 0) score = 0;
  return score;
}

String _humanizeNodeId(String nodeId) {
  // gf_start_stairs_left_top -> "stairs left top"
  var t = nodeId.toLowerCase();
  t = t.replaceAll(RegExp(r'^(gf|sf|tf)_'), '');
  t = t.replaceAll('_', ' ');
  return normalizeLocationText(t);
}

String floorName(int floor) {
  switch (floor) {
    case 0:
      return 'Ground Floor';
    case 1:
      return '2nd Floor';
    case 2:
      return '3rd Floor';
    default:
      return 'Floor $floor';
  }
}

class LocationResolver {
  static List<LocationCandidate>? _index;

  static List<LocationCandidate> get index {
    final cached = _index;
    if (cached != null) return cached;
    final built = _buildIndex();
    _index = built;
    return built;
  }

  static void _mergeAliases(
    List<LocationCandidate> out, {
    required int floor,
    required String nodeId,
    required Set<String> extra,
  }) {
    final idx = out.indexWhere(
      (c) =>
          c.kind == LocationKind.start &&
          c.floor == floor &&
          c.nodeId == nodeId,
    );
    if (idx < 0) return;
    final prev = out[idx];
    final normalized = extra.map(normalizeLocationText).toSet()
      ..removeWhere((e) => e.isEmpty);
    out[idx] = LocationCandidate(
      kind: prev.kind,
      label: prev.label,
      nodeId: prev.nodeId,
      floor: prev.floor,
      roomId: prev.roomId,
      aliases: {...prev.aliases, ...normalized},
    );
  }

  static List<LocationCandidate> _buildIndex() {
    final out = <LocationCandidate>[];
    final seenNode = <String>{}; // "floor:nodeId"

    void addStart({
      required String label,
      required String nodeId,
      required int floor,
      Set<String> extraAliases = const {},
    }) {
      final key = '$floor:$nodeId';
      final aliases = <String>{
        normalizeLocationText(label),
        _humanizeNodeId(nodeId),
        ...extraAliases,
      };
      aliases.removeWhere((e) => e.isEmpty);
      if (seenNode.contains(key)) {
        // Merge aliases into the existing entry.
        final idx = out.indexWhere(
          (c) => c.kind == LocationKind.start && c.floor == floor && c.nodeId == nodeId,
        );
        if (idx >= 0) {
          final prev = out[idx];
          out[idx] = LocationCandidate(
            kind: prev.kind,
            label: prev.label,
            nodeId: prev.nodeId,
            floor: prev.floor,
            roomId: prev.roomId,
            aliases: {...prev.aliases, ...aliases},
          );
        }
        return;
      }
      seenNode.add(key);
      out.add(
        LocationCandidate(
          kind: LocationKind.start,
          label: label,
          nodeId: nodeId,
          floor: floor,
          aliases: aliases,
        ),
      );
    }

    // 1. Configured starting points (authoritative stair/entrance names).
    for (final entry in NavigationGraph.startingPoints.entries) {
      final floor = entry.key;
      for (final sp in entry.value) {
        final label = sp['label']!;
        final nodeId = sp['nodeId']!;
        addStart(label: label, nodeId: nodeId, floor: floor);
      }
    }

    // 2. QR starting locations (extra human names for the same nodes).
    final qrLists = [
      StartingLocations.groundFloorLocations,
      StartingLocations.secondFloorLocations,
      StartingLocations.thirdFloorLocations,
    ];
    for (final list in qrLists) {
      for (final loc in list) {
        final nodeId = loc.navNodeId;
        if (nodeId == null) continue;
        addStart(label: loc.name, nodeId: nodeId, floor: loc.floor);
      }
    }

    // 3. Any remaining stair/elevator/start graph nodes (so "elevator" on
    // every floor resolves to a real node even when not in startingPoints).
    for (var floor = 0; floor < 3; floor++) {
      for (final n in NavigationGraph.nodesForFloor(floor)) {
        final id = n.id.toLowerCase();
        final isNav = id.contains('start') || id.contains('stair') || id.contains('elevator');
        if (!isNav) continue;
        final key = '$floor:${n.id}';
        if (seenNode.contains(key)) continue;
        // Humanize deterministically from the node id; no invented geometry.
        final pretty = n.id
            .replaceAll(RegExp(r'^(gf|sf|tf)_'), '')
            .replaceAll('_', ' ');
        final label = pretty
            .split(' ')
            .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
            .join(' ');
        addStart(label: label, nodeId: n.id, floor: floor);
      }
    }

    // 3b. Documented spelling-variant aliases: wing stairs are the side
    // stairs users mean by "leftside stair" / "left side stair" /
    // "left stairs" (and mirrored right side). These map to EXISTING nodes.
    _mergeAliases(
      out,
      floor: 0,
      nodeId: 'gf_start_stairs_left_top',
      extra: {
        'left side stair',
        'leftside stair',
        'left stairs',
        'left side stairs',
        'left wing stairs',
      },
    );
    _mergeAliases(
      out,
      floor: 0,
      nodeId: 'gf_start_stairs_right_top',
      extra: {
        'right side stair',
        'rightside stair',
        'right stairs',
        'right side stairs',
        'right wing stairs',
      },
    );

    // 4. Rooms from the catalog (destination candidates).
    for (var f = 0; f < RoomCatalog.floorKeys.length; f++) {
      final floorKey = RoomCatalog.floorKeys[f];
      final rooms = RoomCatalog.allRooms[floorKey]!;
      for (final room in rooms) {
        final name = room['name']!;
        final id = room['id']!;
        final nodeId =
            NavigationGraph.roomToNode[id] ?? '$id(unmapped)';
        final aliases = <String>{normalizeLocationText(name)};
        // Add a compact code alias: "MB 105" -> "mb105" as well.
        final compact = normalizeLocationText(name).replaceAll(' ', '');
        if (compact.isNotEmpty) aliases.add(compact);
        aliases.removeWhere((e) => e.isEmpty);
        out.add(
          LocationCandidate(
            kind: LocationKind.room,
            label: name,
            nodeId: nodeId,
            floor: f,
            roomId: id,
            aliases: aliases,
          ),
        );
      }
    }

    return out;
  }

  /// Resolves [query] to a single location, an ambiguity list, or notFound.
  ///
  /// [preferredFloor] boosts same-floor candidates (e.g. prefer the
  /// ground-floor staircase when the destination is on the ground floor).
  /// [kindFilter] restricts to rooms or starts when the caller knows which
  /// slot is being filled.
  static LocationResolution resolve(
    String query, {
    int? preferredFloor,
    LocationKind? kindFilter,
  }) {
    final nq = normalizeLocationText(query);
    if (nq.isEmpty) return const LocationResolution.notFound();

    final scored = <({LocationCandidate c, double score})>[];
    for (final c in index) {
      if (kindFilter != null && c.kind != kindFilter) continue;
      var best = 0.0;
      for (final alias in c.aliases) {
        final s = _aliasScore(nq, alias);
        if (s > best) best = s;
      }
      if (best <= 0) continue;
      if (preferredFloor != null && c.floor == preferredFloor) {
        // Floor context is decisive: allow boosted scores above 100 so a
        // same-floor exact match beats cross-floor exact matches instead of
        // tying into a false ambiguity.
        best += 10;
        if (best > 110) best = 110;
      } else if (best > 100) {
        best = 100;
      }
      scored.add((c: c, score: best));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    if (scored.isEmpty || scored.first.score < 55) {
      return const LocationResolution.notFound();
    }

    // Distinct locations only (same node/room merged).
    final distinct = <({LocationCandidate c, double score})>[];
    final seen = <String>{};
    for (final s in scored) {
      final key =
          '${s.c.kind}:${s.c.roomId ?? s.c.nodeId}:${s.c.floor}';
      if (seen.contains(key)) continue;
      seen.add(key);
      distinct.add(s);
    }

    final top = distinct.first;
    if (distinct.length > 1) {
      final second = distinct[1];
      if ((top.score - second.score).abs() <= 5 && second.score >= 55) {
        // Floor context disambiguates: when the caller prefers a floor
        // (e.g. the destination's floor for a start query) and exactly one
        // of the tied leaders is on it, choose it instead of asking.
        if (preferredFloor != null) {
          final topPref = top.c.floor == preferredFloor;
          final secondPref = second.c.floor == preferredFloor;
          if (topPref && !secondPref) {
            return LocationResolution.single(top.c);
          }
          if (secondPref && !topPref) {
            return LocationResolution.single(second.c);
          }
        }
        // Ambiguous: return the top few close candidates.
        final cands = distinct
            .where((s) => (top.score - s.score) <= 8 && s.score >= 55)
            .take(4)
            .map((s) => s.c)
            .toList();
        return LocationResolution.ambiguous(cands);
      }
    }
    return LocationResolution.single(top.c);
  }

  /// Human label for a graph node (prefers configured start labels).
  static String labelForNode(String nodeId, int floor) {
    for (final c in index) {
      if (c.kind == LocationKind.start &&
          c.nodeId == nodeId &&
          c.floor == floor) {
        return c.label;
      }
    }
    for (final entry in NavigationGraph.roomToNode.entries) {
      if (entry.value == nodeId) {
        final name = RoomCatalog.roomNameById(entry.key);
        if (name != null) return name;
      }
    }
    return _humanizeNodeId(nodeId);
  }
}

/// Splits free text into raw START / DESTINATION fragments.
///
/// Handles:
/// - "from X to Y" / "I'm from X, how ... to Y"
/// - "to Y from X" (reversed)
/// - destination-only ("navigate to Y", "where is Y", "how to get to Y")
String _cleanFragment(String s) {
  var t = s.trim();
  t = t.replaceAll(RegExp(r'[?.!]+$'), '').trim();
  t = t.replaceAll(RegExp(r'\bplease\b'), '').trim();
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  // Strip leading articles/pronouns that are not part of names.
  t = t.replaceAll(RegExp(r'^(the|a|an)\s+'), '').trim();
  return t;
}

ParsedRouteRequest parseRouteRequest(String text) {
  final lower = text.toLowerCase();

  // 1. "from X to Y" (X may contain a trailing ", how can i get" clause).
  final fromTo =
      RegExp(r'from\s+(.+?)\s+to\s+(.+?)(?:\?|\.|$)').firstMatch(lower);
  if (fromTo != null) {
    var s = _cleanFragment(fromTo.group(1)!);
    // "leftside stair, how can i get" -> keep the part before the comma.
    if (s.contains(',')) s = _cleanFragment(s.split(',').first);
    // Drop trailing how-phrases without commas:
    // "left stair how can i get" -> "left stair".
    s = s.replaceAll(RegExp(r'\bhow\b.*$'), '').trim();
    s = _cleanFragment(s);
    var d = _cleanFragment(fromTo.group(2)!);
    return ParsedRouteRequest(
      startRaw: s.isEmpty ? null : s,
      destRaw: d.isEmpty ? null : d,
    );
  }

  // 2. Reversed: "to Y from X".
  final toFrom =
      RegExp(r'to\s+(.+?)\s+from\s+(.+?)(?:\?|\.|$)').firstMatch(lower);
  if (toFrom != null) {
    final d = _cleanFragment(toFrom.group(1)!);
    final s = _cleanFragment(toFrom.group(2)!);
    return ParsedRouteRequest(
      startRaw: s.isEmpty ? null : s,
      destRaw: d.isEmpty ? null : d,
    );
  }

  // 3. Destination-only patterns.
  final destPatterns = [
    RegExp(r'navigate\s+to\s+(.+?)(?:\?|\.|$)'),
    RegExp(r'go\s+to\s+(.+?)(?:\?|\.|$)'),
    RegExp(r'get\s+to\s+(.+?)(?:\?|\.|$)'),
    RegExp(r'way\s+to\s+(.+?)(?:\?|\.|$)'),
    RegExp(r'route\s+to\s+(.+?)(?:\?|\.|$)'),
    RegExp(r'directions?\s+to\s+(.+?)(?:\?|\.|$)'),
    RegExp(r'where\s+is\s+(.+?)(?:\?|\.|$)'),
  ];
  for (final p in destPatterns) {
    final m = p.firstMatch(lower);
    if (m != null) {
      final d = _cleanFragment(m.group(1)!);
      // There may still be a separate "from X" clause (e.g. "how to get
      // to CISO? I'm from X" spans two sentences — keep it simple: look
      // for a from-clause anywhere).
      final fromOnly =
          RegExp(r'from\s+([^?.!]+)').firstMatch(lower);
      String? s;
      if (fromOnly != null) {
        s = _cleanFragment(fromOnly.group(1)!);
        if (s.contains(',')) s = _cleanFragment(s.split(',').first);
        s = s.replaceAll(RegExp(r'\bhow\b.*$'), '').trim();
        if (s.isEmpty) s = null;
      }
      return ParsedRouteRequest(
        startRaw: s,
        destRaw: d.isEmpty ? null : d,
      );
    }
  }

  // 4. Bare "from X" with no destination.
  final fromOnly =
      RegExp(r"(?:i'?m\s+from|i\s+am\s+from|from)\s+([^?.!]+)").firstMatch(lower);
  if (fromOnly != null) {
    var s = _cleanFragment(fromOnly.group(1)!);
    if (s.contains(',')) s = _cleanFragment(s.split(',').first);
    s = s.replaceAll(RegExp(r'\bhow\b.*$'), '').trim();
    return ParsedRouteRequest(
      startRaw: s.isEmpty ? null : s,
      destRaw: null,
    );
  }

  return const ParsedRouteRequest();
}
