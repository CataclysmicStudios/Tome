
/// @pass true
// Non-userfacing functions/macros used to make the system work

#region Macro declaration

#macro __TOME_DATA global.__tomeData

#macro __TOME_CAN_RUN (TOME_ENABLED && (GM_build_type == "run") && ((os_type == os_windows) || (os_type == os_macosx) || (os_type == os_linux)))

#macro __TOME_FILE_OPEN_FAILED -1

#macro __TOME_VERSION "01-29-2026"

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

#region Core System Functions

#region /// @func __tomeSetupData()
/// @desc Initializes the global struct that holds Tome's data(if it doesn't already exist)
function __tomeSetupData(){
    if (!variable_global_exists("__tomeData")){
        var _projectDirectory = string_trim(string_replace_all(filename_dir(GM_project_filename) + "\\", "\\", "/"));
        
        global.__tomeData = {
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
        };
        
        var _cssStruct = __tomeCSSToStruct(__tomeFileTextReadAll($"{_projectDirectory}datafiles/Tome/assets/customTheme.css", true));
        __TOME_DATA.customCSS = _cssStruct;

        var _configStruct = __tomeParseConfig($"{_projectDirectory}datafiles/Tome/config.js");
        __TOME_DATA.config = _configStruct;
    }
}
#endregion // __tomeSetupData

#region /// @func __tomeGenerateDocs()
/// @desc Generates the documentation website
/// Parses all files added via `tome_add` functions and generates your documenation site.  
/// Then it adds them to the repo path specified with the macro `TOME_REPO_PATH`
function __tomeGenerateDocs(){
    
    if (GM_is_sandboxed){
        array_push(__TOME_DATA.warnings, "GameMaker's file system sandbox is enabled. Tome will not function with this enabled, to disable go to Game Options -> Platform (Windows, macOS, Ubuntu) -> Check the \"Disable file system sandbox\"");
        __TOME_DATA.docGenerationFailed = true;
    }
    
    if (!__TOME_DATA.docGenerationFailed){
        var _repoDirectoryIsValid = __tomeVerifyRepoPath();
    }
    
    if (!__TOME_DATA.docGenerationFailed){
    	
        var finalDocDirectory = __tomeFileGetFinalDocPath();
        if (string_ends_with(finalDocDirectory, "/")){
            finalDocDirectory = string_copy(finalDocDirectory, 1, string_length(finalDocDirectory) - 1);
        }
            
        if (directory_exists(finalDocDirectory)){ 
            directory_destroy(finalDocDirectory);
        }
        
        directory_create(finalDocDirectory);
        
    	__tomeUpdateDocsifyFiles();
        
        __tomeProcessDocsItems();
        
        __tomeTrace("Generating sidebar and navbar", true, 2, false);
    	
    	__tomeGenerateSidebar();
        
        __tomeGenerateNavbar();
    }

}
#endregion // __tomeGenerateDocs

#endregion // Core System Functions
    
#region File I/O

#region /// @func __tomeVerifyRepoPath()
/// @desc Makes sure TOME_LOCAL_REPO path is a valid directory
function __tomeVerifyRepoPath(){
    // In case the user didn't end their repo filepath with "/", add it
    if (!string_ends_with(TOME_LOCAL_REPO_PATH, "/")){
        var _repoPathWithAddedForwardSlash = TOME_LOCAL_REPO_PATH + "/";
    }else{
        var _repoPathWithAddedForwardSlash = TOME_LOCAL_REPO_PATH; 
    }
    
    if (!directory_exists(_repoPathWithAddedForwardSlash)){
        array_push(__TOME_DATA.warnings, $"The repo path: \"{_repoPathWithAddedForwardSlash}\" isn't a valid filepath, make sure the directory actually exists!");
        __TOME_DATA.docGenerationFailed = true;
        return false;
    }
    
    __TOME_DATA.repoFilePath = _repoPathWithAddedForwardSlash;
    return true;
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
        array_push(__TOME_DATA.warnings, $"Data was not passed as a string or buffer to write to file at path {_filePath}. If you are seeing this warning, this is a bug in Tome, please report as an issue on Github.");
        __TOME_DATA.docGenerationFailed = true;
    }else if (_existed){
        if (!file_delete(_filePath)){
            array_push(__TOME_DATA.warnings, $"Failed to delete locked file at path {_filePath}. Ensure it is not open in another program.");
            __TOME_DATA.docGenerationFailed = true;
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
            array_push(__TOME_DATA.warnings, $"Failed to {_existed ? "update" : "create"} file at path {_filePath}. Check permissions of the file and ensure the directory exists.");
            __TOME_DATA.docGenerationFailed = true;
        }
    }
    return _success;
}
#endregion // __tomeUpdateFile

#region /// @func __tomeFileTextReadAll(filePath, [tomeInternalCall])
/// @desc Loads a text file and reads its entire contents as a string
/// @param {string} filePath The path to the text file to read
/// @param {boolean} [tomeInternalCall] Whether this function is being called internally by Tome.
function __tomeFileTextReadAll(_filePath, _tomeInternalCall = false){
    var _fileContents = undefined;

    if (file_exists(_filePath)){
        var _fileBuffer = buffer_load(_filePath);
        _fileContents = buffer_read(_fileBuffer, buffer_string);
        buffer_delete(_fileBuffer);
    }else{
        if (_tomeInternalCall){
            array_push(__TOME_DATA.warnings, $"You seem to have deleted a file {_filePath}. This file is necessary for Tome to function. Please restore this file.");
            __TOME_DATA.docGenerationFailed = true;
        }else{
            array_push(__TOME_DATA.warnings, $"File at path {_filePath} does not exist. Check that the file exists and the path is correct.");
        }
    }       
    
    return _fileContents;
}
#endregion // __tomeFileTextReadAll

#region /// @func __tomeFileBinReadAll(filePath, [tomeInternalCall])
/// @desc Loads a binary file
/// @param {string} filePath The path to the binary file to read
/// @param {boolean} [tomeInternalCall] Whether this function is being called internally by Tome.
function __tomeFileBinReadAll(_filePath, _tomeInternalCall = false){
	var _fileBuffer = undefined;

    if (file_exists(_filePath)){
        _fileBuffer = buffer_load(_filePath);
    }else{
        array_push(__TOME_DATA.warnings, $"You seem to have deleted a file {_filePath}. This file is necessary for Tome to function. Please restore this file.");
        __TOME_DATA.docGenerationFailed = true;
    }       

	return _fileBuffer;
}
#endregion // __tomeFileBinReadAll

/// @desc Gets the actual filepath within the repo where the .md files will be pushed
function __tomeFileGetFinalDocPath() { 
    return $"{__TOME_DATA.repoFilePath}{__TOME_DATA.config[$ "latestVersion"]}/";
}
#endregion // File I/O

#region Context Parsing and Markdown Generation

#region /// @func __tomeParseDocumentationFile(filepath, [homepage])
/// @desc Parses a file and generates a context markdown struct that can then be used to generate markdown for the documentation site.
/// @param {boolean} [Default: false] If this is the file that will parce to be used as the homepage.
/// @returns {struct} The markdown struct that holds all data related to this file. To determine if the file was properly parsed check the success variable.
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
                        if (string_lower(string_lower(_tagContent)) == "true"){
                            _passing = true;
                            _addAsText = false;
                            _tagType = "";
                            _tagContent = "";
                            continue;
                        }
                        
                        if (string_lower(string_starts_with(string_lower(_tagContent), "tag"))){
                            _passing = true;
                            _addAsText = true;
                            _tagType = "";
                            _tagContent = "";
                            continue;
                        }
                        
                        if (string_lower(string_lower(_tagContent)) == "false"){
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
                                array_push(__TOME_DATA.warnings, $"{_filepath}: Title tag found with value {_tagContent}, but title was previously set to {_markdownData._title}. Only the first instance of title is respected.")
                            }
                            _tagType = "handled";
                            break;
                        
                        case "@category":
                            if (is_undefined(_markdownData._category)){
                                _markdownData._category = _tagContent;
                            }else{
                                array_push(__TOME_DATA.warnings, $"{_filepath}: Category tag found with value {_tagContent}, but category was previously set to {_markdownData._category}. Only the first instance of category is respected.")
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
                            
                            for (var _slugIndex = 0; _slugIndex < array_length(__TOME_DATA.slugs) && _slugContent == ""; _slugIndex++){
                                if (_tagContent == __TOME_DATA.slugs[_slugIndex][0]){
                                    _slugContent = "\n" + __TOME_DATA.slugs[_slugIndex][1] + "\n";
                                }
                            }

                            if (_slugContent == ""){
                                array_push(__TOME_DATA.warnings, $"Line {_lineNumber}: {_tagType} tag found, but it appears the provided name {_tagContent} does not exist in the parsed slugs.");
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
                                            _context._methods = variable_clone(__TOME_NEW_CONTEXT);
                                            _context._methods._parentContext = _context;
                                            _context = _context._methods;
                                        }else if (!is_undefined(_context._parentContext)){
                                            _context = __tomeNewContext(_context);
                                        }else{
                                            _contextEntered = false;
                                            array_push(__TOME_DATA.warnings, $"Line {_lineNumber}: {_rawLine} {_tagType} tag found, but the current context is not compatable. Please ensure this tag is where you intend it to be or use @func/@function instead.");
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
                                array_push(__TOME_DATA.warnings, $"Line {_lineNumber}: {_rawLine} {_tagType} tag found, but the current context is not compatable. Please ensure this tag is where you intend it to be.");
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
                                        array_push(__TOME_DATA.warnings, $"Line {_lineNumber}: {_tagType} tag found, but only a type was provided. Please ensure this tag has at least the type and a name.");                                 
                                    }
                                }else{
                                    array_push(__TOME_DATA.warnings, $"Line {_lineNumber}: {_tagType} tag found, but no type or description was provided. Please ensure this tag has at least the type and a name.");                                 
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
                                    array_push(__TOME_DATA.warnings, $"Line {_lineNumber}: {_tagType} tag found with name {_preChangeName}, but no parameter was found in the function signature: {_context._signature}");
                                }
                                
                            }else{
                                array_push(__TOME_DATA.warnings, $"Line {_lineNumber}: {_rawLine} {_tagType} tag found, but the current context is not compatable. Please ensure this tag is where you intend it to be.");
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
                                    array_push(__TOME_DATA.warnings, $"Line {_lineNumber}: {_tagType} tag found, but no type was provided. Please ensure this tag has at least the type.");                         
                                }
                                
                                
                                
                                _context._return = _type;
                                _context._returnDescription = _desc;
                                
                                
                            }else{
                                array_push(__TOME_DATA.warnings, $"Line {_lineNumber}: {_rawLine} {_tagType} tag found, but the current context is not compatable. Please ensure this tag is where you intend it to be.");
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
                                _context._methods = variable_clone(__TOME_NEW_CONTEXT);
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
                                    array_push(__TOME_DATA.warnings, $"Line {_lineNumber}: {_tagType} tag found. Tag type is not supported by Tome. If you are using this tag for Feather Stitch, or any other reason you can ignore this warning.");
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
        array_push(__TOME_DATA.warnings, $"Failed to open file {_filepath}: Check permissions of the file.");
        __TOME_DATA.docGenerationFailed = true;
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
                    var _isText = __tomeIsContextTextOnly(_subContext);
                    
                    if (_subContext._contextType != __TOME_CONTEXT_TYPE.METHOD && __tomeIsContextFunction(_subContext)){
                        var _contextTypeString = _subContext._contextType == __TOME_CONTEXT_TYPE.CONSTRUCTOR ? "@constructor" : "@func/@function";
                        array_push(__TOME_DATA.warnings, $"You appear to have a nested {_contextTypeString} inside of a @constructor tag. This can happen if there is no clear ending to a previous context. \n To fix this issue place an @end tag at the end of your {_context._signature} constructor code. This will explicitly end the context.");
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


    return _markdownData;
    
}
#endregion //__tomeParseDocumentationFile

#region /// @func __tomeParseSlugFile(filepath)
/// @desc Parses a slug file and adds the slugs to the __TOME_DATA.slugs array.
/// @param {string} _filePath The path to the file
/// @returns {boolean} If the file was sucessfully parsed or not.
function __tomeParseSlugFile(_filePath){
	var _file = file_text_open_read(_filePath);
	var _inSlug = false;
	var _markdown = "";
	var _slugName = "";
    
    var _success = true;
    
	if (_file == __TOME_FILE_OPEN_FAILED){
        _success = false;
        __TOME_DATA.docGenerationFailed = true;
        array_push(__TOME_DATA.warnings, string($"Failed to open file {_filePath}, check permissions of file."))
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
									array_push(__TOME_DATA.slugs, [_slugName, _markdown]);	
								}
							}
						
							_inSlug = true;
						
							_slugName = _tagContent;
							_markdown = "";
						
						
							var _slugIndex = 0;
							repeat(array_length(__TOME_DATA.slugs)){
								if (_slugName == __TOME_DATA.slugs[_slugIndex][0]){
									_inSlug = false;
									break;
								}
								_slugIndex++;
							}
						    break;
                        
                        case "@pass":
                            _markdown += $"{_tagContent}\n";
                            break;
					
						default:
							_markdown += $"{_lineStringUntrimmed}\n";
						    break;
					}
				}else{
					_markdown += $"{_lineStringUntrimmed}\n";	
				}
			}else{
				_markdown += $"{_lineStringUntrimmed}\n";
			}
		}
		
		if (_inSlug){
			if (_markdown != ""){
				array_push(__TOME_DATA.slugs, [_slugName, _markdown]);	
			}
		}
        
        file_text_close(_file);
	}
    
    return _success;
}
#endregion // __tomeParseSlugFile

#region /// @func __tomeGenerateFile(markdownData)
/// @desc Takes provided context markdown data struct and converts it into a markdown string that is then saved out to a file.
/// @param markdownData The markdown data struct that contains relavant context information.
/// @returns {boolean} True if the markdown data was successfully converted to text and created a file. False otherwise
function __tomeGenerateFile(_markdownData){
    
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
                        _markdownString += $"\n!> **This constructor is deprecated**: {_context._deprecatedCallout}\n";
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
                            
                            _parameterType = __tomeParseDataType(_parameterType);
                            
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
                        _markdownString += "\n<div class=\"tome-methods-header\">\n\n**Methods**\n\n</div>\n"
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
                        _returnType = string_replace(_returnType, "{", "");
                        _returnType = string_replace(_returnType, "}", "");
                    }
                    
                    _returnType = __tomeParseDataType(_returnType);
                    
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
                            
                            _parameterType = __tomeParseDataType(_parameterType);
                            
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
    
    if (_context._contextType == __TOME_CONTEXT_TYPE.TEXT){
        _context._markdown += $"{text}\n";
    }else{
        _context._markdown += text;
    }
    
    return _context;
}
#endregion // __tomeAddTextAnyways

#endregion // Parser Helper Functions

#region Markdown Generation Helper Functions

#region /// @func __tomeParseDataType(dataTypeString)
/// @desc Replaces instances of "|" with "*or*"(colored red
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
                _inString = true;
                _openChar = _currentChar;
                _token += _currentChar;
                _i++;
                continue;
            }else if (_inString && _currentChar == _openChar){
                // Ensure the quote isn't escaped (\")
                var _prevChar = string_char_at(_cssString, _i - 1);
                if (_prevChar != "\\"){
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
            _nestedString += $"{_indent}{_key}{"\{"}\n";
            _nestedString += __tomeStructToCSS(_value, _indent + "\t");
            _nestedString += $"{_indent}{"\}"}\n\n";
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
function __tomeMergeCSSStructs(_target, _source){
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
            __tomeMergeCSSStructs(_target[$ _key], _sourceVal);
            
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
    var _configString = __tomeFileTextReadAll(_filePath, true);
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
    __TOME_DATA.config[$ _propertyName] = _propertyValue;
}
#endregion // __tomeUpdateConfigProperty

#region /// @func __tomeGenerateConfigString()
/// @desc Converts the in-memory config struct back into a formatted config.js string.
function __tomeGenerateConfigString(){
    var _json = json_stringify(__TOME_DATA.config);
    var _formatted = "";
    
    var _arrayDepth = 0;
    var _inString = false;
    var _len = string_length(_json);
    
    for (var _i = 1; _i <= _len; _i++){
        var _currentChar = string_char_at(_json, _i);
        
        if (_currentChar == "\""){
            var _previousChar = string_char_at(_json, _i - 1);
            if (_previousChar != "\\"){
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
/// @desc Sort through site struct if multiple entries contain the same category and title group them together.
function __tomeProcessDocsItems(){
    
    array_reverse_ext(__TOME_DATA.docsPageItems);
    
    /// @type {any}
    var _item = array_pop(__TOME_DATA.docsPageItems);
    var _finalDocPath = __tomeFileGetFinalDocPath();
    var _illegalFilePathChars = [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"];
    while (_item != undefined){
        
        if (_item._sidebarType == __TOME_SIDEBAR_TYPE.FILE){

            var _fileCategoryDashed = string_lower(__tomeStringReplaceAllExt(_item._category, _illegalFilePathChars, "-"));
            var _fileTitleDashed = string_lower(__tomeStringReplaceAllExt(_item._title, _illegalFilePathChars, "-"));
            
            var _filePath = $"{_fileCategoryDashed}-{_fileTitleDashed}.md";

            if (_filePath == "homepage-homepage.md"){
                _filePath = "README.md";
            }

            _item._link = _filePath;

            _filePath = $"{_finalDocPath}{_filePath}"

            __tomeUpdateFile(_filePath, __tomeGenerateFile(_item));
        }

        if (_item._category != "homepage"){
            if (!array_contains(__TOME_DATA.categories.names, _item._category)){
                array_push(__TOME_DATA.categories.names, _item._category);
                variable_struct_set(__TOME_DATA.categories.map, $"{_item._category}", [_item]);
            }else{
                array_push(variable_struct_get(__TOME_DATA.categories.map, $"{_item._category}"), _item);
            }
        }
        
        _item = array_pop(__TOME_DATA.docsPageItems);
        
    }
    
}
#endregion // __tomeProcessDocsItems

#region /// @func __tomeUpdateDocsifyFiles()
/// @desc Updates basic docsify files: Config.js, index.html, codeTheme.css, customTheme.css, docsIcon.png, and .nojekyll
function __tomeUpdateDocsifyFiles(){
    __tomeTrace("Updating Docsify files", true, 2, false);

    var _repoFilePath = __TOME_DATA.repoFilePath;
    
    __tomeUpdateFile($"{_repoFilePath}config.js", __tomeGenerateConfigString());
    
    __tomeUpdateFile($"{_repoFilePath}index.html", __tomeFileTextReadAll(__TOME_DATA.projectDirectory +  "datafiles/Tome/index.html", true));

    __tomeUpdateFile($"{_repoFilePath}assets/codeTheme.css", __tomeFileTextReadAll(__TOME_DATA.projectDirectory +  "datafiles/Tome/assets/codeTheme.css", true));

    __tomeUpdateFile($"{_repoFilePath}assets/customTheme.css", __tomeStructToCSS(__TOME_DATA.customCSS));
    
    __tomeUpdateFile($"{_repoFilePath}assets/docsIcon.png", __tomeFileBinReadAll(__TOME_DATA.projectDirectory + "datafiles/Tome/assets/docsIcon.png", true));
    
    __tomeUpdateFile($"{_repoFilePath}.nojekyll", "");
}
#endregion // __tomeUpdateDocsifyFiles

#region /// @func __tomeGenerateSidebar()
/// @desc Generates the sidebar for the doc site
function __tomeGenerateSidebar(){
    var _sideBarMarkdownString = "";
    _sideBarMarkdownString += "-    [Home](README)\n\n---\n\n"
    
    var _categoriesNames = __TOME_DATA.categories.names;
    var _i = 0;
    
    repeat(array_length(_categoriesNames)){
        var _currentCategory = _categoriesNames[_i];
        
        _sideBarMarkdownString += $"**{_currentCategory}**\n\n";			
        
        var _currentCategoryArray = __TOME_DATA.categories.map[$ _currentCategory];
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

    repeat(array_length(__TOME_DATA.navbarItems)){
        var _currentNavbarItem = __TOME_DATA.navbarItems[_i];
        _navbarMarkdownString += string("-    [{0}]({1})\n", _currentNavbarItem._title, _currentNavbarItem._link);
        _i++;
    }
        
    __tomeUpdateFile($"{__tomeFileGetFinalDocPath()}_navbar.md", _navbarMarkdownString);
}
#endregion // __tomeGenerateNavbar

#endregion // Site Structure Functions

#region Utility functions

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

#endregion // Utility functions

#region Initialization
if (__TOME_CAN_RUN){
    //Create the tome time source that will begin object to start tome generating
	global.__tomeInitTimeSource = time_source_create(time_source_global, 1, time_source_units_frames, function(){
        __tomeTrace($"Tome Enabled, Version: {__TOME_VERSION}");

        __tomeSetupData();

        __tomeTrace("Generating docs...", false, 1, true);
        
        tomeSetup();
        
        __tomeGenerateDocs();
        
        var _warningsFound = array_length(global.__tomeData.warnings) > 0;
        
        if (_warningsFound){
            __tomeTrace("Warnings:", false, 1, true);
            
            var _i = 0;
            
            repeat(array_length(global.__tomeData.warnings)){
                var _currentWarning = global.__tomeData.warnings[_i];
                
                __tomeTrace(_currentWarning, false, 2, false);
                
                _i++;
            }
        }
        
        
        var _finalMessage = global.__tomeData.docGenerationFailed ? "Doc generation failed: Please see warnings above.!\n" : "All docs generated!\n";
        __tomeTrace(_finalMessage);
        
        time_source_destroy(global.__tomeInitTimeSource);
	}, [], 1);

	time_source_start(global.__tomeInitTimeSource);
}
#endregion // Initialization