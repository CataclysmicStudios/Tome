// Whether Tome should run or not 
#macro TOME_ENABLED true

// Where your docs will be placed
#macro TOME_LOCAL_REPO_PATH "E:/TomeTest/Test1"

// Show extended debug information in the console when generating your docs
#macro TOME_VERBOSE true

/*/
 * Determines how depth of method groups in sidebar.
 * A value of H2 will place group header in line with constructor.
 * Ex.
 *  Page Title
 *  |---constructor()
 *  |   |---methodA()
 *  |---Group
 *  |   |---methodB()
 * 
 * A value of H3 will place group header in line with methods.
 * Ex.
 *  Page Title
 *  |---constructor()
 *      |---methodA()
 *      |---Group
 *      |---methodB()
 * 
/*/
#macro TOME_METHOD_GROUP_DEPTH TOME_METHOD_GROUP_DEPTH_HEADER.H2

#macro TOME_DISPLAY_TYPE_IN_BRACKETS true

