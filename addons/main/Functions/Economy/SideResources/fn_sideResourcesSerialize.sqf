params ["_treasury"];

createHashMapFromArray [
    ["balance", _treasury get "_balance"],
    ["reservations", _treasury get "_reservations"],
    ["ledger", _treasury get "_ledger"],
    ["transactionSequence", _treasury get "_transactionSequence"],
    ["lastIncome", _treasury get "_lastIncome"]
]
