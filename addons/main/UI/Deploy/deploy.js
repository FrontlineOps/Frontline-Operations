(function () {
  "use strict";
  var U = FLOUI,
    state = null,
    pending = false;
  var $ = function (id) {
    return document.getElementById(id);
  };
  function reason() {
    return !state.alive
      ? "Unavailable while dead."
      : !state.sideKey
        ? "Join BLUFOR or OPFOR to deploy a base."
        : !state.hasAuthority
          ? "An admin, officer or squad leader must request deployment."
          : state.onWater
            ? "Move onto dry land to deploy."
            : "";
  }
  function render() {
    var s = state,
      blocked = reason();
    $("position").textContent = s.sideName + " \u00b7 Grid " + s.grid;
    $("funds").textContent =
      "Available: " +
      U.number(s.balance) +
      " \u00b7 Committed: " +
      U.number(s.committed);
    $("role").textContent = s.authorityRole;
    $("fob-price").textContent = s.firstFOBFree
      ? "First FOB free"
      : U.number(s.fobCost) + " shared funds";
    $("cop-price").textContent = U.number(s.copCost) + " shared funds";
    ["fob", "cop"].forEach(function (type) {
      var details = $(type + "-details");
      details.textContent = "";
      U.row(details, "Build radius", s[type + "Radius"] + " m");
      U.row(details, "Minimum base spacing", s[type + "MinDistance"] + " m");
      if (type === "cop") U.row(details, "Side limit", s.copMaxPerSide);
      var failure =
        blocked ||
        (s.balance < s[type + "Cost"] ? "Insufficient shared funds." : "");
      $(type + "-reason").textContent = blocked ? "" : failure;
      $(type).disabled = !!failure || pending;
    });
    if (blocked && !pending) {
      $("status").textContent = blocked;
      $("status").className = "notice warn";
    } else if (!pending && $("status").dataset.result !== "true") {
      $("status").textContent = "";
      $("status").className = "notice";
    }
    $("status").hidden = !$("status").textContent;
  }
  function deploy(type) {
    if (
      !state ||
      pending ||
      reason() ||
      state.balance < state[type.toLowerCase() + "Cost"]
    )
      return;
    pending = true;
    $("status").textContent = "Requesting " + type + " deployment\u2026";
    $("status").dataset.result = "false";
    render();
    U.send("deploy::request" + type);
  }
  window.FLODeploy = {
    applySnapshot: function (s) {
      state = s;
      render();
    },
    receiveResult: function (r) {
      pending = false;
      $("status").textContent = r.message;
      $("status").className = "notice " + (r.success ? "good" : "bad");
      $("status").dataset.result = "true";
      if (state) render();
    },
  };
  $("fob").onclick = function () {
    deploy("FOB");
  };
  $("cop").onclick = function () {
    deploy("COP");
  };
  $("refresh").onclick = function () {
    U.send("deploy::refresh");
  };
  $("close").onclick = function () {
    U.send("deploy::close");
  };
  U.send("deploy::ready");
})();
