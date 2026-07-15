class IDS_Logistics {
    tag = "IDS_Logistics";
    class Functions {
        file = "\z\flo\addons\main\IDS_Logistics\functions";

        class cameraHint {};
        class getEntityConfig {};
        class getEntityCategories {};
        class getEntitiesByCategory {};
        class initBuildCamera {};
        class initLogistics { preInit = 1; };
        class pickupEntity {};
        class placeEntity {};
        class startPlacement {};
        class updateEntityPlacement {};
    };

    class Server {
        file = "\z\flo\addons\main\IDS_Logistics\functions\server";

        class finalizeEntity {};
        class onEntityKilled {};
        class toggleEntityVisibility {};
    };

    class UI {
        file = "\z\flo\addons\main\IDS_Logistics\functions\ui";

        class handlePreview {};
        class openBuildMenu {};
        class searchEntities {};
        class selectEntity {};
        class updateEntityList {};
        class updatePreview {};
    };
};
