package echo.shape;

import hxmath.math.MathUtil;
import hxmath.frames.Frame2;
import echo.data.Data;
import echo.util.Pool;
import echo.shape.*;

using echo.util.SAT;
using hxmath.math.Vector2;
using hxmath.math.MathUtil;

class Polygon extends Shape implements IPooled {
  public static var pool(get, never):IPool<Polygon>;
  static var _pool = new Pool<Polygon>(Polygon);
  /**
   * The amount of vertices in the Polygon.
   */
  public var count(default, null):Int;
  /**
   * The Polygon's vertices adjusted for it's rotation.
   *
   * This Array represents a cache'd value, so changes to this Array will be overwritten.
   * Use `set_vertice()` or `set_vertices()` to edit this Polygon's vertices.
   */
  public var vertices(default, null):Array<Vector2>;
  /**
   * The Polygon's computed normals.
   *
   * This Array represents a cache'd value, so changes to this Array will be overwritten.
   * Use `set_vertice()` or `set_vertices()` to edit this Polygon's normals.
   */
  public var normals(default, null):Array<Vector2>;

  public var pooled:Bool;

  var local_frame:Frame2;

  var local_vertices:Array<Vector2>;

  public static inline function get(x:Float = 0, y:Float = 0, sides:Int = 3, radius:Float = 1, rotation:Float = 0):Polygon {
    if (sides < 3) throw 'Polygons require 3 sides as a minimum';

    var polygon = _pool.get();

    var rot:Float = (Math.PI * 2) / sides;
    var angle:Float;
    var verts:Array<Vector2> = new Array<Vector2>();

    for (i in 0...sides) {
      angle = (i * rot) + ((Math.PI - rot) * 0.5);
      var vector:Vector2 = new Vector2(Math.cos(angle) * radius, Math.sin(angle) * radius);
      verts.push(vector);
    }

    polygon.set(x, y, rotation, verts);
    polygon.pooled = false;
    return polygon;
  }

  public static inline function get_from_vertices(x:Float = 0, y:Float = 0, rotation:Float = 0, ?vertices:Array<Vector2>):Polygon {
    var polygon = _pool.get();
    polygon.set(x, y, vertices);
    polygon.pooled = false;
    return polygon;
  }

  public static inline function get_from_rect(rect:Rect):Polygon return _pool.get().set_from_rect(rect);

  // TODO
  // public static inline function get_from_circle(c:Circle, sub_divisions:Int = 6) {}

  override inline function put() {
    parent_frame = null;
    if (!pooled) {
      pooled = true;
      _pool.put_unsafe(this);
    }
  }

  public inline function set(x:Float = 0, y:Float = 0, rotation:Float = 0, ?vertices:Array<Vector2>):Polygon {
    local_x = x;
    local_y = y;
    local_rotation = rotation;
    set_vertices(vertices);
    return this;
  }

  public inline function set_from_rect(rect:Rect):Polygon {
    set_parent();
    count = 4;
    for (i in 0...count) if (local_vertices[i] == null) local_vertices[i] = new Vector2(0, 0);
    local_vertices[0].set(-rect.ex, -rect.ey);
    local_vertices[1].set(rect.ex, -rect.ey);
    local_vertices[2].set(rect.ex, rect.ey);
    local_vertices[3].set(-rect.ex, rect.ey);
    local_x = rect.local_x;
    local_y = rect.local_y;
    local_rotation = rect.local_rotation;
    set_parent(rect.parent_frame);
    return this;
  }

  inline function new(?vertices:Array<Vector2>) {
    super();
    type = POLYGON;
    this.vertices = [];
    this.normals = [];
    local_frame = new Frame2(new Vector2(0, 0), 0);
    set_vertices(vertices);
  }

  public inline function load(polygon:Polygon):Polygon return set(polygon.x, polygon.y, polygon.rotation, polygon.local_vertices);

  override inline function bounds(?rect:Rect):Rect {
    var left = vertices[0].x;
    var top = vertices[0].y;
    var right = vertices[0].x;
    var bottom = vertices[0].y;

    for (i in 1...count) {
      if (vertices[i].x < left) left = vertices[i].x;
      if (vertices[i].y < top) top = vertices[i].y;
      if (vertices[i].x > right) right = vertices[i].x;
      if (vertices[i].y > bottom) bottom = vertices[i].y;
    }

    return rect == null ? Rect.get_from_min_max(left, top, right, bottom) : rect.set_from_min_max(left, top, right, bottom);
  }

  override function clone():Polygon return Polygon.get_from_vertices(x, y, rotation, local_vertices);

  override function contains(v:Vector2):Bool return this.polygon_contains(v);

  override function intersect(l:Line):Null<IntersectionData> return this.polygon_intersects(l);

  override inline function overlaps(s:Shape):Bool {
    var cd = s.collides(this);
    if (cd != null) {
      cd.put();
      return true;
    }
    return false;
  }

  override inline function collides(s:Shape):Null<CollisionData> return s.collide_polygon(this);

  override inline function collide_rect(r:Rect):Null<CollisionData> return r.rect_and_polygon(this, true);

  override inline function collide_circle(c:Circle):Null<CollisionData> return c.circle_and_polygon(this);

  override inline function collide_polygon(p:Polygon):Null<CollisionData> return p.polygon_and_polygon(this, true);

  override inline function sync() {
    if (parent_frame != null) {
      sync_pos.set(local_x, local_y);
      var pos = parent_frame.transformFrom(sync_pos);
      _x = pos.x;
      _y = pos.y;
      _rotation = parent_frame.angleDegrees + local_rotation;
    }
    else {
      _x = local_x;
      _y = local_x;
      _rotation = local_rotation;
    }

    transform_vertices();
    compute_normals();
  }

  override inline function get_top():Float {
    if (count == 0 || vertices[0] == null) return y;

    var top = vertices[0].y;
    for (i in 1...count) if (vertices[i].y < top) top = vertices[i].y;

    return top;
  }

  override inline function get_bottom():Float {
    if (count == 0 || vertices[0] == null) return y;

    var bottom = vertices[0].y;
    for (i in 1...count) if (vertices[i].y > bottom) bottom = vertices[i].y;

    return bottom;
  }

  override inline function get_left():Float {
    if (count == 0 || vertices[0] == null) return x;

    var left = vertices[0].x;
    for (i in 1...count) if (vertices[i].x < left) left = vertices[i].x;

    return left;
  }

  override inline function get_right():Float {
    if (count == 0 || vertices[0] == null) return x;

    var right = vertices[0].x;
    for (i in 1...count) if (vertices[i].x > right) right = vertices[i].x;

    return right;
  }

  public inline function to_rect():Rect return bounds();
  /**
   * Sets the vertice at the desired index.
   * @param index
   * @param x
   * @param y
   */
  public inline function set_vertice(index:Int, x:Float = 0, y:Float = 0):Void {
    if (local_vertices[index] == null) local_vertices[index] = new Vector2(x, y);
    else local_vertices[index].set(x, y);

    transform_vertices();
    compute_normals();
  }

  public inline function set_vertices(?vertices:Array<Vector2>, ?count:Int):Void {
    local_vertices = vertices == null ? [] : vertices;
    this.count = (count != null && count >= 0) ? count : local_vertices.length;
    if (count > local_vertices.length) for (i in local_vertices.length...count) local_vertices[i] = new Vector2(0, 0);

    transform_vertices();
    compute_normals();
  }

  inline function transform_vertices():Void {
    vertices.resize(0);
    local_frame.offset.set(local_x, local_y);
    local_frame.angleDegrees = local_rotation;
    if (parent_frame != null) local_frame.concatWith(parent_frame);
    for (i in 0...count) {
      if (local_vertices[i] == null) continue;
      vertices[i] = local_frame.transformFrom(local_vertices[i].clone());
    }
  }
  /**
   *  Compute face normals
   */
  inline function compute_normals():Void {
    for (i in 0...count) {
      vertices[(i + 1) % count].copyTo(sync_pos);
      sync_pos.subtractWith(vertices[i]);

      // Calculate normal with 2D cross product between vector and scalar
      if (normals[i] == null) normals[i] = new Vector2(-sync_pos.y, sync_pos.x);
      else normals[i].set(-sync_pos.y, sync_pos.x);
      normals[i].normalize();
    }
  }

  // getters
  static function get_pool():IPool<Polygon> return _pool;

  // setters
}
