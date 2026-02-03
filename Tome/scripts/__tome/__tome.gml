/// @title Primary functions
/// @category API Reference
/// @text Below are the functions you'll use to set up your docs and generate them. 



#region /// @func tome_add(file, [slugs])
/// @desc Adds a file to be parsed as a page to your site
/// @param {string} file The name of a file (as shown in the IDE) or a direct file path to an external file
/// @param {string} [slugs] The name of any notes (as shown in the IDE) or a direct file path to an external.txt file that will be used for adding slugs. One additional argument per slug note
function tome_add(_file){
    __tome_setup_data();
    
    var _filePath = $"{__tome_file_project_get_directory()}scripts/{_file}/{_file}.gml";
    
    if (!file_exists(_filePath)){
        _filePath = $"{__tome_file_project_get_directory()}notes/{_file}/{_file}.txt";
    }
    
    if (!file_exists(_filePath)){
        _filePath = _file;
    }

    if (!array_contains(global.__tomeData.filesToBeParsed, _file)){
      	if (!file_exists(_filePath)){
      		array_push(global.__tomeData.setupWarnings, $"tome_add: The given file doesn't seem to exist as an script, note, or external file: {_filePath}");
      		exit;
      	}else{
          	__tomeTrace(string("tome_add: File exists: {0}", _filePath), true, 1, false);
          	array_push(global.__tomeData.filesToBeParsed, _filePath);
            
            // Add slugs
            if (argument_count > 1){
                
                // Figure out if we have been passed an array of slug files or if the list of slug files have been passed as individual arguments
                var _isArray = is_array(argument[1]);
                var _i = _isArray ? 0 : 1;
                var _slugArray = _isArray ? argument[1] : argument
                var _loopCount = array_length(_slugArray);
                
                repeat(_loopCount - _i){
                    var _fileName = argument[_i];
                    var _filePath = ""
                    
                    if (file_exists(_fileName)){
                        _filePath = _fileName;
                    }else{
                        _filePath = $"{__tome_file_project_get_directory()}notes/{_fileName}/{_fileName}.txt";
                    }
                    
                    if (!array_contains(global.__tomeData.slugNoteFilePaths, _filePath)){
                        if (!file_exists(_filePath)){
                           array_push(global.__tomeData.setupWarnings, $"tome_add: The given slug file doesn't seem to exist as a note or external file: {_fileName}");
                           exit;
                        }else{
                            __tomeTrace(string("tome_add_script: File exists: {0}", _fileName), true, 2, false); 
                            array_push(global.__tomeData.slugNoteFilePaths, _filePath);	
                        }
                    }
                    _i++;
                }
            }
        }
    }
    
}#endregion

/// @deprecated Use `tome_add` instead
/// @func tome_add_script(script, [slugs])
/// @desc Adds a script to be parsed as a page to your site
/// @param {string} scriptName The name off the script to add
/// @param {string} [slugs] The name of any notes (as shown in the IDE) or a direct file path to an external.txt file that will be used for adding slugs. One additional argument per slug note
function tome_add_script(_scriptName){
    var slugs = [];
    
    var _i = 0;
    if (argument_count > 1){
        repeat(argument_count - 1){
            array_push(slugs, argument[_i])
        }
    }
    
    if (array_length(slugs) > 0){
        tome_add(_scriptName, slugs);
    }else{
        tome_add(_scriptName);
    } 
}

/// @deprecated Use `tome_add` instead
/// @func tome_add_note(noteName, [slugs])
/// @desc Adds a note to be parsed as a page to your site 
/// @param {string} noteName The note to add
/// @param {string} [slugs] The name of any notes (as shown in the IDE) or a direct file path to an external.txt file that will be used for adding slugs. One additional argument per slug note
function tome_add_note(_noteName){
    var slugs = [];
    
    var _i = 0;
    if (argument_count > 1){
        repeat(argument_count - 1){
            array_push(slugs, argument[_i])
        }
    }
    
    if (array_length(slugs) > 0){
        tome_add(_noteName, slugs);
    }else{
        tome_add(_noteName);
    } 

}

/// @deprecated Use `tome_add` instead
/// @func tome_add_file(filePath)
/// @desc Adds an external file to be parsed when the docs are generated
/// @param {string} filePath The file to add
/// @param {string} [slugs] The name of any notes (as shown in the IDE) or a direct file path to an external.txt file that will be used for adding slugs. One additional argument per slug note
function tome_add_file(_filePath){
    var slugs = [];
    
    var _i = 0;
    if (argument_count > 1){
        repeat(argument_count - 1){
            array_push(slugs, argument[_i])
        }
    }
    
    if (array_length(slugs) > 0){
        tome_add(_filePath, slugs);
    }else{
        tome_add(_filePath);
    }
}

/// @func tome_set_homepage_from_file(filePath)
/// @desc Sets the homepage of your site to be the contents of a file (`.txt`, or `.md`)
/// @param {string} filePath The file to use as the homepage
function tome_set_homepage_from_file(_filePath){
    __tome_setup_data()	
	
    if (!file_exists(_filePath)){
		array_push(global.__tomeData.setupWarnings, $"tome_set_homepage_from_file: The given file doesn't seem to exist: {_filePath}");
		exit;
	}
	
	var _homePageParseStruct = __tome_parse_markdown(_filePath, true);
	global.__tomeData.homepageContent = _homePageParseStruct.markdown;
}

/// @func tome_set_homepage_from_note(noteName)
/// @desc Sets the homepage of your site to be the contents of the given note
/// @param {string} noteName The note to use as the homepage
function tome_set_homepage_from_note(_noteName){
    __tome_setup_data()	
    var _filePath = $"{__tome_file_project_get_directory()}notes/{_noteName}/{_noteName}.txt";
	
	if (!file_exists(_filePath)){
		array_push(global.__tomeData.setupWarnings, $"tome_set_homepage_from_note: The given note doesn't seem to exist: {_filePath}");
		exit;
	}
	
	var _homePageParseStruct = __tome_parse_markdown(_filePath, true);
	global.__tomeData.homepageContent = _homePageParseStruct.markdown;
}

/// @func tome_add_to_sidebar(name, link, category)
/// @desc Adds an item to the sidebar of your site
/// @param {string} name The name of the item
/// @param {string} link The link to the item
/// @param {string} category The category of the item
function tome_add_to_sidebar(_name, _link, _category){
    __tome_setup_data()
	var _sidebarItem = {
		title: _name,
		link: _link,
		category: _category
	}
	
	array_push(global.__tomeData.additionalSidebarItems, _sidebarItem);
}

/// @func tome_set_site_name(name)
/// @desc Sets the name of your site
/// @param {string} name The name of the site
function tome_set_site_name(_name){
    __tome_setup_data()
	__tome_file_update_config("name", _name);
}

/// @func tome_set_site_description(desc)
/// @desc Sets the description of your site
/// @param {string} desc The description of the site
function tome_set_site_description(_desc){
    __tome_setup_data()
	__tome_file_update_config("description", _desc);
}

/// @func tome_set_site_theme_color(color)
/// @desc Sets the theme color of your site
/// @param {string} color The theme color of the site
function tome_set_site_theme_color(_color){
    __tome_setup_data()
	__tome_file_update_config("themeColor", _color);
}

/// @func tome_set_site_latest_version(versionName)
/// @desc Sets the latest version of the docs. The version
/// @param {string} versionName The latest version of the docs
function tome_set_site_latest_version(_versionName){
    __tome_setup_data()
	var _fixedVersionName = string_replace_all(_versionName, " ", "-");
	global.__tomeData.latestDocsVersion = _fixedVersionName;
	__tome_file_update_config("latestVersion", _fixedVersionName);
}

/// @text ?> Version names currently cannot contain spaces!

/// @func tome_set_site_older_versions(versions)
/// @desc Specifically set what older versions of your docs you want to show on the site's version selector
/// @param {array<string>} versions An array of older versions names to display in the version selector
function tome_set_site_older_versions(_versions){
    __tome_setup_data()
	__tome_file_update_config("otherVersions", _versions);	
}

/// @func tome_add_navbar_link(name, link)
/// @desc Adds a link to the navbar
/// @param {string} name The name of the link
/// @param {string} link The link to the link
function tome_add_navbar_link(_name, _link){
    __tome_setup_data()
	var _navbarItem = {
		name: _name,
		link: _link
	}
	
	array_push(global.__tomeData.navbarItems, _navbarItem);
}

