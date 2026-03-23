class Virtualization {
    file = "Functions\Virtualization";

    class initVirtualization              {};
    class activateVirtualGroup            {};
    class deactivateVirtualGroup          {};
    class createVirtualGroup              {};
    class updateVirtualGroupWaypoints     {};
    class initializeObjectiveGroups       {};
    class distributeVirtualGroups         {};
    class activateSavedVirtualGroup       {};
};

class VirtualizationTransport {
    file = "Functions\Virtualization\Transport";

    class transportConfig       {};
    class transportGetCapacity  {};
    class transportGetSpeed     {};
    class transportPool         {};
    class transportAttach       {};
    class transportDetach       {};
    class transportDetachAll    {};
    class transportRequest      {};
    class transportDismount     {};
    class transportMapEdge      {};
};

class VirtualizationCore {
    file = "Functions\Virtualization\Core";

    class virtualizationUpdatePFH       {};
    class virtualizationProcessGroup    {};
    class virtualizationAdvanceWaypoint {};
    class virtualizationSpatialIndex    {};
    class virtualizationEvents          {};
};

class VirtualizationState {
    file = "Functions\Virtualization\State";

    class virtualizationGetEffectiveState {};
    class virtualizationClearCommanderOrder {};
    class virtualizationSetCommanderOrder {};
    class virtualizationAssignMoveOrder {};
    class virtualizationAssignAttackOrder {};
    class virtualizationAssignDefendOrder {};
    class virtualizationAssignGarrisonOrder {};
    class virtualizationRefreshDefendLease {};
    class virtualizationSetMissionLock {};
    class virtualizationClearMissionLock {};
    class virtualizationSetExecutionState {};
    class virtualizationClearExecutionState {};
    class virtualizationSetRuntimeState {};
    class virtualizationSetRealGroup {};
    class virtualizationClearRealGroup {};
    class virtualizationSetAADeployState {};
    class virtualizationClearAADeployState {};
    class virtualizationGetAADeployState {};
    class virtualizationGetAATargetPos {};
    class virtualizationGetAATargetObjective {};
    class virtualizationSetPendingPathRequest {};
    class virtualizationClearPathRequest {};
    class virtualizationSetTransportAttachment {};
    class virtualizationClearTransportAttachment {};
    class virtualizationSetTransportPassengers {};
    class virtualizationAddTransportPassenger {};
    class virtualizationRemoveTransportPassenger {};
    class virtualizationGetTransportAttachment {};
    class virtualizationGetTransportPassengers {};
    class virtualizationIsTransportCarrier {};
    class virtualizationSetMountedIn {};
    class virtualizationClearMountedIn {};
    class virtualizationGetMountedTransport {};
    class virtualizationFinalizeReinforcement {};
    class virtualizationResumeSavedRoutes {};
    class virtualizationMarkReinforcementTransit {};
    class virtualizationMarkStaticAAReplacementTransit {};
    class virtualizationClearReplacementTransit {};
    class virtualizationSerializeGroup {};
    class virtualizationRestoreSavedGroup {};
};

class VirtualizationDebug {
    file = "Functions\Virtualization\Debug";

    class virtualizationDebugManager      {};
    class virtualizationProbe             {};
    class virtualizationDebugUpdateMarker {};
};

class VirtualizationUtilities {
    file = "Functions\Virtualization\Utilities";

    class filterNonCivGroups      {};
    class getGroupTypeCount       {};
    class getRoadParkingPos       {};
    class getSafeLandPos          {};
    class getSafeUnvirtualizePos  {};
    class virtualizationGetRealAssetVehicles {};
    class virtualizationUsesAssetStrength {};
    class validateGroupPosition   {};
    class setSide                 {};
};
