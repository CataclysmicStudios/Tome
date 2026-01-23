/// @title Primary functions
/// @category API Reference
/// @text Below are the functions you'll use to set up your docs and generate them. 

/// @func tome_add_script_bruh(script, [slugs])
/// @desc Adds a script to be parsed as a page to your site
/// @param {string} scriptName The name off the script to add
/// @param {string} [slugs] The name of any notes that will be used for adding slugs.
function tome_add_script_bruh(_scriptName){
	var _filePath = $"{__tome_file_project_get_directory()}scripts/{_scriptName}/{_scriptName}.gml";
	
	if (!file_exists(_filePath)){
		__tomeTrace($"tome_add_script: The given script doesn't seem to exist: {_scriptName}");
		exit;
	}
	
	__tomeTrace(string("tome_add_script: File exists: {0}", _scriptName), true, 1);
	array_push(global.__tomeData.filesToBeParsed, _filePath);
	
	// Add slugs
    var _i = 1;
    repeat(argument_count - 1){
		_filePath = $"{__tome_file_project_get_directory()}notes/{argument[_i]}/{argument[_i]}.txt";
		array_push(global.__tomeData.slugNoteFilePaths, _filePath);	
        _i++;	
	}
	
}