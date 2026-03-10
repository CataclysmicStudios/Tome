// Non-userfacing functions/macros used to make the system work

#region Macro declaration

#macro __TOME_CAN_RUN (TOME_ENABLED && (GM_build_type == "run") && ((os_type == os_windows) || (os_type == os_macosx) || (os_type == os_linux)))

#macro __TOME_FILE_OPEN_FAILED -1

#macro __TOME_NEW_CONTEXT variable_clone({                                          \
                                _contextType: __TOME_CONTEXT_TYPE.TEXT,             \
                                _parentContext: undefined,                          \
                                _nextContext: undefined,                            \
                                _edited: false                                      \
                            })

#macro TOME_VERSION "01-29-2026" 

#endregion // Macro declaration

#region Enum declaration

enum TOME_METHOD_GROUP_DEPTH_HEADER{
    H2,
    H3
}

enum __TOME_CONTEXT_TYPE{
    TEXT,
    CODE,
    FUNCTION,
    CONSTRUCTOR,
    METHOD
}

enum __TOME_FILE_TYPE{
    GML,
    TXT
}

enum __TOME_SIDEBAR_TYPE{
    FILE,
    LINK
}

#endregion // Enum declaration

#region /// @func __tome_generate_docs()
/// @desc Generates the documentation website
/// Parses all files added via `tome_add` functions and generates your documenation site.  
/// Then it adds them to the repo path specified with the macro `TOME_REPO_PATH`
function __tome_generate_docs(){
    
    if (GM_is_sandboxed){
        array_push(global.__tomeData.warnings, "GameMaker's file system sandbox is enabled. Tome will not function with this enabled, to disable go to Game Options -> Platform (Windows, macOS, Ubuntu) -> Check the \"Disable file system sandbox\"");
        global.__tomeData.docGenerationFailed = true;
    }
    
    if (!global.__tomeData.docGenerationFailed){
        var _repoDirectoryIsValid = __verifyRepoPath();
    }
    
    if (!global.__tomeData.docGenerationFailed){
    	
    	__updateDocsifyFiles();
        
        __unifySidebarItems();
        
        __tomeTrace("Generating sidebar and navbar", true, 2, false);
    	
    	__generateSidebar();
        
        __generateNavbar();
    }

}
#endregion // __tome_generate_docs
    
#region Sub functions

/// @desc Sort through site struct if multiple entries contain the same category and title group them together.
function __unifySidebarItems(){
    
    array_reverse_ext(global.__tomeData.docsPageItems);
    
    /// @type {any}
    var _item = array_pop(global.__tomeData.docsPageItems);
    var _finalDocPath = __tome_file_get_final_doc_path();
    var _illegalFilePathChars = [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"];
    while (_item != undefined){
        
        if (_item._sidebarType == __TOME_SIDEBAR_TYPE.FILE){

            var _fileCategoryDashed = __tome_string_replace_all_ext(_item._category, _illegalFilePathChars, "-");
            var _fileTitleDashed = __tome_string_replace_all_ext(_item._title, _illegalFilePathChars, "-");
            
            var _filePath = $"{_fileCategoryDashed}-{_fileTitleDashed}.md";

            if (_filePath == "homepage-homepage.md"){
                _filePath = "README.md";
            }

            _item._link = _filePath;

            _filePath = $"{_finalDocPath}/{_filePath}"

            __updateFile(_filePath, __tome_generate(_item));
        }

        if (_item._category != "homepage"){
            if (!array_contains(global.__tomeData.categories.names, _item._category)){
                array_push(global.__tomeData.categories.names, _item._category);
                variable_struct_set(global.__tomeData.categories.map, $"{_item._category}", [_item]);
            }else{
                array_push(variable_struct_get(global.__tomeData.categories.map, $"{_item._category}"), _item);
            }
        }
        
        _item = array_pop(global.__tomeData.docsPageItems);
        
    }
    
}

/// @desc Updates basic docsify files: Config.js, index.html, codeTheme.css, customTheme.css, docsIcon.png, and .nojekyll
function __updateDocsifyFiles(){
    __tomeTrace("Updating Docsify files", true, 2, false);

    var _repoFilePath = global.__tomeData.repoFilePath;
    
    __updateFile($"{_repoFilePath}config.js", __tome_file_text_read_all(global.__tomeData.projectDirectory +  "datafiles/Tome/config.js"));
    
    __updateFile($"{_repoFilePath}index.html", __tome_file_text_read_all(global.__tomeData.projectDirectory +  "datafiles/Tome/index.html"));

    __updateFile($"{_repoFilePath}assets/codeTheme.css", __tome_file_text_read_all(global.__tomeData.projectDirectory +  "datafiles/Tome/assets/codeTheme.css"));

    __updateFile($"{_repoFilePath}assets/customTheme.css", __tome_file_text_read_all(global.__tomeData.projectDirectory +  "datafiles/Tome/assets/customTheme.css"));
    
    __updateFile($"{_repoFilePath}assets/docsIcon.png", __tome_file_bin_read_all(global.__tomeData.projectDirectory +  "datafiles/Tome/assets/docsIcon.png"));
    
    __updateFile($"{_repoFilePath}.nojekyll", "");
}

/// @desc Updates a given file, with the given content
/// @param {string} _filePath The path to the file to update
/// @param {string|buffer} _fileContent The data to save out to disk. If providing a buffer, it will be deleted after saving.
/// @returns {boolean} Whether the file was successfully updated/created or not.
function __updateFile(_filePath, _fileContent){
    var _fileBuffer;
    
    var _success = (is_string(_fileContent)) || (!is_undefined(_fileContent) && buffer_exists(_fileContent));

    var _existed = file_exists(_filePath);
    
    if (!_success){
        array_push(global.__tomeData.warnings, $"Data was not passed as a string or buffer to write to file at path {_filePath}. If you are seeing this warning, this is a bug in Tome, please report as an issue on Github.");
        global.__tomeData.docGenerationFailed = true;
    }else if (_existed){
        if (!file_delete(_filePath)) {
            array_push(global.__tomeData.warnings, $"Failed to delete locked file at path {_filePath}. Ensure it is not open in another program.");
            global.__tomeData.docGenerationFailed = true;
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
            array_push(global.__tomeData.warnings, $"Failed to {_existed ? "update" : "create"} file at path {_filePath}. Check permissions of the file and ensure the directory exists.");
            global.__tomeData.docGenerationFailed = true;
        }
    }
    return _success;
}

/// @desc Makes sure TOME_LOCAL_REPO path is a valid directory
function __verifyRepoPath(){
    // In case the user didn't end their repo filepath with "/", add it
    if (!string_ends_with(TOME_LOCAL_REPO_PATH, "/")){
        var _repoPathWithAddedForwardSlash = TOME_LOCAL_REPO_PATH + "/";
    }else{
        var _repoPathWithAddedForwardSlash = TOME_LOCAL_REPO_PATH; 
    }
    
    if (!directory_exists(_repoPathWithAddedForwardSlash)){
        array_push(global.__tomeData.warnings, $"The repo path: \"{_repoPathWithAddedForwardSlash}\" isn't a valid filepath, make sure the directory actually exists!");
        global.__tomeData.docGenerationFailed = true;
        return false;
    }
    
    global.__tomeData.repoFilePath = _repoPathWithAddedForwardSlash;
    return true;
}

/// @desc Generates the sidebar for the doc site
function __generateSidebar(){
    var _sideBarMarkdownString = "";
    _sideBarMarkdownString += "-    [Home](README)\n\n---\n\n"
    
    var _categoriesNames = global.__tomeData.categories.names;
    var _i = 0;
    
    repeat(array_length(_categoriesNames)){
        var _currentCategory = _categoriesNames[_i];
        
        _sideBarMarkdownString += $"**{_currentCategory}**\n\n";			
        
        var _currentCategoryArray = global.__tomeData.categories.map[$ _currentCategory];
        var _j = 0;
        
        repeat(array_length(_currentCategoryArray)){

            var _item = _currentCategoryArray[_j];

            if (_item._link != "") {
                _sideBarMarkdownString += $"-    [{_item._title}]({_item._link})\n";
            }

            _j++;
        }
        _sideBarMarkdownString += "\n---\n\n";
        _i++;
    }   
    
    __updateFile($"{__tome_file_get_final_doc_path()}_sidebar.md", _sideBarMarkdownString); 
}

/// @desc Generates the navbar for the doc site
function __generateNavbar(){
    var _navbarMarkdownString = "";

    var _i = 0;

    repeat(array_length(global.__tomeData.navbarItems)){
        var _currentNavbarItem = global.__tomeData.navbarItems[_i];
        _navbarMarkdownString += string("-    [{0}]({1})\n", _currentNavbarItem._title, _currentNavbarItem._link);
        _i++;
    }
        
    __updateFile($"{__tome_file_get_final_doc_path()}_navbar.md", _navbarMarkdownString);
}

function __tome_string_replace_all_ext(_string, _subStrArray, _newStr){
    var _str = _string;
    var _i = 0;

    repeat(array_length(_subStrArray)){
        _str = string_replace_all(_str, _subStrArray[_i], _newStr);
        _i++;
    }

    return _str;
}

#endregion // Sub functions


#region /// @func __tome_parse_file(filepath, [homepage])
/// @desc Parses a file and generates markdown documentation.
/// @param {string} filepath Path to the file.
/// @param {boolean} [Default: false] If this is the file that will parce to be used as the homepage.
/// @returns {struct} The markdown struct that holds all data related to this file. To determine if the file was properly parsed check the success variable.
function __tome_parse_file(_filepath, _homepage = false){
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
        
        __tomeTrace($"File type: {_fileType == __TOME_FILE_TYPE.GML ? "gml" : "txt"}");
        
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
            _lineString = string_replace(_lineString, "#region", "");
            
            var _lineIsJSDoc = string_starts_with(string_trim_start(_lineString), "///");

            if (_lineIsJSDoc || _fileIsText){
                _lineString = string_replace(_lineString, "///", "");
    			
                
    			//If the line contains a tag 
    			if (string_starts_with(string_trim(_lineString), "@")){
    				_lineString = string_trim(_lineString);

    				_tagType = string_split_ext(_lineString, [" ", "\t"], true)[0]; 
                    _tagContent = string_trim(string_replace(_lineString, _tagType, ""));
    				
    				if (_tagType == "@pass"){
                        if (string_lower(string_letters(_tagContent)) == "true"){
                            _passing = true;
                            _addAsText = false;
                            _tagType = "";
                            _tagContent = "";
                            continue;
                        }
                        
                        if (string_lower(string_letters(_tagContent)) == "tag"){
                            _passing = true;
                            _addAsText = true;
                            _tagType = "";
                            _tagContent = "";
                            continue;
                        }
                        
                        if (string_lower(string_letters(_tagContent)) == "false"){
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
                                array_push(global.__tomeData.warnings, $"{_filepath}: Title tag found with value {_tagContent}, but title was previously set to {_markdownData._title}. Only the first instance of title is respected.")
                            }
                            _tagType = "handled";
                            break;
                        
                        case "@category":
                            if (is_undefined(_markdownData._category)){
                                _markdownData._category = _tagContent;
                            }else{
                                array_push(global.__tomeData.warnings, $"{_filepath}: Category tag found with value {_tagContent}, but category was previously set to {_markdownData._category}. Only the first instance of category is respected.")
                            }
                            _tagType = "handled";
                            break;
                        
                        case "@pass":
                            if (!__isContextTextOnly(_context)){
                                _context = __newContext(_context);
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
                                
                                _context = __newContext(_context, false);
                            }
                            _tagType = "handled";
                            break;
                        
                        case "@slug":
                        case "@insert":
                            var _slugContent = "";    
                            
                            for (var _slugIndex = 0; _slugIndex < array_length(global.__tomeData.slugs) && _slugContent == ""; _slugIndex++){
                                if (_tagContent == global.__tomeData.slugs[_slugIndex][0]){
                                    _slugContent = "\n" + global.__tomeData.slugs[_slugIndex][1] + "\n";
                                }
                            }

                            if (_slugContent == ""){
                                array_push(global.__tomeData.warnings, $"Line {_lineNumber}: {_tagType} tag found, but it appears the provided name {_tagContent} does not exist in the parsed slugs.");
                            }else{
                                if (__isContextFunction(_context)){
                                    if (_context._firstParameterFound){
                                        _context._footer += _slugContent;
                                    }else{
                                        _context._description += _slugContent;
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
                                    
                                        _context = __newContext(_context);
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
                                            _context = __newContext(_context);
                                            _context._contextType = __TOME_CONTEXT_TYPE.FUNCTION;
                                        }
                                        _context._signature = _tagContent;
                                        _parameters = __getParametersFromSignature(_context._signature);
                                        break;
                                    
                                    case "@method":
                                        if (_context._contextType == __TOME_CONTEXT_TYPE.CONSTRUCTOR){
                                            _context._methods = variable_clone(__TOME_NEW_CONTEXT);
                                            _context._methods._parentContext = _context;
                                            _context = _context._methods;
                                        }else if (!is_undefined(_context._parentContext)){
                                            _context = __newContext(_context);
                                        }else{
                                            _contextEntered = false;
                                            array_push(global.__tomeData.warnings, $"Line {_lineNumber}: {_tagType} tag found, but current context is not compatable. Please ensure this tag is where you intend it to be or use @func/@function instead.");
                                        }

                                        if (_contextEntered){ 
                                            
                                            _context._contextType = __TOME_CONTEXT_TYPE.METHOD;
                                            _context._groupTag = "";
                                            _context._signature = _tagContent;
                                            _parameters = __getParametersFromSignature(_context._signature);
                                        }
                                        break;
                                    }
                                
                                if (_contextEntered){
                                    _context._edited = true;
                                    _context._deprecated = false;
                                    _context._description = ""
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
                            if (__isContextFunction(_context)){
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
                            if (__isContextFunction(_context)){
                                _context._deprecated = true;
                                _context._deprecatedCallout = _tagContent; 
                            }else{
                                array_push(global.__tomeData.warnings, $"Line {_lineNumber}: {_tagType} tag found, but current context is not compatable. Please ensure this tag is where you intend it to be.");
                            }
                            _tagType = "handled";
                            break;
                        
                        case "@argument":
                        case "@arg":
                        case "@parameter":
                        case "@param":
                            
                            if (__isContextFunction(_context)){
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
                                        array_push(global.__tomeData.warnings, $"Line {_lineNumber}: {_tagType} tag found, but only a type was provided. Please ensure this tag has at least the type and a name.");                                 
                                    }
                                }else{
                                    array_push(global.__tomeData.warnings, $"Line {_lineNumber}: {_tagType} tag found, but no type or description was provided. Please ensure this tag has at least the type and a name.");                                 
                                }
                                
                                // Remove any square brackets that the user put in the name we will add those ourselves based on if they exist here or in the signature.
                                var _preChangeName = _name;
                                _name = string_replace(_name, "[", "");
                                _name = string_replace(_name, "]", "");
                                
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
                                    array_push(global.__tomeData.warnings, $"Line {_lineNumber}: {_tagType} tag found with name {_preChangeName}, but no parameter was found in the function signature: {_context._signature}");
                                }
                                
                            }else{
                                array_push(global.__tomeData.warnings, $"Line {_lineNumber}: {_tagType} tag found, but current context is not compatable. Please ensure this tag is where you intend it to be.");
                            }
                            _tagType = "handled";
                            break;
                        
                        case "@return":
                        case "@returns":
                            if (__isContextFunction(_context)){
                                
                                var _splitContent = string_split_ext(_tagContent, ["}"], true, 1);
                                
                                var _type = "";
                                var _desc = "";
                                
                                if (array_length(_splitContent) > 0){
                                    _type = string("{0}}", _splitContent[0]);
                                    
                                    if (array_length(_splitContent) > 1){
                                        _desc = _splitContent[1];
                                    }
                                }else{
                                    array_push(global.__tomeData.warnings, $"Line {_lineNumber}: {_tagType} tag found, but no type was provided. Please ensure this tag has at least the type.");                         
                                }
                                
                                
                                
                                _context._return = _type;
                                _context._returnDescription = _desc;
                                
                                
                            }else{
                                array_push(global.__tomeData.warnings, $"Line {_lineNumber}: {_tagType} tag found, but current context is not compatable. Please ensure this tag is where you intend it to be.");
                            }
                            _tagType = "handled";
                            break;
                                                
                        case "@code":
                        case "@example":
                            
                            if (_context._contextType == __TOME_CONTEXT_TYPE.CONSTRUCTOR){
                                _context._methods = variable_clone(__TOME_NEW_CONTEXT);
                                _context._methods._parentContext = _context;
                                _context = _context._methods;
                                _context._contextType = __TOME_CONTEXT_TYPE.CODE;
                            }
                            
                            if (_context._contextType != __TOME_CONTEXT_TYPE.CODE){
                                _context = __newContext(_context);
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
                                _context._methods = variable_clone(__TOME_NEW_CONTEXT);
                                _context._methods._parentContext = _context;
                                _context = _context._methods;
                                _context._contextType = __TOME_CONTEXT_TYPE.TEXT;
                            }
                            
                            if (_context._contextType != __TOME_CONTEXT_TYPE.TEXT){
                                _context = __newContext(_context);
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
                                    array_push(global.__tomeData.warnings, $"Line {_lineNumber}: {_tagType} tag found. Tag type is not supported by Tome. If you are using this tag for Feather Stitch, or any other reason you can ignore this warning.");
                                }   
                            }
                            break;

                    }
                }else{
                    if (_addAsText){
                        // We set this to the context returned because the context may change in the helper function
                        _context = __addTextAnyways(_context, _rawLine);
                    }
                }
            }
        }
        
        file_text_close(_file);
    }else{
        array_push(global.__tomeData.warnings, $"Failed to open file {_filepath}: Check permissions of the file.");
        global.__tomeData.docGenerationFailed = true;
        _markdownData.success = false;
    }
    
    _context = _contextHead;
    
    while (!is_undefined(_context)){

        if (_context._contextType == __TOME_CONTEXT_TYPE.CONSTRUCTOR){
            var _subContext = _context._methods;
            
            if (!is_undefined(_subContext)){
                var _contextGroupHead = _subContext;
                var _groups = { names: [""],
                    ungrouped: undefined,
                    ungroupedTail: undefined
                }
                
                while (!is_undefined(_subContext)){
                    var _isMethod = _subContext._contextType == __TOME_CONTEXT_TYPE.METHOD;
                    var _isText = __isContextTextOnly(_subContext);
                    
                    if (_subContext._contextType != __TOME_CONTEXT_TYPE.METHOD && __isContextFunction(_subContext)){
                        var _contextTypeString = _subContext._contextType == __TOME_CONTEXT_TYPE.CONSTRUCTOR ? "@constructor" : "@func/@function";
                        array_push(global.__tomeData.warnings, $"You appear to have a nested {_contextTypeString} inside of a @constructor tag. This can happen if there is no clear ending to a previous context. \n To fix this issue place an @end tag at the end of your {_context._signature} constructor code. This will explicitly end the context.");
                    }
                    
                    if (_isMethod || _isText){
                        
                        var _groupName = _isMethod ? $"{_subContext._groupTag}" : "ungrouped";
                        
                        if (_groupName == ""){
                            _groupName = "ungrouped";
                        }
                        
                        if (!array_contains(_groups.names, _groupName)){
                            variable_struct_set(_groups, _groupName, _contextGroupHead);
                            variable_struct_set(_groups, $"{_groupName}Tail", _subContext);
                            if (_groupName != "ungrouped"){
                                array_push(_groups.names, _groupName);
                            }else{
                                _groups.names[0] = "ungrouped";
                            }
                        }else{
                            var _contextTail = variable_struct_get(_groups, $"{_groupName}Tail");
                            _contextTail._nextContext = _contextGroupHead;
                            variable_struct_set(_groups, $"{_groupName}Tail", _subContext);
                        }
                        
                        _contextGroupHead = _subContext._nextContext;
                        _subContext._nextContext = undefined;
                        _subContext = _contextGroupHead;
                    }else{
                        _subContext = _subContext._nextContext;
                    }
                }
                
                var _sortedMethods = _groups.ungrouped;
                /// @type  {Struct} | {Undefined} 
                var _tail = _groups.ungroupedTail;
                
                var _i = 1;
                
                repeat(array_length(_groups.names) - 1){
                var _groupName = _groups.names[_i];
                var _headerDepth = TOME_METHOD_GROUP_DEPTH == TOME_METHOD_GROUP_DEPTH_HEADER.H2 ? "##" : "###";
                var _groupHeader = variable_clone(__TOME_NEW_CONTEXT);
                    
                _groupHeader._edited = true;
                _groupHeader._markdown = $"<div class=\"group-header\">\n\n{_headerDepth} {_groupName}\n\n</div>";
                _groupHeader._nextContext = variable_struct_get(_groups, $"{_groupName}");
                    
                if (is_undefined(_sortedMethods)){
                    _sortedMethods = _groupHeader;
                }else{
                    _tail._nextContext = _groupHeader;
                }
                    
                _tail = variable_struct_get(_groups, $"{_groupName}Tail");
                _i++; 
                }
                
                if (is_undefined(_tail)) {
                    _sortedMethods = _contextGroupHead;
                } else {
                    _tail._nextContext = _contextGroupHead;
                }
                
                _context._methods = _sortedMethods;
            }
        }
        
        _context = _context._nextContext;
    }


    return _markdownData;
    
}
#endregion //__tome_parse_file

#region Helper functions
function __getParametersFromSignature(_signature){
    
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
           _name = string_replace(_name, "[", "");
           _name = string_replace(_name, "]", "");
           
           var _optional = _name != _parameters[_i];
           _parameters[_i] = {
               name: _name,
               type: "",
               description: "",
               optional: _optional
           }
           
           _i++;
        }   

    }
    
    return _parameters;
}

function __isContextFunction(_context){
    return(_context._contextType == __TOME_CONTEXT_TYPE.CONSTRUCTOR ||
        _context._contextType == __TOME_CONTEXT_TYPE.METHOD ||
        _context._contextType == __TOME_CONTEXT_TYPE.FUNCTION
    );
}
    
function __isContextTextOnly(_context){
    return(
        _context._contextType == __TOME_CONTEXT_TYPE.TEXT ||
        _context._contextType == __TOME_CONTEXT_TYPE.CODE
    );
}

function __newContext(_context, _copyParent = true){
    _context._nextContext = __TOME_NEW_CONTEXT;
    _context._nextContext._parentContext = _copyParent ? _context._parentContext : undefined;
    
    return _context._nextContext;
}

function __addTextAnyways(_context, text){
    if (!__isContextTextOnly(_context)){
        _context = __newContext(_context);
    }
    
    if (!_context._edited){
        _context._edited = true;
        _context._markdown = "";
    }

    _context._markdown += text;
    
    return _context;
}
#endregion // Helper functions

#region /// @func __tome_generate(markdownData)
/// @desc Takes provided context markdown data struct and converts it into a markdown string that is then saved out to a file.
/// @param markdownData The markdown data struct that contains relavant context information.
/// @returns {boolean} True if the markdown data was successfully converted to text and created a file. False otherwise
function __tome_generate(_markdownData){
    
    var _context = _markdownData._context;

    var _markdownString = $"# {_markdownData._title}\n";

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
                        _markdownString += $"\n!> This constructor is deprecated: {_context._deprecatedCallout}\n";
                    }

                    _markdownString += $"\n## `{_context._signature}` (constructor)\n";
                    _markdownString += "\n<div class=\"tome-function\">\n";
                    _markdownString += $"\n{_context._description}\n";

                    if (array_length(_context._parameters) > 0){
                        var _markdownTable = "| Parameter | Datatype  | Purpose |\n|-----------|-----------|---------|\n";

                        var _i = 0;
                        repeat (array_length(_context._parameters)){
                            var _parameter = _context._parameters[_i];
                            
                            var _name = _parameter.optional ? $"[{_parameter.name}]" : _parameter.name;
                            
                            var _parameterType = _parameter.type;
                            
                    
                            if (!TOME_DISPLAY_TYPE_IN_BRACKETS){
                                _parameterType = string_replace(_parameterType, "{", "");
                                _parameterType = string_replace(_parameterType, "}", "");
                            }
                            
                            _parameterType = __tome_parse_data_type(_parameterType);
                            
                            _markdownTable += $"| {_name} | {_parameterType} | {_parameter.description}\n";

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
                        _markdownString += "\n**Methods**\n"
                    }
                    

                    _nextContext = _context._methods;
                    break;

                case __TOME_CONTEXT_TYPE.FUNCTION:
                case __TOME_CONTEXT_TYPE.METHOD:
                    var _type = _context._contextType == __TOME_CONTEXT_TYPE.FUNCTION ? "function" : "method";
                    if (_context._deprecated){
                        _markdownString += $"\n!> This {_type} is deprecated: {_context._deprecatedCallout}\n";
                    }

                    _type = _type == "function" ? "##" : "###";
                    
                    var _returnType = _context._return;
                    
                    if (!TOME_DISPLAY_TYPE_IN_BRACKETS){
                        _returnType = string_replace(_returnType, "{", "");
                        _returnType = string_replace(_returnType, "}", "");
                    }
                    
                    _returnType = __tome_parse_data_type(_returnType);
                    
                    _markdownString += $"\n{_type} `{_context._signature}` → **{_returnType}**\n";
                    _markdownString += "\n<div class=\"tome-function\">\n";
                    _markdownString += $"\n{_context._description}\n";

                    if (array_length(_context._parameters) > 0){
                        var _markdownTable = "| Parameter | Datatype  | Purpose |\n|-----------|-----------|---------|\n";

                        var _i = 0;
                        repeat (array_length(_context._parameters)){
                            var _parameter = _context._parameters[_i];
                            
                            var _name = _parameter.optional ? $"[{_parameter.name}]" : _parameter.name;
                            
                            var _parameterType = _parameter.type;
                            
                    
                            if (!TOME_DISPLAY_TYPE_IN_BRACKETS){
                                _parameterType = string_replace(_parameterType, "{", "");
                                _parameterType = string_replace(_parameterType, "}", "");
                            }
                            
                            _parameterType = __tome_parse_data_type(_parameterType);
                            
                            _markdownTable += $"| {_name} | {_parameterType} | {_parameter.description}\n";

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
#endregion __tome_generate

#region /// @func __tome_parse_slug(filepath)
/// @desc Parses a markdown file and returns a struct containing the markdown text, title, and category. Unlike the script parser, this function only parses the tags @title and @category, all other text is just added to the markdown.
/// @param {string} _filePath The path to the file
/// @returns {boolean} If the file was sucessfully parsed or not.
function __tome_parse_slug(_filePath){
	var _file = file_text_open_read(_filePath);
	var _inSlug = false;
	var _markdown = "";
	var _slugName = "";
    
    var _success = true;
    
	if (_file == __TOME_FILE_OPEN_FAILED) {
        _success = false;
        global.__tomeData.docGenerationFailed = true;
        array_push(global.__tomeData.warnings, string($"Failed to open file {_filePath}, check permissions of file."))
	}else{
		while (!file_text_eof(_file)) {
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
									array_push(global.__tomeData.slugs, [_slugName, _markdown]);	
								}
							}
						
							_inSlug = true;
						
							_slugName = _tagContent;
							_markdown = "";
						
						
							var _slugIndex = 0;
							repeat(array_length(global.__tomeData.slugs)){
								if (_slugName == global.__tomeData.slugs[_slugIndex][0]){
									_inSlug = false;
									break;
								}
								_slugIndex++;
							}
						    break;
					
						default:
							_markdown += _lineStringUntrimmed;
						    break;
					}
				}else{
					_markdown += _lineStringUntrimmed;		
				}
			}else{
				_markdown += _lineStringUntrimmed;	
			}
		}
		
		if (_inSlug){
			if (_markdown != ""){
				array_push(global.__tomeData.slugs, [_slugName, _markdown]);	
			}
		}
        
        file_text_close(_file);
	}
    
    return _success;
}
#endregion // __tome_parse_slug

/// @desc If the game is ran from the IDE, this will return the file path to the game's project file with the ending "/"
function __tome_file_project_get_directory(){
	var _originalPath = filename_dir(GM_project_filename) + "\\";
	var _fixedPath = string_replace_all(_originalPath, "\\", "/");
	
	return string_trim(_fixedPath);
}

/// @desc Replaces instances of "|" with "*or*"(colored red
function __tome_parse_data_type(_dataTypeString){
	return string_replace_all(_dataTypeString, "|", "<span class=\"tome-type-separator\"> *or* </span>");
}

/// @desc Gets the actual filepath within the repo where the .md files will be pushed
function  __tome_file_get_final_doc_path() { 
	return $"{global.__tomeData.repoFilePath}{global.__tomeData.latestDocsVersion}/";
}

/// @desc Loads a text file and reads its entire contents as a string
/// @param {string} filePath The path to the text file to read
function __tome_file_text_read_all(_filePath){

    var _fileContents = undefined;

    if (file_exists(_filePath)){
        var _fileBuffer = buffer_load(_filePath);
        _fileContents = buffer_read(_fileBuffer, buffer_string);
        buffer_delete(_fileBuffer);
    }else{
        array_push(global.__tomeData.warnings, $"You seem to have deleted a file {_filePath}. This file is necessary for Tome to function. Please restore this file.");
        global.__tomeData.docGenerationFailed = true;
    }       
    
    return _fileContents;
}

/// @desc Loads a binary file
/// @param {string} filePath The path to the binary file to read
function __tome_file_bin_read_all(_filePath){
	var _fileBuffer = undefined;

    if (file_exists(_filePath)){
        _fileBuffer = buffer_load(_filePath);
    }else{
        array_push(global.__tomeData.warnings, $"You seem to have deleted a file {_filePath}. This file is necessary for Tome to function. Please restore this file.");
        global.__tomeData.docGenerationFailed = true;
    }       

	return _fileBuffer;
}

/// @desc Updates the config file with the given property name and value
/// @param {string} propertyName The name of the property to update
/// @param {any} propertyValue The value to set the property to
function __tome_file_update_config(_propertyName, _propertyValue){
	var _configFileContents = __tome_file_text_read_all(global.__tomeData.projectDirectory +  "datafiles/Tome/config.js");

    var _finalConfig = undefined;

    if (_configFileContents != undefined){
        // Remove the extra JS stuff so we can parse it as JSON
        _configFileContents = string_replace(_configFileContents, "const config = ", "");
        _configFileContents = string_replace_all(_configFileContents, ";", "");
        _configFileContents = string_replace_all(_configFileContents, "\r", "\n");
        _configFileContents = string_replace_all(_configFileContents, "\n\n", "\n");
        _configFileContents = string_replace_all(_configFileContents, "name", "\"name\"");
        _configFileContents = string_replace_all(_configFileContents, "description", "\"description\"");
        _configFileContents = string_replace_all(_configFileContents, "latestVersion", "\"latestVersion\"");
        _configFileContents = string_replace_all(_configFileContents, "otherVersions", "\"otherVersions\"");
        _configFileContents = string_replace_all(_configFileContents, "favicon", "\"favicon\"");
        _configFileContents = string_replace_all(_configFileContents, "themeColor", "\"themeColor\"");
        var _configStruct = json_parse(_configFileContents);
        
        //If the latest version is being updated, add the old version name to the otherVersions property
        if (_propertyName == "latestVersion"){
            if (_configStruct.latestVersion != _propertyValue){
                array_push(_configStruct.otherVersions, _configStruct.latestVersion);	
            }
        }
        
        _configStruct[$ _propertyName] = _propertyValue;
        
        //Now that the config is updated, let's convert it back into JS
        var _updatedJson = json_stringify(_configStruct);
        _updatedJson = string_replace_all(_updatedJson, "\"name\"", "    name");
        _updatedJson = string_replace_all(_updatedJson, "\"description\"", "    description");
        _updatedJson = string_replace_all(_updatedJson, "\"latestVersion\"", "    latestVersion");
        _updatedJson = string_replace_all(_updatedJson, "\"otherVersions\"", "    otherVersions");
        _updatedJson = string_replace_all(_updatedJson, "\"favicon\"", "    favicon");
        _updatedJson = string_replace_all(_updatedJson, "\"themeColor\"", "    themeColor");
        _updatedJson = string_replace_all(_updatedJson, ",  ", ",\n");
        _updatedJson = string_replace_all(_updatedJson, "}", ",\n}");
        _updatedJson = string_replace_all(_updatedJson, "{", "{\n");
        _updatedJson = string_replace_all(_updatedJson, "\\/", "/");
        _finalConfig = $"const config = {_updatedJson};";
    }
     

    __updateFile(global.__tomeData.projectDirectory +  "datafiles/Tome/config.js", _finalConfig);
}

#region /// @func __tomeTrace(text, [verboseOnly], [indentation], [includePrefix])
/// @desc Outputs a message to the console prefixed with "Tome:"
/// @param {string} text The message to display in the console
/// @param {boolean} [verboseOnly] [Default: false] Whether the message should only be displayed if `TOME_VERBOSE` is enabled or not
/// @param {real} [indentation] [Default: 0] What level of indentation the string content should exist at.
/// @param {boolean} [includePrefix] [Default: true] Whether "Tome: " will prepended to the output string or not.
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

#region /// @func __tome_setup_data()
/// @desc Initializes the global struct that holds Tome's data(if it doesn't already exist)
function __tome_setup_data(){
    if (!variable_global_exists("__tomeData")){
        global.__tomeData = {
            repoFilePath: "",
            latestDocsVersion: "Latest-Version",
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
            projectDirectory: __tome_file_project_get_directory()
        };
    }
}
#endregion // __tome_setup_data