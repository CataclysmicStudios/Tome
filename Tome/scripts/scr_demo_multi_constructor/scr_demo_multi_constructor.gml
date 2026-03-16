/// @title Multi-Logic
/// @category Object Orientation

/// @constructor
/// @func InputHandler(device_id)
/// @desc The primary system for reading hardware inputs. This tests the first constructor in a multi-logic file.
/// @param {real} device_id The ID of the hardware device (0 for keyboard, 1+ for gamepads).
function InputHandler(_device_id) constructor {
    device = _device_id;
    is_connected = true;

    /// @method poll_axis(axis_index, [deadzone])
    /// @group Analog Input
    /// @desc Reads the current value of an analog stick or trigger.
    /// @param {real} axis_index The engine constant for the specific axis.
    /// @param {real} [deadzone] The threshold below which input is ignored. Defaults to 0.1.
    /// @return {real} A normalized value between -1.0 and 1.0.
    static poll_axis = function(_axis_index, _deadzone = 0.1) {}

    /// @method check_button_pressed(button_id)
    /// @group Digital Input
    /// @desc Checks if a button was pressed exactly on this frame.
    /// @param {real | Array.real} button_id The internal constant for the button, or an array of buttons to check.
    /// @return {bool} True if pressed.
    static check_button_pressed = function(_button_id) {}
}

/// @end

/// @text ## Bridging Systems
/// 
/// Once the `InputHandler` reads a physical action, it needs to be translated into a game command.
/// We use the `CommandQueue` to buffer these actions before the game step processes them. This text tests context switching outside of the constructor.
/// 
/// ### Example Workflow:
/// 
/// @code
/// var _input = new InputHandler(0);
/// var _queue = new CommandQueue(16);
/// 
/// if (_input.check_button_pressed(vk_space)) {
///     _queue.enqueue("JUMP");
/// }

/// @constructor
/// @func CommandQueue([max_commands])
/// @desc A FIFO buffer for storing parsed input commands before execution. Testing the secondary constructor following a text break.
/// @param {real} [max_commands] The maximum number of commands to store before dropping new ones. Defaults to 32.
function CommandQueue(_max_commands = 32) constructor {
    limit = _max_commands;
    queue = [];

    /// @method enqueue(command_string)
    /// @desc Pushes a new command to the back of the queue.
    /// @param {string} command_string The action to perform (e.g., "JUMP", "ATTACK").
    /// @return {bool} Returns true if added, false if the queue is full.
    static enqueue = function(_command_string) {}

    /// @method dequeue()
    /// @desc Removes and returns the oldest command from the front of the queue.
    /// @return {string | undefined} The command string, or undefined if the queue is empty.
    static dequeue = function() {}
    
    /// @method flush()
    /// @desc Clears all pending commands instantly without executing them.
    /// @return {undefined}
    static flush = function() {}
}

/// @end

/// @text ## Global Dispatch
/// 
/// Finally, a standard function can be used to execute the queue across all game entities. This verifies that standard functions can be appended at the end of a multi-constructor script.

/// @func execute_global_queue(queue_instance)
/// @desc Takes a CommandQueue and distributes its actions to the relevant player objects.
/// @param {struct.CommandQueue} queue_instance The queue to process.
/// @return {real} The total number of commands successfully executed this frame.
function execute_global_queue(_queue_instance) {}