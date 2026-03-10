/// @title Advanced Constructor Tests
/// @category Tests

/// @text This file tests constructors with deprecated methods, full parameter definitions, inline formatting tags, and multiple slug insertions.

// ============================================================================
// TEST 1: Constructor with groups, deprecated methods, and slugs
// ============================================================================

/// @constructor
/// @func NetworkClient(ip_address, port)
/// @desc Initializes a new network client to communicate with the server.
/// @slug network-client-example
/// @param {string} ip_address The IPv4 address of the target server.
/// @param {real} port The port number to connect over.
function NetworkClient(_ip, _port) constructor {

    /// @text These methods handle the core connection lifecycle.
    
    /// @method connect(timeout)
    /// @desc Attempts to connect to the server.
    /// @param {real} timeout The maximum time in milliseconds to wait before failing.
    /// @returns {bool | real}
    static connect = function(timeout) {
        show_debug_message("This function is a test and should never be called.");
        return false;
    }

    /// @text The following methods are for sending data to the server.

    /// @method send_packet(data, reliable)
    /// @group Data Transmission
    /// @desc Sends a raw buffer packet to the server.
    /// @param {buffer} data The raw buffer data to send.
    /// @param {bool} reliable Whether to require a delivery receipt.
    /// @deprecated Use the new send_message method instead for better security and stability.
    static send_packet = function(data, reliable) {
        show_debug_message("This function is a test and should never be called.");
    }

    /// @method send_message(str_msg, priority)
    /// @group Data Transmission
    /// @desc Sends an encrypted string message to the server.
    /// @slug send-message-priority
    /// @param {string} str_msg The string message to transmit.
    /// @param {real} priority The priority level of the message.
    static send_message = function(str_msg, priority) {
        show_debug_message("This function is a test and should never be called.");
    }
}

/// @end

/// @text
/// ---
/// ## Entity Management
/// The next section covers the internal entity management system. These constructors are entirely separate from the networking layer.

// ============================================================================
// TEST 2: Constructor without groups, with a deprecated method and slugs
// ============================================================================

/// @constructor
/// @func EntitySpawner(x, y)
/// @desc An object that handles spawning entities into the game world at a specific location.
/// @param {real} x The starting x coordinate in the room.
/// @param {real} y The starting y coordinate in the room.
function EntitySpawner(_x, _y) constructor {

    /// @method spawn_enemy(enemy_type, count)
    /// @desc Spawns a specific number of standard enemies.
    /// @slug spawn-enemy-usage
    /// @param {string} enemy_type The string ID of the enemy to spawn.
    /// @param {real} count The number of enemies to generate.
    static spawn_enemy = function(enemy_type, count) {
        show_debug_message("This function is a test and should never be called.");
    }

    /// @method spawn_boss(boss_id, difficulty_multiplier)
    /// @desc Spawns a boss entity with a given difficulty.
    /// @slug boss-encounter-warning
    /// @param {real} boss_id The numeric ID of the boss.
    /// @param {real} difficulty_multiplier The multiplier for boss stats.
    /// @deprecated Bosses should now be spawned using the dedicated BossEncounter struct instead of standard spawners.
    static spawn_boss = function(boss_id, difficulty_multiplier) {
        show_debug_message("This function is a test and should never be called.");
    }
}