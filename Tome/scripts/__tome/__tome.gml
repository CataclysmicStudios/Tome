/// @title Primary functions
/// @category API Reference
/// @text Below are the functions you'll use to set up your docs and generate them. 

#region Add functions

#region /// @func tome_add(file, [slugs])
/// @desc Adds a file to be parsed as a page to your site
/// @param {string} file The name of a file (as shown in the IDE) or a direct file path to an external file
/// @param {string | Array.string} [slugs] [Defualt = undefined] The name of any notes (as shown in the IDE) or a direct file path to an external.txt file that will be used for adding slugs.
function tome_add(_file, _slugs = undefined){
    

    var _filePath = $"{global.__tomeData.projectDirectory}scripts/{_file}/{_file}.gml";
    
    if (!file_exists(_filePath)){
        _filePath = $"{global.__tomeData.projectDirectory}notes/{_file}/{_file}.txt";
    }
    
    if (!file_exists(_filePath)){
        _filePath = _file;
    }

    if (!array_contains(global.__tomeData.parsedFilePaths, _filePath)){
      	if (!file_exists(_filePath)){
      		array_push(global.__tomeData.warnings, $"tome_add: The given file doesn't seem to exist as an script, note, or external file: {_file}");
      		exit;
      	}else{
            var _success = true;
            var _slugParseSuccess = true;
            var _fileParseSuccess = true;
        

            // Determine if we have been passed an acceptable amount of arguments. We want slugs passed as an array of files, instead of individual file paths being passed as single arguments.
            var _isSlugValid = (is_array(_slugs) || is_string(_slugs));
            var _isCallValid = _isSlugValid || is_undefined(_slugs);
            if (_isCallValid){

                if (_isSlugValid){
                    // Add slug(s)
                    var _singleSlug = is_string(_slugs);
                    
                    var _i = 0;
                    var _slugArray = (_singleSlug ? [_slugs] : _slugs);
                    var _loopCount = array_length(_slugArray);
                    
                    repeat(_loopCount){
                        var _slugName = _slugArray[_i];
                        var _slugPath = ""
                        
                        if (file_exists(_slugName)){
                            _slugPath = _slugName;
                        }else{
                            _slugPath = $"{global.__tomeData.projectDirectory}notes/{_slugName}/{_slugName}.txt";
                        }
                        
                        if (!array_contains(global.__tomeData.parsedSlugPaths, _slugPath)){
                            if (!file_exists(_slugPath)){ 
                                array_push(global.__tomeData.warnings, $"tome_add: The given slug file doesn't seem to exist as a note or external file: {_slugName}");
                                _slugParseSuccess = false;
                                exit;
                            }else{
                                _slugParseSuccess = __tomeParseSlugFile(_slugPath);
                                
                                if (_slugParseSuccess){
                                    array_push(global.__tomeData.parsedSlugPaths, _slugPath);
                                }else{
                                    exit;
                                }	
                            }
                        }
                        
                        _success = _success && _slugParseSuccess;
                        
                        _i++;
                    }
                }

                /// @type {Any}
                var _markdownData = undefined;
                if (_success){
                    _markdownData = __tomeParseDocumentationFile(_filePath);
                    
                    _fileParseSuccess = _markdownData.success;
                    
                    if (_fileParseSuccess){

                        var _i = 0;
                        var _foundMatch = false;
                        repeat (array_length(global.__tomeData.docsPageItems)){
                            var _item = global.__tomeData.docsPageItems[_i];

                            if (_item._category == _markdownData._category && _item._title == _markdownData._title){

                                var _context = _item._context;
                                
                                if (!is_undefined(_context)){
                                    while (!is_undefined(_context._nextContext)){
                                        _context = _context._nextContext;
                                    }

                                    _context._nextContext = _markdownData._context;
                                }else{
                                    _item._context = _markdownData._context;
                                }
                                _foundMatch = true;
                                break;
                            }
                            _i++;
                        }

                        if (!_foundMatch){
                            array_push(global.__tomeData.docsPageItems, _markdownData);
                        }

                        array_push(global.__tomeData.parsedFilePaths, _filePath);
                    }
                }
                
                _success = _success && _fileParseSuccess;
                
                if (!_success){
                    array_push(global.__tomeData.warnings, $"tome_add: {_file} Something went wrong during parsing. Please check warnings above for more information.");
                    global.__tomeData.docGenerationFailed = true;
                }
                
            }else{
                array_push(global.__tomeData.warnings, $"tome_add: {_file} - Arguments recieved - {argument_count}, Expected one for doc file, and optional string or array of strings for slug file(s). The provided slug file(s) appear to have not been added as an array. Please see documentation for how tome_add expects slug file(s) as this has changed:");
            }
        }
    }else{
        array_push(global.__tomeData.warnings, $"tome_add: File {_file} has already been added to docs skipping.");
    }
    
}
#endregion // tome_add

#region /// @func tome_add_raw(file, title, category)
/// @description Adds your own markdown file to a category. No parsing of this file is performed, it is added to the docs website as is.
/// @param {string} file The filepath pointing to the file you wish to add to the docs site
/// @param {string} title The title the page will have on the sidebar.
/// @param {string} category The category the page will appear under on the sidebar.
function tome_add_raw(_file, _title, _category){
    var _message = "";

    _message += _title == "" ? "title" : "";
    _message += _category == "" ? (_message == "" ? "" : ", ") + "category" : "";

    if (_message != ""){
        _message += (string_count(",", _message) ? " values are" : " value is") + " empty";

        array_push(global.__tomeData.warnings, $"tome_add_raw({_file}, {_title}, {_category}):  - {_message}.");
        exit;
    }
   
    var _filePath = $"{global.__tomeData.projectDirectory}notes/{_file}/{_file}.txt";
    
    if (!file_exists(_filePath)){
        _filePath = _file;
    }
    
    if (!array_contains(global.__tomeData.parsedFilePaths, _filePath)){
        if (file_exists(_filePath)){

            var _markdownString = __tomeFileTextReadAll(_filePath);
            
            var _context = {
                _contextType: __TOME_CONTEXT_TYPE.TEXT,
                _parentContext: undefined,
                _nextContext: undefined,
                _edited: true,
                _markdown: _markdownString
            };

            var _i = 0;
            var _foundMatch = false;
            repeat (array_length(global.__tomeData.docsPageItems)){
                var _item = global.__tomeData.docsPageItems[_i];

                if (_item._category == _category && _item._title == _title){

                    var _contextTail = _item._context;
                    
                    if (!is_undefined(_contextTail)){
                        while (!is_undefined(_contextTail._nextContext)){
                            _contextTail = _contextTail._nextContext;
                        }

                        _contextTail._nextContext = _context;
                    }else{
                        _item._context = _context;
                    }
                    _foundMatch = true;
                    break;
                }
                _i++;
            }
            
            if (!_foundMatch){
                var _markdownData = {
                    _title,
                    _category,
                    _context,
                    _link: "",
                    _sidebarType: __TOME_SIDEBAR_TYPE.FILE,
                    success: true
                };

                array_push(global.__tomeData.docsPageItems, _markdownData);
            }
            array_push(global.__tomeData.parsedFilePaths, _filePath);


        }else{
            array_push(global.__tomeData.warnings, $"tome_add_raw: The given file doesn't seem to exist at: {_file}. Check that the file does exist");
            exit;
        }
    }else{
        array_push(global.__tomeData.warnings, $"tome_add_raw: File {_file} has already been added to docs skipping.");
    }
}
#endregion // tome_add_raw

#region /// @func tome_add_sidebar_link(link, title, category)
/// @desc Adds a link to the sidebar of your site.
/// @param {string} link The path to the link.
/// @param {string} title The title of the link.
/// @param {string} category The category of the link.
function tome_add_sidebar_link(_link, _title, _category){

    var _message = "";

    _message += _link == "" ? "link" : "";
    _message += _title == "" ? (_message == "" ? "" : ", ") + "title" : "";
    _message += _category == "" ? (_message == "" ? "" : ", ") + "category" : "";

    if (_message != ""){
        _message += (string_count(",", _message) ? " values are" : " value is") + " empty";

        array_push(global.__tomeData.warnings, $"tome_add_sidebar_link({_link}, {_title}, {_category}): {_message}.");
        exit;
    }

    var _sidebarItem = {
        _link,
        _title,
        _category,
        _sidebarType: __TOME_SIDEBAR_TYPE.LINK
    };
    
    array_push(global.__tomeData.docsPageItems, _sidebarItem);

}
#endregion // tome_add_sidebar_link

#region /// @func tome_add_navbar_link(_link, _title)
/// @desc Adds a link to the navbar
/// @param {string} link The path to the link
/// @param {string} title The title of the link
function tome_add_navbar_link(_link, _title){
	
    var _message = "";

    _message += _link == "" ? "link" : "";
    _message += _title == "" ? (_message == "" ? "" : ", ") + "title" : "";

    if (_message != ""){
        _message += (string_count(",", _message) ? " values are" : " value is") + " empty";

        array_push(global.__tomeData.warnings, $"tome_add_navbar_link({_link}, {_title}): {_message}.");
        exit;
    }

    var _navbarItem = {
        _link,
        _title
    }
    
    array_push(global.__tomeData.navbarItems, _navbarItem);
}
#endregion // tome_add_navebar_link

#region Deprecated add functions

#region /// @func tome_add_script(script, [slugs])
/// @deprecated Use `tome_add` instead. This function is only retained for compatibility.
/// @desc Adds a script to be parsed as a page to your site
/// @param {string} scriptName The name off the script to add
/// @param {string} [slugs] The name of any notes (as shown in the IDE) or a direct file path to an external.txt file that will be used for adding slugs. One additional argument per slug note
function tome_add_script(_scriptName){
    var slugs = [];
    
    var _i = 1;
    if (argument_count > 1){
        repeat(argument_count - 1){
            array_push(slugs, argument[_i])
            _i++;
        }
    }
    
    if (array_length(slugs) > 0){
        tome_add(_scriptName, slugs);
    }else{
        tome_add(_scriptName);
    } 
}
#endregion // tome_add_script

#region /// @func tome_add_note(noteName, [slugs])
/// @deprecated Use `tome_add` instead. This function is only retained for compatibility.
/// @desc Adds a note to be parsed as a page to your site 
/// @param {string} noteName The note to add
/// @param {string} [slugs] The name of any notes (as shown in the IDE) or a direct file path to an external.txt file that will be used for adding slugs. One additional argument per slug note
function tome_add_note(_noteName){
    var slugs = [];
    
    var _i = 1;
    if (argument_count > 1){
        repeat(argument_count - 1){
            array_push(slugs, argument[_i])
            _i++;
        }
    }
    
    if (array_length(slugs) > 0){
        tome_add(_noteName, slugs);
    }else{
        tome_add(_noteName);
    } 

}
#endregion // tome_add_note

#region /// @func tome_add_file(filePath)
/// @deprecated Use `tome_add` instead. This function is only retained for compatibility.
/// @desc Adds an external file to be parsed when the docs are generated
/// @param {string} filePath The file to add
/// @param {string} [slugs] The name of any notes (as shown in the IDE) or a direct file path to an external.txt file that will be used for adding slugs. One additional argument per slug note
function tome_add_file(_filePath){
    var slugs = [];
    
    var _i = 1;
    if (argument_count > 1){
        repeat(argument_count - 1){
            array_push(slugs, argument[_i])
            _i++;
        }
    }
    
    if (array_length(slugs) > 0){
        tome_add(_filePath, slugs);
    }else{
        tome_add(_filePath);
    }
}
#endregion // tome_add_file

#region /// @func tome_add_to_sidebar(name, link, category)
/// @deprecated Use `tome_add_sidebar_link` instead. This function is only retained for compatibility.
/// @desc Adds an item to the sidebar of your site
/// @param {string} name The name of the item
/// @param {string} link The link to the item
/// @param {string} category The category of the item
function tome_add_to_sidebar(_name, _link, _category){
	tome_add_sidebar_link(_link, _name, _category)
}
#endregion // tome_add_to_sidebar

#endregion // Deprecated add functions

#endregion // Add functions

#region Homepage functions

#region /// @func tome_set_homepage(file, [raw])
/// @desc Sets the homepage of your site to be the contents of a file (`.txt`, or `.md`)  or note asset from your project.
/// @param {string} file The filepath or note asset name as shown in your project.
/// @param {boolean} raw [Defualt = false] If the file should be used as is (true), or parsed by tome's parser (false)
function tome_set_homepage(_file, _raw = false){
    
    if (!file_exists(_file)){
        _file = $"{global.__tomeData.projectDirectory}notes/{_file}/{_file}.txt";
    }
    
    if (!file_exists(_file)){
        array_push(global.__tomeData.warnings, $"tome_set_homepage: The given file doesn't seem to exist: {_file}");
		exit;
	}

    if (_raw){
        tome_add_raw(_file, "homepage", "homepage");
    }else{
        /// @type {any}
        var _markdownData = __tomeParseDocumentationFile(_file, true);
    
        if (!_markdownData.success){
            array_push(global.__tomeData.warnings, $"tome_set_homepage: {_file} Something went wrong during parsing. Please check warnings above for more information.");
            global.__tomeData.docGenerationFailed = true;
        }else{ 
            array_push(global.__tomeData.docsPageItems, _markdownData);
        }
    }
}
#endregion // tome_set_homepage

#region Deprecated homepage functions

#region /// @func tome_set_homepage_from_file(filePath)
/// @deprecated Use `tome_set_homepage` instead. This function is only retained for compatibility.
/// @desc Sets the homepage of your site to be the contents of a file (`.txt`, or `.md`)
/// @param {string} filePath The file to use as the homepage
function tome_set_homepage_from_file(_filePath){
    
    tome_set_homepage(_filePath);
}
#endregion // tome_set_homepage_from_file

#region /// @func tome_set_homepage_from_note(noteName)
/// @deprecated Use `tome_set_homepage` instead. This function is only retained for compatibility.
/// @desc Sets the homepage of your site to be the contents of the given note
/// @param {string} noteName The note to use as the homepage
function tome_set_homepage_from_note(_noteName){
    var _filePath = $"{global.__tomeData.projectDirectory}notes/{_noteName}/{_noteName}.txt";

    tome_set_homepage(_filePath);
}
#endregion // tome_set_homepage_from_note

#endregion // Deprecated homepage functions

#endregion // Homepage functions

#region Site data and customization

#region /// @func tome_set_site_name(name)
/// @desc Sets the name of your site
/// @param {string} name The name of the site
function tome_set_site_name(_name){
	__tomeUpdateConfigProperty("name", _name);
}
#endregion // tome_set_site_name

#region /// @func tome_set_site_description(desc)
/// @desc Sets the description of your site
/// @param {string} desc The description of the site
function tome_set_site_description(_desc){
	__tomeUpdateConfigProperty("description", _desc);
}
#endregion // tome_set_site_description

#region /// @func tome_set_site_theme_color(color)
/// @desc Sets the theme color of your site
/// @param {string} color The theme color of the site
function tome_set_site_theme_color(_color){
	__tomeUpdateConfigProperty("themeColor", _color);
}
#endregion // tome_set_site_theme_color

#region /// @func tome_set_site_latest_version(versionName)
/// @desc Sets the latest version of the docs. The version
/// @param {string} versionName The latest version of the docs
function tome_set_site_latest_version(_versionName){
    
    if (string_count(" ", _versionName) > 0) {
        array_push(global.__tomeData.warnings, $"tome_set_site_latest_version: The version name '{_versionName}' contains spaces. Spaces have been replaced with hyphens.");
    }

	var _fixedVersionName = string_replace_all(_versionName, " ", "-");
	__tomeUpdateConfigProperty("latestVersion", _fixedVersionName);
}
#endregion // tome_set_site_latest_versions

/// @text ?> Version names currently cannot contain spaces!

#region /// @func tome_set_site_older_versions(versions)
/// @desc Specifically set what older versions of your docs you want to show on the site's version selector
/// @param {array<string>} versions An array of older versions names to display in the version selector
function tome_set_site_older_versions(_versions){

    var _fixedVersions = _versions;

    if (!is_array(_versions)) {
        array_push(global.__tomeData.warnings, $"tome_set_site_older_versions: Expected an array of version strings, but received a {typeof(_versions)}. This has been stringified and placed in an array");
        _fixedVersions = [ $"{_versions}" ];
    }

	__tomeUpdateConfigProperty("otherVersions", _fixedVersions);
}
#endregion // tome_set_sige_older_versions

#region /// @func tome_edit_site_custom_css(css_data)
/// @desc Adds or overrides custom CSS for the documentation site.
/// @param {string|struct} _css_data A raw CSS string or a nested struct containing CSS rules.
function tome_edit_site_custom_css(_css_data) {
    var _parsedSource = {};

    if (is_string(_css_data)) {
        _parsedSource = __tomeCSSToStruct(_css_data);
    } else if (is_struct(_css_data)) {
        _parsedSource = _css_data;
    } else {
        array_push(global.__tomeData.warnings, "tome_edit_site_custom_css(): Provided CSS data must be a string or a struct.");
        return;
    }

    __tomeMergeCSSStructs(global.__tomeData.customCSS, _parsedSource);
}
#endregion // tome_edit_site_custom_css

/// @func tome_color_to_hex(color_integer)
/// @desc Converts a GameMaker color (BGR) into a CSS-ready "#RRGGBB" hex string.
function tome_color_to_css_hex(_col) {
    var _r = color_get_red(_col);
    var _g = color_get_green(_col);
    var _b = color_get_blue(_col);
    
    var _chars = "0123456789ABCDEF";
    
    // Convert each channel to a 2-digit hex string
    var _hex_r = string_char_at(_chars, (_r >> 4) + 1) + string_char_at(_chars, (_r & 15) + 1);
    var _hex_g = string_char_at(_chars, (_g >> 4) + 1) + string_char_at(_chars, (_g & 15) + 1);
    var _hex_b = string_char_at(_chars, (_b >> 4) + 1) + string_char_at(_chars, (_b & 15) + 1);
    
    return "#" + _hex_r + _hex_g + _hex_b;
}

#endregion // Site data and customization