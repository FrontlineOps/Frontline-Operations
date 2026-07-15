/* Maps a virtual group archetype to its operational formation branch. */
params ["_groupData"];

if (_groupData get "transportRole") exitWith { "" };
if ((_groupData get "organicPackageRole") == "dismount") exitWith { "" };

switch (_groupData get "groupType") do {
    case "infantry": { "infantry" };
    case "motorized": { "motorized" };
    case "mechanized": { "mechanized" };
    case "armor": { "armor" };
    case "artillery": { "artillery" };
    case "static_aa": { "air_defense" };
    case "mobile_aa": { "air_defense" };
    case "helicopter": { "helicopter" };
    case "air": { "fixed_wing" };
    case "jet": { "fixed_wing" };
    default { "" };
}
