/* Returns the canonical persisted key for one side/objective probe front. */
params [
    ["_sideKey", "", [""]],
    ["_objectiveId", "", [""]]
];

_sideKey = toUpper _sideKey;
if !(_sideKey in ["WEST", "EAST"]) then {
    throw format ["Cannot build a probe ID for invalid side %1", _sideKey];
};
if (_objectiveId == "") then {
    throw "Cannot build a probe ID without an objective";
};

format ["PROBE_%1_%2", _sideKey, _objectiveId]
