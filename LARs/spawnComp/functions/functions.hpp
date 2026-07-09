class LARs_spawnComp {
	tag = "LARs";
	class Compositions {
		file = "LARs\spawnComp\functions";
		class createComp{};
		class createLinks{};
		class customAttributes{};
		class deferLinks{};
		class getCfgValue{};
		class getCompPosition{};
		class getUnitInventory{};
		class setPositionAndRotation{};
		class sortCfgItems{};
		class spawnComp{};
		class spawnCompItems{};
		class spawnGroup{};
		class spawnLogic{};
		class spawnMarker{};
		class spawnObject{};
		class spawnTrigger{};
		class spawnWaypoint{};
	};

	class Utilitys {
		file = "LARs\spawnComp\functions\utility";
		//Utility funcs
		class deleteComp{};
		class getCompObjects{};
		class getCompItem{};
		class getItemComp{};
	};

	class Debug {
		file = "LARs\spawnComp\functions\debug";
		//Debug funcs
		class drawBounds{};
	};

};
