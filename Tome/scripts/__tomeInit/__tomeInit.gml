//Create the tome controller object to start tome generating
if (__TOME_CAN_RUN){
	global.__tomeInitTimeSource = time_source_create(time_source_global, 1, time_source_units_frames, __tome_init, [], 1);

	function __tome_init(){
        show_debug_message($"Tome Enabled, Version: {TOME_VERSION}");
        
        var _warningsFound = array_length(global.__tomeData.setupWarnings) > 0;
        
        if (_warningsFound){
            show_debug_message("   Warnings:");
            
            var _i = 0;
            
            repeat(array_length(global.__tomeData.setupWarnings)){
                var _currentWarning = global.__tomeData.setupWarnings[_i];
                show_debug_message($"        {_currentWarning}");
                _i++;
            }
        }
        
        show_debug_message("   Generating docs...");
        
        __tome_generate_docs();
        
        var _finalMessage = global.__tomeData.docGenerationFailed ? "Doc generation failed!\n" : "All docs generated!\n";
        __tomeTrace(_finalMessage);
        
        time_source_destroy(global.__tomeInitTimeSource);
	}

	time_source_start(global.__tomeInitTimeSource);
}