(function () {
  "use strict";
  var U = FLOUI,
    snapshot = null,
    selected = "",
    received = 0;
  var $ = function (id) {
    return document.getElementById(id);
  };
  function clear(id) {
    var n = $(id);
    n.textContent = "";
    return n;
  }
  function projectState(p) {
    return (
      {
        FUNDING: "Waiting for funding",
        ACTIVE: "Under construction",
        PAUSED_COMBAT: "Paused by combat",
        BLOCKED_LOGISTICS: "Supply route blocked",
      }[p.state] || U.readable(p.state)
    );
  }
  function renderList() {
    U.keepFocus(document.querySelector("main"), function () {
      var list = clear("list"),
        query = $("search").value.toLowerCase(),
        filter = $("filter").value;
      var rows = snapshot.objectives.filter(function (o) {
        var p = o.development.project;
        return (
          (o.name + " " + o.grid).toLowerCase().includes(query) &&
          (filter === "all" ||
            (p.active && (filter !== "blocked" || p.state !== "ACTIVE")))
        );
      });
      if (!rows.length) {
        list.appendChild(
          U.el(
            "div",
            "empty",
            "No matching objectives. Try All friendly territory.",
          ),
        );
      }
      if (
        !rows.some(function (o) {
          return o.id === selected;
        })
      )
        selected = rows.length ? rows[0].id : "";
      rows.forEach(function (o) {
        var p = o.development.project,
          b = U.button(
            "",
            function () {
              selected = o.id;
              renderList();
            },
            "card list-entry" + (selected === o.id ? " selected" : ""),
          );
        b.dataset.focusKey = "objective:" + o.id;
        b.setAttribute("aria-pressed", selected === o.id);
        b.appendChild(U.el("h3", "", o.name));
        b.appendChild(
          U.el(
            "p",
            "muted",
            p.active
              ? projectState(p) + " \u00b7 " + p.progressPercent + "%"
              : "No current project \u00b7 Grid " + o.grid,
          ),
        );
        list.appendChild(b);
      });
      renderDetail();
    });
  }
  function renderDetail() {
    var node = clear("detail"),
      o = snapshot.objectives.find(function (v) {
        return v.id === selected;
      });
    if (!o) {
      node.appendChild(
        U.el(
          "p",
          "muted",
          "Choose an objective from the list or change the filter.",
        ),
      );
      return;
    }
    var d = o.development,
      p = d.project;
    node.appendChild(U.el("h1", "project-title", o.name));
    node.appendChild(U.el("p", "muted", U.readable(o.subtype) + " \u00b7 Grid " + o.grid));
    var metrics = U.el("div", "metrics");
    U.metric(metrics, "Revenue level", d.revenueLevel);
    U.metric(metrics, "Development level", d.developmentLevel);
    U.metric(
      metrics,
      "Current income / minute",
      "+" + U.number((d.incomePerCycle * 60) / snapshot.incomeIntervalSeconds),
    );
    U.metric(
      metrics,
      "Construction discount",
      Math.round(d.developmentDiscount * 100) + "%",
    );
    node.appendChild(metrics);
    if (p.active) {
      var card = U.el("section", "card");
      card.appendChild(U.el("h2", "", U.readable(p.targetName)));
      card.appendChild(
        U.el("p", p.state === "ACTIVE" ? "good" : "warn", projectState(p)),
      );
      var progress = U.el("progress", "project-progress");
      progress.max = 100;
      progress.value = p.progressPercent;
      progress.setAttribute("aria-label", projectState(p) + " progress");
      card.appendChild(progress);
      U.row(
        card,
        p.state === "FUNDING" ? "Funds reserved" : "Construction supplies",
        U.number(p.progressCurrent) + " / " + U.number(p.progressRequired),
      );
      if (p.state === "FUNDING")
        card.appendChild(
          U.el(
            "p",
            "muted",
            "Military replacements have funding priority.",
          ),
        );
      else if (p.state === "PAUSED_COMBAT")
        card.appendChild(
          U.el(
            "p",
            "warn",
            "Secure this objective so construction can resume.",
          ),
        );
      else if (p.state === "BLOCKED_LOGISTICS")
        card.appendChild(
          U.el(
            "p",
            "warn",
            "Restore a connected supply source to resume construction.",
          ),
        );
      else
        U.row(
          card,
          "Time at uninterrupted supply rate",
          U.age(p.estimatedRemainingSeconds),
        );
      U.row(card, "Supply source", p.sourceName);
      U.row(
        card,
        "Player supplies delivered",
        U.number(p.playerSupply) + " / " + U.number(p.playerSupplyCap),
      );
      var assign = U.button(
        "Assign nearby shipment",
        function () {
          assign.disabled = true;
          U.send("development::assignShipment", { objectiveId: o.id });
        },
        "primary",
      );
      assign.disabled = !p.canContribute;
      assign.dataset.focusKey = "shipment:" + o.id;
      card.appendChild(assign);
      card.appendChild(
        U.el(
          "p",
          "muted",
          p.canContribute
            ? "Within " +
                snapshot.assignmentRadius +
                " m of an unassigned shipment; deliver it here."
            : p.state === "FUNDING"
              ? "Shipments can be assigned after funding completes."
              : "This project cannot accept another full player shipment.",
        ),
      );
      node.appendChild(card);
    } else
      node.appendChild(
        U.el(
          "p",
          "notice",
          "No construction planned.",
        ),
      );
    var quotes = U.el("div", "quotes");
    [
      ["Revenue improvement", d.nextRevenueQuote],
      ["Development improvement", d.nextDevelopmentQuote],
    ].forEach(function (entry) {
      var q = entry[1],
        c = U.el("div", "card");
      c.appendChild(U.el("h3", "", entry[0] + " \u00b7 Level " + q.targetLevel));
      U.row(c, "Treasury quote", U.number(q.treasuryCost));
      U.row(c, "Supplies required", U.number(q.supplyRequired));
      if (q.branch === "REVENUE")
        U.row(
          c,
          "Additional income / minute",
          "+" + U.number((q.addedIncome * 60) / snapshot.incomeIntervalSeconds),
        );
      else
        U.row(
          c,
          "Resulting discount",
          Math.round(q.targetDevelopmentDiscount * 100) + "%",
        );
      quotes.appendChild(c);
    });
    node.appendChild(quotes);
  }
  window.FLODevelopment = {
    applySnapshot: function (s) {
      snapshot = s;
      received = Date.now();
      $("freshness").textContent = "Updated just now";
      $("summary").textContent = s.sideName + " \u00b7 " + s.activeCount + " / " + s.projectCapacity + " projects";
      $("summary").title = s.levelsToNextCapacity + " development levels to the next project slot";
      $("funds").textContent =
        "Available: " +
        U.number(s.economy.available) +
        " \u00b7 Room for construction: " +
        U.number(s.economy.commanderSpending.developmentAvailable);
      renderList();
    },
  };
  $("search").oninput = function () {
    if (snapshot) renderList();
  };
  $("filter").onchange = function () {
    if (snapshot) renderList();
  };
  document.querySelectorAll("[data-event]").forEach(function (b) {
    b.onclick = function () {
      U.send("development::" + b.dataset.event);
    };
  });
  var refresh = setInterval(function () {
      U.send("development::refresh");
    }, 10000),
    timer = setInterval(function () {
      if (received)
        $("freshness").textContent =
          Date.now() - received > 25000
            ? "Report is stale \u00b7 Refresh to retry"
            : "Updated " + U.age((Date.now() - received) / 1000) + " ago";
    }, 1000);
  window.addEventListener("unload", function () {
    clearInterval(refresh);
    clearInterval(timer);
  });
  U.send("development::ready");
})();
