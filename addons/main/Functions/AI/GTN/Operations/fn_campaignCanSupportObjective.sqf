/* Returns whether the side currently owns the objective and may defend/support it. */
params [
    ["_side", sideUnknown, [east]],
    ["_objectiveId", "", [""]]
];

if !(_objectiveId in FLO_Objectives) then {
    throw format ["FLO_fnc_campaignCanSupportObjective: missing objective %1", _objectiveId];
};
((FLO_Objectives get _objectiveId) get "owner") isEqualTo _side
