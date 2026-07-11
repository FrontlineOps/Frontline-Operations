params [["_category", "", [""]]];

if (_category in FLO_StoreGearCategories) exitWith { "gear" };
switch (_category) do {
    case "recruits": { "recruits" };
    case "cars": { "cars" };
    case "armor": { "armor" };
    case "helis": { "helis" };
    case "planes": { "planes" };
    case "naval": { "naval" };
    case "static": { "static" };
    case "logistics": { "logistics" };
    case "other": { "cars" };
    default { throw format ["No logistics capability mapping for Store category %1", _category]; };
}
