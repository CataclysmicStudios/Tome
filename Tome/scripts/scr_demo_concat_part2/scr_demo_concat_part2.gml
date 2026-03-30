// Part 2
/// @title Merged Page
/// @category Concatenation

/// @text ## File Operations
/// 
/// This content is dynamically appended directly below the models defined in Part 1. 
/// These standard functions take the `PlayerProfile` struct (from Part 1) and handle writing it to the local disk.

/// @func save_profile(profile_instance, slot)
/// @desc Serializes a PlayerProfile struct into a base64 encoded JSON string and commits it to memory.
/// @param {struct.PlayerProfile} profile_instance The user data struct to save.
/// @param {real} slot The save slot index (0-3).
/// @return {bool} True if the file write operation was successful.
function save_profile(_profile_instance, _slot) {
    // Serialization logic here
    return true;
}

/// @func load_profile(slot)
/// @desc Reads a saved profile from disk, decrypts it, and reconstructs the original PlayerProfile struct.
/// @param {real} slot The save slot to read from.
/// @return {struct.PlayerProfile | undefined} The loaded profile struct, or undefined if the slot is empty or corrupted.
function load_profile(_slot) {
    // Deserialization logic here
    return undefined;
}

/// @text ### Final Concatenation Note
/// 
/// Because Tome processes these files sequentially based on the order of your `tome_add` calls in `tomeDocSetup.gml`, the order of concatenation is completely predictable. This allows you to split massive documentation pages across multiple manageable GML scripts!

/// @func delete_save_data([slot])
/// @desc Erases the saved data from the disk.
/// @param {real} [slot] The specific slot to wipe. If omitted, wipes all slots.
/// @return {undefined}
function delete_save_data(_slot = undefined) {
    // Wipe logic here
}