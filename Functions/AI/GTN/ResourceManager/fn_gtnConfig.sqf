/*
 * Function: FLO_fnc_gtnConfig
 * Author: Frontline Operations Development Group
 * Description:
 * Returns the GTN Resource Manager configuration HashMap with all tunable parameters.
 * Centralizes magic numbers for easy adjustment and difficulty scaling.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Configuration HashMap <HASHMAP>
 *
 * Example:
 * private _config = call FLO_fnc_gtnConfig;
 */

if (!isNil "FLO_GTNConfig") exitWith { FLO_GTNConfig };

FLO_GTNConfig = createHashMapFromArray [
    // ===========================================
    // TIMING CONFIGURATION
    // ===========================================
    ["updateInterval", 60],              // Main loop interval (seconds)
    ["strategyInterval", 300],           // Strategic reassessment interval (5 min)
    ["artilleryMissionExpiry", 600],     // Artillery mission tracking expiry (10 min)
    ["airMissionExpiry", 900],           // Air mission tracking expiry (15 min)
    ["prepFiresExpiry", 300],            // Preparatory fires expiry (5 min)
    ["groupCacheExpiry", 30],            // Military groups cache refresh (seconds)

    // ===========================================
    // FORCE LIMITS
    // ===========================================
    ["maxDefendingGroups", 6],           // Max groups defending simultaneously
    ["minGarrisonGroups", 2],            // Minimum groups that must stay in garrison
    ["reserveRatio", 0.25],              // Fraction of forces kept in reserve
    ["maxAttackGroups", 16],             // Absolute cap on attacking groups

    // ===========================================
    // PLAYER SCALING
    // ===========================================
    ["minPlayersForAttack", 2],          // Minimum players before AI attacks
    ["playersPerAttackGroup", 2],        // Players needed per attack group
    ["aggressionGroupBonus", 4],         // Aggression score divisor for bonus groups

    // ===========================================
    // DISTANCE THRESHOLDS
    // ===========================================
    ["attackReturnDistance", 800],       // Distance from enemy to return from attack
    ["defenseReturnDistance", 1000],     // Distance from enemy to return from defense
    ["garrisonWaypointRadius", 10],      // Waypoint completion radius for garrison

    // ===========================================
    // FIRE SUPPORT PARAMETERS
    // ===========================================
    ["preparatoryFireRounds", 12],       // Rounds for preparatory artillery
    ["suppressiveFireRounds", 6],        // Rounds for suppressive fire
    ["counterBatteryRounds", 10],        // Rounds for counter-battery
    ["airPrepAltitude", 400],            // Altitude for preparatory air strikes
    ["casAltitude", 150],                // Altitude for CAS
    ["bombingAltitude", 300],            // Altitude for bombing runs
    ["capPatrolRadius", 2000],           // Radius for CAP patrol pattern

    // ===========================================
    // PRIORITY SCORING (for strategic reserve)
    // ===========================================
    ["priorityScoreArmor", 100],         // Strategic reserve priority for armor
    ["priorityScoreMechanized", 80],     // Priority for mechanized
    ["priorityScoreMotorized", 60],      // Priority for motorized
    ["priorityScoreHelicopter", 90],     // Priority for helicopters
    ["priorityScoreJet", 95],            // Priority for jets
    ["priorityScoreInfantry", 40],       // Priority for infantry

    // ===========================================
    // DEBUG
    // ===========================================
    ["debugEnabled", false],             // Enable debug markers and logging
    ["debugMarkerUpdateInterval", 30],   // Debug marker refresh rate

    // ===========================================
    // GTN (Goal Task Network) CONFIGURATION
    // ===========================================
    ["gtnUpdateInterval", 5],            // GTN update cycle interval (seconds)
    ["gtnReplanInterval", 60],           // Minimum time between replans (seconds)
    ["gtnCasualtyThreshold", 0.2],       // Force loss ratio to trigger replan (0-1)
    ["gtnAggressiveness", 0.5],          // Offensive vs defensive posture (0-1)
    ["gtnRiskTolerance", 0.5],           // Willingness to attack with lower ratios (0-1)
    ["gtnDebugMode", false]              // Enable verbose GTN logging
];

["GTN Config", 3, "Configuration loaded"] call FLO_fnc_log;

FLO_GTNConfig

