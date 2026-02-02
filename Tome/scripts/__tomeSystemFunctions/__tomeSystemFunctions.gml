//Non-userfacing functions/macros used to make the system work
#macro __TOME_CAN_RUN (TOME_ENABLED && (GM_build_type == "run") && ((os_type == os_windows) || (os_type == os_macosx) || (os_type == os_linux)))

#macro TOME_VERSION "02-02-2026" 

/// @desc Generates the documentation website
/// @desc Parses all files added via `tome_add_` functions and generates your documenation site.  
///              Then it adds them to the repo path specified with the macro `TOME_REPO_PATH`
function __tome_generate_docs(){
    var _repoDirectoryIsValid = __verifyRepoPath();
    
    if (!_repoDirectoryIsValid){
        exit;
    }
    
	// Check for duplicate files, because someone may accidentally add files multiple times.
    __removeDuplicateFiles(global.__tomeData.filesToBeParsed);
    // Same for slugs
    __removeDuplicateFiles(global.__tomeData.slugNoteFilePaths);
    
	__parseAllSlugs();
	
	__updateDocsifyFiles();

	// Update homepage 
    __tomeTrace("Updating homepage", true, 2, false);
    __updateFile($"{__tome_file_get_final_doc_path()}README.md", global.__tomeData.homepageContent);

	__generateDocFiles();
    
    __addAdditionalSidebarItemsToSidebarData();
    
    __tomeTrace("Generating sidebar and navbar", true, 2, false);
	
	__generateSidebar();
    
    __generateNavbar();
    
    #region SubFunctions
    
    /// @desc Parsing each added file and generates doc pages for them
    function __generateDocFiles(){
        var _i = 0;
	
    	// Parse each file and add it to the repo
    	repeat (array_length(global.__tomeData.filesToBeParsed)){
    		// Parse file and get results
    		var _currentFilePath = global.__tomeData.filesToBeParsed[_i];
    		var _fileExtension = __tome_file_get_extension(_currentFilePath);
    		var _docStruct = _fileExtension == "gml" ? __tome_parse_script(_currentFilePath) : __tome_parse_markdown(_currentFilePath);
    		// Save the .md files to the local repo directory
            var _pageTitleWithSpacesReplacedWithDashes = string_replace_all(_docStruct.title, " ", "-");
    		var _fullFilePath = $"{__tome_file_get_final_doc_path()}{string_replace_all(_docStruct.category, " ", "-")}-{_pageTitleWithSpacesReplacedWithDashes}.md";
            __updateFile(_fullFilePath, _docStruct.markdown);
    		
    		// Add this file's category to the global.__tomeData.categories struct
    		if (_docStruct.category == ""){
    			array_push(global.__tomeData.categories.none, _docStruct.title);
    		}else{
    			if (!variable_struct_exists(global.__tomeData.categories, _docStruct.category)){
                    global.__tomeData.categories[$ _docStruct.category] = []  
                }
                
                if (array_get_index(global.__tomeData.categories[$ _docStruct.category], _docStruct.title) == -1){
                    array_push(global.__tomeData.categories[$ _docStruct.category], _docStruct.title);
                }
    		}
    		
    		_i++;
    	}
    }
    
    /// @desc Updates basic docsify files: Config.js, index.html, codeTheme.css, customTheme.css, docsIcon.png, and .nojekyll
    function __updateDocsifyFiles(){
        __tomeTrace("Updating Docsify files", true, 2, false);
        
        var _configFileContents = __tome_file_text_read_all(__tome_file_project_get_directory() +  "datafiles/Tome/config.js");
    	__updateFile($"{global.__tomeData.repoFilePath}config.js", _configFileContents);
    	
    	var _indexFileContents = __tome_file_text_read_all(__tome_file_project_get_directory() +  "datafiles/Tome/index.html");
        __updateFile($"{global.__tomeData.repoFilePath}index.html", _indexFileContents);
    	
    	var _codeThemeFileContents = __tome_file_text_read_all(__tome_file_project_get_directory() +  "datafiles/Tome/assets/codeTheme.css");
        __updateFile($"{global.__tomeData.repoFilePath}assets/codeTheme.css", _codeThemeFileContents);
    	
    	var _customThemeFileContents = __tome_file_text_read_all(__tome_file_project_get_directory() +  "datafiles/Tome/assets/customTheme.css");
        __updateFile($"{global.__tomeData.repoFilePath}assets/customTheme.css", _customThemeFileContents);
    	
    	var _iconFileContents = __tome_file_bin_read_all(__tome_file_project_get_directory() +  "datafiles/Tome/assets/docsIcon.png");
    	__updateFile($"{global.__tomeData.repoFilePath}assets/docsIcon.png", _iconFileContents);
        
        __updateFile($"{global.__tomeData.repoFilePath}.nojekyll", "");
    }
    
    /// @desc Removes duplicate files names from an array
    /// @param {array<string>} fileArray The array of file names
    function __removeDuplicateFiles(_fileArray){
        for (var _fileIndex = 0; _fileIndex < array_length(_fileArray); _fileIndex++){
    		for (var _checkIndex = _fileIndex; _checkIndex < array_length(_fileArray); _checkIndex++){
    			if (_checkIndex != _fileIndex){
    				if (_fileArray[_checkIndex] == _fileArray[_fileIndex]){
    					array_delete(_fileArray, _checkIndex, 1);
    					_checkIndex--;	
    				}
    			}
    		}
    	}
    }
    
    /// @desc Updates a given file, with the given content
    /// @param {string} _filePath The path to the file to update
    /// @param {string|buffer} fileContent The data to save out to disk
    function __updateFile(_filePath, _fileContent){
    	var _fileBuffer;
    	
    	if (is_string(_fileContent)){
    		_fileBuffer = buffer_create(0, buffer_grow, 1);
    	
    		buffer_write(_fileBuffer, buffer_text, _fileContent);
    	}else{
    		_fileBuffer = _fileContent;	
    	}
        
    	buffer_save(_fileBuffer, _filePath);
    	buffer_delete(_fileBuffer);
    	
    	__tomeTrace("Local repo file updated: " + _filePath, true, 3, false);
    }
    
    /// @desc Parses all slug notes and adds the slugs to global.__tomeData.slugs
    function __parseAllSlugs(){
        var _slugIndex = 0;
    	repeat (array_length(global.__tomeData.slugNoteFilePaths)){
    		__tome_parse_markdown_slug(global.__tomeData.slugNoteFilePaths[_slugIndex]);
    		_slugIndex++;	
    	}
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
            __tomeTrace($"The repo path: \"{_repoPathWithAddedForwardSlash}\" isn't a valid filepath, make sure the directory actually exists!", false, 1, false);
            global.__tomeData.docGenerationFailed = true;
            return false;
        }
        
        global.__tomeData.repoFilePath = _repoPathWithAddedForwardSlash;
        return true;
    }
    
    /// @desc Adds any additional sidebar specified by the user to `global.__tomeData.categories` for generation
    function __addAdditionalSidebarItemsToSidebarData(){
        var _i = 0;

    	repeat(array_length(global.__tomeData.additionalSidebarItems)){
    		var _currentSidebarItem = global.__tomeData.additionalSidebarItems[_i];
    
    		//Add this file's category to the _categories struct
    		if (_currentSidebarItem.category == ""){
    			array_push(global.__tomeData.categories.none, _currentSidebarItem.title);
    		}else{
    			if (variable_struct_exists(global.__tomeData.categories, _currentSidebarItem.category)){
    				array_push(global.__tomeData.categories[$ _currentSidebarItem.category], {title: _currentSidebarItem.title, link: _currentSidebarItem.link});
    			}else{
    				global.__tomeData.categories[$ _currentSidebarItem.category] = [{title: _currentSidebarItem.title, link: _currentSidebarItem.link}];
    			}
    		}
    		
    		_i++;
    	}
    }
    
    /// @desc Generates the sidebar for the doc site
    function __generateSidebar(){
        var _sideBarMarkdownString = "";
    	_sideBarMarkdownString += "-    [Home](README)\n\n---\n\n"
    	
        var _categoriesNames = struct_get_names(global.__tomeData.categories);
        var _a = 0;
    	
    	repeat(array_length(_categoriesNames)){
    		var _currentCategory = _categoriesNames[_a];
    		
    		if (_currentCategory != "none"){
    			_sideBarMarkdownString += $"**{_currentCategory}**\n\n";			
    		}
    		
    		var _b = 0; 
    		var _categoryArrayLength = array_length(global.__tomeData.categories[$ _currentCategory]);
    		
    		repeat(_categoryArrayLength){
    			var _currentCategoryArray = global.__tomeData.categories[$ _currentCategory];
    			
    			if (is_struct(_currentCategoryArray[_b])){
    				var _currentPageTitle = _currentCategoryArray[_b].title;
    				var _currentPageLink = _currentCategoryArray[_b].link;
    				_sideBarMarkdownString += $"-    [{_currentPageTitle}]({_currentPageLink})\n";
    			
    				if (_b == (_categoryArrayLength - 1)){
    					_sideBarMarkdownString += "\n---\n\n";	
    				}
    			}else{
    				var _currentPageTitle = _currentCategoryArray[_b];
    				var _currentPageFileName = string_replace_all(_currentCategory + " " + _currentPageTitle, " ", "-");
    				_sideBarMarkdownString += $"-    [{_currentPageTitle}]({_currentPageFileName})\n";
    			
    				if (_b == (_categoryArrayLength - 1)){
    					_sideBarMarkdownString += "\n---\n\n";	
    				}
    			}
    			_b++;
    		}
    		_a++;
    	}   
        
        __updateFile($"{__tome_file_get_final_doc_path()}_sidebar.md", _sideBarMarkdownString); 
    }
    
    /// @desc Generates the navbar for the doc site
    function __generateNavbar(){
    	var _navbarMarkdownString = "";
    
    	var _i = 0;
    
    	repeat(array_length(global.__tomeData.navbarItems)){
    		var _currentNavbarItem = global.__tomeData.navbarItems[_i];
    		_navbarMarkdownString += string("-    [{0}]({1})\n", _currentNavbarItem.name, _currentNavbarItem.link);
    		_i++;
    	}
    		
        __updateFile($"{__tome_file_get_final_doc_path()}_navbar.md", _navbarMarkdownString);
    }
    
    #endregion
}

/// @desc Parses a GML file and generates markdown documentation.
/// @param {string} filepath Path to the GML file.
/// @returns {struct} Struct containing the markdown text, title, and category
function __tome_parse_script(_filepath) {
    var _markdown = ""; // The final markdown string that will be returned

    // Here we are looking specifically for the @title and @category tags
    // If a file with the same category and tag already exist, we want to load that file and append this new script's content to it
    var _titleAndCategoryStruct = __tome_get_file_title_and_category(_filepath);
    
    var _title = _titleAndCategoryStruct.title;
    var _category = _titleAndCategoryStruct.category;
    
    var _titleFound = (_title != "");
    var _categoryFound = (_category != "");
    
    // Stop trying to parse the script right away if a title for the page cannot be found
    if (!_titleFound){
        __tomeTrace($"No @title tag can be found for: {_filepath}", false, 2, false);
        return {
			markdown: _markdown,
			category: _category,
			title: _title
		};
    }
    
    if (!_categoryFound){
        _category = "none";
    }
    
    /// Now lets figure out if there is a page with the same title and category that has already been parsed
    var _titleAlreadyExistsInCategory = false;
    var _titleFilePath = "";
    var _categoryTitles = global.__tomeData.categories[$ _category];
    var _categoryAlreadyExists = _categoryTitles != undefined ? true : false;
    var _titleWithNoDashes = string_replace_all(_title, "-", " ");
    
    if (_categoryAlreadyExists){
        if (array_get_index(_categoryTitles, _titleWithNoDashes) != -1){
            _titleAlreadyExistsInCategory = true;
            var _categoryWithDashesInsteadOfSpaces = string_replace_all(_category, " ", "-");
            _titleFilePath = $"{__tome_file_get_final_doc_path()}{_categoryWithDashesInsteadOfSpaces}-{_title}.md";
            __tomeTrace($"The title: {_title} is already present in the category: {_category}, content for this script will be appended onto the existing .md file", true, 3, false); 
        }           
    }
    
    if (_titleAlreadyExistsInCategory){
        _title = _titleWithNoDashes;
        
        if (file_exists(_titleFilePath)){
            _markdown = __tome_file_text_read_all(_titleFilePath) + "\n </div> <br>\n"; // Add the existing content to the markdown string
        }
    }
	
	var _textBoxStarted = false;
	var _inTextBlock = false;
	var _descStarted = false;
	var _inDesc = false;
	var _constructorStarted = false;
	var _inConstructor = false;
	var _funcStarted = false;
	var _inFunc = false;
	var _inMethod = false;
    var _currentInFunc = "";
	var _foundReturn = false;
	var _tableStarted = false;
	var _inTable = false;
	var _codeBlockStarted = false;
	var _inCodeBlock = false;
	var _ignoring = false;
    var _previousTag = "@none";
    var _tagType = "";
    
    var _file = file_text_open_read(_filepath);
    
    if (_file == -1) {
		__tomeTrace("Failed to open file: " + _filePath, false, 2, false);
		return {
			markdown: _markdown,
			category: _category,
			title: _title
		};
	}

    //Loop through each line of the text file
	while (!file_text_eof(_file)) {
		var _lineString = file_text_readln(_file);
		var _rawUneditedLineString = _lineString;
        
		/// Added removal of #region tags as the line may not always begin with "///" but may begin with "#region ///"
		if (string_starts_with(string_trim_start(_lineString), "#region")){
			_lineString = string_replace(_lineString, "#region", "");
		}
		
		//If the line has text to parse, it will start with "///"
		if (string_starts_with(string_trim_start(_lineString), "///")){
			_lineString = string_replace(_lineString, "///", "");
			
			// Right now I only care about indention if it's a code block or text block
			if (!_inCodeBlock && !_inTextBlock){
				_lineString = string_trim(_lineString);	
			}

			if (_inDesc){
				_lineString = __tome_string_trim_starting_whitespace(_lineString, 2);
			}
			
			//If the line contains a tag 
			if (string_count("@", _lineString) > 0){
				_lineString = string_trim(_lineString);
				
                _previousTag = _tagType;
				var _splitString = __tome_string_split_spaces_tabs(_lineString);
				_tagType = _splitString[0];
				var _tagContent = string_trim(string_replace(_lineString, _tagType, ""));
				
				if (_tagType == "@ignore"){
					_ignoring = _tagContent == "true" || _tagContent == "True" || _tagContent == "TRUE";
				}
				
				if (!_ignoring){
					switch(_tagType){
						case "@title":
							if !(_titleAlreadyExistsInCategory){
                                _markdown += "# " + _tagContent + "\n";		
    							_title = _tagContent;
    							_inTextBlock = false;
                            }   
						break;
					
						case "@function":
						case "@func":
                            if (_inCodeBlock){
                                 _markdown += "\n```\n"
                            }
                            
                            if (_inTable || _tableStarted || _inCodeBlock || _inTextBlock || _inDesc){
                                _markdown += "\n </div> <br>\n"
                            }
                            
                            _inCodeBlock = false;
                            _tableStarted = false;
							_inTable = false;
							_foundReturn = false;
							_markdown += string("\n ## <span style=\"white-space: nowrap;\"> `{0}`", _tagContent);		
							_inTextBlock = false;
						
							if (_inConstructor){
								_markdown += " (*constructor*)</span><br>";		
							}else{
								_markdown += " → {rv}</span><br>";	
							}
						
							_markdown += "\n";
						
							_inDesc = false;
                            _inFunc = true;
                            _inMethod = false;
                            _currentInFunc = _tagContent;
						break;
					
						case "@method":
                            if (_inCodeBlock){
                                 _markdown += "\n```\n"
                            }
                            
                            if (_inTable || _inCodeBlock || _inTextBlock || _inDesc){
                                _markdown += "\n </div> <br>\n"
                            }
                            
							if (_inConstructor){
                                _markdown += "<div style=\"margin-left: 32px;\">\n"
								_markdown += "\n ### Methods";	
								_markdown += "\n ---";	
								_markdown += "\n</div>\n";	
								_inConstructor = false;
							}
						
							_markdown += string("\n ### &emsp; `.{0}` → {rv}\n" , _tagContent);	
                            _inCodeBlock = false;	
							_inTextBlock = false;
							_tableStarted = false;
							_inTable = false;
							_inFunc = true;
                            _inMethod = true;
						break;
						
						case "@slug":
						case "@insert":
                            var addDiv = ((_inFunc || _inMethod) && !(_inDesc || _inTable || _inCodeBlock || _inTextBlock))
                            
                            if (addDiv){
                                var _indentAmount = _inMethod ? 64 : 32;
                                _markdown += string("\n<div style=\"margin-left: {0}px;\">\n\n", _indentAmount);
                            }
                            
							for (var _slugIndex = 0; _slugIndex < array_length(global.__tomeData.slugs); _slugIndex++){
								if (_tagContent == global.__tomeData.slugs[_slugIndex][0]){
									_markdown +=  "\n" + global.__tomeData.slugs[_slugIndex][1] + "\n";
								}
							}
                            
                            if (addDiv){
                                _markdown += "\n</div>\n";	
                            }
						break;
						
						case "@constructor":
							_inConstructor = true;
							_tableStarted = false;
						break;
				
						case "@desc":
						case "@description":
                            var _previousTagIsCompatible = __previousTagIsCompatible(_tagType, _previousTag)
							
                            if (_inFunc && _previousTagIsCompatible){
                                var _indentAmount = _inMethod ? 64 : 32;
                                _markdown += string("\n<div style=\"margin-left: {0}px;\">\n\n", _indentAmount);
								_markdown += _tagContent + "\n\n";		
								_inDesc = true;
                                _tableStarted = false;
                                _inTable = false;
							}else if (!_previousTagIsCompatible){
                                // If a desc tag is found without a preceeding @function or @method tag, we are no longer in a valid function/method
                                _inFunc = false;
                                _inMethod = false;
                            }
						break; 
					
						case "@text":
                            if (_inCodeBlock){
                                _markdown += "\n```\n"
                            }
                            
                             if (_inCodeBlock || _tableStarted){
                                _markdown += "\n</div>\n";	    
                            }
                            
                            var _indentAmount = _inMethod ? 64 : (_inFunc ? 32 : 0);
                            
                            if (!_inDesc){
                                _markdown += string("<div style=\"margin-left: {0}px;\">\n", _indentAmount);
                            }
                    
                            _markdown += "\n" + _tagContent + "\n";			
							_inTextBlock = true;
							_inCodeBlock = false;
							_tableStarted = false;
							_inDesc = false;
							_inTable = false;
							_tableStarted = false;
						break;
					
						case "@code":
						case "@example":
                            if (_inTextBlock || _inTable){
                                _markdown += "\n</div>\n";	    
                            }
                            
                            var _indentAmount = _inMethod ? 64 : (_inFunc ? 32 : 0);
                            _markdown += string("<div style=\"margin-left: {0}px;\">\n", _indentAmount);
							_markdown += "\n```gml\n";			
							_inCodeBlock = true;
							_tableStarted = false;
							_inTextBlock = false;
							_inTable = false;
						break;
					
						case "@param":
						case "@parameter":
						case "@arg":
						case "@argument":
							if (_inFunc && __previousTagIsCompatible(_tagType, _previousTag)){
                                if (_inDesc || _inTextBlock){
                                    _markdown += "\n</div> \n\n";	
                                }
                                
                                _inDesc = false;
								_inTextBlock = false;
                                
								if (!_tableStarted){
                                    var _indentAmount = _inMethod ? 64 : 32;
                                    _markdown += string("<div style=\"margin-left: {0}px;\">\n", _indentAmount);
									_markdown += "\n| Parameter | Datatype  | Purpose |\n";
									_markdown += "|-----------|-----------|---------|\n";				
									_tableStarted = true;
									_inTable = true;
								}
						
								if (array_length(_splitString) < 3){
                                    __tomeTrace($"@param tags must include a dataType, name, and description \n    function/method with issue: {_currentInFunc}");
                                    break;
                                }
						
								var _paramDataTypeUntrimed = _splitString[1];
								var _paramDataType = string_delete(_paramDataTypeUntrimed, 1, 1);
								_paramDataType = string_delete(_paramDataType, string_pos("}", _paramDataType), 1);
								var _paramName = _splitString[2];
								var _paramInfo = string_replace(_tagContent, _splitString[1], "");
								_paramInfo = string_replace(_paramInfo, _splitString[2], "");
								_paramInfo = string_trim(_paramInfo);
						
								_markdown += string("|`{0}` |{1} |{2} |\n", _paramName, _paramDataType, _paramInfo);
							}
						break;
					
						case "@returns":
						case "@return":
							if (_inFunc){
                                if (_inTable || _inMethod || _inDesc || _inTextBlock){
                                    _markdown += "\n </div>\n"
                                }
                                
								_foundReturn = true;
								var _returnInfo = string_replace(_tagContent, _splitString[1], "");
								_returnInfo = string_trim(_returnInfo);	
						
								var _returnDataTypeUntrimed = _splitString[1];
								var _returnDataType = string_delete(_returnDataTypeUntrimed, 1, 1);
								_returnDataType = string_delete(_returnDataType, string_pos("}", _returnDataType), 1);
								_returnDataType = __tome_parse_data_type(_returnDataType);
						
								var _returnStyle = (_returnDataType == "undefined") ?  "`{0}`" : "*{0}*" ;
						
								_markdown = string_replace(_markdown, "{rv}", string(_returnStyle, _returnDataType));
						
								if (_returnInfo != ""){
                                    var _indentAmount = _inMethod ? 64 : 32;
                                    _markdown += string("<div style=\"margin-left: {0}px;\">\n", _indentAmount);
									_markdown += string("\n**Returns:** {0}\n", _returnInfo);
                                    _markdown += "</div>\n";
								}
							
								_inDesc = false;
                                _inTable = false;
							}
						break;
					
						case "@category":
							_category = _tagContent;
						break;
                    
                        //Unknown tag found
                        default:
                            if (_inDesc || _inTextBlock){
                                _markdown += "\n</div>\n";   
                            }
                        break;
					}
				}
			}else if (string_pos("///", _rawUneditedLineString) != 0){
				//Lines that start with "///" and there is no tag, but we are in a function, description, or text block, add the line to the markdown
				if (_inTextBlock){
					_markdown += _lineString;	
				}
				
				if (_inDesc){
					_markdown += _lineString + "\n";	
				}
				
				if (_inCodeBlock){
					_markdown += _lineString;	
				}
				
				if (_inTable){
					_markdown += "\n";	
				}
			}
		}else{
            //Line is completely blank
			if (!_foundReturn){
				_markdown = string_replace(_markdown, "{rv}", "`undefined`");		
			}
			
			if (_inCodeBlock){
				//_markdown += "```\n";	
			}
			
			if (_inTable){
				_markdown += "\n";	
			}
		}
    }

    file_text_close(_file);
    
    _markdown += "\n </div> <br>\n";
    
    return {
		markdown: _markdown,
		category: _category,
		title: _title
	}
    
    #endregion
    
    /// @desc Subfunction to make sure that a given tag should be parsed based on what the previous tag was.
    ///       For example, if a desc tag is found but the previous tag was not @method or @function, it is not valid
    function __previousTagIsCompatible(_tag, _previousTag){
        //sdbm($"Tag:{_tag}, PreviousTag:{_previousTag}");
        // I know this is scuffed, oh well 
        static compatibilityStruct =  {
            "@desc": [ // desc/description is compatible with the following previous tags, else it's not parsed
                "@slug",
                "@method",
                "@func",
                "@function"
            ],
            "@description": [
                "@slug",
                "@method",
                "@func",
                "@function"
            ],
            "@param": [
                "@slug",
                "@param",
                "@parameter",
                "@arg",
                "@argument",
                "@method",
                "@function",
                "@func",
                "@desc",
                "description"
            ],
            "@parameter": [
                "@slug",
                "@param",
                "@parameter",
                "@arg",
                "@argument",
                "@method",
                "@function",
                "@func",
                "@desc",
                "description"
            ],
            "@arg": [
                "@slug",
                "@param",
                "@parameter",
                "@arg",
                "@argument",
                "@method",
                "@function",
                "@func",
                "@desc",
                "description"
            ],
            "@argument": [
                "@slug",
                "@param",
                "@parameter",
                "@arg",
                "@argument",
                "@method",
                "@function",
                "@func",
                "@desc",
                "description"
            ]
        }
        
        var _compatible = false;
        var _compatibleTags = compatibilityStruct[$ _tag]
        
        // If current Tag is found
        if (_compatibleTags != undefined){
            _compatible = array_contains(_compatibleTags, _previousTag);
        }
        
        return _compatible;
    }
}

/// @desc Parses a markdown file and returns a struct containing the markdown text, title, and category. Unlike the script parser, this function only parses the tags @title and @category, all other text is just added to the markdown.
/// @param {string} _filePath The path to the file
/// @returns {struct} Struct containing the markdown text, title, and category
function __tome_parse_markdown(_filepath, _homepage = false){
	var _markdown = "";
    var _title = "";
    var _category = "";
    
    if (!_homepage){
        // Here we are looking specifically for the @title and @category tags
        // If a file with the same category and tag already exist, we want to load that file and append this new script's content to it
        var _titleAndCategoryStruct = __tome_get_file_title_and_category(_filepath);
        
    	_title = _titleAndCategoryStruct.title;
        _category = _titleAndCategoryStruct.category;
        
    	var _titleFound = (_title != "");
        var _categoryFound = (_category != "");
        
        // Stop trying to parse the script right away if a title for the page cannot be found
        if (!_titleFound){
            __tomeTrace($"No @title tag can be found for: {_filepath}", false, 2, false);
            return {
    			markdown: _markdown,
    			category: _category,
    			title: _title
    		};
        }
        
        if (!_categoryFound){
            _category = "none";
        }
        
        /// Now lets figure out if there is a page with the same title and category that has already been parsed
        var _titleAlreadyExistsInCategory = false;
        var _titleFilePath = "";
        var _categoryTitles = global.__tomeData.categories[$ _category];
        var _categoryAlreadyExists = _categoryTitles != undefined ? true : false;
        var _titleWithNoDashes = string_replace_all(_title, "-", " ");
        
        if (_categoryAlreadyExists){
            if (array_get_index(_categoryTitles, _titleWithNoDashes) != -1){
                _titleAlreadyExistsInCategory = true;
                var _categoryWithDashesInsteadOfSpaces = string_replace_all(_category, " ", "-");
                _titleFilePath = $"{__tome_file_get_final_doc_path()}{_categoryWithDashesInsteadOfSpaces}-{_title}.md";
                __tomeTrace($"The title: {_title} is already present in the category: {_category}, content for this script will be appended onto the existing .md file", true, 3, false); 
            }           
        }
        
        if (_titleAlreadyExistsInCategory){
            _title = _titleWithNoDashes;
            
            if (file_exists(_titleFilePath)){
                _markdown = __tome_file_text_read_all(_titleFilePath) + "\n </div> <br>\n"; // Add the existing content to the markdown string
            }
        }
    }
	
    var _file = file_text_open_read(_filepath);
    
    if (_file == -1) {
		__tomeTrace("Failed to open file: " + _filepath);
		return {
			markdown: _markdown,
			category: _category,
			title: _title
		};
	}
	
	while (!file_text_eof(_file)) {
		var _lineStringUntrimmed = file_text_readln(_file);
		
		if (string_starts_with(_lineStringUntrimmed, "///")){
			var _lineString = string_trim(_lineStringUntrimmed);
			_lineString = string_replace(_lineStringUntrimmed, "///", "");
			
			if (string_count("@", _lineString) > 0){
				var _splitString = string_split_ext(_lineString, [" ", "	"]);
				var _tagType = _splitString[1];
				var _tagContent = string_trim(string_replace(_lineString, _tagType, ""));
			
				switch(_tagType){
					case "@title":
                        if !(_titleAlreadyExistsInCategory){
							_markdown += "# " + _tagContent + "\n";		
							_title = _tagContent;
							_titleFound = true;
						}
					break;
					
					case "@category":
						if (!_categoryFound){
							_category = _tagContent;
						}else{
							//_markdown += _lineStringUntrimmed;	
						}
					break;
					
					case "@slug":
					case "@insert":
                        for (var _slugIndex = 0; _slugIndex < array_length(global.__tomeData.slugs); _slugIndex++){
							if (_tagContent == global.__tomeData.slugs[_slugIndex][0]){
								_markdown +=  "\n" + global.__tomeData.slugs[_slugIndex][1] + "\n";
							}
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
	
	file_text_close(_file);
	return {
		markdown: _markdown,
		category: _category,
		title: _title
	}
}

/// @desc Parses a markdown file and returns a struct containing the markdown text, title, and category. Unlike the script parser, this function only parses the tags @title and @category, all other text is just added to the markdown.
/// @param {string} _filePath The path to the file
/// @returns {undefined}
function __tome_parse_markdown_slug(_filePath){
	var _file = file_text_open_read(_filePath);
	var _inSlug = false;
	var _markdown = "";
	var _slugName = "";

	if (_file == -1) {
		__tomeTrace("Failed to open file: " + _filePath);
	}else{
		while (!file_text_eof(_file)) {
			var _lineStringUntrimmed = file_text_readln(_file);
		
			if (string_starts_with(_lineStringUntrimmed, "///")){
				var _lineString = string_trim(_lineStringUntrimmed);
				_lineString = string_replace(_lineStringUntrimmed, "///", "");
			
				if (string_count("@", _lineString) > 0){
					var _splitString = string_split_ext(_lineString, [" ", "	"]);
					var _tagType = _splitString[1];
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
						
						case "@ignore":
							_markdown += _tagContent + "\n";
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
	}
}

/// @desc If the game is ran from the IDE, this will return the file path to the game's project file with the ending "/"
function __tome_file_project_get_directory(){
	var _originalPath = filename_dir(GM_project_filename) + "\\";
	var _fixedPath = string_replace_all(_originalPath, "\\", "/");
	
	return string_trim(_fixedPath);
}

/// @desc Gets the title and category 
function __tome_get_file_title_and_category(_filePath){
    var _titleFound = false;
    var _categoryFound = false;
    var _title = "";
    var _category = "";
    
    var _file = file_text_open_read(_filePath);
    
    while (!file_text_eof(_file)){
        // This is a stupid way of getting the title in the format firstWord-secondWord-thirdWord
        var _lineString = file_text_readln(_file);
        var _lineStringWithSpacesAndTabsRemoved = string_replace_all(_lineString, " ", "-"); 
        var _lineStringWithSpacesAndTabsRemoved = string_replace_all(_lineStringWithSpacesAndTabsRemoved, "    ", ""); 
        var _lineStringWithSpacesAndTabsRemoved = string_replace_all(_lineStringWithSpacesAndTabsRemoved, "\n", ""); 
        var _lineStringWithSpacesAndTabsRemoved = string_replace_all(_lineStringWithSpacesAndTabsRemoved, "\r", ""); 
        
        if (string_pos("///-@title-", _lineStringWithSpacesAndTabsRemoved) != 0){
            _title = string_replace(_lineStringWithSpacesAndTabsRemoved, "///-@title-", ""); // Remove tag
            _titleFound = true;
            __tomeTrace($"Title: {_title} found", true, 2, false);
        }
        
        if (string_pos("///-@category-", _lineStringWithSpacesAndTabsRemoved) != 0){
            _category = string_replace(_lineStringWithSpacesAndTabsRemoved, "///-@category-", ""); // Remove tag
            _category = string_replace_all(_category, "-", " "); // Replace "-"s with " " because only the title cares about the "-"s 
            _categoryFound = true;
            __tomeTrace($"Category: {_category} found", true, 2, false);
        }
        
        if (_titleFound && _categoryFound){
            return {
                title: _title,
                category: _category
            }
        }
    }
    
    file_text_close(_file);
    
    return {
        title: _title,
        category: _category
    }
}

/// @desc Replaces instances of "|" with "*or*"(colored red
function __tome_parse_data_type(_dataTypeString){
	return string_replace_all(_dataTypeString, "|", " <span style=\"color: red;\"> *or* </span> ");	
}

/// @desc Gets the actual filepath within the repo where the .md files will be pushed
function  __tome_file_get_final_doc_path() { 
	return global.__tomeData.repoFilePath + global.__tomeData.latestDocsVersion + "/";
}

/// @desc Returns the file extension of the given file path
/// @param {string} _filePath The path to the file
/// @return {string} The file extension
function __tome_file_get_extension(_filePath){
	var _splitPath = string_split(_filePath, ".");
	return _splitPath[array_length(_splitPath) - 1];
}

/// @desc Loads a text file and reads its entire contents as a string
/// @param {string} filePath The path to the text file to read
function __tome_file_text_read_all(_filePath){
	var fileBuffer = buffer_load(_filePath);
	var _fileContents = buffer_read(fileBuffer, buffer_string);
	buffer_delete(fileBuffer);
	return _fileContents;
}

/// @desc Loads a binary file
/// @param {string} filePath The path to the binary file to read
function __tome_file_bin_read_all(_filePath){
	var fileBuffer = buffer_load(_filePath);
	return fileBuffer;
}

/// @desc Updates the config file with the given property name and value
/// @param {string} propertyName The name of the property to update
/// @param {any} propertyValue The value to set the property to
function __tome_file_update_config(_propertyName, _propertyValue){
	var _configFileContents = __tome_file_text_read_all(__tome_file_project_get_directory() +  "datafiles/Tome/config.js");
	// Remove the extra JS crap so we can parse it as JSON
	// This is dirty af and is a terrible solution but it works
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
	var _finalConfig = "const config = " + _updatedJson + ";";
	var _fileBuffer = buffer_create(0, buffer_grow, 1);
	//sdbm(_finalConfig);
	buffer_write(_fileBuffer, buffer_text, _finalConfig);
	buffer_save(_fileBuffer, __tome_file_project_get_directory() +  "datafiles/Tome/config.js");
	buffer_delete(_fileBuffer);
}

/// @desc Trims the starting whitespace of a string leaving a given amount of it 
/// @param {string} string The string to trim
/// @param {real} maxNumberOfWhitespace The maximum number of whitespace characters to leave
function __tome_string_trim_starting_whitespace(_string, _maxNumberOfWhitespace){
	var _stringInfoStruct = {
		startingWhitespaceCount: 0,
		startingWhitespaceEnded: false,
		positionOfFirstNonWhitespaceCharacter: 0,
		checkCurrentCharForWhitespace: function(_character, _position){
			if (!startingWhitespaceEnded){
				if (_character == " "){
					startingWhitespaceCount++;	
				}else{
					startingWhitespaceEnded = true;		
					positionOfFirstNonWhitespaceCharacter = _position;
				}
			}
		}	
	}
	
	string_foreach(_string, _stringInfoStruct.checkCurrentCharForWhitespace)	
	
	return string_copy(_string, clamp(_stringInfoStruct.positionOfFirstNonWhitespaceCharacter - _maxNumberOfWhitespace, 1, string_length(_string)), string_length(_string));
}

/// @desc Splits up words separated by any number of spaces or tabs
/// @param {string} string The string to split
function __tome_string_split_spaces_tabs(_string) {
    var _len = string_length(_string);
    var _words = [];
    var _word = "";
    var _index = 0;

    for (var i = 1; i <= _len; i++) {
        var c = string_char_at(_string, i);
        if (c != " " && c != "\t") {
            _word += c;
        } else {
            if (string_length(_word) > 0) {
                _words[_index] = _word;
                _index += 1;
                _word = "";
            }
            // Continue if the character is a space or tab
        }
    }

    // Add the last word if it's not empty
    if (string_length(_word) > 0) {
        _words[_index] = _word;
    }

    return _words;
}

/// @Desc Outputs a message to the console prefixed with "Tome:"
/// @param {string} text The message to display in the console
/// @param {string} [verboseOnly] Whether the message should only be displayed if `TOME_VERBOSE` is enabled or not
function __tomeTrace(_text, _verboseOnly = false, _indention = 0, _includePrefix = true){
    var _indentionString = "";
    var _tomePrefix = _includePrefix ? "Tome: " : "";
    
    repeat(_indention){
        _indentionString += "   ";
    }
    
    var _finalMessageString = _indentionString + $"{_tomePrefix}{_text}";
    
	if (_verboseOnly && TOME_VERBOSE){
		show_debug_message(_finalMessageString);	
	}
	
	if (!_verboseOnly){
		show_debug_message(_finalMessageString);			
	}
}

/// @desc Initializes the global struct that holds Tome's data(if it doesn't already exist)
function __tome_setup_data(){
    if (!variable_global_exists("__tomeData")){
        global.__tomeData = {
            repoFilePath: "",
            categories: {
                none: []
            },
            slugs: [],
            slugNoteFilePaths: [],
            filesToBeParsed: [],
            homepageContent: "Homepage",
            latestDocsVersion: "Latest-Version",
            navbarItems: [],
            additionalSidebarItems: [],
            docGenerationFailed: false,
            setupWarnings: []
        };
    }
}


