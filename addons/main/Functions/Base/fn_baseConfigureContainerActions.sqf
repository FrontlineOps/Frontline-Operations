/*
 * Function: FLO_fnc_baseConfigureContainerActions
 * Author: Frontline Operations Development Group
 * Description:
 *   Configures FOB/COP terminal actions.
 *
 * Arguments:
 * 0: Building <OBJECT>
 * 1: Base config <HASHMAP>
 *
 * Returns: None
 */
params ["_building", "_config"];

private _type = _config get "type";
private _actionPrefix = _config get "actionPrefix";
private _containerType = missionNamespace getVariable [
    _config get "containerTypeVariable",
    _config get "containerFallbackType"
];

private _containers = nearestObjects [_building, [_containerType], _config get "containerSearchRadius"];
if (_containers isEqualTo []) exitWith {
    [_type, 2, _config get "containerMissingLog"] call FLO_fnc_log;
};

private _container = _containers select 0;
private _containerActions = if (_actionPrefix isEqualTo "FOB") then {
    private _commanderCondition = "(serverCommandAvailable '#kick') && (serverCommandAvailable '#debug')";
    [
        ["<img size=2 color='#7CC2FF' image='\z\flo\addons\main\Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Skip_Time", { createDialog 'C_LOCK'; }, nil, 4, true, true, "", _commanderCondition],
        ["<img size=2 color='#7CC2FF' image='\z\flo\addons\main\Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>Change_Weather", { [player] remoteExecCall ["FLO_fnc_randomizeWeather", 2]; }, nil, 4, true, true, "", _commanderCondition],
        ["<img size=2 color='#FFE496' image='\z\flo\addons\main\Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#FFE496'>SAVE Mission Progress", { [] remoteExec ["FLO_fnc_MissionSave", 2]; }, nil, 6, true, true, "", _commanderCondition],
        ["<img size=2 color='#59ff58' image='\z\flo\addons\main\Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#59ff58'>Bribe_Militia_(200)", { [player] remoteExecCall ["FLO_fnc_bribeMilitia", 2]; }, nil, 3, true, true, "", _commanderCondition],
        ["<img size=2 color='#7CC2FF' image='\z\flo\addons\main\Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>STORE", { params ["_target", "_caller", "_actionId", "_base"]; [_base] call FLO_fnc_storeOpenDialog; }, _building, 99999, true, true, "", "_this distance _target < 40"]
    ]
} else {
    [
        [
            "<img size=2 color='#7CC2FF' image='\z\flo\addons\main\Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>STORE",
            { params ["_target", "_caller", "_actionId", "_base"]; [_base] call FLO_fnc_storeOpenDialog; }, _building, 99999, true, true, "", "_this distance _target < 40"
        ],
        [
            "<img size=2 color='#FF0000' image='\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa'/><t font='PuristaBold' color='#FF0000'>Build Mode",
            { [player] call IDS_Logistics_fnc_initBuildCamera; },
            nil, 1.4, false, true, "", "!IDS_Logistics_isHolding"
        ]
    ]
};

try {
    [_container, format ["%1_CONTAINER", _actionPrefix], _containerActions] remoteExec [
        "FLO_fnc_configureObjectActionsLocal",
        0,
        format ["FLO_OBJ_ACT_%1_%2_CONTAINER", netId _container, _actionPrefix]
    ];
} catch {
    [_type, 1, format["Failed to configure container actions: %1", _exception]] call FLO_fnc_log;
};

[_type, 3, format["Added %1 container actions", count _containerActions]] call FLO_fnc_log;
