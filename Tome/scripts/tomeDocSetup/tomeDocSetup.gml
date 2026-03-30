// Place all of your Tome.site.* function calls inside of this function. 
function tomeSetup(){
    /*/
     * Set your site info here!
    /*/
    
    Tome.site.setName("Tome");
    
    Tome.site.setDescription("Documentation for the Tome library"); 
    Tome.site.setLatestVersion("1.0.0"); 
    Tome.site.setOlderVersions(["0.5.0", "0.4.0", "0.3.0", "0.2.0", "0.1.0"]);
    
    /*/
     * Set any theme data here!
     * Check out the tome docs as there is so much more that can be customized now.
    /*/ 
    #region CSS Overrides
    var cssOverrides = {
        __order: [
            ":root",
            ".version-dropdown-selected",
            ".version-dropdown-options",
            ".version-dropdown-options li",
            ".version-dropdown-options li:hover",
            ".version-dropdown-options li.version-active",
            ".sidebar .search input[type=\"search\"]:hover",
            ".sidebar .search input[type=\"search\"]:focus",
            ".sidebar-nav li a, .sidebar-nav li a code",
            ".sidebar-nav li a:hover, .sidebar-nav li a:hover code",
            ".sidebar-nav li.active > a, .sidebar-nav li.active > a code, .sidebar-nav li.active > a:hover, .sidebar-nav li.active > a:hover code",
            ".tome-type-separator"
        ],
        ":root": {
            __order: [
                "--base-background-color",
                "--sidebar-background",
                "--base-color",
                "--sidebar-nav-link-color--active",
                "--sidebar-nav-link-color--hover",
                "--search-background",
                "--search-input-background-color",
                "--search-input-border-color",
                "--search-input-color",
                "--search-input-placeholder-color",
                "--search-input-focus-border-color"
            ],
            "--base-background-color": "#202225",
            "--sidebar-background": "#18191c",
            "--base-color": "#cccccc",
            "--sidebar-nav-link-color--active": "#f5d342",
            "--sidebar-nav-link-color--hover": "#a37df0",
            "--search-background": "var(--sidebar-background)",
            "--search-input-background-color": "var(--base-background-color)",
            "--search-input-border-color": "#3a3f47",
            "--search-input-color": "var(--base---sidebar-nav-link-color--active)",
            "--search-input-placeholder-color": "#a0a5ab",
            "--search-input-focus-border-color": "var(--sidebar-nav-link-color--hover)"
        },
        ".version-dropdown-selected": {
            __order: [
                "color",
                "border-color",
                "background-color",
                "transition"
            ],
            "color": "var(--sidebar-nav-link-color--active)",
            "border-color": "var(--sidebar-nav-link-color--active)",
            "background-color": "var(--base-background-color)",
            "transition": "color 0.2s ease, border-color 0.2s ease"
        },
        ".version-dropdown-options": {
            __order: [
                "background-color",
                "border-color",
                "box-shadow"
            ],
            "background-color": "var(--sidebar-background)",
            "border-color": "#3a3f47",
            "box-shadow": "0 4px 12px rgba(0, 0, 0, 0.4)"
        },
        ".version-dropdown-options li": {
            __order: [
                "color",
                "background-color"
            ],
            "color": "#a0a5ab",
            "background-color": "var(--sidebar-background)"
        },
        ".version-dropdown-options li:hover": {
            __order: [
                "color",
                "background-color"
            ],
            "color": "var(--sidebar-nav-link-color--hover)",
            "background-color": "#000"
        },
        ".version-dropdown-options li.version-active": {
            __order: [
                "color"
            ],
            "color": "var(--sidebar-nav-link-color--active)"
        },
        ".sidebar .search input[type=\"search\"]:hover": {
            __order: [
                "box-shadow",
                "transition"
            ],
            "box-shadow": "0 0 0 1px var(--sidebar-nav-link-color--hover)",
            "transition": "border-color 0.2s ease, box-shadow 0.2s ease"
        },
        ".sidebar .search input[type=\"search\"]:focus": {
            __order: [
                "box-shadow",
                "transition"
            ],
            "box-shadow": "0 0 0 1px var(--sidebar-nav-link-color--active)",
            "transition": "border-color 0.2s ease, box-shadow 0.2s ease"
        },
        ".sidebar-nav li a, .sidebar-nav li a code": {
            __order: [
                "color",
                "transition",
                "strong"
            ],
            "color": "#a0a5ab" ,
            "transition": "color 0.2s ease",
            "strong": {
                __order: [
                    "font-size",
                    "color"
                ],
                "font-size": "inherit",
                "color": "inherit"
            }
        },
        ".sidebar-nav li a:hover, .sidebar-nav li a:hover code": {
            __order: [
                "color",
                "strong"
            ],
            "color": "var(--sidebar-nav-link-color--hover)",
            "strong": {
                __order: [
                    "font-size",
                    "color"
                ],
                "font-size": "inherit",
                "color": "inherit"
            }
        },
        ".sidebar-nav li.active > a, .sidebar-nav li.active > a code, .sidebar-nav li.active > a:hover, .sidebar-nav li.active > a:hover code": {
            __order: [
                "color",
                "font-weight",
                "strong"
            ],
            "color": "var(--sidebar-nav-link-color--active)",
            "font-weight": "600",
            "strong": {
                __order: [
                    "font-size",
                    "color"
                ],
                "font-size": "inherit",
                "color": "inherit"
            }
        },
        ".tome-type-separator": {
            __order: [
                "color"
            ],
            "color": "var(--sidebar-nav-link-color--active)"
        }
    };
    #endregion // CSS Overrides
    
    Tome.site.setThemeColor("#11DD11");

    Tome.site.editCustomCSS(cssOverrides);
    
    /*/
     * Add files and links you wish to make up the docs page sidebar here!
    /*/	
    
    Tome.site.setHomepage("nte_homepage");
    
     
    Tome.site.add("__tome"); 
    Tome.site.addRaw("nte_configuration", "Configuration", "API Reference");
    
    Tome.site.addRaw("nte_settingUp", "Setting Up Tome", "Getting Started"); 
    Tome.site.addRaw("nte_exampleSite", "Setting Up Your Site", "Getting Started"); 
    
    Tome.site.add("nte_formattingScripts", "nte_slugs"); 
    Tome.site.addRaw("nte_advancedUse", "Advanced Use", "Misc");
    
    /*/
     * Add any information you want added to the navbar here!
    /*/ 
    
    Tome.site.addNavbarLink("https://github.com/CataclysmicStudios/Tome/issues", "Report a bug"); 
    Tome.site.addNavbarLink("https://github.com/CataclysmicStudios/Tome/releases", "Releases");
     
}

