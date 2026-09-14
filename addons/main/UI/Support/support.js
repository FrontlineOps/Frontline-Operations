(function () {
  "use strict";
  var U = FLOUI,
    snapshot = null,
    received = 0;
  var $ = function (id) {
    return document.getElementById(id);
  };
  function clear(id) {
    var n = $(id);
    n.textContent = "";
    return n;
  }
  function render() {
    U.keepFocus(document.querySelector(".workspace"), function () {
      var s = snapshot,
        p = s.packages.find(function (v) {
          return v.type === s.selectedType;
        });
      $("side-name").textContent =
        s.sideName;
      var packages = clear("packages");
      s.packages.forEach(function (item) {
        var b = U.button(
            item.type,
            function () {
              U.send("support::select", { type: item.type });
            },
            item.type === s.selectedType ? "active" : "",
          );
        b.dataset.focusKey = "package:" + item.type;
        b.setAttribute("aria-pressed", item.type === s.selectedType);
        b.title = item.name;
        packages.appendChild(b);
      });
      $("package-name").textContent = p.name;
      $("package-description").textContent = p.asset;
      var costs = clear("costs");
      U.row(costs, "Shared funds", p.treasury);
      U.row(costs, "Local supplies", p.supply);
      U.row(costs, "Ready assets", p.ready + " / " + p.total);
      $("safety").textContent = p.safety;
      $("target-grid").textContent = s.hasTarget
        ? "Grid " + s.targetGrid
        : "Click the map";
      var minimum = Number(String(p.treasury).split("-")[0].replace(/,/g, ""));
      var reason = !s.hasTarget
        ? "Choose a target first."
        : p.ready === 0
          ? "No ready asset. Open Assigned assets to see why."
          : s.available < minimum
            ? "Insufficient shared funds for this package."
            : "";
      var allowed = s.hasTarget && p.ready > 0 && s.available >= minimum;
      $("readiness").textContent = reason;
      $("readiness").hidden = allowed;
      $("readiness").className = "notice " + (allowed ? "" : "warn");
      $("request-button").disabled = !allowed;
      $("request-button").textContent = "Request " + p.name.toLowerCase();
      $("funds").textContent =
        "Available: " +
        U.number(s.available) +
        " \u00b7 Committed: " +
        U.number(s.committed);
      $("asset-summary").textContent = "Assigned assets \u00b7 " + p.ready + " ready";
      var assets = clear("assets");
      var rows = s.assets.filter(function (a) {
        return a.supports.includes(s.selectedType);
      });
      if (!rows.length)
        assets.appendChild(
          U.el("p", "empty", "No assigned assets of this type."),
        );
      rows.forEach(function (a) {
        var c = U.el("div", "card");
        c.appendChild(U.el("h3", "", a.displayName));
        c.appendChild(
          U.el(
            "p",
            a.available ? "good" : "muted",
            U.readable(a.status) + " \u00b7 " + U.readable(a.statusDetail),
          ),
        );
        c.appendChild(U.el("small", "muted", a.callSign + " \u00b7 " + a.location));
        assets.appendChild(c);
      });
    });
  }
  document.querySelectorAll("[data-event]").forEach(function (b) {
    b.onclick = function () {
      U.send("support::" + b.dataset.event);
    };
  });
  $("request-button").onclick = function () {
    this.disabled = true;
    U.send("support::submit");
  };
  window.FLOSupport = {
    applySnapshot: function (s) {
      snapshot = s;
      received = Date.now();
      $("freshness").textContent = "Updated just now";
      render();
    },
  };
  var refresh = setInterval(function () {
      U.send("support::refresh");
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
  U.send("support::ready");
})();
