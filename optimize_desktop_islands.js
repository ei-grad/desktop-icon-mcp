const { main, planLayout, mergePreferences, DEFAULT_CATALOG, MODE_PRESETS } = require("./src/planner.js");

if (require.main === module) main();

module.exports = { planLayout, mergePreferences, DEFAULT_CATALOG, MODE_PRESETS };
