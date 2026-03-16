/// @title Legacy API
/// @category Deprecated Systems
/// @text This page tests how Tome handles and flags deprecated functions, constructors, and methods within the documentation.

/// @func legacy_draw_sprite(sprite, x, y)
/// @deprecated Use `render_sprite_ext()` instead. This function relies on the old batching pipeline.
/// @desc Draws a sprite to the screen using the outdated rendering pipeline.
/// @param {real} sprite The sprite index.
/// @param {real} x The X coordinate.
/// @param {real} y The Y coordinate.
/// @return {undefined}
function legacy_draw_sprite(_sprite, _x, _y) {}

/// @func gui_set_color(color_hex)
/// @deprecated Use `ThemeManager.set_primary_color()` instead.
/// @desc Sets the global GUI color using the old globalvar system.
/// @param {string} color_hex The hex color string.
/// @return {bool} True if successful.
function gui_set_color(_color_hex) {}

/// @constructor
/// @func OldAudioEngine(channels)
/// @deprecated The `OldAudioEngine` constructor is severely unoptimized and will be removed in v3.0.0. Please migrate to the `AudioCore` class.
/// @desc An outdated system for managing game audio and channel allocation.
/// @param {real} channels The number of audio channels to reserve.
function OldAudioEngine(_channels) constructor {
    max_channels = _channels;

    /// @method play_sound(soundid, loop)
    /// @deprecated Use `AudioCore.play_stream()` for standard SFX.
    /// @desc Plays a sound effect using the legacy emitter system.
    /// @param {real} soundid The sound asset to play.
    /// @param {bool} loop Whether the sound should loop indefinitely.
    /// @return {real} The audio channel index used.
    static play_sound = function(_soundid, _loop) {}
    
    /// @method stop_all()
    /// @desc Halts all currently playing audio on this engine. This specific method is not marked deprecated to test mixed tag states within a deprecated constructor.
    /// @return {undefined}
    static stop_all = function() {}
}