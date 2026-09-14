(function () {
  "use strict";
  var U = FLOUI,
    snapshot = null,
    selectedId = "",
    received = 0,
    tab = "missions";
  var $ = function (id) {
    return document.getElementById(id);
  };
  function clear(id) {
    var n = $(id);
    n.textContent = "";
    return n;
  }
  function showTab(name) {
    tab = name;
    ["missions", "supply", "funds"].forEach(function (id) {
      $(id).hidden = id !== name;
    });
    document.querySelectorAll("[data-tab]").forEach(function (b) {
      b.classList.toggle("active", b.dataset.tab === name);
      b.setAttribute("aria-pressed", b.dataset.tab === name);
    });
  }
  function selectObjective(id, notify) {
    selectedId = id;
    showTab("missions");
    renderObjective();
    document.querySelectorAll("#operation-list button").forEach(function (b) {
      b.classList.toggle("selected", b.dataset.objectiveId === id);
      b.setAttribute("aria-pressed", b.dataset.objectiveId === id);
    });
    if (notify) U.send("operations::selectObjective", { objectiveId: id });
  }
  function renderObjective() {
    var node = clear("objective");
    if (!snapshot) return;
    var o = snapshot.objectives.find(function (v) {
      return v.id === selectedId;
    });
    if (!o) {
      node.appendChild(
        U.el("p", "empty", "Select a map objective or operation for details."),
      );
      return;
    }
    node.appendChild(U.el("h2", "", o.name));
    var c = U.el("div", "card");
    U.row(c, "Control", U.readable(o.owner));
    U.row(c, "Territory", U.readable(o.integrationState));
    U.row(c, "Friendly personnel", U.number(o.friendlyCount));
    U.row(
      c,
      "Reported enemy",
      o.enemyStrengthKnown ? "\u2248 " + U.number(o.enemyCount) : "Unknown",
    );
    if (o.enemyStrengthKnown)
      U.row(c, "Report confidence", Math.round(o.intelConfidence * 100) + "%");
    if (o.underAttack)
      c.appendChild(U.el("p", "warn", "Enemy activity reported here."));
    node.appendChild(c);
  }
  function renderOperations() {
    U.keepFocus(document.querySelector(".workspace"), function () {
      var list = clear("operation-list"),
        filter = $("filter").value;
      var operations = snapshot.operations.filter(function (o) {
        return (
          filter === "ALL" ||
          (filter === "DEFENSE"
            ? ["DEFEND", "GARRISON"].includes(o.kind)
            : o.kind === filter)
        );
      });
      if (!operations.length) {
        list.appendChild(
          U.el(
            "div",
            "empty",
            filter === "CAPTURE"
              ? "No offensive underway. " +
                  snapshot.operations.filter(function (o) {
                    return o.kind !== "CAPTURE";
                  }).length +
                  " defensive or support operations active."
              : "No operations in this category.",
          ),
        );
      }
      operations.forEach(function (o) {
        var card = U.button(
            "",
            function () {
              selectObjective(o.targetId, true);
            },
            "card",
          ),
          head = U.el("div", "operation-header");
        card.dataset.focusKey = "operation:" + o.id;
        card.dataset.objectiveId = o.targetId;
        card.classList.toggle("selected", o.targetId === selectedId);
        card.setAttribute("aria-pressed", o.targetId === selectedId);
        head.appendChild(U.el("strong", "", o.targetName));
        head.appendChild(U.el("span", "pill", U.readable(o.role)));
        card.appendChild(head);
        card.appendChild(U.el("p", "", o.status));
        var meta =
          o.attackerCount +
          " groups \u00b7 " +
          U.age(o.phaseSeconds) +
          " in this phase";
        if (o.transportedGroups)
          meta += " \u00b7 " + o.transportedGroups + " in transport";
        card.appendChild(U.el("small", "muted", meta));
        list.appendChild(card);
      });
      renderObjective();
    });
  }
  function renderSupply() {
    var nodes = clear("nodes");
    if (!snapshot.logistics.nodes.length)
      nodes.appendChild(
        U.el("p", "empty", "No friendly supply nodes available."),
      );
    snapshot.logistics.nodes.forEach(function (n) {
      var c = U.el("div", "card");
      c.appendChild(U.el("h3", "", n.objectiveName || "Grid " + n.grid));
      U.row(c, U.readable(n.type), U.readable(n.state));
      U.row(
        c,
        "Local supplies",
        U.number(n.throughput) + " / " + U.number(n.throughputMax),
      );
      if (["CONNECTED", "STRAINED"].includes(n.state))
        U.row(
          c,
          "Resupply",
          "+" +
            U.number(n.resupplyAmount) +
            " / " +
            U.age(n.resupplyIntervalSeconds),
        );
      else
        c.appendChild(
          U.el("p", "warn", "Resupply paused. Restore the supply connection."),
        );
      nodes.appendChild(c);
    });
    var enemy = clear("enemy-nodes");
    if (!snapshot.enemyLogisticsIntel.length)
      enemy.appendChild(U.el("p", "muted", "No current reports."));
    snapshot.enemyLogisticsIntel.forEach(function (n) {
      var c = U.el("div", "card");
      c.appendChild(
        U.el("strong", "", U.readable(n.type) + " \u00b7 Grid " + n.grid),
      );
      c.appendChild(
        U.el("p", "muted", "Report expires in " + U.age(n.remainingSeconds)),
      );
      enemy.appendChild(c);
    });
  }
  function renderFunds() {
    var e = snapshot.economy,
      p = e.commanderSpending,
      m = clear("money"),
      b = clear("budget");
    U.metric(m, "Available now", U.number(e.available));
    U.metric(m, "Already committed", U.number(e.committed));
    U.metric(m, "Income per minute", "+" + U.number(e.incomePerMinute));
    U.metric(m, "Total treasury", U.number(e.balance));
    U.row(b, "Commander posture", U.readable(p.posture));
    U.row(b, "Working capital", U.number(p.reserveFloor));
    U.row(b, "Next replacement batch", U.number(p.replacementFundingNeed));
    U.row(b, "Room for construction", U.number(p.developmentAvailable));
    renderSave();
  }
  function renderSave() {
    if (!snapshot) return;
    var s = snapshot.save,
      elapsed = (Date.now() - received) / 1000;
    var age =
      s.lastSuccessAge < 0
        ? "No successful save this session"
        : "Last saved " + U.age(s.lastSuccessAge + elapsed) + " ago";
    var active = ["SAVING", "QUEUED"].includes(s.phase);
    $("save-status").textContent =
      (active ? "Saving\u2026 \u00b7 " : s.phase === "FAILED" ? "Save failed \u00b7 " : "") +
      age;
    $("save-status").className =
      "save-line " + (s.phase === "FAILED" ? "bad" : "");
    var d = $("save-detail");
    d.textContent =
      age +
      ". " +
      (s.intervalMinutes
        ? "Autosave every " + s.intervalMinutes + " minutes."
        : "Autosave is disabled.") +
      (s.phase === "FAILED"
        ? " Check the server RPT for the rejected state or write failure."
        : active
          ? " The save worker is still running."
          : "");
    d.className = "notice " + (s.phase === "FAILED" ? "bad" : "");
    $("save-button").disabled = !snapshot.canSave || active;
    $("save-button").title = snapshot.canSave ? "" : "Only the host, single-player owner or a logged-in admin can save.";
    $("freshness").textContent =
      elapsed > 25
        ? "Report is stale \u00b7 Refresh to retry"
        : "Updated " + U.age(elapsed) + " ago";
  }
  function openGuide() {
    $("guide").hidden = false;
    document.querySelectorAll("body > header, body > main, body > footer").forEach(function (n) {
      n.inert = true;
    });
    U.send("operations::guideOpen");
    $("guide-done").focus();
  }
  function applySnapshot(next) {
    snapshot = next;
    received = Date.now();
    $("theater").textContent =
      next.viewerSideName +
      " \u00b7 " +
      next.summary.friendlyObjectives +
      " objectives";
    renderOperations();
    renderSupply();
    renderFunds();
    showTab(tab);
  }
  document.querySelectorAll("[data-tab]").forEach(function (b) {
    b.addEventListener("click", function () {
      showTab(b.dataset.tab);
      U.send("operations::mapFocus");
    });
  });
  document.querySelectorAll("[data-event]").forEach(function (b) {
    b.addEventListener("click", function () {
      U.send("operations::" + b.dataset.event);
    });
  });
  $("filter").addEventListener("change", function () {
    if (snapshot) renderOperations();
    U.send("operations::mapFocus");
  });
  $("development").onclick = function () {
    U.send("operations::developmentOpen");
  };
  $("help").onclick = openGuide;
  $("guide-done").onclick = function () {
    $("guide").hidden = true;
    document.querySelectorAll("body > header, body > main, body > footer").forEach(function (n) {
      n.inert = false;
    });
    $("help").focus();
    U.send("operations::guideComplete");
  };
  $("guide").addEventListener("keydown", function (e) {
    if (e.key === "Tab") {
      e.preventDefault();
      $("guide-done").focus();
    }
  });
  $("save-button").onclick = function () {
    this.disabled = true;
    U.send("operations::save");
  };
  var statusTimer = setInterval(renderSave, 1000),
    refreshTimer = setInterval(function () {
      U.send("operations::refresh");
    }, 10000);
  window.addEventListener("unload", function () {
    clearInterval(statusTimer);
    clearInterval(refreshTimer);
  });
  window.FLOOperations = {
    applySnapshot: applySnapshot,
    selectObjective: function (id) {
      selectObjective(id, false);
    },
    openGuide: openGuide,
  };
  U.send("operations::ready");
})();
