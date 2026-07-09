FLO_StoreDialogIdd = 9800;
FLO_StoreBrowserIdc = 9801;
FLO_StoreActiveBaseNetId = "";
FLO_StoreCatalogCache = createHashMap;
FLO_StorePlaceableMagazineCache = createHashMap;
FLO_StorePlaceableMagazineCacheReady = false;

FLO_StoreFOBDeployCost = 1500;
FLO_StoreCOPDeployCost = 600;

FLO_StoreCategories = [
    ["primary", "Primary"],
    ["handgun", "Handgun"],
    ["secondary", "Launchers"],
    ["uniforms", "Uniforms"],
    ["vests", "Vests"],
    ["headgear", "Headgear"],
    ["facewear", "Facewear"],
    ["backpacks", "Backpacks"],
    ["ammo", "Ammo"],
    ["mines", "Mines"],
    ["misc", "Items"],
    ["cars", "Cars"],
    ["armor", "Armor"],
    ["helis", "Helicopters"],
    ["planes", "Planes"],
    ["naval", "Naval"],
    ["static", "Statics"],
    ["other", "Other"],
    ["recruits", "Recruit AI"]
];

FLO_StoreCatalogCategories = FLO_StoreCategories + [
    ["attachments", "Attachments"]
];

FLO_StoreGearCategories = [
    "primary",
    "handgun",
    "secondary",
    "uniforms",
    "vests",
    "headgear",
    "facewear",
    "backpacks",
    "attachments",
    "ammo",
    "mines",
    "misc"
];

FLO_StoreVehicleCategories = [
    "cars",
    "armor",
    "helis",
    "planes",
    "naval",
    "static",
    "other"
];

FLO_StoreGearContainers = [
    "auto",
    "uniform",
    "vest",
    "backpack"
];

FLO_StoreFreeItemClasses = [
    "ace_earplugs",
    "ace_elasticbandage",
    "ace_fielddressing",
    "ace_packingbandage",
    "ace_quikclot",
    "ace_splint",
    "ace_tourniquet"
];
