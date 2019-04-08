package haxegon;

typedef Vec2f = {
    x: Float,
    y: Float
}

typedef Vec2i = {
    x: Int,
    y: Int
}

@:publicFields
class MathExtensions {

    static function project_circle(math: Class<Math> = null, x: Float, y: Float, r: Float, axis: Vec2f): Vec2f {
        var dot = dot(x, y, axis.x, axis.y);
        return {x: dot - r, y: dot + r};
    }

    static function project_triangle(math: Class<Math> = null, tri: Array<Float>, axis: Vec2f): Vec2f {
        var dot1 = dot(tri[0], tri[1], axis.x, axis.y);
        var dot2 = dot(tri[2], tri[3], axis.x, axis.y);
        var dot3 = dot(tri[4], tri[5], axis.x, axis.y);
        return {x: min3(dot1, dot2, dot3), y: max3(dot1, dot2, dot3)};
    }

    static function project_rectangle(math: Class<Math> = null, x: Float, y: Float, width: Float, height: Float, axis: Vec2f): Vec2f {
        var dot1 = dot(x, y, axis.x, axis.y);
        var dot2 = dot(x + width, y, axis.x, axis.y);
        var dot3 = dot(x, y + height, axis.x, axis.y);
        var dot4 = dot(x + width, y + height, axis.x, axis.y);
        return {x: min4(dot1, dot2, dot3, dot4), y: max4(dot1, dot2, dot3, dot4)};
    }

    static function fixed_float(math: Class<Math> = null, x: Float, precision: Int): String {
        var string = '${x}';
        var dot = string.indexOf('.');
        if (dot == -1) {
            string += '.';
            dot = string.length - 1;
        }
        for (i in 0...(precision - (string.length - dot) + 1)) {
            string += '0';
        }
        return string.substr(0, dot + precision + 1);
    }

    // dynamic a-segment is collided against static b-segment; axis is left to right
    static function collision_1d(math: Class<Math> = null, a1: Float, a2: Float, b1: Float, b2: Float): Float {
        if (a1 < b1 && b2 < a2) {
            if (b2 - a1 < a2 - b1) {
                return b2 - a1;
            } else {
                return b1 - a2;
            }
        } else if (b1 < a1 && a2 < b2) {
            if (a2 - b1 < b2 - a1) {
                return b1 - a2;
            } else {
                return b2 - a1;
            }
        } else if (b1 < a1 && a1 < b2) {
            return b2 - a1;
        } else if (b1 < a2 && a2 < b2) {
            return b1 - a2;
        } else if (a1 == b1 && a2 == b2) {
            return a2 - a1;
        } else {
            return 0;
        }
    }

    static inline function max3(math: Class<Math> = null, x1: Float, x2: Float, x3: Float): Float {
        return Math.max(Math.max(x1, x2), x3);
    }
    static inline function max4(math: Class<Math> = null, x1: Float, x2: Float, x3: Float, x4: Float): Float {
        return Math.max(Math.max(Math.max(x1, x2), x3), x4);
    }
    static inline function min3(math: Class<Math> = null, x1: Float, x2: Float, x3: Float): Float {
        return Math.min(Math.min(x1, x2), x3);
    }
    static inline function min4(math: Class<Math> = null, x1: Float, x2: Float, x3: Float, x4: Float): Float {
        return Math.min(Math.min(Math.min(x1, x2), x3), x4);
    }

    static function scale_vertices(math: Class<Math> = null, vertices: Array<Float>, scale: Float, x: Float = null, y: Float = null) {
        if (x == null || y == null) {
            var centroid = poly_centroid(vertices);
            x = centroid.x;
            y = centroid.y;
        }
        for (i in 0...Std.int(vertices.length / 2)) {
            vertices[i * 2] = x + (vertices[i * 2] - x) * scale;
            vertices[i * 2 + 1] = y + (vertices[i * 2 + 1] - y) * scale;
        }
    }

    static function translate_vertices(math: Class<Math> = null, vertices: Array<Float>, dx: Float, dy: Float) {
        for (i in 0...Std.int(vertices.length / 2)) {
            vertices[i * 2] += dx;
            vertices[i * 2 + 1] += dy;
        }
    }

    static function rotate_vertices(math: Class<Math> = null, vertices: Array<Float>, origin_x: Float, origin_y: Float, angle: Float) {
        var rotated = {x: 0.0, y: 0.0};
        for (i in 0...Std.int(vertices.length / 2)) {
            rotated.x = vertices[i * 2];
            rotated.y = vertices[i * 2 + 1];
            rotate_vector(rotated, origin_x, origin_y, angle);
            vertices[i * 2] = rotated.x;
            vertices[i * 2 + 1] = rotated.y;
        }
        return vertices;
    }

    static function rotate_vector(math: Class<Math> = null, point: Vec2f, origin_x: Float, origin_y: Float, angle: Float) {
        var cos = Math.cos(deg_to_rad(angle));
        var sin = Math.sin(deg_to_rad(angle));
        point.x -= origin_x;
        point.y -= origin_y;
        var temp_x = point.x;
        var temp_y = point.y;
        point.x = temp_x * cos - temp_y * sin;
        point.y = temp_x * sin + temp_y * cos;
        point.x += origin_x;
        point.y += origin_y;
    }

    static inline function dot(math: Class<Math> = null, ux: Float, uy: Float, vx: Float, vy: Float): Float {
        return ux * vx + uy * vy;
    }

    static function normalize(math: Class<Math> = null, v: Vec2f): Vec2f {
        var length = Math.sqrt(v.x * v.x + v.y * v.y);
        v.x /= length;
        v.y /= length;
        return v;
    }

    static function project(math: Class<Math> = null, ux: Float, uy: Float, vx: Float, vy: Float): Vec2f {
        var dp = dot(ux, uy, vx, vy);
        var result = {
            x: (dp / (vx * vx + vy * vy)) * ux, 
            y: (dp / (vx * vx + vy * vy)) * uy
        };
        return result;
    }

    static inline function line_point_sign(math: Class<Math> = null, px: Float, py: Float, lx1: Float, ly1: Float, lx2: Float, ly2: Float): Float {
        return (px - lx2) * (ly1 - ly2) - (lx1 - lx2) * (py - ly2);
    }

    static function poly_centroid(math: Class<Math> = null, poly: Array<Float>): Vec2f {
        var off = {x: poly[0], y: poly[1]};
        var twicearea = 0.0;
        var x = 0.0;
        var y = 0.0;
        var p1: Vec2f;
        var p2: Vec2f;
        var f: Float;
        var i = 0;
        var j = Std.int(poly.length / 2 - 1);
        while (i < poly.length / 2) {
            p1 = {x: poly[i * 2], y: poly[i * 2 + 1]};
            p2 = {x: poly[j * 2], y: poly[j * 2 + 1]};
            f = (p1.x - off.x) * (p2.y - off.y) - (p2.x - off.x) * (p1.y - off.y);
            twicearea += f;
            x += (p1.x + p2.x - 2 * off.x) * f;
            y += (p1.y + p2.y - 2 * off.y) * f;
            j = i++;
        }

        f = twicearea * 3;

        return {x: x / f + off.x, y: y / f + off.y};
    }

    static function line_line_intersect(math: Class<Math> = null,
        p0_x: Float, p0_y: Float, p1_x: Float, p1_y: Float, 
        p2_x: Float, p2_y: Float, p3_x: Float, p3_y: Float, intersection: Vec2f = null): Bool
    {
        var s1_x = p1_x - p0_x;     
        var s1_y = p1_y - p0_y;
        var s2_x = p3_x - p2_x;     
        var s2_y = p3_y - p2_y;

        var s = (-s1_y * (p0_x - p2_x) + s1_x * (p0_y - p2_y)) / (-s2_x * s1_y + s1_x * s2_y);
        var t = ( s2_x * (p0_y - p2_y) - s2_y * (p0_x - p2_x)) / (-s2_x * s1_y + s1_x * s2_y);

        if (s >= 0 && s <= 1 && t >= 0 && t <= 1) {
            if (intersection != null) {
                intersection.x = p0_x + (t * s1_x);
                intersection.y = p0_y + (t * s1_y);
            }
            return true;
        } else {
            return false;
        }
    }

    static inline function point_box_intersect(math: Class<Math> = null, point_x: Float, point_y: Float, box_x: Float, box_y: Float, box_width: Float, box_height: Float): Bool {
        return point_x >= box_x && point_x < box_x + box_width && point_y >= box_y && point_y < box_y + box_height;
    }

    static inline function box_box_intersect(math: Class<Math> = null, 
        x1: Float, y1: Float, width1: Float, height1: Float,
        x2: Float, y2: Float, width2: Float, height2: Float): Bool {
        return x1 < x2 + width2 && x1 + width1 > x2 && y1 < y2 + height2 && y1 + height1 > y2;
    }

    static inline function circle_circle_intersect(math: Class<Math> = null, x1: Float, y1: Float, r1: Float, x2: Float, y2: Float, r2: Float): Bool {
        return dst2(x1, y1, x2, y2) < r1 * r1 + r2 * r2;
    }

    static function circle_polygon_intersect(math: Class<Math> = null, circle_x: Float, circle_y: Float, circle_radius: Float, polygon: Array<Float>): Bool {
        for (i in 0...Std.int(polygon.length / 2 - 1)) {
            if (circle_line_intersect(circle_x, circle_y, circle_radius, polygon[i * 2], polygon[i * 2 + 1], polygon[i * 2 + 2], polygon[i * 2 + 3])) {
                return true;
            }
        }
        if (circle_line_intersect(circle_x, circle_y, circle_radius, polygon[polygon.length - 2], polygon[polygon.length - 1], polygon[0], polygon[1])) {
            return true;
        } else {
            return false;
        }
    }

    static function circle_tri_intersect(math: Class<Math> = null, circle_x: Float, circle_y: Float, circle_radius: Float, tri: Array<Float>): Bool {
        return circle_line_intersect(circle_x, circle_y, circle_radius, tri[0], tri[1], tri[2], tri[3])
        || circle_line_intersect(circle_x, circle_y, circle_radius, tri[2], tri[3], tri[4], tri[5])
        || circle_line_intersect(circle_x, circle_y, circle_radius, tri[4], tri[5], tri[0], tri[1]);
    }

    static function circle_line_intersect(math: Class<Math> = null, circle_x: Float, circle_y: Float, circle_radius: Float, line_x1: Float, line_y1: Float, line_x2: Float, line_y2: Float): Bool {
        return point_line_dst(circle_x, circle_y, line_x1, line_y1, line_x2, line_y2) < circle_radius;
    }

    static function circle_point_intersect(math: Class<Math> = null, circle_x: Float, circle_y: Float, circle_radius: Float, point_x: Float, point_y: Float): Bool {
        return dst2(circle_x, circle_y, point_x, point_y) < circle_radius * circle_radius;
    }

    static function point_line_dst2(math: Class<Math> = null, point_x: Float, point_y: Float, line_x1: Float, line_y1: Float, line_x2: Float, line_y2: Float): Float {
        var line_length2 = dst2(line_x1, line_y1, line_x2, line_y2);
        if (line_length2 == 0) {
            return dst(point_x, point_y, line_x1, line_y1);
        }

        var t = ((point_x - line_x1) * (line_x2 - line_x1) + (point_y - line_y1) * (line_y2 - line_y1)) / line_length2;
        t = Math.max(0, Math.min(1, t));
        return dst2(point_x, point_y, line_x1 + t * (line_x2 - line_x1), line_y1 + t * (line_y2 - line_y1));
    }

    static function point_line_dst(math: Class<Math> = null, point_x: Float, point_y: Float, line_x1: Float, line_y1: Float, line_x2: Float, line_y2: Float): Float {
        var line_length2 = dst2(line_x1, line_y1, line_x2, line_y2);
        if (line_length2 == 0) {
            return dst(point_x, point_y, line_x1, line_y1);
        }

        var t = ((point_x - line_x1) * (line_x2 - line_x1) + (point_y - line_y1) * (line_y2 - line_y1)) / line_length2;
        t = Math.max(0, Math.min(1, t));
        return dst(point_x, point_y, line_x1 + t * (line_x2 - line_x1), line_y1 + t * (line_y2 - line_y1));
    }

    static function point_line_dst_3d(math: Class<Math> = null, 
        point_x: Float, point_y: Float, point_z: Float,
        line_x1: Float, line_y1: Float, line_z1: Float,
        line_x2: Float, line_y2: Float, line_z2: Float): Float {

        var line_length2 = dst3d2(line_x1, line_y1, line_z1, line_x2, line_y2, line_z2);
        if (line_length2 == 0) {
            return dst3d(point_x, point_y, point_z, line_x1, line_y1, line_z1);
        }

        var t = ((point_x - line_x1) * (line_x2 - line_x1) + (point_y - line_y1) * (line_y2 - line_y1) + (point_z - line_z1) * (line_z2 - line_z1)) / line_length2;
        t = Math.max(0, Math.min(1, t));
        return dst3d(point_x, point_y, point_z, 
            line_x1 + t * (line_x2 - line_x1), 
            line_y1 + t * (line_y2 - line_y1),
            line_z1 + t * (line_z2 - line_z1));
    }

    static function dst(math: Class<Math> = null, x1: Float, y1: Float, x2: Float, y2: Float): Float {
        return Math.sqrt(dst2(x1, y1, x2, y2));
    }

    static function dst2(math: Class<Math> = null, x1: Float, y1: Float, x2: Float, y2: Float): Float {
        return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2);
    }

    static function dst3d(math: Class<Math> = null, x1: Float, y1: Float, z1: Float, x2: Float, y2: Float, z2: Float): Float {
        return Math.sqrt(dst3d2(x1, y1, z1, x2, y2, z2));
    }

    static function dst3d2(math: Class<Math> = null, x1: Float, y1: Float, z1: Float, x2: Float, y2: Float, z2: Float): Float {
        return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2) + (z1 - z2) * (z1 - z2);
    }

    static function rad_to_deg(math: Class<Math> = null, angle: Float): Float {
        return angle * 57.2958;
    }

    static function deg_to_rad(math: Class<Math> = null, angle: Float): Float {
        return angle / 57.2958;
    }

    static function sign(math: Class<Math> = null, x: Float): Int {
        if (x > 0) {
            return 1;
        } else if (x < 0) {
            return -1;
        } else {
            return 0;
        }
    }

    static function lerp(math: Class<Math> = null, x1: Float, x2: Float, a: Float): Float {
        return x1 + (x2 - x1) * a;
    }

    static function mean(math: Class<Math> = null, v: Array<Float>): Float {
        var mean = 0.0;
        for (i in 0...v.length) {
            mean += v[i];
        }
        mean /= v.length;
        return mean;
    }

    static function std_dev(math: Class<Math> = null, v: Array<Float>): Float {
        var mean = mean(v);
        var std_dev = 0.0;
        for (i in 0...v.length) {
            std_dev += (v[i] - mean) * (v[i] - mean);
        }
        std_dev = Math.sqrt(std_dev / v.length);
        return std_dev;
    }

    static function inner_product(math: Class<Math> = null, m1: Array<Float>, m2: Array<Float>): Float {
        var out = 0.0;
        for (i in 0...m1.length) {
            out += m1[i] * m2[i];
        }
        return out;
    }
    
    static function outer_product(math: Class<Math> = null, v1: Array<Float>, v2: Array<Float>, out: Array<Array<Float>> = null): Array<Array<Float>> {
        if (out == null) {
            out = Data.create2darray(v1.length, v2.length, 0.0);
        }
        for (i in 0...out.length) {
            for (j in 0...out[i].length) {
                out[i][j] = v1[i] * v2[j];
            }
        }
        return out;
    }

    static function mat_transpose(math: Class<Math> = null, m: Array<Array<Float>>, out: Array<Array<Float>> = null): Array<Array<Float>> {
        if (out == null) {
            out = Data.create2darray(m[0].length, m.length, 0.0);
        }
        for (i in 0...out.length) {
            for (j in 0...out[i].length) {
                out[i][j] = m[j][i];
            }
        }
        return out;
    }

    static function mat_add(math: Class<Math> = null, m1: Array<Array<Float>>, m2: Array<Array<Float>>, out: Array<Array<Float>> = null): Array<Array<Float>> {
        if (out == null) {
            out = Data.create2darray(m1.length, m1[0].length, 0.0);
        }
        for (i in 0...out.length) {
            for (j in 0...out[i].length) {
                out[i][j] = m1[i][j] + m2[i][j];
            }
        }
        return out;
    }

    static function mat_dot(math: Class<Math> = null, m1: Array<Array<Float>>, m2: Array<Array<Float>>, out: Array<Array<Float>> = null): Array<Array<Float>> {
        if (out == null) {
            out = Data.create2darray(m1.length, m2[0].length, 0.0);
        }
        var sum: Float;
        for (i in 0...m1.length) {
            for (j in 0...m2[0].length) {
                sum = 0;
                for (k in 0...m1[0].length) {
                    sum += m1[i][k] * m2[k][j];
                }
                out[i][j] = sum;
            }
        }
        return out;
    }

    static function mat_scalar_mult(math: Class<Math> = null, m: Array<Array<Float>>, s: Float, out: Array<Array<Float>> = null): Array<Array<Float>> {
        if (out == null) {
            out = Data.create2darray(m.length, m[0].length, 0.0);
        }
        for (i in 0...m.length) {
            for (j in 0...m[i].length) {
                out[i][j] = m[i][j] * s;
            }
        }
        return out;
    }

    static function hadamard_product(math: Class<Math> = null, m1: Array<Array<Float>>, m2: Array<Array<Float>>, out: Array<Array<Float>> = null): Array<Array<Float>> {
        if (out == null) {
            out = Data.create2darray(m1.length, m2[0].length, 0.0);
        }
        for (i in 0...m1.length) {
            for (j in 0...m2[0].length) {
                out[i][j] = m1[i][j] * m2[i][j];
            }
        }
        return out;
    }

    static function kronecker_product(math: Class<Math> = null, v1: Array<Float>, v2: Array<Float>, out: Array<Array<Float>> = null): Array<Array<Float>> {
        if (out == null) {
            out = Data.create2darray(v1.length * v2.length, v1.length * v2.length, 0.0);
        }
        for (i in 0...v1.length) {
            for (j in 0...v1.length) {
                out[i][j] = v1[i] * v2[j];
            }
        }
        return out;
    }

    static function mat_concat_horizontal(math: Class<Math> = null, m1: Array<Array<Float>>, m2: Array<Array<Float>>, out: Array<Array<Float>> = null): Array<Array<Float>> {
        if (out == null) {
            out = Data.create2darray(m1.length, m1[0].length + m2[0].length, 0.0);
        }
        var m1Width = m1[0].length;
        for (i in 0...out.length) {
            for (j in 0...out[0].length) {
                if (j < m1Width) {
                    out[i][j] = m1[i][j];
                } else {
                    out[i][j] = m2[i][j - m1Width];
                }
            }
        }
        return out;
    }

    // https://www.geometrictools.com/Documentation/TriangulationByEarClipping.pdf
    static inline var CONCAVE = -1; 
    static inline var TANGENTIAL = 0; 
    static inline var CONVEX = 1;
    static function triangulate(math: Class<Math> = null, vertices: Array<Float>): Array<Int> {
        var vertex_count = Std.int(vertices.length / 2);

        var vertices_are_clockwise = function() {
            if (vertices.length <= 4) {
                return false;
            }
            var area = 0.0;
            var p1x: Float;
            var p1y: Float;
            var p2x: Float;
            var p2y: Float;
            var i = 0;
            while (i < vertices.length - 1 - 2) {
                p1x = vertices[i];
                p1y = vertices[i + 1];
                p2x = vertices[i + 2];
                p2y = vertices[i + 3];
                area += p1x * p2y - p2x * p1y;
                i += 2;
            }
            p1x = vertices[vertices.length - 2];
            p1y = vertices[vertices.length - 1];
            p2x = vertices[0];
            p2y = vertices[1];
            area += p1x * p2y - p2x * p1y;
            return area < 0;
        } ();

        var indices: Array<Int>;
        if (vertices_are_clockwise) {
            indices = [for (i in 0...vertex_count) i];
        } else {
            indices = [for (i in 0...vertex_count) vertex_count - 1 - i];
        }

        function get_previous_index(index: Int): Int {
            if (index == 0) {
                return vertex_count - 1;
            } else {
                return index - 1;
            }
        }
        function get_next_index(index: Int): Int {
            return (index + 1) % vertex_count;
        }
        function compute_spanned_area_sign(p1x: Float, p1y: Float, p2x: Float, p2y: Float, p3x: Float, p3y: Float): Int {
            var area = p1x * (p3y - p2y) + p2x * (p1y - p3y) + p3x * (p2y - p1y);
            return sign(area);
        }
        function get_vertex_type(index: Int): Int {
            var previous = indices[get_previous_index(index)] * 2;
            var current = indices[index] * 2;
            var next = indices[get_next_index(index)] * 2;
            return compute_spanned_area_sign(
                vertices[previous], vertices[previous + 1], 
                vertices[current], vertices[current + 1],
                vertices[next], vertices[next + 1]);
        }

        var vertex_types = [for (i in 0...vertex_count) get_vertex_type(i)];
        var triangles = new Array<Int>();


        function is_ear_tip(index: Int): Bool {
            if (vertex_types[index] == CONCAVE) {
                return false;
            }

            var previous_index = get_previous_index(index);
            var next_index = get_next_index(index);
            var p1 = indices[previous_index] * 2;
            var p2 = indices[index] * 2;
            var p3 = indices[next_index] * 2;
            var p1x = vertices[p1];
            var p1y = vertices[p1 + 1];
            var p2x = vertices[p2];
            var p2y = vertices[p2 + 1];
            var p3x = vertices[p3];
            var p3y = vertices[p3 + 1];

            var i = get_next_index(next_index);
            while (i != previous_index) {
                if (vertex_types[i] != CONVEX) {
                    var v = indices[i] * 2;
                    var vx = vertices[v];
                    var vy = vertices[v + 1];
                    if (compute_spanned_area_sign(p3x, p3y, p1x, p1y, vx, vy) >= 0
                        && compute_spanned_area_sign(p1x, p1y, p2x, p2y, vx, vy) >= 0
                        && compute_spanned_area_sign(p2x, p2y, p3x, p3y, vx, vy) >= 0)
                    {
                        return false;
                    }
                }
                i = get_next_index(i);
            }
            return true;
        }

        while (vertex_count > 3) {
            // find ear tip
            var ear_tip_index = function() {
                for (i in 0...vertex_count) {
                    if (is_ear_tip(i)) {
                        return i;
                    }
                }
                for (i in 0...vertex_count) {
                    if (vertex_types[i] != CONCAVE) {
                        return i;
                    }
                }
                return 0;
            } ();
            // cut ear tip
            triangles.push(indices[get_previous_index(ear_tip_index)]);
            triangles.push(indices[ear_tip_index]);
            triangles.push(indices[get_next_index(ear_tip_index)]);

            indices.splice(ear_tip_index, 1);
            vertex_types.splice(ear_tip_index, 1);

            vertex_count--;

            var previous_index = get_previous_index(ear_tip_index);
            var next_index: Int;
            if (ear_tip_index == vertex_count) {
                next_index = 0;
            } else {
                next_index = ear_tip_index;
            }
            vertex_types[previous_index] = get_vertex_type(previous_index);
            vertex_types[next_index] = get_vertex_type(next_index);
        }

        if (vertex_count == 3) {
            triangles.push(indices[0]);
            triangles.push(indices[1]);
            triangles.push(indices[2]);
        }

        return triangles;
    }

    static function indices_to_vertices(math: Class<Math> = null, polygon: Array<Float>, indices: Array<Int>): Array<Array<Float>> {
        var triangles = [for (i in 0...Std.int(indices.length / 3))
        [
        polygon[indices[i * 3 + 0] * 2], polygon[indices[i * 3 + 0] * 2 + 1],
        polygon[indices[i * 3 + 1] * 2], polygon[indices[i * 3 + 1] * 2 + 1],
        polygon[indices[i * 3 + 2] * 2], polygon[indices[i * 3 + 2] * 2 + 1],
        ]
        ];
        return triangles;
    }

    static function fill_circle_map(math: Class<Math> = null, radius: Int): Array<Array<Bool>> {

        var diameter = 2 * radius;
        var x = radius - 1;
        var y = 0;
        var dx = 1;
        var dy = 1;
        var err = dx - diameter;
        var x0 = radius;
        var y0 = radius;

        var map = [for (i in 0...diameter) [for (i in 0...diameter) false]];

        while (x >= y) {
            map[x0 + x][y0 + y] = true;
            map[x0 + y][y0 + x] = true;
            map[x0 - y][y0 + x] = true;
            map[x0 - x][y0 + y] = true;
            map[x0 - x][y0 - y] = true;
            map[x0 - y][y0 - x] = true;
            map[x0 + y][y0 - x] = true;
            map[x0 + x][y0 - y] = true;

            if (err <= 0) {
                y++;
                err += dy;
                dy += 2;
            }

            if (err > 0) {
                x--;
                dx += 2;
                err += dx - diameter;
            }
        }

        for (x in 0...diameter) {
            y = 0;
            while (y < diameter) {
                if (map[x][y]) {
                    for (y2 in (y + 1)...(diameter - y)) {
                        map[x][y2] = true;
                    }
                    break;
                }
                y++;
            }
        }

        return map;
    }
}
