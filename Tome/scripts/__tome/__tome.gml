/// @title Primary functions
/// @category API Reference

/// @pass true

// Non-userfacing functions/macros used to make the system work
#region Macro declaration

///@type {struct}
global.__tome = {
    __initialized: false,
    __data: {},
    site: {},
    utils: {}
};

#macro Tome global.__tome

#macro __TOME_CAN_RUN (TOME_ENABLED && (GM_build_type == "run") && ((os_type == os_windows) || (os_type == os_macosx) || (os_type == os_linux)))

#macro __TOME_FILE_OPEN_FAILED -1

#macro __TOME_VERSION "1.0.0"

#macro __TOME_NEW_CONTEXT variable_clone({                                          \
                                _contextType: __TOME_CONTEXT_TYPE.TEXT,             \
                                _parentContext: undefined,                          \
                                _nextContext: undefined,                            \
                                _edited: false                                      \
                            })

#endregion // Macro declaration

#region Enum declaration

enum TOME_METHOD_GROUP_DEPTH_HEADER{
    H2,
    H3
};

enum __TOME_CONTEXT_TYPE{
    TEXT,
    CODE,
    FUNCTION,
    CONSTRUCTOR,
    METHOD
};

enum __TOME_FILE_TYPE{
    GML,
    TXT
};

enum __TOME_SIDEBAR_TYPE{
    FILE,
    LINK
};

#endregion // Enum declaration

#region /// @func __tomeInitializeAPI()
/// @desc Initializes the Tome API by defining all the functions that will be used to set up and generate the documentation site. This is called automatically.
function __tomeInitializeAPI(){
    /// @pass false
    /// @text Your docs are set up by using functions found in the Tome namespace. Add/edit site items with Tome.site.\*, and check out Tome.utils.\* for functions that will help with the generation of your site.
    /// <br>
    /// <br>
    /// @text Below are the functions you'll use to set up your docs and generate them.

    #region Site Functions

    #region Add Functions

    #region /// @func Tome.site.add(file, [slugs])
    /// @desc Adds a file to be parsed as a page to your site
    /// @param {string} file The name of a file (as shown in the IDE) or a direct file path to an external file.
    /// @param {string | Array.string | undefined} [slugs] [Default = undefined] The name of any notes (as shown in the IDE) or a direct file path to an external .txt file that will be used for adding slugs.
    Tome.site.add = function(_file, _slugs = undefined){

        __tomeUpdateDebug();

        var _filePath = $"{Tome.__data.projectDirectory}scripts/{_file}/{_file}.gml";
        
        if (!file_exists(_filePath)){
            _filePath = $"{Tome.__data.projectDirectory}notes/{_file}/{_file}.txt";
        }
        
        if (!file_exists(_filePath)){
            _filePath = _file;
        }

        if (!array_contains(Tome.__data.parsedFilePaths, _filePath)){
            if (!file_exists(_filePath)){
                __tomePushWarning("The given file doesn't seem to exist as a script, note, or external file.");
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
                            if (!_success){
                                break;
                            }
                                
                            var _slugName = _slugArray[_i];
                            var _slugPath = "";
                            
                            if (file_exists(_slugName)){
                                _slugPath = _slugName;
                            }else{
                                _slugPath = $"{Tome.__data.projectDirectory}notes/{_slugName}/{_slugName}.txt";
                            }
                            
                            if (!array_contains(Tome.__data.parsedSlugPaths, _slugPath)){
                                if (!file_exists(_slugPath)){ 
                                    __tomePushWarning("The given slug file doesn't seem to exist as a note or external file.", true);
                                    _slugParseSuccess = false;
                                }else{
                                    _slugParseSuccess = __tomeParseSlugFile(_slugPath);
                                    
                                    if (_slugParseSuccess){
                                        array_push(Tome.__data.parsedSlugPaths, _slugPath);
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
                            repeat (array_length(Tome.__data.docsPageItems)){
                                var _item = Tome.__data.docsPageItems[_i];

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
                                array_push(Tome.__data.docsPageItems, _markdownData);
                            }

                            array_push(Tome.__data.parsedFilePaths, _filePath);
                        }
                    }
                    
                    _success = _success && _fileParseSuccess;
                    
                    if (!_success){
                        __tomePushWarning("Something went wrong during parsing. Please check warnings above for more information.", true);
                    }
                    
                }else{
                    __tomePushWarning($"Arguments received - {argument_count}. Expected one string for doc file path, and optional string or array of strings for slug file(s). The provided slug file(s) do not appear to be added as an array. Please see documentation for how Tome.site.add expects slug file(s) as this has changed:");
                }
            }
        }else{
            __tomePushWarning("File has already been added to docs, skipping.");
        }
        
    };
    #endregion // Tome.site.add

    #region /// @func Tome.site.addRaw(file, title, category)
    /// @description Adds your own markdown file to a category. No parsing of this file is performed; it is added to the docs website as is.
    /// @param {string} file The filepath pointing to the file you wish to add to the docs site
    /// @param {string} title The title the page will have on the sidebar.
    /// @param {string} category The category the page will appear under on the sidebar.
    Tome.site.addRaw = function(_file, _title, _category){
        
        if (is_undefined(_title)){
            _title = "";
        }

        if (is_undefined(_category)){
            _category = "";
        }

        __tomeUpdateDebug();
        
        var _message = "";

        _message += _title == "" ? "title" : "";
        _message += _category == "" ? (_message == "" ? "" : ", ") + "category" : "";

        if (_message != ""){
            _message += (string_count(",", _message) ? " values are" : " value is") + " empty.";

           __tomePushWarning(_message, true);
            exit;
        }
    
        var _filePath = $"{Tome.__data.projectDirectory}notes/{_file}/{_file}.txt";
        
        if (!file_exists(_filePath)){
            _filePath = _file;
        }
        
        if (!array_contains(Tome.__data.parsedFilePaths, _filePath)){
            if (file_exists(_filePath)){

                var _markdownString = __tomeFileTextReadAll(_filePath);
                
                if (!is_undefined(_markdownString)){

                    var _context = {
                        _contextType: __TOME_CONTEXT_TYPE.TEXT,
                        _parentContext: undefined,
                        _nextContext: undefined,
                        _edited: true,
                        _markdown: _markdownString
                    };

                    var _i = 0;
                    var _foundMatch = false;
                    repeat (array_length(Tome.__data.docsPageItems)){
                        var _item = Tome.__data.docsPageItems[_i];

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

                        array_push(Tome.__data.docsPageItems, _markdownData);
                    }
                    array_push(Tome.__data.parsedFilePaths, _filePath);
                }

            }else{
                __tomePushWarning($"The given file doesn't seem to exist.", true);
                exit;
            }
        }else{
            __tomePushWarning("File has already been added to docs, skipping.");
        }
    };
    #endregion // tome_add_raw

    #region /// @func Tome.site.addSidebarLink(link, title, category)
    /// @desc Adds a link to the sidebar of your site.
    /// @param {string} link The path to the link.
    /// @param {string} title The title of the link.
    /// @param {string} category The category of the link.
    Tome.site.addSidebarLink = function(_link, _title, _category){

        if (is_undefined(_title)){
            _title = "";
        }

        if (is_undefined(_category)){
            _category = "";
        }

        __tomeUpdateDebug();
        
        var _message = "";

        _message += _link == "" ? "link" : "";
        _message += _title == "" ? (_message == "" ? "" : ", ") + "title" : "";
        _message += _category == "" ? (_message == "" ? "" : ", ") + "category" : "";

        if (_message != ""){
            
            _message += (string_count(",", _message) ? " values are" : " value is") + " empty.";

            __tomePushWarning(_message);
            exit;
        }

        var _sidebarItem = {
            _link,
            _title,
            _category,
            _sidebarType: __TOME_SIDEBAR_TYPE.LINK
        };
        
        array_push(Tome.__data.docsPageItems, _sidebarItem);

    };
    #endregion // Tome.site.addSidebarLink

    #region /// @func Tome.site.addNavbarLink(link, title)
    /// @desc Adds a link to the navbar
    /// @param {string} link The path to the link
    /// @param {string} title The title of the link
    Tome.site.addNavbarLink = function(_link, _title){
        if (is_undefined(_link)){
            _link = "";
        }

        if (is_undefined(_title)){
            _title = "";
        }
        __tomeUpdateDebug();
        
        var _message = "";

        _message += _link == "" ? "link" : "";
        _message += _title == "" ? (_message == "" ? "" : ", ") + "title" : "";

        if (_message != ""){
            _message += (string_count(",", _message) ? " values are" : " value is") + " empty.";

            __tomePushWarning(_message);
            exit;
        }

        var _navbarItem = {
            _link,
            _title
        };
        
        array_push(Tome.__data.navbarItems, _navbarItem);
    };
    #endregion // Tome.site.addNavbarLink

    #endregion // Add functions

    #region /// @func Tome.site.setHomepage(file, [raw])
    /// @desc Sets the homepage of your site to be the contents of a file (`.txt`, or `.md`) or note asset from your project.
    /// @param {string} file The filepath or note asset name as shown in your project.
    /// @param {boolean} raw [Default = false] If the file should be used as is (true), or parsed by Tome's parser (false)
    Tome.site.setHomepage = function(_file, _raw = false){
        
        __tomeUpdateDebug();
        
        if (!file_exists(_file)){
            _file = $"{Tome.__data.projectDirectory}notes/{_file}/{_file}.txt";
        }
        
        if (!file_exists(_file)){
            __tomePushWarning("The given file doesn't seem to exist.");
            exit;
        }

        if (_raw){
            Tome.site.addRaw(_file, "homepage", "homepage");
        }else{
            /// @type {any}
            var _markdownData = __tomeParseDocumentationFile(_file, true);
        
            if (!_markdownData.success){
                __tomePushWarning("Something went wrong during parsing. Please check warnings above for more information.", true);
            }else{ 
                array_push(Tome.__data.docsPageItems, _markdownData);
            }
        }
    };
    #endregion // Tome.site.setHomepage

    #region Config functions

    #region /// @func Tome.site.setName(name)
    /// @desc Sets the name of your site, this will appear in the header and the title tag of the generated documentation.
    /// @param {string} name The name of your site.    
    Tome.site.setName = function(_name){
        
        __tomeUpdateDebug();
        
        Tome.site.setConfigProperty("name", _name);
    };
    #endregion // Tome.site.setName

    #region /// @func Tome.site.setDescription(description)
    /// @desc Sets the description of your site, this will appear in the meta description tag of the generated documentation.
    /// @param {string} description The description of your site.
    Tome.site.setDescription = function(_description){
        
        __tomeUpdateDebug();
        
        Tome.site.setConfigProperty("description", _description);
    };
    #endregion // Tome.site.setDescription

    /// @text ?> Version names cannot contain illegal filepath characters or spaces!
    
    #region /// @func Tome.site.setLatestVersion(_versionName)
    /// @desc Sets the latest version of your project. This will be used to determine which version of the docs to show by default, and will be shown in the version dropdown if you have multiple versions of docs.
    /// @param {string} _versionName The latest version of your project.   
    Tome.site.setLatestVersion = function(_versionName){
        
        var _fixedVersionName = string(_versionName);
        
        __tomeUpdateDebug();
        
        var _oldVersionName = _fixedVersionName;
        var _illegalFilePathChars = [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"];

        _fixedVersionName = __tomeStringReplaceAllExt(_fixedVersionName, _illegalFilePathChars, "-");
        if (_fixedVersionName != _oldVersionName) {
            __tomePushWarning($"The version name contains illegal file path characters. All illegal characters have been replaced with hyphens.");
        }

        
        Tome.site.setConfigProperty("latestVersion", _fixedVersionName);
    };
    #endregion // Tome.site.setLatestVersion

    #region /// @func Tome.site.setOlderVersions(versions)
    /// @desc Sets the older versions of your project. This will be used to populate the version dropdown if you have multiple versions of docs.
    /// @param {Array.string} _versions An array of older versions of your project.
    Tome.site.setOlderVersions = function(_versions){
        
        __tomeUpdateDebug();
        
        var _fixedVersions = _versions;
        
        if (!is_array(_versions)) {
            __tomePushWarning($"Expected an array of version strings, but received a {typeof(_versions)}. This has been {is_string(_versions) ? "" : "stringified and "}placed in an array.");
            _fixedVersions = [ $"{_versions}" ];
        }

        __tomeUpdateConfigProperty("otherVersions", _fixedVersions);
    };
    #endregion // Tome.site.setOlderVersions

    #region /// @func Tome.site.setThemeColor(themeColor)
    /// @desc Sets the theme color of your site. This will be used as the primary color for your docs site, used in the header, links, and other accents.
    /// @param {Constant.Color | string} themeColor The theme color of your site. This can be a GameMaker color constant, or a CSS hex string (e.g. "#FF0000" for red). If providing a GameMaker color, it will be converted to a CSS hex string automatically.
    Tome.site.setThemeColor = function(_themeColor){
        
        __tomeUpdateDebug();
        
        var _themeColorString = _themeColor;
        if (!is_string(_themeColor)){ 
            _themeColorString = Tome.utils.colorToCSSHex(real(_themeColor));
        }

        Tome.site.setConfigProperty("themeColor", _themeColorString);
    };
    #endregion // Tome.site.setThemeColor

    #region /// @func Tome.site.setConfigProperty(property, value)
    /// @desc Sets a custom configuration property for your site. This can be any value, but keep in mind that if you want to use this property in your site you'll need to reference it in the index.html of your docs site, and you may need to use custom JavaScript to make use of it depending on how you want to use it.
    /// @param {string} property The name of the configuration property to set.
    /// @param {any} value The value of the configuration property. 
    Tome.site.setConfigProperty = function(_property, _value){
        
        __tomeUpdateDebug();
        
        __tomeUpdateConfigProperty(_property, _value);
    };
    #endregion // Tome.site.setConfigProperty

    #endregion // Config functions
    
    /// @text ?> For more information about using custom CSS with Tome check [this](misc-advanced-use?id=custom-css) out!

    #region /// @func Tome.site.editCustomCSS(cssData)
    /// @desc Adds or overrides custom CSS for the documentation site.
    /// @param {string|struct} _cssData A raw CSS string or a nested struct containing CSS rules.
    Tome.site.editCustomCSS = function(_cssData) {
        
        __tomeUpdateDebug();
        
        var _parsedSource = {};

        if (is_string(_cssData)) {
            _parsedSource = __tomeCSSToStruct(_cssData);
        } else if (is_struct(_cssData)) {
            _parsedSource = _cssData;
        } else {
            __tomePushWarning("Provided CSS data must be a string or a struct.");
            return;
        }

        __tomeMergeCSSStructs(_parsedSource);
    };
    #endregion // Tome.site.editCustomCSS

    #endregion // Site functions

    #region Utility functions

    #region /// @func Tome.utils.colorToCSSHex(color)
    /// @desc Converts a GameMaker color to a CSS hex string.
    /// @param {number} color The GameMaker color to convert.
    /// @returns {string} The CSS hex string representation of the color.
    Tome.utils.colorToCSSHex = function(_color){
        var _r = color_get_red(_color);
        var _g = color_get_green(_color);
        var _b = color_get_blue(_color);
        
        var _chars = "0123456789ABCDEF";
        
        // Convert each channel to a 2-digit hex string
        var _hex_r = string_char_at(_chars, (_r >> 4) + 1) + string_char_at(_chars, (_r & 15) + 1);
        var _hex_g = string_char_at(_chars, (_g >> 4) + 1) + string_char_at(_chars, (_g & 15) + 1);
        var _hex_b = string_char_at(_chars, (_b >> 4) + 1) + string_char_at(_chars, (_b & 15) + 1);
        
        return "#" + _hex_r + _hex_g + _hex_b;
    };
    #endregion // Tome.utils.colorToCSSHex
    
    #region /// @func Tome.utils.fileReadAllText(filepath)
    /// @desc Loads a text file and reads its entire contents as a string
    /// @param {string} filePath The path to the text file to read
    /// @returns {string} The contents of a file as a string.
    Tome.utils.fileReadAllText = function(_filepath){
        return __tomeFileTextReadAll(_filepath, false);
    };
    #endregion // Tome.utils.fileReadAllText
    
    #region /// @func Tome.utils.fileReadAllBin(filepath)
    /// @desc Loads a binary file into a buffer (You are responsible for deleting the returned buffer)
    /// @param {string} filePath The path to the binary file to read.
    /// @returns {buffer} A buffer reference containing the data of the binary file
    Tome.utils.fileReadAllBin = function(_filepath){
        return __tomeFileBinReadAll(_filepath, false);
    };
    #endregion // Tome.utils.fileReadAllBin

    #endregion // Utility functions
    
}

#endregion // __tomeInitializeAPI

/// @pass true
#region Core System Functions

#region /// @func __tomeSetupData()
/// @desc Initializes the global struct that holds Tome's data.
function __tomeSetupData(){
    if (!__tomeInitialized()){    
        var _projectDirectory = string_trim(string_replace_all(filename_dir(GM_project_filename) + "\\", "\\", "/"));
        
        global.__tome = {
            __data: {
                repoFilePath: "",
                categories: {
                    names: [],
                    map: {}
                },
                slugs: [],
                docsPageItems: [],
                parsedSlugPaths: [],
                parsedFilePaths: [],
                navbarItems: [],
                warnings: [],
                docGenerationFailed: false,
                projectDirectory: _projectDirectory,
                customCSS: {},
                config: {}
            },
            __debug: {
                setupFileLines: [],
                mostRecentCallLine: 0,
                mostRecentCall: "",
                hasBeenUsed: false
            },
            site: {},
            utils: {},
            __initialized: false
        };
        
        // Load in the default theme css and config.
        var _cssStruct = __tomeCSSToStruct(__tomeFileTextReadAll($"{_projectDirectory}datafiles/Tome/assets/customTheme.css", true));
        Tome.__data.customCSS = _cssStruct;

        var _configStruct = __tomeParseConfig($"{_projectDirectory}datafiles/Tome/config.js");
        Tome.__data.config = _configStruct;

        __tomeVerifyRepoPath();

        __tomeSetupDebug();

        __tomeInitializeAPI();

        Tome.__initialized = true;
    }
}
#endregion // __tomeSetupData

#region /// @func __tomeGenerateDocs()
/// @desc Generates the documentation website
/// Parses all files added via `Tome.site` functions and generates your documentation site.  
/// Then it adds them to the repo path specified with the macro `TOME_LOCAL_REPO_PATH`
function __tomeGenerateDocs(){

        __tomeClearDocsPath();

        __tomeTrace("Updating Docsify Files", true, 2, false);
    
    	__tomeUpdateDocsifyFiles();

        __tomeTrace("Processing Site Items", true, 2, false);

        __tomeProcessDocsItems();
        
        __tomeTrace("Generating sidebar and navbar", true, 2, false);
    	
    	__tomeGenerateSidebar();
        
        __tomeGenerateNavbar();

}
#endregion // __tomeGenerateDocs

#endregion // Core System Functions
    
#region File I/O

#region /// @func __tomeVerifyRepoPath()
/// @desc Makes sure TOME_LOCAL_REPO_PATH path is a valid directory
function __tomeVerifyRepoPath(){
    var _repoPathWithAddedForwardSlash = TOME_LOCAL_REPO_PATH; 
    
    // In case the user didn't end their repo filepath with "/", add it
    if (!string_ends_with(_repoPathWithAddedForwardSlash, "/")){
        _repoPathWithAddedForwardSlash += "/";
    }
    
    if (!directory_exists(_repoPathWithAddedForwardSlash)){
        __tomeTrace("Repo directory does not exist, creating now...", false, 1, false);
        directory_create(_repoPathWithAddedForwardSlash);
    }

    Tome.__data.repoFilePath = _repoPathWithAddedForwardSlash;

}
#endregion // __tomeVerifyRepoPath

#region /// @func __tomeUpdateFile(filePath, fileContent)
/// @desc Updates a given file, with the given content
/// @param {string} _filePath The path to the file to update
/// @param {string|buffer} _fileContent The data to save out to disk. If providing a buffer, it will be deleted after saving.
/// @returns {boolean} Whether the file was successfully updated/created or not.
function __tomeUpdateFile(_filePath, _fileContent){
    var _fileBuffer;
    
    var _success = (is_string(_fileContent)) || (!is_undefined(_fileContent) && buffer_exists(_fileContent));

    var _existed = file_exists(_filePath);
    
    if (!_success){
        __tomePushWarning($"Data was not passed as a string or buffer to write to file at path {_filePath}. If you are seeing this warning, this is a bug in Tome; please report as an issue on GitHub.", true);
    }else if (_existed){
        if (!file_delete(_filePath)){
            __tomePushWarning($"Failed to delete locked file at path {_filePath}. Ensure it is not open in another program.", true);
            _success = false;

            if (!is_string(_fileContent)){
                buffer_delete(_fileContent);
            }
        }
    }

    if (_success){
        if (is_string(_fileContent)){
            _fileBuffer = buffer_create(0, buffer_grow, 1);
        
            buffer_write(_fileBuffer, buffer_text, _fileContent);
        }else{
            _fileBuffer = _fileContent;	
        }
    
        buffer_save(_fileBuffer, _filePath);
        buffer_delete(_fileBuffer);
        
        _success = file_exists(_filePath);
        
        if (_success){
            __tomeTrace(string("Local repo file {0}: {1}", _existed ? "updated" : "created", _filePath), true, 3, false);
        }else{
            __tomePushWarning($"Failed to {_existed ? "update" : "create"} file at path {_filePath}. Check permissions of the file and ensure the directory exists.", true);
        }
    }
    return _success;
}
#endregion // __tomeUpdateFile

#region /// @func __tomeFileTextReadAll(filePath, [tomeInternalCall])
/// @desc Loads a text file and reads its entire contents as a string
/// @param {string} filePath The path to the text file to read
/// @param {boolean} [tomeInternalCall] Whether this function is being called internally by Tome.
/// @returns {string} The contents of a file as a string.
function __tomeFileTextReadAll(_filePath, _tomeInternalCall = true){
    var _fileContents = undefined;

    if (file_exists(_filePath)){
        var _fileBuffer = buffer_load(_filePath);
        if (_fileBuffer != __TOME_FILE_OPEN_FAILED){
            if (buffer_get_size(_fileBuffer) > 0){
                _fileContents = buffer_read(_fileBuffer, buffer_text);
            }
            buffer_delete(_fileBuffer);
        }
    }else{
        if (_tomeInternalCall){
            __tomePushWarning($"You seem to have deleted a file {_filePath}. This file is necessary for Tome to function. Please restore this file.", true);
        }else{
            __tomePushWarning($"File at path {_filePath} does not exist. Check that the file exists and the path is correct.");
        }
    }       
    
    return _fileContents;
}
#endregion // __tomeFileTextReadAll

#region /// @func __tomeFileBinReadAll(filePath, [tomeInternalCall])
/// @desc Loads a binary file into a buffer 
/// @param {string} filePath The path to the binary file to read
/// @param {boolean} [tomeInternalCall] Whether this function is being called internally by Tome.
function __tomeFileBinReadAll(_filePath, _tomeInternalCall = true){
	var _fileBuffer = undefined;

    if (file_exists(_filePath)){
        _fileBuffer = buffer_load(_filePath);
        if (buffer_get_size(_fileBuffer) > 0){
            _fileBuffer = buffer_load(_filePath);
        }
    }else{
        if (_tomeInternalCall){
            __tomePushWarning($"You seem to have deleted a file {_filePath}. This file is necessary for Tome to function. Please restore this file.", true);
        }else{
            __tomePushWarning($"File at path {_filePath} does not exist. Check that the file exists and the path is correct.");
        }
    }        

	return _fileBuffer;
}
#endregion // __tomeFileBinReadAll

#region /// @func __tomeFileGetFinalDocPath()
/// @desc Gets the actual filepath within the repo where the .md files will be pushed
function __tomeFileGetFinalDocPath() { 
    var _version = Tome.__data.config[$ "latestVersion"];
    if (is_undefined(_version)){
        _version = "unversioned";
    }
    return $"{Tome.__data.repoFilePath}{_version}/";
}
#endregion // __tomeFileGetFinalDocPath

#endregion // File I/O

#region Context Parsing and Markdown Generation

#region /// @func __tomeParseDocumentationFile(filepath, [homepage])
/// @desc Parses a file and generates a context markdown struct that can then be used to generate markdown for the documentation site.
/// @param {string} filepath The path of the file to parse.
/// @param {boolean} homepage [Default: false] If this is the file that will be parsed to be used as the homepage.
/// @returns {struct} The markdown struct that holds all data related to this file. To determine if the file was properly parsed, check the success variable.
function __tomeParseDocumentationFile(_filepath, _homepage = false){
    var _markdownData = {
        _title: _homepage ? "homepage" : undefined,
        _category: _homepage ? "homepage" : undefined,
        _context: __TOME_NEW_CONTEXT,
        _link: "",
        _sidebarType: __TOME_SIDEBAR_TYPE.FILE,
        success: true
    }; // The markdown struct that is generated for this particular file
    
    var _context = _markdownData._context;
    
    var _contextHead = _context;
    
    var _fileType = string_trim(filename_ext(_filepath), ["."]) == "gml" ? __TOME_FILE_TYPE.GML : __TOME_FILE_TYPE.TXT;
    var _file = file_text_open_read(_filepath);
    
    var _passing = false;
    var _addAsText = false;

    
    if (_file != __TOME_FILE_OPEN_FAILED){
        var _lineNumber = 0;
        var _tagType = "";
        var _tagContent = "";

        var _fileIsText = _fileType == __TOME_FILE_TYPE.TXT;
        
        if (_fileIsText){
            _tagType = "@text";
        }

        while (!file_text_eof(_file)){
            _lineNumber++;
            var _lineString = file_text_readln(_file);
            var _rawLine = _lineString;
            
            /// Added removal of #region tags as the line may not always begin with "///" but may begin with "#region ///"
            if (string_starts_with(string_trim_start(_lineString), "#region")){
                _lineString = string_replace(_lineString, "#region", "");
            }

            var _lineIsJSDoc = string_starts_with(string_trim_start(_lineString), "///");

            if (_lineIsJSDoc || _fileIsText){
                if (_lineIsJSDoc){
                    _lineString = string_replace(_lineString, "///", "");
                }
                
    			//If the line contains a tag 
    			if (string_starts_with(string_trim(_lineString), "@")){
    				_lineString = string_trim(_lineString);

    				_tagType = string_split_ext(_lineString, [" ", "\t"], true)[0]; 
                    _tagContent = string_trim(string_replace(_lineString, _tagType, ""));
    				
    				if (_tagType == "@pass"){
                        if (string_lower(_tagContent) == "true"){
                            _passing = true;
                            _addAsText = false;
                            _tagType = "";
                            _tagContent = "";
                            continue;
                        }
                        
                        if (string_starts_with(string_lower(_tagContent), "tag")){
                            _passing = true;
                            _addAsText = true;
                            _tagType = "";
                            _tagContent = "";
                            continue;
                        }
                        
                        if (string_lower(_tagContent) == "false"){
                            _passing = false;
                            _tagType = "";
                            _tagContent = "";
                            continue;
                        }
    				}
                }else{
                    _tagContent = _lineString;
                }
                
                if (_tagType == "handled"){
                    _tagType = "@text";
                }
                
                // Right now I only care about indentation if it's a code block or text block
    			if (!(_tagContent == "@text" || _tagContent == "@code" || _tagContent == "@example")){
    				_lineString = string_trim(_lineString);	
    			}
                                
                var _editIfPassing = (
                    _tagType == "@end" ||
                    _tagType == "@category" || 
                    _tagType == "@title"
                );
                
                if (!_passing || _editIfPassing){
                    switch (_tagType){
                        case "@title":
                            if (is_undefined(_markdownData._title)){
                                _markdownData._title = _tagContent;
                            }else{
                                __tomePushWarning($"Line {_lineNumber}: Title tag found with value {_tagContent}, but title was previously set to {_markdownData._title}. Only the first instance of title is respected.");
                            }
                            _tagType = "handled";
                            break;
                        
                        case "@category":
                            if (is_undefined(_markdownData._category)){
                                _markdownData._category = _tagContent;
                            }else{
                                __tomePushWarning($"Line {_lineNumber}: Category tag found with value {_tagContent}, but category was previously set to {_markdownData._category}. Only the first instance of category is respected.");
                            }
                            _tagType = "handled";
                            break;
                        
                        case "@pass":
                            if (!__tomeIsContextTextOnly(_context)){
                                _context = __tomeNewContext(_context);
                            }
                            
                            if (!_context._edited){
                                _context._edited = true;
                                _context._markdown = "";
                            }
                            
                            _context._markdown += _tagContent;
                            _tagType = "handled";
                            break;
                        
                        case "@end":
                            if (!_fileIsText){
                                if (_context._parentContext != undefined){
                                    _context = _context._parentContext;
                                }
                                
                                _context = __tomeNewContext(_context, false);
                            }
                            _tagType = "handled";
                            break;
                        
                        case "@slug":
                        case "@insert":
                            var _slugContent = "";    
                            
                            for (var _slugIndex = 0; _slugIndex < array_length(Tome.__data.slugs) && _slugContent == ""; _slugIndex++){
                                if (_tagContent == Tome.__data.slugs[_slugIndex][0]){
                                    _slugContent = "\n" + Tome.__data.slugs[_slugIndex][1] + "\n";
                                }
                            }

                            if (_slugContent == ""){
                                __tomePushWarning($"Line {_lineNumber}: {_tagType} tag found, but it appears the provided name {_tagContent} does not exist in the parsed slugs.");
                            }else{
                                if (__tomeIsContextFunction(_context)){
                                    if (_context._firstParameterFound){
                                        _context._footer += _slugContent;
                                    }else{
                                        _context._description += _slugContent;
                                    }
                                }else{
                                    if (_context._contextType != __TOME_CONTEXT_TYPE.TEXT){
                                        _context = __tomeNewContext(_context);
                                        _context._edited = true;
                                        _context._markdown = _slugContent;
                                    }else{
                                        if (!_context._edited){
                                            _context._edited = true;
                                        }
                                        _context._markdown += _slugContent;
                                    }
                                }
                            }
                            _tagType = "handled";
                            break;

                        case "@constructor":
                        case "@function":
                        case "@func":
                        case "@method":
                            if (!_fileIsText){
                                var _parameters = [];
                                var _contextEntered = true;
                                switch(_tagType){
                                    case "@constructor":
                                        
                                        if (_context._parentContext != undefined){
                                            _context = _context._parentContext;
                                        }
                                    
                                        _context = __tomeNewContext(_context);
                                        _context._contextType = __TOME_CONTEXT_TYPE.CONSTRUCTOR;
                                        _context._methods = undefined;
                                        _context._signature = undefined;
                                        break;
                                    
                                    case "@function":
                                    case "@func":
                                        if (!(_context._contextType == __TOME_CONTEXT_TYPE.CONSTRUCTOR && is_undefined(_context._signature))){
                                            if (_context._parentContext != undefined){
                                                _context = _context._parentContext;
                                            }
                                            _context = __tomeNewContext(_context);
                                            _context._contextType = __TOME_CONTEXT_TYPE.FUNCTION;
                                        }
                                        _context._signature = _tagContent;
                                        _parameters = __tomeGetParametersFromSignature(_context._signature);
                                        break;
                                    
                                    case "@method":
                                        if (_context._contextType == __TOME_CONTEXT_TYPE.CONSTRUCTOR){
                                            _context._methods = __TOME_NEW_CONTEXT;
                                            _context._methods._parentContext = _context;
                                            _context = _context._methods;
                                        }else if (!is_undefined(_context._parentContext)){
                                            _context = __tomeNewContext(_context);
                                        }else{
                                            _contextEntered = false;
                                            __tomePushWarning($"Line {_lineNumber}: {_tagType} tag found, but the current context is not compatible. Please ensure this tag is where you intend it to be or use @func/@function instead.");
                                        }

                                        if (_contextEntered){ 
                                            
                                            _context._contextType = __TOME_CONTEXT_TYPE.METHOD;
                                            _context._groupTag = "";
                                            _context._signature = _tagContent;
                                            _parameters = __tomeGetParametersFromSignature(_context._signature);
                                        }
                                        break;
                                    }
                                
                                if (_contextEntered){
                                    _context._edited = true;
                                    _context._deprecated = false;
                                    _context._description = "";
                                    _context._firstParameterFound = false;
                                    _context._parameters = _parameters;
                                    _context._return = "{undefined}";
                                    _context._returnDescription = "";
                                    _context._footer = "";
                                }

                                _tagType = "handled";
                            }else{
                                _context._markdown += _rawLine;
                            }
                            
                            break;
                        
                        case "@desc":
                        case "@description":
                            if (__tomeIsContextFunction(_context)){
                                _context._description += $"{_tagContent} ";
                            }
                            break;
                        
                        case "@group":
                            if (_context._contextType == __TOME_CONTEXT_TYPE.METHOD){
                                _context._groupTag = _tagContent;
                            }
                            _tagType = "handled";
                            break;

                        case "@deprecated":
                            if (__tomeIsContextFunction(_context)){
                                _context._deprecated = true;
                                _context._deprecatedCallout = _tagContent; 
                            }else{
                                __tomePushWarning($"Line {_lineNumber}: {_tagType} tag found, but the current context is not compatible. Please ensure this tag is where you intend it to be.");
                            }
                            _tagType = "handled";
                            break;
                        
                        case "@argument":
                        case "@arg":
                        case "@parameter":
                        case "@param":
                            
                            if (__tomeIsContextFunction(_context)){
                                _context._firstParameterFound = true;
                                
                                var _splitContent = string_split_ext(_tagContent, ["}"], true, 1); 
                                
                                
                                var _type = "";
                                var _name = "";
                                var _desc = "";
                                
                                if (array_length(_splitContent) > 0){
                                    _type = string("{0}}", _splitContent[0]);
                                
                                    if (array_length(_splitContent) > 1){
                                        var _nameDesc = string_trim(_splitContent[1]);
    
                                        _splitContent = string_split_ext(_nameDesc, [" ", "\t"], false, 1); 
       
                                        _name = _splitContent[0]; 
                                        
                                        if (array_length(_splitContent) > 1){
                                            _desc = _splitContent[1];
                                        }
                                    }else{
                                        __tomePushWarning($"Line {_lineNumber}: {_tagType} tag found, but only a type was provided. Please ensure this tag has at least a type and a name.");                                 
                                    }
                                }else{
                                    __tomePushWarning($"Line {_lineNumber}: {_tagType} tag found, but no type or description was provided. Please ensure this tag has at least a type and a name.");                                 
                                }
                                
                                // Remove any square brackets that the user put in the name we will add those ourselves based on if they exist here or in the signature.
                                var _preChangeName = _name;
                                _name = string_replace_all(_name, "[", "");
                                _name = string_replace_all(_name, "]", "");
                                
                                var _optional = _preChangeName != _name;
                                
                                var _i = 0, found = false;
                                repeat(array_length(_context._parameters)){
                                    var _param = _context._parameters[_i];
                                    if (_param.name == _name){
                                        _param.type = _type;
                                        _param.description = _desc;
                                        _param.optional = _param.optional || _optional;
                                        found = true;
                                        break;
                                    }
                                    _i++;
                                }
                                    
                                if (!found){
                                    __tomePushWarning($"Line {_lineNumber}: {_tagType} tag found with name {_preChangeName}, but no parameter was found in the function signature: {_context._signature}");
                                }
                                
                            }else{
                                __tomePushWarning($"Line {_lineNumber}: {_tagType} tag found, but the current context is not compatible. Please ensure this tag is where you intend it to be.");
                            }
                            _tagType = "handled";
                            break;
                        
                        case "@return":
                        case "@returns":
                            if (__tomeIsContextFunction(_context)){
                                
                                var _splitContent = string_split_ext(_tagContent, ["}"], true, 1);
                                
                                var _type = "";
                                var _desc = "";
                                
                                if (array_length(_splitContent) > 0){
                                    _type = string("{0}}", _splitContent[0]);
                                    
                                    if (array_length(_splitContent) > 1){
                                        _desc = _splitContent[1];
                                    }
                                }else{
                                    __tomePushWarning($"Line {_lineNumber}: {_tagType} tag found, but no type was provided. Please ensure this tag has at least the type.");                         
                                }
                                
                                
                                
                                _context._return = _type;
                                _context._returnDescription = _desc;
                                
                                
                            }else{
                                __tomePushWarning($"Line {_lineNumber}: {_tagType} tag found, but the current context is not compatible. Please ensure this tag is where you intend it to be.");
                            }
                            _tagType = "handled";
                            break;
                                                
                        case "@code":
                        case "@example":
                            
                            if (_context._contextType == __TOME_CONTEXT_TYPE.CONSTRUCTOR){
                                _context._methods = __TOME_NEW_CONTEXT;
                                _context._methods._parentContext = _context;
                                _context = _context._methods;
                                _context._contextType = __TOME_CONTEXT_TYPE.CODE;
                            }
                            
                            if (_context._contextType != __TOME_CONTEXT_TYPE.CODE){
                                _context = __tomeNewContext(_context);
                            }
                            
                            if (!_context._edited){
                                _context._edited = true;
                                _context._contextType = __TOME_CONTEXT_TYPE.CODE;
                                _context._markdown = "";
                            }
                                
                            _context._markdown += _tagContent;
                            break;
                        
                        case "@text":
                            if (_context._contextType == __TOME_CONTEXT_TYPE.CONSTRUCTOR){
                                _context._methods = __TOME_NEW_CONTEXT;
                                _context._methods._parentContext = _context;
                                _context = _context._methods;
                                _context._contextType = __TOME_CONTEXT_TYPE.TEXT;
                            }
                            
                            if (_context._contextType != __TOME_CONTEXT_TYPE.TEXT){
                                _context = __tomeNewContext(_context);
                            }
                            
                            if (!_context._edited){
                                _context._edited = true;
                                _context._contextType = __TOME_CONTEXT_TYPE.TEXT;
                                _context._markdown = "";
                            }
                    
                            _context._markdown += _tagContent;
                            break;

                        default:
                            if (_fileIsText){
                                _tagType = "@text";
                                _context._markdown += _tagContent;
                                
                            }else{
                                if (_tagType != "handled"){
                                    __tomePushWarning($"Line {_lineNumber}: {_tagType} tag found. Tag type is not supported by Tome. If you are using this tag for Feather, Stitch, or any other reason, you can ignore this warning.");
                                }   
                            }
                            break;

                    }
                }else{
                    if (_addAsText){
                        // We set this to the context returned because the context may change in the helper function
                        _context = __tomeAddTextAnyways(_context, _rawLine);
                    }
                }
            }
        }
        
        file_text_close(_file);
    }else{
        __tomePushWarning($"Failed to open file. Check permissions of the file.", true);
        _markdownData.success = false;
    }
    
    var titleUndefined = is_undefined(_markdownData._title);
    var categoryUndefined = is_undefined(_markdownData._category);

    if (titleUndefined || categoryUndefined){

        var _message = "No ";
        _message += titleUndefined ? "title " + (categoryUndefined ? "or " : "") : "";
        _message += categoryUndefined ? "category " : "";
        _message += "defined. Tome expects both a title and category tag to be provided for each file added using Tome.site.add(). Please check the documentation for more information.";
        

        __tomePushWarning(_message);
        _markdownData.success = false;
    }

    if (_markdownData.success){
        _context = _contextHead;
        
        while (!is_undefined(_context)){

            if (_context._contextType == __TOME_CONTEXT_TYPE.CONSTRUCTOR){
                var _subContext = _context._methods;
                
                if (!is_undefined(_subContext)){
                    var _contextGroupHead = _subContext;
                    var _groups = { names: [""],
                        group_ungrouped: undefined,
                        group_ungroupedTail: undefined
                    };
                    
                    while (!is_undefined(_subContext)){
                        var _isMethod = _subContext._contextType == __TOME_CONTEXT_TYPE.METHOD;
                        var _isText = __tomeIsContextTextOnly(_subContext);
                        
                        if (_subContext._contextType != __TOME_CONTEXT_TYPE.METHOD && __tomeIsContextFunction(_subContext)){
                            var _contextTypeString = _subContext._contextType == __TOME_CONTEXT_TYPE.CONSTRUCTOR ? "@constructor" : "@func/@function";
                            __tomePushWarning($"You appear to have a nested {_contextTypeString} inside of a @constructor tag. This can happen if there is no clear ending to a previous context. To fix this issue, place an @end tag at the end of your {_context._signature} constructor code. This will explicitly end the context.");
                        }
                        
                        if (_isMethod || _isText){
                            
                            var _groupName = _isMethod ? $"{_subContext._groupTag}" : "ungrouped";
                            
                            if (_groupName == ""){
                                _groupName = "ungrouped";
                            }
                            
                            if (!array_contains(_groups.names, _groupName)){
                                variable_struct_set(_groups, $"group_{_groupName}", _contextGroupHead);
                                variable_struct_set(_groups, $"group_{_groupName}Tail", _subContext);
                                if (_groupName != "ungrouped"){
                                    array_push(_groups.names, _groupName);
                                }else{
                                    _groups.names[0] = "ungrouped";
                                }
                            }else{
                                var _contextTail = variable_struct_get(_groups, $"group_{_groupName}Tail");
                                _contextTail._nextContext = _contextGroupHead;
                                variable_struct_set(_groups, $"group_{_groupName}Tail", _subContext);
                            }
                            
                            _contextGroupHead = _subContext._nextContext;
                            _subContext._nextContext = undefined;
                            _subContext = _contextGroupHead;
                        }else{
                            _subContext = _subContext._nextContext;
                        }
                    }
                    
                    var _sortedMethods = _groups.group_ungrouped;
                    /// @type  {Struct | Undefined} 
                    var _tail = _groups.group_ungroupedTail;
                    
                    var _i = 1;
                    
                    repeat(array_length(_groups.names) - 1){
                        var _groupName = _groups.names[_i];
                        var _headerDepth = TOME_METHOD_GROUP_DEPTH == TOME_METHOD_GROUP_DEPTH_HEADER.H2 ? "##" : "###";
                        var _groupHeader = __TOME_NEW_CONTEXT;
                            
                        _groupHeader._edited = true;
                        _groupHeader._markdown = $"<div class=\"group-header\">\n\n{_headerDepth} {_groupName}\n\n</div>";

                        _groupName = $"group_{_groups.names[_i]}";

                        _groupHeader._nextContext = variable_struct_get(_groups, $"{_groupName}");
                            
                        if (is_undefined(_sortedMethods)){
                            _sortedMethods = _groupHeader;
                        }else{
                            _tail._nextContext = _groupHeader;
                        }
                            
                        _tail = variable_struct_get(_groups, $"{_groupName}Tail");
                        _i++; 
                    }
                    
                    if (is_undefined(_tail)){
                        _sortedMethods = _contextGroupHead;
                    }else{
                        _tail._nextContext = _contextGroupHead;
                    }
                    
                    _context._methods = _sortedMethods;
                }
            }
            
            _context = _context._nextContext;
        }
    }

    return _markdownData;
    
}
#endregion // __tomeParseDocumentationFile

#region /// @func __tomeParseSlugFile(filepath)
/// @desc Parses a slug file and adds the slugs to the Tome.__data.slugs array.
/// @param {string} _filePath The path to the file
/// @returns {boolean} If the file was successfully parsed or not.
function __tomeParseSlugFile(_filePath){
	var _file = file_text_open_read(_filePath);
	var _inSlug = false;
	var _markdown = "";
	var _slugName = "";
    
    var _success = true;
    
	if (_file == __TOME_FILE_OPEN_FAILED){
        _success = false;
        __tomePushWarning("Failed to open file. Please check the permissions.", true);
	}else{
		while (!file_text_eof(_file)){
			var _lineStringUntrimmed = file_text_readln(_file);
		
			if (string_starts_with(string_trim_start(_lineStringUntrimmed), "///")){
				var _lineString = string_replace(_lineStringUntrimmed, "///", "");
				_lineString = string_trim(_lineString);
			
				if (string_starts_with(_lineString, "@")){
					var _splitString = string_split_ext(_lineString, [" ", "\t"], true);
					var _tagType = _splitString[0];
					var _tagContent = string_trim(string_replace(_lineString, _tagType, ""));
			
					switch(_tagType){
						case "@slug":
						case "@insert":
							if (_inSlug){
								if (_markdown != ""){
									array_push(Tome.__data.slugs, [_slugName, _markdown]);	
								}
							}
						
							_inSlug = true;
						
							_slugName = _tagContent;
							_markdown = "";
						
						
							var _slugIndex = 0;
							repeat(array_length(Tome.__data.slugs)){
								if (_slugName == Tome.__data.slugs[_slugIndex][0]){
									_inSlug = false;
									break;
								}
								_slugIndex++;
							}
						    break;
                        
                        case "@pass":
                            _markdown += $"{_tagContent}";
                            break;
					
						default:
							_markdown += $"{_lineStringUntrimmed}";
						    break;
					}
				}else{
					_markdown += $"{_lineStringUntrimmed}";	
				}
			}else{
				_markdown += $"{_lineStringUntrimmed}";
			}
		}
		
		if (_inSlug){
			if (_markdown != ""){
				array_push(Tome.__data.slugs, [_slugName, _markdown]);	
			}
		}
        
        file_text_close(_file);
	}
    
    return _success;
}
#endregion // __tomeParseSlugFile

#region /// @func __tomeGenerateFile(markdownData)
/// @desc Takes provided context markdown data struct and converts it into a markdown string that is then saved out to a file.
/// @param {struct} markdownData The markdown data struct that contains relevant context information.
/// @returns {boolean} True if the markdown data was successfully converted to text and created a file. False otherwise
function __tomeGenerateFile(_markdownData){
    
    var _context = _markdownData._context;

    var _markdownString = "";
    
    if (_markdownData._title != "homepage"){
        _markdownString += $"# {_markdownData._title}\n";
    }

    while(!is_undefined(_context)){
        var _nextContext = undefined;
        
        if (_context._edited){
            switch (_context._contextType){

                case __TOME_CONTEXT_TYPE.TEXT:
                    _markdownString += $"\n{_context._markdown}\n";
                    break;

                case __TOME_CONTEXT_TYPE.CODE:
                    _markdownString += $"\n```gml\n{_context._markdown}\n```\n";
                    break;

                case __TOME_CONTEXT_TYPE.CONSTRUCTOR:
                    if (_context._deprecated){
                        _markdownString += $"\n!> **This constructor is deprecated**: {_context._deprecatedCallout}\n";
                    }

                    _markdownString += $"\n## `{_context._signature}` (constructor)\n";
                    _markdownString += "\n<div class=\"tome-function\">\n";
                    _markdownString += $"\n{_context._description}\n";

                    if (array_length(_context._parameters) > 0){
                        var _markdownTable = "| Parameter | Datatype | Purpose |\n|-----------|-----------|---------|\n";

                        var _i = 0;
                        repeat (array_length(_context._parameters)){
                            var _parameter = _context._parameters[_i];
                            
                            var _name = _parameter.optional ? $"[{_parameter.name}]" : _parameter.name;
                            
                            var _parameterType = _parameter.type;
                            
                    
                            if (!TOME_DISPLAY_TYPE_IN_BRACKETS){
                                _parameterType = string_replace_all(_parameterType, "{", "");
                                _parameterType = string_replace_all(_parameterType, "}", "");
                            }
                            
                            _parameterType = __tomeParseDataType(_parameterType);
                            
                            _markdownTable += $"| {_name} | {_parameterType} | {_parameter.description} |\n";

                            _i++;
                        }

                        _markdownString += $"\n{_markdownTable}\n";
                    }

                    if (_context._footer != ""){
                        _markdownString += $"\n{_context._footer}\n";
                    }
                    
                    if (is_undefined(_context._methods)){
                        _markdownString += "\n</div>\n";
                    }else{
                        _markdownString += "\n<div class=\"tome-methods-header\">\n\n**Methods**\n\n</div>\n";
                    }
                    

                    _nextContext = _context._methods;
                    break;

                case __TOME_CONTEXT_TYPE.FUNCTION:
                case __TOME_CONTEXT_TYPE.METHOD:
                    var _type = _context._contextType == __TOME_CONTEXT_TYPE.FUNCTION ? "function" : "method";
                    if (_context._deprecated){
                        _markdownString += $"\n!> **This {_type} is deprecated**: {_context._deprecatedCallout}\n";
                    }

                    _type = _type == "function" ? "##" : "###";
                    
                    var _returnType = _context._return;
                    
                    if (!TOME_DISPLAY_TYPE_IN_BRACKETS){
                        _returnType = string_replace_all(_returnType, "{", "");
                        _returnType = string_replace_all(_returnType, "}", "");
                    }
                    
                    _returnType = __tomeParseDataType(_returnType);
                    
                    _markdownString += $"\n{_type} `{_context._signature}` → **{_returnType}**\n";
                    _markdownString += "\n<div class=\"tome-function\">\n";
                    _markdownString += $"\n{_context._description}\n";

                    if (array_length(_context._parameters) > 0){
                        var _markdownTable = "| Parameter | Datatype | Purpose |\n|-----------|-----------|---------|\n";

                        var _i = 0;
                        repeat (array_length(_context._parameters)){
                            var _parameter = _context._parameters[_i];
                            
                            var _name = _parameter.optional ? $"[{_parameter.name}]" : _parameter.name;
                            
                            var _parameterType = _parameter.type;
                            
                    
                            if (!TOME_DISPLAY_TYPE_IN_BRACKETS){
                                _parameterType = string_replace_all(_parameterType, "{", "");
                                _parameterType = string_replace_all(_parameterType, "}", "");
                            }
                            
                            _parameterType = __tomeParseDataType(_parameterType);
                            
                            _markdownTable += $"| {_name} | {_parameterType} | {_parameter.description} |\n";

                            _i++;
                        }

                        _markdownString += $"\n{_markdownTable}\n";
                    }
                    
                    if (_context._footer != ""){
                        _markdownString += $"\n{_context._footer}\n";
                    }

                    if (_context._return != "{undefined}"){
                        _markdownString += $"\nReturns: {_context._returnDescription}\n";
                    }
                    
                    _markdownString += "\n</div>\n";
                    
                    break;
            }
        }

        if (is_undefined(_nextContext)){
            _nextContext = _context._nextContext;
        
            // Check if this new context is undefined and if the old context has a parent context defined.
            if (is_undefined(_nextContext) && !is_undefined(_context._parentContext)){
                // We know that we only have a parent context if we are in the method stack of a constructor. So we move onto our parents next context.
                _nextContext = _context._parentContext._nextContext;
                _markdownString += "\n</div>\n";
            }
        }
        
        _context = _nextContext;

    }

    return (_markdownString);

}
#endregion // __tomeGenerateFile

#region Helper functions

#region Parser Helper Functions

#region /// @func __tomeGetParametersFromSignature(signature)
function __tomeGetParametersFromSignature(_signature){
    
    var _splitContent = string_split(_signature, "(", true, 1);
    var _parameters = [];
    if (array_length(_splitContent) > 1){
    
       var _rawParameters = _splitContent[1];
       
       _rawParameters = string_replace_all(_rawParameters, "(", "");
       _rawParameters = string_replace_all(_rawParameters, ")", "");
       _rawParameters = string_replace_all(_rawParameters, ";", "");
       _rawParameters = string_replace_all(_rawParameters, " ", "");
       _rawParameters = string_replace_all(_rawParameters, "\t", "");
       
       _parameters = string_split(_rawParameters, ",", true);
       
       var _i = 0;
       repeat(array_length(_parameters)){
           var _name = _parameters[_i];
           _name = string_split(_name, "=", true, 1)[0];
           _name = string_trim(_name);
           _name = string_replace(_name, "[", "");
           _name = string_replace(_name, "]", "");
           
           var _optional = _name != string_trim(_parameters[_i]);
           _parameters[_i] = {
               name: _name,
               type: "",
               description: "",
               optional: _optional
           };
           
           _i++;
        }   

    }
    
    return _parameters;
}
#endregion // __tomeGetParametersFromSignature

#region /// @func __tomeIsContextFunction(_context)
function __tomeIsContextFunction(_context){
    return(_context._contextType == __TOME_CONTEXT_TYPE.CONSTRUCTOR ||
        _context._contextType == __TOME_CONTEXT_TYPE.METHOD ||
        _context._contextType == __TOME_CONTEXT_TYPE.FUNCTION
    );
}
#endregion // __tomeIsContextFunction  

#region /// @func __tomeIsContextTextOnly(_context)
function __tomeIsContextTextOnly(_context){
    return(
        _context._contextType == __TOME_CONTEXT_TYPE.TEXT ||
        _context._contextType == __TOME_CONTEXT_TYPE.CODE
    );
}
#endregion // __tomeIsContextTextOnly

#region /// @func __tomeNewContext(_context, _copyParent)
function __tomeNewContext(_context, _copyParent = true){
    _context._nextContext = __TOME_NEW_CONTEXT;
    _context._nextContext._parentContext = _copyParent ? _context._parentContext : undefined;
    
    return _context._nextContext;
}
#endregion // __tomeNewContext

#region /// @func __tomeAddTextAnyways(_context, text)
function __tomeAddTextAnyways(_context, text){
    if (!__tomeIsContextTextOnly(_context)){
        _context = __tomeNewContext(_context);
    }
    
    if (!_context._edited){
        _context._edited = true;
        _context._markdown = "";
    }
    
    _context._markdown += text;
    
    return _context;
}
#endregion // __tomeAddTextAnyways

#endregion // Parser Helper Functions

#region Markdown Generation Helper Functions

#region /// @func __tomeParseDataType(dataTypeString)
/// @desc Replaces instances of "|" with "*or*"
function __tomeParseDataType(_dataTypeString){
	return string_replace_all(_dataTypeString, "|", "<span class=\"tome-type-separator\"> *or* </span>");
}
#endregion // __tomeParseDataType

#endregion // Markdown Generation Helper Functions

#endregion // Helper functions

#endregion // Context Parsing and Markdown Generation

#region CSS Functions

#region /// @func __tomeCSSToStruct(cssString)
/// @desc Parses the contents of a CSS file as a string into a struct.
/// @param {string} _cssString The CSS file contents as a string.
function __tomeCSSToStruct(_cssString){

    if (is_undefined(_cssString)){
        // An undefined value was passed to be turned into a struct. This would only happen when using __tomeCSSToStruct(__tomeFileTextReadAll()) with a non-existent file. This is only ever called in one place that this would potentially be an issue but it's already received a warning message in the stack so we just exit.
        // If a user managed to get here, they'd also have user facing warnings telling them what happened.
        return {};
    }

    var _rootStruct = { __order: [] };
    var _contextStack = [_rootStruct];
    var _token = "";
    
    var _inString = false;
    var _openChar = "";
    var _inComment = false;
    var _depth = 0;
    
    var _length = string_length(_cssString);
    var _i = 1;
    
    while (_i <= _length){
        var _currentChar = string_char_at(_cssString, _i);
        var _nextChar = (_i < _length) ? string_char_at(_cssString, _i + 1) : "";
        
        if (!_inString){
            if (!_inComment && _currentChar == "/" && _nextChar == "*"){
                _inComment = true;
                _i += 2;
                continue;
            }
            if (_inComment && _currentChar == "*" && _nextChar == "/"){
                _inComment = false;
                _i += 2;
                continue;
            }
        }
        if (_inComment){
            _i++;
            continue;
        }
        

        if (!_inComment){
            if (!_inString && (_currentChar == "\"" || _currentChar == "'")){
                var _backslashCount = 0;
                var _checkPos = _i - 1;

                while (_checkPos > 0 && string_char_at(_cssString, _checkPos) == "\\") {
                    _backslashCount++;
                    _checkPos--;
                }
                
                if ((_backslashCount mod 2) == 0){
                    _inString = true;
                    _openChar = _currentChar;
                }

                _token += _currentChar;
                _i++;
                continue;
            }else if (_inString && _currentChar == _openChar){
                
                var _backslashCount = 0;
                var _checkPos = _i - 1;

                while (_checkPos > 0 && string_char_at(_cssString, _checkPos) == "\\") {
                    _backslashCount++;
                    _checkPos--;
                }
                
                if ((_backslashCount mod 2) == 0){
                    _inString = false;
                }

                _token += _currentChar;
                _i++;
                continue;
            }
        }
        
        if (_inString){
            _token += _currentChar;
            _i++;
            continue;
        }

        if (_currentChar == "("){
            _depth++;
            _token += _currentChar;
            _i++;
            continue;
        }else if (_currentChar == ")"){
            _depth = max(0, _depth - 1);
            _token += _currentChar;
            _i++;
            continue;
        }
        
        if (_depth > 0){
            _token += _currentChar;
            _i++;
            continue;
        }

        if (_currentChar == "{"){
            
            var _selector = string_trim(_token);
            if (_selector != ""){
                var _currentContext = _contextStack[array_length(_contextStack) - 1];
                
                if (!variable_struct_exists(_currentContext, _selector)){
                    _currentContext[$ _selector] = { __order: [] };
                    array_push(_currentContext.__order, _selector);
                }
                array_push(_contextStack, _currentContext[$ _selector]);
            }
            _token = "";
            
        }else if (_currentChar == "}"){

            var _trailingProperty = string_trim(_token);
            if (_trailingProperty != ""){
                var _colonPosition = string_pos(":", _trailingProperty);
                if (_colonPosition > 0){
                    var _property = string_trim(string_copy(_trailingProperty, 1, _colonPosition - 1));
                    var _value = string_trim(string_delete(_trailingProperty, 1, _colonPosition));
                    var _currentContext = _contextStack[array_length(_contextStack) - 1];
                    
                    if (!variable_struct_exists(_currentContext, _property)){
                        array_push(_currentContext.__order, _property);
                    }
                    
                    _currentContext[$ _property] = _value;
                }
            }
            
            // Pop the stack to return to the parent scope
            if (array_length(_contextStack) > 1){
                array_pop(_contextStack);
            }
            _token = "";
            
        }else if (_currentChar == ";"){
            // The token holds a full property-value pair
            var _propertyDefinition = string_trim(_token);
            if (_propertyDefinition != ""){
                // Split at the first colon to protect colons in the value (like URLs)
                var _colonPosition = string_pos(":", _propertyDefinition);
                if (_colonPosition > 0){
                    var _property = string_trim(string_copy(_propertyDefinition, 1, _colonPosition - 1));
                    var _value = string_trim(string_delete(_propertyDefinition, 1, _colonPosition));
                    var _currentContext = _contextStack[array_length(_contextStack) - 1];
                    
                    if (!variable_struct_exists(_currentContext, _property)){
                        array_push(_currentContext.__order, _property);
                    }
                    
                    _currentContext[$ _property] = _value;
                }
            }
            _token = "";
            
        }else{
            // Ignore newlines/tabs outside of strings, converting them to single spaces to keep the buffer clean
            if (_currentChar != "\n" && _currentChar != "\r" && _currentChar != "\t"){
                _token += _currentChar;
            }else if (_token != "" && string_char_at(_token, string_length(_token)) != " "){
                 _token += " "; 
            }
        }
        
        _i++;
    }
    
    return _rootStruct;
}
#endregion // __tomeCSSToStruct

#region /// @func __tomeStructToCSS(cssStruct, [indentation])
/// @desc Converts a GameMaker struct into a formatted, nested CSS string, preserving order.
function __tomeStructToCSS(_cssStruct, _indent = ""){
    var _orderedKeys = [];
    
    if (variable_struct_exists(_cssStruct, "__order")){
        array_copy(_orderedKeys, 0, _cssStruct.__order, 0, array_length(_cssStruct.__order));
    }
    
    var _allKeys = variable_struct_get_names(_cssStruct);
    var _i = 0;
    repeat(array_length(_allKeys)){
        var _k = _allKeys[_i];
        if (_k != "__order" && !array_contains(_orderedKeys, _k)){
            array_push(_orderedKeys, _k); 
        }
        _i++;
    }
    
    var _propertyString = "";
    var _nestedString = "";
    
    _i = 0;
    repeat(array_length(_orderedKeys)){
        var _key = _orderedKeys[_i];
        var _value = _cssStruct[$ _key];
        
        if (is_struct(_value)){
            _nestedString += $"{_indent}{_key}{"{"}\n";
            _nestedString += __tomeStructToCSS(_value, _indent + "\t");
            _nestedString += $"{_indent}{"}"}\n\n";
        }else{
            _propertyString += $"{_indent}{_key}: {_value};\n";
        }
        
        _i++;
    }
    
    var _cssString = _propertyString;
    
    if (_propertyString != "" && _nestedString != ""){
        _cssString += "\n";
    }
    
    _cssString += _nestedString;

    return _indent == "" ? string_trim_end(_cssString) : _cssString;
}
#endregion // __tomeStructToCSS

#region /// @func __tomeMergeCSSStructs(targetStruct, sourceStruct)
/// @desc Recursively merges a source CSS struct into a target CSS struct, maintaining cascade order.

function __tomeMergeCSSStructs(_source, _target = Tome.__data.customCSS ){
    var _sourceKeys = [];
    
    if (variable_struct_exists(_source, "__order")){
        array_copy(_sourceKeys, 0, _source.__order, 0, array_length(_source.__order));
    }
    
    var _allSourceKeys = variable_struct_get_names(_source);
    var _i = 0;
    repeat(array_length(_allSourceKeys)){
        var _k = _allSourceKeys[_i];
        if (_k != "__order" && !array_contains(_sourceKeys, _k)){
            array_push(_sourceKeys, _k);
        }
        _i++;
    }

    if (!variable_struct_exists(_target, "__order")){
        _target.__order = [];
    }

    _i = 0;
    repeat(array_length(_sourceKeys)){
        var _key = _sourceKeys[_i];
        var _sourceVal = _source[$ _key];
        
        if (is_struct(_sourceVal)){
            if (!variable_struct_exists(_target, _key) || !is_struct(_target[$ _key])){
                _target[$ _key] = { __order: [] };
                
                if (!array_contains(_target.__order, _key)){
                    array_push(_target.__order, _key);
                }
            }
            __tomeMergeCSSStructs(_sourceVal, _target[$ _key]);
            
        }else{
            _target[$ _key] = _sourceVal;
            
            if (!array_contains(_target.__order, _key)){
                array_push(_target.__order, _key);
            }
        }
        
        _i++;
    }
}
#endregion // __tomeMergeCSSStructs

#endregion // CSS Functions

#region Config Functions

#region /// @func __tomeParseConfig(filePath)
/// @desc Reads the config.js file and parses it into a GameMaker struct.
/// @param {string} _filePath The full path to the config.js file.
/// @returns {struct} The parsed configuration struct.
function __tomeParseConfig(_filePath){
    var _configString = __tomeFileTextReadAll(_filePath);
    var _configStruct = {};
    
    if (_configString != undefined){
        _configString = string_replace(_configString, "const config = ", "");
        _configString = string_replace_all(_configString, ";", "");
        _configStruct = json_parse(_configString);
    }
    return _configStruct;
}
#endregion // __tomeParseConfig

#region /// @func __tomeUpdateConfigProperty(propertyName, propertyValue)
/// @desc Updates a property in the in-memory config struct.
/// @param {string} _propertyName The name of the property to update
/// @param {any} _propertyValue The value to set the property to
function __tomeUpdateConfigProperty(_propertyName, _propertyValue){
    Tome.__data.config[$ _propertyName] = _propertyValue;
}
#endregion // __tomeUpdateConfigProperty

#region /// @func __tomeGenerateConfigString()
/// @desc Converts the in-memory config struct back into a formatted config.js string.
function __tomeGenerateConfigString(){
    var _json = json_stringify(Tome.__data.config);
    var _formatted = "";
    
    var _arrayDepth = 0;
    var _inString = false;
    var _len = string_length(_json);
    
    for (var _i = 1; _i <= _len; _i++){
        var _currentChar = string_char_at(_json, _i);
        
        if (_currentChar == "\""){
            var _backslashCount = 0;
            var _checkPos = _i - 1;

            while (_checkPos > 0 && string_char_at(_json, _checkPos) == "\\") {
                _backslashCount++;
                _checkPos--;
            }
            
            if ((_backslashCount mod 2) == 0){
                _inString = !_inString;
            }
        }
        
        if (!_inString){
            if (_currentChar == "["){
                _arrayDepth++;
            }else if (_currentChar == "]"){
                _arrayDepth = max(0, _arrayDepth - 1);
            }
            if (_currentChar == "{"){
                _formatted += "{\n\t";
            }else if (_currentChar == "}"){
                _formatted += "\n}";
            }else if (_currentChar == ","){
                _formatted += _arrayDepth > 0 ? ", " : ",\n\t";
            }else if (_currentChar == ":"){
                _formatted += ": ";
            }else{
                _formatted += _currentChar;
            }
        }else{
            _formatted += _currentChar;
        }
    }
    


    // GameMaker escapes forward slashes in URLs, so we revert them
    _formatted = string_replace_all(_formatted, "\\/", "/");
    
    return $"const config = {_formatted};";
}
#endregion // __tomeGenerateConfigString

#endregion // Config functions

#region Site Structure Functions

#region /// @func __tomeProcessDocsItems()
/// @desc Processes the docs page items, generates documentation files, and unifies items for sidebar creation.
function __tomeProcessDocsItems(){
    
    array_reverse_ext(Tome.__data.docsPageItems);
    
    /// @type {any}
    var _item = array_pop(Tome.__data.docsPageItems);
    var _finalDocPath = __tomeFileGetFinalDocPath();
    var _illegalFilePathChars = [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"];
    while (_item != undefined){
        
        if (_item._sidebarType == __TOME_SIDEBAR_TYPE.FILE){

            var _fileCategoryDashed = string_lower(__tomeStringReplaceAllExt(_item._category, _illegalFilePathChars, "-"));
            var _fileTitleDashed = string_lower(__tomeStringReplaceAllExt(_item._title, _illegalFilePathChars, "-"));
            
            var _filePath = $"{_fileCategoryDashed}-{_fileTitleDashed}";

            if (_filePath == "homepage-homepage"){
                _filePath = "README";
            }

            _item._link = _filePath;

            _filePath = $"{_finalDocPath}{_filePath}.md";

            __tomeUpdateFile(_filePath, __tomeGenerateFile(_item));
        }

        if (_item._category != "homepage"){
            if (!array_contains(Tome.__data.categories.names, _item._category)){
                array_push(Tome.__data.categories.names, _item._category);
                variable_struct_set(Tome.__data.categories.map, $"{_item._category}", [_item]);
            }else{
                array_push(variable_struct_get(Tome.__data.categories.map, $"{_item._category}"), _item);
            }
        }
        
        _item = array_pop(Tome.__data.docsPageItems);
        
    }
    
}
#endregion // __tomeProcessDocsItems

#region /// @func __tomeUpdateDocsifyFiles()
/// @desc Updates basic docsify files: config.js, index.html, codeTheme.css, customTheme.css, docsIcon.png, and .nojekyll
function __tomeUpdateDocsifyFiles(){

    var _repoFilePath = Tome.__data.repoFilePath;
    
    __tomeUpdateFile($"{_repoFilePath}config.js", __tomeGenerateConfigString());
    
    __tomeUpdateFile($"{_repoFilePath}index.html", __tomeFileTextReadAll(Tome.__data.projectDirectory +  "datafiles/Tome/index.html"));

    __tomeUpdateFile($"{_repoFilePath}assets/codeTheme.css", __tomeFileTextReadAll(Tome.__data.projectDirectory +  "datafiles/Tome/assets/codeTheme.css"));

    __tomeUpdateFile($"{_repoFilePath}assets/customTheme.css", __tomeStructToCSS(Tome.__data.customCSS));
    
    __tomeUpdateFile($"{_repoFilePath}assets/docsIcon.png", __tomeFileBinReadAll(Tome.__data.projectDirectory + "datafiles/Tome/assets/docsIcon.png"));
    
    __tomeUpdateFile($"{_repoFilePath}.nojekyll", "");
}
#endregion // __tomeUpdateDocsifyFiles

#region /// @func __tomeGenerateSidebar()
/// @desc Generates the sidebar for the doc site
function __tomeGenerateSidebar(){
    var _sideBarMarkdownString = "";
    _sideBarMarkdownString += "-    [Home](README)\n\n---\n\n";
    
    var _categoriesNames = Tome.__data.categories.names;
    var _i = 0;
    
    repeat(array_length(_categoriesNames)){
        var _currentCategory = _categoriesNames[_i];
        
        _sideBarMarkdownString += $"**{_currentCategory}**\n\n";			
        
        var _currentCategoryArray = Tome.__data.categories.map[$ _currentCategory];
        var _j = 0;
        
        repeat(array_length(_currentCategoryArray)){

            var _item = _currentCategoryArray[_j];

            if (_item._link != ""){
                _sideBarMarkdownString += $"-    [{_item._title}]({_item._link})\n";
            }

            _j++;
        }
        _sideBarMarkdownString += "\n---\n\n";
        _i++;
    }   
    
    __tomeUpdateFile($"{__tomeFileGetFinalDocPath()}_sidebar.md", _sideBarMarkdownString); 
}
#endregion // __tomeGenerateSidebar

#region /// @func __tomeGenerateNavbar()
/// @desc Generates the navbar for the doc site
function __tomeGenerateNavbar(){
    var _navbarMarkdownString = "";

    var _i = 0;

    repeat(array_length(Tome.__data.navbarItems)){
        var _currentNavbarItem = Tome.__data.navbarItems[_i];
        _navbarMarkdownString += string("-    [{0}]({1})\n", _currentNavbarItem._title, _currentNavbarItem._link);
        _i++;
    }
        
    __tomeUpdateFile($"{__tomeFileGetFinalDocPath()}_navbar.md", _navbarMarkdownString);
}
#endregion // __tomeGenerateNavbar

#endregion // Site Structure Functions

#region Utility functions

#region /// @func __tomePushWarning(warningText, triggerFail)
/// @desc Pushes a warning to the Tome.__data.warnings array and optionally triggers a doc generation failure.
/// @param {string} warningText The text of the warning to push
/// @param {boolean} triggerFail [Default: false] Whether to set the doc generation as failed or not. This is useful for warnings that should be brought to the user's attention but don't necessarily need to cause a full failure on their own.
function __tomePushWarning(_warningText, _triggerFail = false){

    if (!Tome.__debug.hasBeenUsed){
        Tome.__debug.hasBeenUsed = true;
        array_push(Tome.__data.warnings, "");
        array_push(Tome.__data.warnings, $"tomeSetup [line {Tome.__debug.mostRecentCallLine}]: {Tome.__debug.mostRecentCall}");
        array_push(Tome.__data.warnings, "|");
    }

    array_push(Tome.__data.warnings, $"| - {_warningText}");
    
    if (_triggerFail){
        Tome.__data.docGenerationFailed = true;
    }
}
#endregion // __tomePushWarning

#region /// @func __tomeInitialized()
/// @desc Checks if the Tome struct has been initialized yet. Useful for ensuring that API functions are not called before they are ready.
function __tomeInitialized(){
    var _initialized = Tome != undefined && Tome.__initialized;
    return _initialized;
}
#endregion // __tomeInitialized

#region /// @func __tomeTrace(text, [verboseOnly], [indentation], [includePrefix])
/// @desc Outputs a message to the console prefixed with "Tome:"
/// @param {string} text The message to display in the console
/// @param {boolean} [verboseOnly] [Default: false] Whether the message should only be displayed if `TOME_VERBOSE` is enabled or not
/// @param {real} [indentation] [Default: 0] What level of indentation the string content should exist at.
/// @param {boolean} [includePrefix] [Default: true] Whether "Tome: " will be prepended to the output string or not.
function __tomeTrace(_text, _verboseOnly = false, _indentation = 0, _includePrefix = true){
    var _indentationString = "";
    var _tomePrefix = _includePrefix ? "Tome: " : "";
    
    repeat(_indentation){
        _indentationString += "\t";
    }
    
    var _finalMessageString = _indentationString + $"{_tomePrefix}{_text}";
    
	if ((_verboseOnly && TOME_VERBOSE) || !_verboseOnly){
		show_debug_message(_finalMessageString);	
	}
}
#endregion // __tomeTrace

#region /// @func __tomeStringReplaceAllExt(string, subStrArray, newStr)
/// @desc Replaces all instances of multiple substrings within a string with a new string.
/// @param {string} string The original string to perform replacements on
/// @param {array} subStrArray An array of substrings to replace within the original string
/// @param {string} newStr The string to replace the substrings with
function __tomeStringReplaceAllExt(_string, _subStrArray, _newStr){
    var _str = _string;
    var _i = 0;

    repeat(array_length(_subStrArray)){
        _str = string_replace_all(_str, _subStrArray[_i], _newStr);
        _i++;
    }

    return _str;
}
#endregion // __tomeStringReplaceAllExt

function __tomeSetupDebug(){
    var _setupFilePath = $"{Tome.__data.projectDirectory}scripts/{TOME_SETUP_SCRIPT_FILE}/{TOME_SETUP_SCRIPT_FILE}.gml";

    if (file_exists(_setupFilePath)){
        var _setupFile = file_text_open_read(_setupFilePath);

        var _fileArray = [ $"{TOME_SETUP_SCRIPT_FILE}" ];

        if (_setupFile != __TOME_FILE_OPEN_FAILED){

            while (!file_text_eof(_setupFile)){
                array_push(_fileArray, string_trim(file_text_readln(_setupFile)));
            }

            file_text_close(_setupFile);

            Tome.__debug.setupFileLines = _fileArray;
        }else{ 
            __tomeTrace("Failed to open tomeSetup.gml for debug setup. Debug info will be limited. Check file permissions. If your tomeSetup function is in a different script, change the TOME_SETUP_SCRIPT_FILE constant to match the correct file name.", false, 2, false);
            Tome.__debug.setupFileLines = [];
        }
    }
}

#region /// @func __tomeUpdateDebug([tomeInternal])
/// @desc Updates the most recent call variable to be used when showing a warning to the user. This is used to direct users to the exact line function call that triggered the warning.
/// @param {boolean} tomeInternal [Default = false] Whether to bypass callstack parsing (true) or include the tomeSetup line (false)
function __tomeUpdateDebug(_tomeInternal = false){
    if (_tomeInternal){
        Tome.__debug.hasBeenUsed = true;
    }else{
        
        var _callstack = debug_get_callstack();
        
        var _debugLine = -1;
    
        var _i = 1;
        
        var _repeatCount = array_length(_callstack) - 1;
        
        repeat (_repeatCount){
            var _scriptComponents = string_split(_callstack[_i], ":", true);
    
            var _componentsLength = array_length(_scriptComponents);
            
            if (_componentsLength >= 2){
                if (string_ends_with(_scriptComponents[_componentsLength - 2], "tomeSetup")){ // Subtract 2 because the last index should be the line number, the index prior should be the script name
                    _debugLine = real(_scriptComponents[_componentsLength - 1]); // This is the line number.
                    break;
                }
            }
    
            _i++;
        }
        
    
        if (_debugLine != -1){
            Tome.__debug.mostRecentCallLine = _debugLine;
            Tome.__debug.hasBeenUsed = false;
            
            if (_debugLine < array_length(Tome.__debug.setupFileLines)){
                Tome.__debug.mostRecentCall = Tome.__debug.setupFileLines[_debugLine];
            }else{
                Tome.__debug.mostRecentCall = "";
            }
        }
    }
}
#endregion // __tomeUpdateDebug

#region /// @func __tomeClearDocsPath()
/// @desc Clears out old generated files from the final docs directory to ensure that deleted pages are not left behind in the generated docs.
function __tomeClearDocsPath(){
    var _finalDocPath = __tomeFileGetFinalDocPath();
    if (directory_exists(_finalDocPath)){
        
        __tomeTrace($"Subdirectory \"{Tome.__data.config[$ "latestVersion"]}\" exists. Removing the directory and starting fresh.", true, 2, false);

        directory_destroy(_finalDocPath);
    }

    directory_create(_finalDocPath);

}
#endregion // __tomeClearDocsPath

#endregion // Utility functions

#region Initialization
if (__TOME_CAN_RUN){
    
    if (GM_is_sandboxed){
        __tomeTrace("Tome is set to run, but GameMaker's file system sandbox is enabled. Tome will not function with this enabled. To disable, go to Game Options -> Platform (Windows, macOS, Ubuntu) -> Check the \"Disable file system sandbox\".");
    
        if (string_ends_with(GM_project_filename, "Tome/Tome.yyp")){
            game_end();
        }
    }else{
        global.__tomeInitTimeSource = time_source_create(time_source_global, 1, time_source_units_frames, function(){
            
            __tomeTrace($"Tome Enabled, Version: {__TOME_VERSION}");

            __tomeSetupData();

            __tomeTrace("Gathering data from scripts, notes, and files...", false, 1, false);

            tomeSetup();

            __tomeTrace("Generating docs...", false, 1, false);
            
            __tomeGenerateDocs();
            
            var _warningsFound = array_length(Tome.__data.warnings) > 0;
            
            if (_warningsFound){
                __tomeTrace("Warnings:", false, 1, false);
                
                var _i = 0;
                
                repeat(array_length(Tome.__data.warnings)){
                    var _currentWarning = Tome.__data.warnings[_i];
                    
                    __tomeTrace(_currentWarning, false, 2, false);
                    
                    _i++;
                }
            }
            
            
            var _finalMessage = Tome.__data.docGenerationFailed ? "Doc generation failed: Please see warnings above!\n" : "All docs generated!\n";
            
            __tomeTrace(_finalMessage);
            
            time_source_destroy(global.__tomeInitTimeSource);

            Tome = undefined;

            if (string_ends_with(GM_project_filename, "Tome/Tome.yyp")){
                game_end();
            }

        }, [], 1);

        time_source_start(global.__tomeInitTimeSource);
    }


}
#endregion // Initialization

#region Deprecated API Functions
/// @pass false
/// @text ## Deprecated API.
///
/// Below are functions that are still available for compatibility reasons, but are no longer recommended for use. These functions may be removed in a future update, so it is recommended to switch to the new API equivalents where possible. If you have any questions about how to update your code, please refer to the documentation.

#region /// @func tome_add_script(scriptName, [slugs])
/// @deprecated Use `Tome.site.add` instead. This function is only retained for compatibility.
/// @desc Adds a script to be parsed as a page to your site
/// @param {string} scriptName The name of the script to add
/// @param {string} slugs The name of any notes (as shown in the IDE) or a direct file path to an external .txt file that will be used for adding slugs. One additional argument per slug note.
function tome_add_script(_scriptName){
    if (__tomeInitialized()){
        var slugs = [];
        
        var _i = 1;
        if (argument_count > 1){
            repeat(argument_count - 1){
                array_push(slugs, argument[_i]);
                _i++;
            }
        }
        
        if (array_length(slugs) > 0){
            Tome.site.add(_scriptName, slugs);
        }else{
            Tome.site.add(_scriptName);
        } 
    }else{
        __tomeTrace("tome_add_script: Cannot add script before Tome has been initialized. Review the documentation and ensure you are calling this function within the tomeSetup function.");
    }
}
#endregion // tome_add_script

#region /// @func tome_add_note(noteName, [slugs])
/// @deprecated Use `Tome.site.add` instead. This function is only retained for compatibility.
/// @desc Adds a note to be parsed as a page to your site 
/// @param {string} noteName The note to add
/// @param {string} slugs The name of any notes (as shown in the IDE) or a direct file path to an external .txt file that will be used for adding slugs. One additional argument per slug note.
function tome_add_note(_noteName){
    if (__tomeInitialized()){
        var slugs = [];
        
        var _i = 1;
        if (argument_count > 1){
            repeat(argument_count - 1){
                array_push(slugs, argument[_i]);
                _i++;
            }
        }
        
        if (array_length(slugs) > 0){
            Tome.site.add(_noteName, slugs);
        }else{
            Tome.site.add(_noteName);
        } 
    }else{
        __tomeTrace("tome_add_note: Cannot add note before Tome has been initialized. Review the documentation and ensure you are calling this function within the tomeSetup function.");
    }

}
#endregion // tome_add_note

#region /// @func tome_add_file(filePath)
/// @deprecated Use `Tome.site.add` instead. This function is only retained for compatibility.
/// @desc Adds an external file to be parsed when the docs are generated
/// @param {string} filePath The file to add
/// @param {string} slugs The name of any notes (as shown in the IDE) or a direct file path to an external .txt file that will be used for adding slugs. One additional argument per slug note.
function tome_add_file(_filePath){
    if (__tomeInitialized()){
        var slugs = [];
        
        var _i = 1;
        if (argument_count > 1){
            repeat(argument_count - 1){
                array_push(slugs, argument[_i]);
                _i++;
            }
        }
        
        if (array_length(slugs) > 0){
            Tome.site.add(_filePath, slugs);
        }else{
            Tome.site.add(_filePath);
        }
    }else{
        __tomeTrace("tome_add_file: Cannot add file before Tome has been initialized. Review the documentation and ensure you are calling this function within the tomeSetup function.");
    }
}
#endregion // tome_add_file

#region /// @func tome_set_homepage_from_file(filePath)
/// @deprecated Use `Tome.site.setHomepage` instead. This function is only retained for compatibility.
/// @desc Sets the homepage of your site to be the contents of a file (`.txt`, or `.md`)
/// @param {string} filePath The file to use as the homepage
function tome_set_homepage_from_file(_filePath){
    if (__tomeInitialized()){
        Tome.site.setHomepage(_filePath);
    }else{
        __tomeTrace("tome_set_homepage_from_file: Cannot set homepage before Tome has been initialized. Review the documentation and ensure you are calling this function within the tomeSetup function.");
    }
}
#endregion // tome_set_homepage_from_file

#region /// @func tome_set_homepage_from_note(noteName)
/// @deprecated Use `Tome.site.setHomepage` instead. This function is only retained for compatibility.
/// @desc Sets the homepage of your site to be the contents of the given note
/// @param {string} noteName The note to use as the homepage
function tome_set_homepage_from_note(_noteName){
    if (__tomeInitialized()){
        var _filePath = $"{Tome.__data.projectDirectory}notes/{_noteName}/{_noteName}.txt";

        Tome.site.setHomepage(_filePath);
    }else{
        __tomeTrace("tome_set_homepage_from_note: Cannot set homepage before Tome has been initialized. Review the documentation and ensure you are calling this function within the tomeSetup function.");
    }
}
#endregion // tome_set_homepage_from_note

#region /// @func tome_add_to_sidebar(name, link, category)
/// @deprecated Use `Tome.site.addSidebarLink` instead. This function is only retained for compatibility.
/// @desc Adds an item to the sidebar of your site
/// @param {string} name The name of the item
/// @param {string} link The link to the item
/// @param {string} category The category of the item
function tome_add_to_sidebar(_name, _link, _category){
    if (__tomeInitialized()){
        Tome.site.addSidebarLink(_link, _name, _category);
    }else{
        __tomeTrace("tome_add_to_sidebar: Cannot add sidebar link before Tome has been initialized. Review the documentation and ensure you are calling this function within the tomeSetup function.");
    }

}
#endregion // tome_add_to_sidebar

#region /// @func tome_set_site_name(name)
/// @deprecated Use `Tome.site.setName` instead. This function is only retained for compatibility.
/// @desc Sets the name of your site
/// @param {string} name The name of the site
function tome_set_site_name(_name){
    if (__tomeInitialized()){
        Tome.site.setName(_name);
    }else{
        __tomeTrace("tome_set_site_name: Cannot set site name before Tome has been initialized. Review the documentation and ensure you are calling this function within the tomeSetup function.");
    }
}
#endregion // tome_set_site_name

#region /// @func tome_set_site_description(desc)
/// @deprecated Use `Tome.site.setDescription` instead. This function is only retained for compatibility.
/// @desc Sets the description of your site
/// @param {string} desc The description of the site
function tome_set_site_description(_desc){
	if (__tomeInitialized()){
        Tome.site.setDescription(_desc);
    }else{
        __tomeTrace("tome_set_site_description: Cannot set site description before Tome has been initialized. Review the documentation and ensure you are calling this function within the tomeSetup function.");
    }
}
#endregion // tome_set_site_description

#region /// @func tome_set_site_theme_color(color)
/// @deprecated Use `Tome.site.setThemeColor` instead. This function is only retained for compatibility.
/// @desc Sets the theme color of your site
/// @param {string} color The theme color of the site as a GameMaker Color or hex code string (e.g. "#FF0000" for red)
function tome_set_site_theme_color(_color){
	if (__tomeInitialized()){
        Tome.site.setThemeColor(_color);
    }else{
        __tomeTrace("tome_set_site_theme_color: Cannot set site theme color before Tome has been initialized. Review the documentation and ensure you are calling this function within the tomeSetup function.");
    }
}
#endregion // tome_set_site_theme_color

#region /// @func tome_set_site_latest_version(versionName)
/// @deprecated Use `Tome.site.setLatestVersion` instead. This function is only retained for compatibility.
/// @desc Sets the latest version of the docs.
/// @param {string} versionName The latest version of the docs
function tome_set_site_latest_version(_versionName){
    if (__tomeInitialized()){
        Tome.site.setLatestVersion(_versionName);
    }else{
        __tomeTrace("tome_set_site_latest_version: Cannot set site latest version before Tome has been initialized. Review the documentation and ensure you are calling this function within the tomeSetup function.");
    }
}
#endregion // tome_set_site_latest_version

#region /// @func tome_set_site_older_versions(versions)
/// @deprecated Use `Tome.site.setOlderVersions` instead. This function is only retained for compatibility.
/// @desc Specifically set what older versions of your docs you want to show on the site's version selector
/// @param {array<string>} versions An array of older versions' names to display in the version selector
function tome_set_site_older_versions(_versions){
    if (__tomeInitialized()){
        Tome.site.setOlderVersions(_versions);
    }else{
        __tomeTrace("tome_set_site_older_versions: Cannot set site older versions before Tome has been initialized. Review the documentation and ensure you are calling this function within the tomeSetup function.");
    }
}
#endregion // tome_set_site_older_versions

#region /// @func tome_add_navbar_link(name, link)
/// @deprecated Use `Tome.site.addNavbarLink` instead. This function is only retained for compatibility.
/// @desc Adds a link to the navbar
/// @param {string} name The name of the link
/// @param {string} link The link to the link
function tome_add_navbar_link(_name, _link){
    if (__tomeInitialized()){
        Tome.site.addNavbarLink(_link, _name);
    }else{
        __tomeTrace("tome_add_navbar_link: Cannot add navbar link before Tome has been initialized. Review the documentation and ensure you are calling this function within the tomeSetup function.");
    }
}
#endregion // tome_add_navbar_link

#endregion // Deprecated API Functions