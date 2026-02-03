//Create the tome controller object to start tome generating
if (__TOME_CAN_RUN){
	global.__tomeInitTimeSource = time_source_create(time_source_global, 1, time_source_units_frames, __tome_init, [], 1);

	function __tome_init(){
        __tomeTrace($"Tome Enabled, Version: {TOME_VERSION}");

        var _warningsFound = array_length(global.__tomeData.setupWarnings) > 0;
        
        if (_warningsFound){
            __tomeTrace("Warnings:", false, 1, true);
            
            var _i = 0;
            
            repeat(array_length(global.__tomeData.setupWarnings)){
                var _currentWarning = global.__tomeData.setupWarnings[_i];
                
                __tomeTrace(_currentWarning, false, 2, false);
                
                _i++;
            }
        }
        
        __tomeTrace("Generating docs...", false, 1, true);
        
        __tome_generate_docs();
        
        _warningsFound = array_length(global.__tomeData.generationWarnings) > 0;
        
        if (_warningsFound){
            __tomeTrace("Warnings:", false, 1, true);
            
            var _i = 0;
            
            repeat(array_length(global.__tomeData.generationWarnings)){
                var _currentWarning = global.__tomeData.generationWarnings[_i];
                
                __tomeTrace(_currentWarning, false, 2, false);
                
                _i++;
            }
        }
        
        
        var _finalMessage = global.__tomeData.docGenerationFailed ? "Doc generation failed: Please see warnings above.!\n" : "All docs generated!\n";
        __tomeTrace(_finalMessage);
        
        time_source_destroy(global.__tomeInitTimeSource);
	}

	time_source_start(global.__tomeInitTimeSource);
}