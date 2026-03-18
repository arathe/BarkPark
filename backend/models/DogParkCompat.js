/**
 * DogParkCompat — forwards to DogPark.
 *
 * Previously this held a dual-path implementation that could fall back to plain
 * lat/lng columns when PostGIS was not available. PostGIS is now required by
 * the schema (migration 001), so the fallback paths were dead code and the
 * non-PostGIS branch contained a bug (it tried to INSERT latitude/longitude as
 * standalone columns that no longer exist). Simplified to a direct re-export.
 */
module.exports = require('./DogPark');
