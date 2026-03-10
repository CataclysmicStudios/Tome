/*/
 * Set your site info here!
/*/

//Set your site name first as this is what triggers tome to setup all data related to the site
tome_set_site_name("Tome");

//Then set the rest of your data in whatever order you see fit.
tome_set_site_description("Documentation for the Tome library");
tome_set_site_latest_version("01-29-2026");
tome_set_site_older_versions(["04-10-2025", "03-27-2025", "11-20-2024", "03-06-2024", "02-16-2024", "02-15-2024", "Beta-1"]);


/*/
 * Set any theme data here!
 * Check out the tome docs as there is so much more that can be customized now.
/*/ 
tome_set_site_theme_color("#11DD11");


/*/
 * Add files and links you wish to make up the docs page sidebar here!
/*/	

//tome_set_homepage_from_note("nte_homepage");

tome_add("__tome");
//tome_add("nte_settingUp");
//tome_add("nte_configuration");
//tome_add("nte_configuration");
//tome_add("nte_exampleSite");
//tome_add("nte_formattingScripts", "nte_slugs");
//tome_add("nte_advancedUse");
//
//tome_add_to_sidebar("Google", "Https://www.google.com", "API Reference");

tome_add("constructorTest", "constructorTestSlugs");

/*/
 * Add any information you want added to the navbar here!
/*/ 

tome_add_navbar_link("Report a bug", "https://github.com/CataclysmicStudios/Tome/issues");
tome_add_navbar_link("Releases", "https://github.com/CataclysmicStudios/Tome/releases");