// _placement = _this select 0;
ctrlDelete (findDisplay 999 displayCtrl 1600);
ctrlDelete (findDisplay 999 displayCtrl 1955);
ctrlDelete (findDisplay 999 displayCtrl 1956);

(findDisplay 999) closeDisplay 1;

private _playerbox = findDisplay 999 displayCtrl 1955;
private _enemybox = findDisplay 999 displayCtrl 1956;
private _civilianbox = findDisplay 999 displayCtrl 1957;
private _Presencebox = findDisplay 999 displayCtrl 1958;
private _Resourcesbox = findDisplay 999 displayCtrl 1959;
private _Reputationbox = findDisplay 999 displayCtrl 1960;
private _Difficultybox = findDisplay 999 displayCtrl 1961;

private _PlayerfactionName = _playerbox lbText lbCurSel _playerbox;
private _EnemyfactionName = _enemybox lbText lbCurSel _enemybox;
private _CivilianfactionName = _civilianbox lbText lbCurSel _civilianbox;
private _PresenceName = _Presencebox lbText lbCurSel _Presencebox;
private _ResourcesName = _Resourcesbox lbText lbCurSel _Resourcesbox;
private _ReputationName = _Reputationbox lbText lbCurSel _Reputationbox;
private _DifficultyName = _Difficultybox lbText lbCurSel _Difficultybox;

if ((_PlayerfactionName isEqualTo "") || (_EnemyfactionName isEqualTo "") || (_CivilianfactionName isEqualTo "") || (_PresenceName isEqualTo "") || (_ResourcesName isEqualTo "") || (_ReputationName isEqualTo "") || (_DifficultyName isEqualTo "")) then {execVM "Scripts\MissionSetupMenu\Dialog_Faction.sqf";} else {

	hint "Done";

	// Reputation Handle
	private _reputationValue = switch (_ReputationName) do {
		case "LOW_Enemy to Guerillas": {2};
		case "MEDIUM_Neutral to Guerillas": {9};
		case "HIGH_Friendly to Guerillas": {16};
		default {0};
	};
	FLO_ReputationHandle = createHashMapFromArray [
		["value", _reputationValue],
		["name", _ReputationName]
	];
	publicVariable "FLO_ReputationHandle";

	// Difficulty Handle
	private _difficultyValue = switch (_DifficultyName) do {
		case "EASY _ Low Enemy Presence _ progressive": {0};
		case "NORMAL _ Half Enemy Presence _ progressive": {6};
		case "HARD _ Full Enemy Presence _ progressive": {11};
		default {0};
	};
	FLO_DifficultyHandle = createHashMapFromArray [
		["value", _difficultyValue],
		["name", _DifficultyName]
	];
	publicVariable "FLO_DifficultyHandle";

	// Money Handle
	FLO_MoneyHandle = createHashMapFromArray [
		["value", _ResourcesName],
		["name", _ResourcesName]
	];
	publicVariable "FLO_MoneyHandle";

	// Friendly Handle
	FLO_FriendlyHandle = createHashMapFromArray [
		["name", _PlayerfactionName]
	];
	publicVariable "FLO_FriendlyHandle";

	// Enemy Handle
	FLO_EnemyHandle = createHashMapFromArray [
		["name", _EnemyfactionName]
	];
	publicVariable "FLO_EnemyHandle";

	// Civilian Handle
	FLO_CivilianHandle = createHashMapFromArray [
		["name", _CivilianfactionName]
	];
	publicVariable "FLO_CivilianHandle";

	titleText ["", "BLACK IN",7, true, true];
			
	HQLOCC = 0;
	publicVariable "HQLOCC";
	hint "Choose Your Starting Point"; 
	openMap [true, true]; 
		
	FLO_mapClickDFD = addMissionEventHandler ["MapSingleClick", {
    	params ["_control", "_pos", "_alt", "_shift"];

		// Remove this event handler so it only triggers once
		removeMissionEventHandler ["MapSingleClick", FLO_mapClickDFD];

		player setpos _pos;
		TSAT setpos _pos;
		hintSilent "LOADING . . . "; 
		HQLOCC = 1;
		publicVariable "HQLOCC";

		titleText ["", "BLACK IN",999, true, true];
	}];

	waitUntil {HQLOCC == 1};
	openMap [true, false]; 
	openMap [false, false];


	private _FOBC = createVehicle ["B_Slingload_01_Cargo_F", (player getPos [random 10, random 360]), [], 0, "NONE"];
	_FOBC allowDammage false;


	switch (_PresenceName) do {
		case "10% _ Small Operation": {EnemyPrec = 7};
		case "30% _ Short Campaign": {EnemyPrec = 3};
		case "50% _ Medium Campaign": {EnemyPrec = 2};
		case "75% _ Long Campaign": {EnemyPrec = 1.5};
		case "100% _ Dedi Servers with HCs": {EnemyPrec = 1};
	};

	ZonMarkers = execVM "Scripts\Init\init_Markers.sqf";
	waitUntil { scriptDone ZonMarkers };

	StartingLocationDone = true;
	publicVariable "StartingLocationDone";

	// Initialize Virtualization System
	waitUntil {F_Init}; // Wait for faction initialization to complete
	["VIRTUALIZATION", 3, "Faction initialization complete, starting virtualization"] call FLO_fnc_log;

	// Initialize virtualization system on the server
	[OPFOR_Virtualization_Distance] remoteExec ["FLO_fnc_initVirtualization", 2];

	// Wait a moment for virtualization to initialize
	sleep 1;

	// Initialize objective groups on the server
	[] remoteExec ["FLO_fnc_initializeObjectiveGroups", 2];
};
sleep 2; 