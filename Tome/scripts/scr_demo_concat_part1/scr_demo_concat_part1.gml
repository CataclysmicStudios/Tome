// Part 1
/// @title Merged Page
/// @category Concatenation

/// @text # Game State Serialization
/// 
/// This page is compiled from multiple separate script files to test Tome's context concatenation. 
/// Because this file and the next share the exact same `@title` and `@category`, Tome will merge them into a single continuous page on the sidebar.
/// 
/// Below is the first half of the system, focusing strictly on the data models.

/// @text ## Core Data Models
/// 
/// These constructors define the raw data structures before they are processed by the file system in Part 2.

/// @constructor
/// @func PlayerProfile(username, [level])
/// @desc Represents a single user's save profile. This struct is defined in Part 1 of the concatenation test.
/// @param {string} username The player's chosen display name.
/// @param {real} [level] The player's starting level. Defaults to 1.
function PlayerProfile(_username, _level = 1) constructor {
    username = _username;
    level = _level;
    inventory = [];
    playtime = 0;

    /// @method add_item(item_id, [amount])
    /// @group Inventory Management
    /// @desc Grants an item to the player's profile data.
    /// @param {string} item_id The internal string ID of the item.
    /// @param {real} [amount] The quantity to add. Defaults to 1.
    /// @return {bool} Returns true if the item was successfully added.
    static add_item = function(_item_id, _amount = 1) {}

    /// @method get_playtime_formatted()
    /// @group Analytics
    /// @desc Formats the raw playtime frames into a readable string.
    /// @return {string} The formatted time (e.g., "12h 34m").
    static get_playtime_formatted = function() {}
}

/// @end

/// @text ### System Flags
/// 
/// The following standard function initializes the global flags required for the structures above. It sits at the very bottom of Part 1.

/// @func init_serialization_flags()
/// @desc Sets up global variables for the save system. Defined at the end of Part 1.
/// @return {undefined}
function init_serialization_flags() {
    global.save_encryption_enabled = true;
    global.compression_level = 9;
}