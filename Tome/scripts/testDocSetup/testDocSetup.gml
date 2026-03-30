/// @title API Stress Test
/// @category Debugging
/// @desc Executes a series of intentionally malformed function calls to verify that all Tome warning systems are catching errors properly.

function ____tomeSetup() {
    
    // ==========================================
    // 0. Generation Warnings
    // ==========================================
    
    Tome.site.add("scr_test_warnings");


    // ==========================================
    // 1. Tome.site.add() Warnings
    // ==========================================
    
    // Warning: "The given file doesn't seem to exist as a script, note, or external file."
    Tome.site.add("this_script_does_not_exist_anywhere");

    // Warning: "The given slug file doesn't seem to exist as a note or external file"
    // (Requires a valid first file to get past the first check. Using the intro script we made earlier.)
    Tome.site.add("scr_test_intro", "this_slug_does_not_exist");

    // Warning: "Arguments received... Expected one for doc file, and optional string or array of strings for slug file(s)..."
    // (Passing a number or struct instead of a string/array for the slug parameter)
    Tome.site.add("scr_test_intro", 12345);
    Tome.site.add("scr_test_intro", { invalid: "data" });

    // Warning: "File has already been added to docs skipping."
    // (Successfully add it once, then immediately try to add it again)
    Tome.site.add("scr_test_intro"); 
    Tome.site.add("scr_test_intro"); 

    // Warning: "Something went wrong during parsing..."
    // Note: To hit this specific warning, you would need to pass a file that physically exists, 
    // but contains intentionally broken/malformed JSDoc tags that cause `__tomeParseDocumentationFile()` to return success: false.


    // ==========================================
    // 2. Tome.site.addRaw() Warnings
    // ==========================================

    // Warning: "title, category values are empty."
    Tome.site.addRaw("nte_internal_linking", "", "");
    Tome.site.addRaw("nte_internal_linking", "Linking", "");
    Tome.site.addRaw("nte_internal_linking", "", "Tests");

    // Warning: "The given file doesn't seem to exist."
    Tome.site.addRaw("fake_raw_markdown_file", "Valid Title", "Valid Category");

    // Warning: "File has already been added to docs skipping."
    Tome.site.addRaw("nte_internal_linking", "Linking", "Tests");
    Tome.site.addRaw("nte_internal_linking", "Linking", "Tests");


    // ==========================================
    // 3. Link Warnings
    // ==========================================

    // Warning: "link, title, category values are empty."
    Tome.site.addSidebarLink("", "", "");
    Tome.site.addSidebarLink("www.google.com", "", "");
    Tome.site.addSidebarLink("", "Goolge", "");
    Tome.site.addSidebarLink("", "", "Links");
    Tome.site.addSidebarLink("www.google.com", "Google", "");
    Tome.site.addSidebarLink("www.google.com", "", "Links");
    Tome.site.addSidebarLink("", "Goolge", "Links");


    // Warning: "link, title values are empty."
    Tome.site.addNavbarLink("", "");
    Tome.site.addNavbarLink("www.google.com", "");
    Tome.site.addNavbarLink("", "Google");


    // ==========================================
    // 4. Homepage Warnings
    // ==========================================

    // Warning: "The given file doesn't seem to exist."
    Tome.site.setHomepage("fake_homepage_file");
    
    // (To hit the parsing error here, you would again need a file that exists but fails the internal markdown parser).


    // ==========================================
    // 5. Config Warnings
    // ==========================================

    // Warning: "The version name contains spaces. Spaces have been replaced with hyphens."
    Tome.site.setLatestVersion("1.0 Beta");

    // Warning: "Expected an array of version strings, but received a string. This has been stringified and placed in an array"
    Tome.site.setOlderVersions("v0.9.5"); 
    // Let's also throw a struct at it to test the typeof() output
    Tome.site.setOlderVersions({ version: "0.8" });


    // ==========================================
    // 6. CSS Warnings
    // ==========================================

    // Warning: "Provided CSS data must be a string or a struct."
    Tome.site.editCustomCSS(999);
    Tome.site.editCustomCSS(["color", "red"]);

}