/// @title Parameter Tag Variations Test
/// @category Tests

/// @text
/// This file tests the various parameter tags supported by Tome to ensure they all parse correctly into the markdown table, as well as testing optional parameters.

// ============================================================================
// TEST 1: Standard Function with @param
// ============================================================================

/// @func math_multiply(val1, val2)
/// @desc Multiplies two values together.
/// @param {real} val1 The first value.
/// @param {real} val2 The second value.
/// @returns {real} The product of the two values.
function math_multiply(val1, val2) {
    show_debug_message("This function is a test and should never be called.");
    return val1 * val2;
}

// ============================================================================
// TEST 2: Function with @arg and Optional Parameters
// ============================================================================

/// @func string_pad_left(str, length, [pad_char])
/// @desc Pads a string on the left side to a certain length.
/// @arg {string} str The original string.
/// @arg {real} length The desired total length.
/// @arg {string} [pad_char] The character to pad with.
/// @return {string} The formatted string.
function string_pad_left(str, length, pad_char = " ") {
    show_debug_message("This function is a test and should never be called.");
    return "";
}

// ============================================================================
// TEST 3: Constructor using @parameter and @argument
// ============================================================================

/// @constructor
/// @func PlayerEntity(start_x, start_y, display_name)
/// @desc Represents a player character in the game.
/// @parameter {real} start_x The starting x position.
/// @parameter {real} start_y The starting y position.
/// @argument {string} display_name The player's display name.
/// @deprecated This entity system is old, please migrate to the new one.
function PlayerEntity(_x, _y, _name) constructor {
    
    /// @method set_health(amount)
    /// @desc Updates the player's health.
    /// @param {real} amount The new health value.
    static set_health = function(amount) {
        show_debug_message("This function is a test and should never be called.");
    }
    
    /// @method apply_buff(buff_id, duration)
    /// @group Status Effects
    /// @desc Applies a temporary buff to the player.
    /// @argument {string} buff_id The unique identifier for the buff.
    /// @arg {real} duration How many frames the buff lasts.
    static apply_buff = function(buff_id, duration) {
        show_debug_message("This function is a test and should never be called.");
    }
}