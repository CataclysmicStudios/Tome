//Create the tome time source that will begin object to start tome generating
if (__TOME_CAN_RUN){

	global.__tomeInitTimeSource = time_source_create(time_source_global, 1, time_source_units_frames, __tome_init, [], 1);
    
	function __tome_init(){
        __tomeTrace($"Tome Enabled, Version: {TOME_VERSION}");

        __tomeTrace("Generating docs...", false, 1, true);
        
        __tome_generate_docs();
        
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
	}

	time_source_start(global.__tomeInitTimeSource);
}