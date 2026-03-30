
#macro TEST_SECONDARY_COLOR c_blue

#macro TEST_USER_CUSTOM_CSS @"@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

.roulette-container {
    text-align: center;
    font-family: sans-serif;
    background-color: #0a0a0a;
    color: #00ffcc;
    padding: 20px;
    border-radius: 12px;
    box-shadow: 0 0 20px #00ffcc inset;
}

.roulette-title {
    text-transform: uppercase;
    text-shadow: 2px 2px 4px #ff00ff;
}

.roulette-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
    gap: 15px;
    margin-top: 20px;
    margin-bottom: 30px;
}

.roulette-btn {
    background-color: #ff00ff;
    color: #ffffff;
    border: none;
    padding: 12px 24px;
    font-size: 16px;
    font-weight: bold;
    text-transform: uppercase;
    border-radius: 8px;
    cursor: pointer;
    box-shadow: 0 4px 10px rgba(255, 0, 255, 0.4);
    transition: transform 0.1s, background-color 0.2s;
}

.roulette-btn:active {
    transform: scale(0.95);
}

.roulette-wrapper {
    position: relative;
    width: 100%;
    height: 180px;
    background-color: #111111;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 2px solid #222222;
}

.roulette-spinner {
    width: 40px;
    height: 40px;
    border: 4px solid #333333;
    border-top-color: #00ffcc;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
}

.roulette-image {
    width: 100%;
    height: 180px;
    object-fit: cover;
    border-radius: 8px;
    border: 2px solid #ff00ff;
    transition: transform 0.2s;
    position: absolute;
    top: 0;
    left: 0;
}

.roulette-image:hover {
    transform: scale(1.05);
}"

function __________tomeSetup(){
    // Initialize the site data - MUST BE FIRST
    Tome.site.setName("Tome Stress Test Suite");
    
    // General Configuration
    Tome.site.setDescription("A rigorous testing environment for Tome's JSDoc and Markdown parser.");
    Tome.site.setLatestVersion("2.1.0");
    Tome.site.setOlderVersions(["1.5.0", "1.0.0", "Alpha-Refactor"]);
    
    Tome.site.setConfigProperty("executeScript", "true");
    
    // Theme Data
    Tome.site.setThemeColor("#FF4500");
    
   Tome.site.editCustomCSS({
        ".tome-methods-header": {
            "background-color": Tome.utils.colorToCSSHex(TEST_SECONDARY_COLOR),
            "border-left": $"1px dashed {Tome.utils.colorToCSSHex($FFFFFF - TEST_SECONDARY_COLOR)}",
            "margin-left": "3.0em"
        }
    });
    
    Tome.site.editCustomCSS(TEST_USER_CUSTOM_CSS);
    
    // Homepage
    Tome.site.setHomepage("nte_demo_homepage", true);
    
    // Category: Getting Started
    Tome.site.add("scr_demo_intro", "nte_demo_slugs"); 
    
    // Category: Constants & Data
    Tome.site.add("scr_demo_enums_macros");
    
    // Category: Concatenation (Testing merging of contexts)
    Tome.site.addSidebarLink("https://www.google.com/search?q=concatenate", "What this means", "Concatenation");
    Tome.site.add("scr_demo_concat_part1");
    
    // Category: Object Orientation (Constructors & Methods)
    Tome.site.add("scr_demo_massive_constructor");
    Tome.site.add("scr_demo_network_client")
    Tome.site.add("scr_demo_multi_constructor");
    
    Tome.site.addRaw("nte_demo_html", "HTML Rendering Test", "Misc & Edge Cases");
    
    Tome.site.add("scr_demo_random");
    
    // Testing that files are properly categorized even if not grouped together in docSetup.
    Tome.site.addRaw("nte_demo_concat_bridge", "Merged Page", "Concatenation")
    Tome.site.add("scr_demo_deprecated");
    Tome.site.addSidebarLink("https://www.google.com/", "Another Link", "Concatenation"); // This should be placed below the concat file but we are placing it above to test this.
    Tome.site.add("scr_demo_mixed_types");
    Tome.site.add("scr_demo_concat_part2");
    Tome.site.addRaw("nte_demo_internal_linking", "Internal Linking", "Getting Started");
    
    
    // External Sidebar Links
    Tome.site.addSidebarLink("https://github.com/", "Source Code", "External");
    Tome.site.addSidebarLink("https://discord.com/", "Community Support", "External");
    
    // Navbar Links
    Tome.site.addNavbarLink("https://wiki.example.com", "Internal Wiki");
    Tome.site.addNavbarLink("https://github.com/issues", "Bug Tracker");
    
}