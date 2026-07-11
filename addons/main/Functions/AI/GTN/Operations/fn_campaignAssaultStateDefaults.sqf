/* Returns the canonical persisted ASSAULT wave ledger defaults. */
createHashMapFromArray [
    ["assaultPackageTarget", 0],
    ["assaultActiveTarget", 0],
    ["assaultWaveSize", 0],
    ["assaultCommittedTotal", 0],
    ["assaultLosses", 0],
    ["assaultWaveSequence", 0],
    ["assaultNextWaveAtDateNum", -1],
    ["assaultPauseUntilDateNum", -1],
    ["assaultLastProgressAtDateNum", -1],
    ["assaultBestDistance", 1e12],
    ["assaultLastEnemyCount", -1],
    ["assaultLastArrivedCount", 0],
    ["assaultPauseCount", 0],
    ["assaultLastContested", false],
    ["assaultStatus", "PENDING"]
]
