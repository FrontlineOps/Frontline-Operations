class UI {
    file = "\z\flo\addons\main\Functions\UI";

    class uiRestoreMapFocus {};
    class uiWebAction {};
    class initClientUI { postInit = 1; };
    class initClientUIPreInit { preInit = 1; };

};

class UICapture {
    file = "\z\flo\addons\main\Functions\UI\CaptureUI";

    class captureUIHandleUiEvent {};
    class captureUIOnLoad {};
    class captureUIOnUnload {};
    class captureUIOpen {};
    class captureUIPreInit { preInit = 1; };
    class captureUIPublishPlayerState {};
    class captureUIRender {};
    class captureUIRequestState {};
    class captureUIRequestStateServer {};
    class captureUIResolvePlayerObjective {};
    class initCaptureUIEvents {};
};

class UISetup {
    file = "\z\flo\addons\main\Functions\UI\Setup";

    class shouldOpenFactionDialog {};
    class openFactionDialog {};
    class factionDialogOnLoad {};
    class factionDialogInitializeLayout {};
    class factionDialogOnUnload {};
    class factionDialogAddFactionItems {};
    class factionDialogAddItems {};
    class factionDialogBuildFactionHandle {};
    class factionDialogBuildGarrisonHandle {};
    class factionDialogBuildScalarHandle {};
    class factionDialogCreateObjectiveEdit {};
    class factionDialogCreateObjectiveGroupControls {};
    class factionDialogCreateObjectiveLabel {};
    class factionDialogCreateObjectiveSideControls {};
    class factionDialogFillCompositionDefaults {};
    class factionDialogGetSelection {};
    class factionDialogGetSelections {};
    class factionDialogJoinSelectionNames {};
    class factionDialogNormalizeMultiSelection {};
    class factionDialogPopulate {};
    class factionDialogSelectDefault {};
    class factionDialogShowCompositionTab {};
    class factionDialogStart {};
    class factionDialogReadConfig {};
    class factionDialogSelectStartPosition {};
    class factionDialogWaitForMission {};

    class factionDialogValidateFactionSelections {};
};

class OperationsUI {
    file = "\z\flo\addons\main\Functions\UI\Operations";

    class operationsBuildMapDrawData {};
    class operationsDrawMap {};
    class operationsFocusMap {};
    class operationsHandleMapClick {};
    class operationsHandleUiEvent {};
    class operationsInitClient {};
    class operationsOpenDialog {};
    class operationsPreInit { preInit = 1; };
    class operationsReceiveSnapshot {};
    class operationsRequestSnapshot {};
    class operationsSelectObjective {};
    class operationsShowGuide {};
    class operationsUpdateDialog {};

};

class DevelopmentUI {
    file = "\z\flo\addons\main\Functions\UI\Development";

    class developmentHandleUiEvent {};
    class developmentInitClient {};
    class developmentOpenDialog {};
    class developmentPreInit { preInit = 1; };
    class developmentReceiveSnapshot {};
    class developmentRequestSnapshot {};
    class developmentRequestSnapshotServer {};
    class developmentUpdateDialog {};
};

class SupportUI {
    file = "\z\flo\addons\main\Functions\UI\Support";

    class supportBuildSnapshot {};
    class supportDrawMap {};
    class supportFocusMap {};
    class supportHandleMapClick {};
    class supportHandleUiEvent {};
    class supportInitClient {};
    class supportOpenDialog {};
    class supportPreInit { preInit = 1; };
    class supportReceiveSnapshot {};
    class supportRequestSnapshot {};
    class supportRequestSnapshotServer {};
    class supportUpdateDialog {};

};
