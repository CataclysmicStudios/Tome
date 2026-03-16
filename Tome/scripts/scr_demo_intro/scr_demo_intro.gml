/// @title Introduction
/// @category Getting Started

/// @text # Welcome to the Test Suite
/// 
/// This specific file tests the injection of multiple slugs into a standard text flow, as well as providing a basic overview of the documentation.
/// 
/// Below is a critical warning injected directly from our slug file:

/// @slug warning-callout

/// @text ## How to use this suite
/// 
/// You can browse the sidebar to see how Tome handles various GML structures, from massive constructors to simple macros. 
/// 
/// Here is an example of an injected code box:

/// @slug example-usage-box

/// @text ## Building Your Site
/// 
/// Tome provides several functions to construct your documentation site from your GameMaker assets. Below are examples of how to use them, injected via slugs!

/// @slug example-tome-add
/// @slug example-tome-add-raw
/// @slug example-tome-add-sidebar
/// @slug example-tome-add-navbar

/// @func init_test_suite()
/// @desc A simple initialization function to ensure the test environment is ready.
/// @return {bool} Returns true if the environment is stable.
function init_test_suite() {
    return true;
}