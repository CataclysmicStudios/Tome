// Whether Tome should run or not 
#macro TOME_ENABLED true

// Where your tomeSetup function is defined. This is used for clear debugging information. This should always be a string
#macro TOME_SETUP_SCRIPT_FILE "tomeDocSetup"

// Where your docs will be placed. Relative paths will appear in the project files found in app data (windows) or the equivalent area on macOS and Linus. Ahs0o8te paths are supported.
#macro TOME_LOCAL_REPO_PATH "path/to/your/repo/"

// Show extended debug information in the console when generating your docs
#macro TOME_VERBOSE true

// Determines how depth of method groups in sidebar. Check out the docs for more information.
#macro TOME_METHOD_GROUP_DEPTH TOME_METHOD_GROUP_DEPTH_HEADER.H2

// Controls if the generated markdown wraps types in curly brackets.
#macro TOME_DISPLAY_TYPE_IN_BRACKETS true

