
#define DEBUG_DEV getNumber( missionConfigFile >> "LARs_spawnComp_debug" ) isEqualTo 2
#define DEBUG getNumber( missionConfigFile >> "LARs_spawnComp_debug" ) isEqualTo 1 || DEBUG_DEV
#define DEBUG_MSG(COND,MSG) if ( COND ) then { diag_log MSG }