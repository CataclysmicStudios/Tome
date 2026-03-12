//Create the tome time source that will begin object to start tome generating
/* 
if (__TOME_CAN_RUN){

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