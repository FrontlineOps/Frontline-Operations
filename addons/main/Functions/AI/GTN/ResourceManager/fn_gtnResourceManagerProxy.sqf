/*
 * Function: FLO_fnc_gtnResourceManagerProxy
 * Description:
 *   Builds the lightweight missionNamespace-facing GTN handle. It preserves
 *   the existing call shape while delegating every operation to the live
 *   uiNamespace manager so mission serialization cannot capture cyclic state.
 */

createHashMapObject [[
    ["_isProxy", true],

    ["_getCommanderBySide", {
        params [["_side", sideUnknown, [sideUnknown]]];
        [_side] call FLO_fnc_gtnGetCommanderBySide
    }],

    ["_getAllCommanders", {
        call FLO_fnc_gtnGetCommandersBySide
    }],

    ["_markCommanderDirty", {
        params [["_side", sideUnknown], ["_reason", "", [""]], ["_payload", [], [[]]]];
        private _manager = call FLO_fnc_gtnGetResourceManager;
        if (isNil "_manager") exitWith { false };
        _manager call ["_markCommanderDirty", [_side, _reason, _payload]]
    }],

    ["_onVirtualGroupRemoved", {
        params [["_groupId", "", [""]]];
        private _manager = call FLO_fnc_gtnGetResourceManager;
        if (isNil "_manager") exitWith {};
        _manager call ["_onVirtualGroupRemoved", [_groupId]];
    }],

    ["_initializeGTN", {
        private _manager = call FLO_fnc_gtnGetResourceManager;
        if (isNil "_manager") exitWith { false };
        _manager call ["_initializeGTN", []];
        true
    }]
]]
