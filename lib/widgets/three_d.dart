import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Minimal 3D vector, enough for rotation, lighting and projection. No external package needed.
class Vec3 {
  final double x, y, z;
  const Vec3(this.x, this.y, this.z);

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double k) => Vec3(x * k, y * k, z * k);

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;
  Vec3 cross(Vec3 o) => Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => math.sqrt(x * x + y * y + z * z);

  Vec3 normalized() {
    final l = length;
    return l == 0 ? this : this * (1 / l);
  }

  static Vec3 lerp(Vec3 a, Vec3 b, double t) => a + (b - a) * t;

  static Vec3 average(List<Vec3> pts) {
    var sx = 0.0, sy = 0.0, sz = 0.0;
    for (final p in pts) {
      sx += p.x;
      sy += p.y;
      sz += p.z;
    }
    final n = pts.isEmpty ? 1 : pts.length;
    return Vec3(sx / n, sy / n, sz / n);
  }
}

/// Rotates a point around the Y axis ([yaw]) and then the X axis ([pitch]).
/// After rotation, +z points toward the viewer.
Vec3 rotateYawPitch(Vec3 v, double yaw, double pitch) {
  final cy = math.cos(yaw), sy = math.sin(yaw);
  final x1 = v.x * cy + v.z * sy;
  final z1 = -v.x * sy + v.z * cy;
  final cp = math.cos(pitch), sp = math.sin(pitch);
  final y2 = v.y * cp - z1 * sp;
  final z2 = v.y * sp + z1 * cp;
  return Vec3(x1, y2, z2);
}

/// A projected point: screen position plus the perspective factor (bigger = closer).
class Projected {
  final Offset offset;
  final double k;
  const Projected(this.offset, this.k);
}

/// Simple perspective camera looking down -z from [distance].
class PerspectiveCamera {
  final Offset center;
  final double scale;
  final double distance;
  const PerspectiveCamera({required this.center, required this.scale, this.distance = 4.5});

  Projected project(Vec3 v) {
    final denom = math.max<double>(0.2, distance - v.z);
    final k = distance / denom;
    return Projected(Offset(center.dx + v.x * scale * k, center.dy - v.y * scale * k), k);
  }
}
