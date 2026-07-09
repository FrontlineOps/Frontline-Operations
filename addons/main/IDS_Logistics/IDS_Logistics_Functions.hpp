class IDS_Logistics {
    tag = "IDS_Logistics";
    class Functions {
        file = "IDS_Logistics\functions";

        class cameraHint {};
        class getEntityConfig {};
        class getEntityCategories {};
        class getEntitiesByCategory {};
        class initBuildCamera {};
        class initLogistics { preInit = 1; };
        class pickupEntity {};
        class placeEntity {};
        class startPlacement {};
        class testLoadEntities {};
        class updateEntityPlacement {};
    };

    class Server {
        file = "IDS_Logistics\functions\server";

        class finalizeEntity {};
        class loadEntities {};
        class onEntityKilled {};
        class saveEntities {};
        class toggleEntityVisibility {};
    };

    class UI {
        file = "IDS_Logistics\functions\ui";

        class handlePreview {};
        class openBuildMenu {};
        class searchEntities {};
        class selectEntity {};
        class updateEntityList {};
        class updatePreview {};
    };
};
