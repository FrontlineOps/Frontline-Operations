/* Returns the runtime-only air-defense contact state. */
if (isNil "FLO_GTN_AirDefenseState") then {
    FLO_GTN_AirDefenseState = createHashMapFromArray [
        ["contactWorkerPfhId", -1],
        ["pairReadyAt", createHashMap],
        ["aaReadyAt", createHashMap],
        ["lastLiveContactAt", createHashMap],
        ["pairCooldownSeconds", 120],
        ["aaCooldownSeconds", 30],
        ["liveContactGraceSeconds", 90],
        ["staticDetectionRange", 12000],
        ["staticEngagementRange", 8000],
        ["mobileDetectionRange", 8000],
        ["mobileEngagementRange", 5000]
    ];
};

FLO_GTN_AirDefenseState
