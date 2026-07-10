params ["_treasury"];

createHashMapFromArray [
    ["schemaVersion", 2],
    ["balance", _treasury get "_balance"],
    ["reservations", _treasury get "_reservations"],
    ["ledger", _treasury get "_ledger"],
    ["transactionSequence", _treasury get "_transactionSequence"],
    ["lastIncome", _treasury get "_lastIncome"],
    ["lastUpdate", _treasury get "_lastUpdate"]
]
