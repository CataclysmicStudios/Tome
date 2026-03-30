/// @title Hybrid Systems
/// @category Object Orientation

/// @text ## Data Structures
/// 
/// The following structures are lightweight and contain no internal methods. They are strictly used for data passing.

/// @constructor
/// @func Coordinate3D(x, y, z)
/// @desc A simple constructor with no methods to test empty group rendering. Used to represent a point in 3D space.
/// @slug warning-callout
/// @param {real} x The X coordinate.
/// @param {real} y The Y coordinate.
/// @param {real} z The Z coordinate.
function Coordinate3D(_x, _y, _z) constructor {
    x = _x;
    y = _y;
    z = _z;
}

/// @end

/// @text ### Utility Functions
/// 
/// These standard functions operate on the lightweight data structures.
/// We are testing standard functions interspersed between constructors.

/// @func calculate_distance_3d(point_a, point_b)
/// @desc A regular function sitting next to constructors. Calculates the Euclidean distance between two 3D coordinates.
/// @slug example-usage-box
/// @param {struct.Coordinate3D} point_a The first point.
/// @param {struct.Coordinate3D} point_b The second point.
/// @return {real} The distance between the points.
function calculate_distance_3d(_point_a, _point_b) {
    // Math logic here
    return 0; 
}

/// @func invert_coordinate(point)
/// @desc Flips the signs of all axes in a Coordinate3D struct. Testing another standalone function.
/// @param {struct.Coordinate3D} point The coordinate to invert.
/// @return {struct.Coordinate3D} A new inverted coordinate struct.
function invert_coordinate(_point) {
    return new Coordinate3D(-_point.x, -_point.y, -_point.z);
}

/// @text ## Complex Entities
/// 
/// Finally, a standard constructor with methods can exist in the same file without breaking the context of the previous standalone functions.

/// @constructor
/// @func PhysicsBody(coordinate)
/// @desc A complex entity that utilizes the lightweight data structures.
/// @param {struct.Coordinate3D} coordinate The starting position.
function PhysicsBody(_coordinate) constructor {
    position = _coordinate;
    velocity = new Coordinate3D(0, 0, 0);

    /// @method apply_force(force_vector)
    /// @desc Adds a force vector to the current velocity.
    /// @param {struct.Coordinate3D} force_vector The direction and magnitude of the force.
    /// @return {undefined}
    static apply_force = function(_force_vector) {}
    
    /// @method update_position()
    /// @desc Applies the current velocity to the position coordinate.
    /// @return {undefined}
    static update_position = function() {}
}