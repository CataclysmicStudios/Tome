/// @title Constructor Grouping Tests
/// @category Tests

// ============================================================================
// TEST 1: Constructor with NO groups
// ============================================================================

/// @constructor
/// @func TestConstructorNoGroups()
/// @desc A constructor that contains methods but no @group tags. All methods should fall into the default ungrouped bucket.
function TestConstructorNoGroups() constructor {
    
    /// @method do_something()
    /// @desc A basic method.
    /// @returns {bool}
    static do_something = function() {
        show_debug_message("This function is a test and should never be called.");
        return true;
    }

    /// @method do_something_else()
    /// @desc Another basic method.
    static do_something_else = function() {
        show_debug_message("This function is a test and should never be called.");
    }
}

// ============================================================================
// TEST 2: Constructor WITH groups and UNGROUPED methods
// ============================================================================

/// @constructor
/// @func TestConstructorWithGroups()
/// @desc A constructor that contains both grouped and ungrouped methods.
function TestConstructorWithGroups() constructor {
    
    /// @method ungrouped_first()
    /// @desc This method has no group and should fall into the default bucket at the top.
    static ungrouped_first = function() {
        show_debug_message("This function is a test and should never be called.");
    }
    
    /// @text This is preamble text for the Math group to test the sticky text attachment feature.
    /// It should attach to the math_add method below it.
    
    /// @method math_add(a, b)
    /// @group Math
    /// @desc Adds two numbers.
    /// @param {real} a First number
    /// @param {real} b Second number
    static math_add = function(a, b) {
        show_debug_message("This function is a test and should never be called.");
    }
    
    /// @method math_sub(a, b)
    /// @group Math
    /// @desc Subtracts two numbers.
    static math_sub = function(a, b) {
        show_debug_message("This function is a test and should never be called.");
    }

    /// @text Preamble for the Strings group.
    
    /// @method string_concat(str1, str2)
    /// @group Strings
    /// @desc Concatenates two strings.
    static string_concat = function(str1, str2) {
        show_debug_message("This function is a test and should never be called.");
    }

    /// @method ungrouped_second()
    /// @desc Another ungrouped method to test if the parser correctly drops it back into the default bucket after processing groups.
    static ungrouped_second = function() {
        show_debug_message("This function is a test and should never be called.");
    }
    
    /// @method ungrouped_third()
    /// @desc A third ungrouped method.
    static ungrouped_third = function() {
        show_debug_message("This function is a test and should never be called.");
    }
	
	/// @text This is footer text for the constructor. It trails the final method and should be appended to the end of the constructor block.
}

// ============================================================================
// TEST 3: Empty Constructor
// ============================================================================

/// @constructor
/// @func TestConstructorEmpty()
/// @desc A constructor with no methods to test the crash prevention logic.
/// @text This constructor has no methods, just text. The parser should skip the sorting loop entirely and not crash.
function TestConstructorEmpty() constructor {
    show_debug_message("This constructor is empty and has no methods.");
}