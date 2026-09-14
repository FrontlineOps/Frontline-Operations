(function () {
  "use strict";
  var state = {
    kits: [], currentItems: [], selectedId: "", query: "",
    pending: "ready", pendingName: "", deleteArmedId: "", replaceArmedName: ""
  };
  function node(id) { return document.getElementById(id); }
  function send(event, data) {
    if (window.A3API && A3API.SendAlert) A3API.SendAlert(JSON.stringify({ event: event, data: data || {} }));
  }
  function message(text, tone) {
    node("message").textContent = text || "";
    node("message").className = tone || "";
  }
  function countLabel(items) {
    var count = items.reduce(function (sum, item) { return sum + item.quantity; }, 0);
    return count + (count === 1 ? " item" : " items");
  }
  function selectedKit() { return state.kits.find(function (kit) { return kit.id === state.selectedId; }); }
  function matchingName(name) { return state.kits.find(function (kit) { return kit.name.toLowerCase() === name.toLowerCase(); }); }
  function groupName(item) {
    var labels = {
      primary: "Primary weapon", handgun: "Handgun", secondary: "Launcher", assigned: "Assigned items",
      uniform: "Uniform", vest: "Vest", backpack: "Backpack", headgear: "Headgear", facewear: "Facewear", binocular: "Observation"
    };
    if (labels[item.slot]) return labels[item.slot];
    if (item.container && item.container !== "auto") return FLOUI.readable(item.container) + " contents";
    return FLOUI.readable(item.category);
  }
  function renderItems(items) {
    var target = node("detailList");
    target.textContent = "";
    if (!items.length) {
      var empty = document.createElement("p");
      empty.className = "empty";
      empty.textContent = "No equipment to save.";
      target.appendChild(empty);
      return;
    }
    var groups = new Map();
    items.forEach(function (item) {
      var label = groupName(item);
      if (!groups.has(label)) groups.set(label, []);
      groups.get(label).push(item);
    });
    groups.forEach(function (items, label) {
      var section = document.createElement("section");
      var heading = document.createElement("h3");
      section.className = "kit-group";
      heading.textContent = label;
      section.appendChild(heading);
      items.forEach(function (item) {
        var row = document.createElement("div");
        var name = document.createElement("span");
        var count = document.createElement("span");
        row.className = "kit-item";
        name.textContent = item.name;
        count.className = "item-qty";
        count.textContent = "\u00d7" + item.quantity;
        row.appendChild(name);
        row.appendChild(count);
        section.appendChild(row);
      });
      target.appendChild(section);
    });
  }
  function select(id) {
    state.selectedId = id;
    state.deleteArmedId = "";
    state.replaceArmedName = "";
    message("");
    render();
    node("detailList").scrollTop = 0;
  }
  function renderLibrary() {
    var target = node("kitList");
    target.textContent = "";
    var visible = state.kits.filter(function (kit) { return kit.name.toLowerCase().includes(state.query.toLowerCase()); });
    visible.forEach(function (kit) {
      var row = document.createElement("button");
      row.type = "button";
      row.className = "kit-row";
      row.dataset.focusKey = "kit:" + kit.id;
      row.setAttribute("aria-pressed", kit.id === state.selectedId);
      row.textContent = kit.name;
      row.disabled = !!state.pending;
      row.onclick = function () { select(kit.id); };
      target.appendChild(row);
    });
    if (!visible.length) {
      var empty = document.createElement("p");
      empty.className = "empty";
      empty.textContent = state.pending === "ready" ? "Loading loadouts..." : state.kits.length ? "No matching loadouts." : "No saved loadouts yet.";
      target.appendChild(empty);
    }
  }
  function render() {
    FLOUI.keepFocus(node("loadouts"), function () {
      var kit = selectedKit();
      var busy = !!state.pending;
      renderLibrary();
      node("currentButton").setAttribute("aria-pressed", !kit);
      node("detailTitle").textContent = kit ? kit.name : "Current equipment";
      node("detailCount").textContent = countLabel(kit ? kit.items : state.currentItems);
      renderItems(kit ? kit.items : state.currentItems);
      node("selectionActions").hidden = !kit;
      ["currentButton", "refreshButton", "kit-search", "kitName", "loadButton", "deleteButton"].forEach(function (id) { node(id).disabled = busy; });
      node("saveButton").disabled = busy || !state.currentItems.length;
      node("saveButton").textContent = state.pending === "save" ? "Saving..." : state.replaceArmedName ? "Replace loadout" : "Save loadout";
      node("loadButton").textContent = state.pending === "load" ? "Loading..." : "Load into cart";
      node("deleteButton").textContent = state.pending === "delete" ? "Deleting..." : state.deleteArmedId ? "Confirm delete" : "Delete";
      node("refreshButton").textContent = state.pending === "refresh" ? "Refreshing..." : "Refresh";
      node("loadouts").setAttribute("aria-busy", busy);
    });
  }
  function request(action, data) {
    state.pending = action;
    render();
    send("storeKits::" + action, data);
  }
  window.FLOKits = {
    receive: function (payload) {
      var action = state.pending;
      var oldId = state.selectedId;
      state.kits = payload.kits;
      state.currentItems = payload.currentItems;
      if (action === "save" && payload.success) {
        var saved = matchingName(state.pendingName);
        state.selectedId = saved ? saved.id : "";
        state.query = "";
        node("kit-search").value = "";
      }
      if (!selectedKit()) state.selectedId = "";
      state.pending = "";
      state.pendingName = "";
      state.deleteArmedId = "";
      state.replaceArmedName = "";
      render();
      message(payload.message, payload.success ? "good" : "error");
      if (action === "save" && payload.success) {
        var row = node("kitList").querySelector('[aria-pressed="true"]');
        if (row) { row.focus({ preventScroll: true }); row.scrollIntoView({ block: "nearest" }); }
      } else if (oldId && !state.selectedId) node("currentButton").focus({ preventScroll: true });
      else if (action === "ready") node("kitName").focus({ preventScroll: true });
    },
    current: function () { if (!state.pending) select(""); },
    filter: function (value) {
      if (state.pending) return;
      state.query = value;
      var kit = selectedKit();
      if (kit && !kit.name.toLowerCase().includes(value.toLowerCase())) select("");
      else FLOUI.keepFocus(node("loadouts"), renderLibrary);
    },
    nameChanged: function () {
      state.replaceArmedName = "";
      node("kitName").removeAttribute("aria-invalid");
      node("saveButton").textContent = "Save loadout";
      message("");
    },
    saveCurrent: function () {
      if (state.pending || !state.currentItems.length) return;
      var name = node("kitName").value.trim();
      if (!name || name.length > 40) {
        message(name ? "Use a name of 40 characters or fewer." : "Enter a name for this loadout.", "error");
        node("kitName").setAttribute("aria-invalid", "true");
        node("kitName").focus();
        return;
      }
      if (matchingName(name) && state.replaceArmedName !== name.toLowerCase()) {
        state.replaceArmedName = name.toLowerCase();
        state.deleteArmedId = "";
        render();
        message('Replace "' + matchingName(name).name + '" with your current equipment?', "warn");
        return;
      }
      state.pendingName = name;
      request("save", { name: name });
    },
    loadSelected: function () {
      var kit = selectedKit();
      if (kit && !state.pending) request("load", { id: kit.id });
    },
    removeSelected: function () {
      var kit = selectedKit();
      if (!kit || state.pending) return;
      if (state.deleteArmedId !== kit.id) {
        state.deleteArmedId = kit.id;
        state.replaceArmedName = "";
        render();
        message('Delete "' + kit.name + '"?', "warn");
        return;
      }
      request("delete", { id: kit.id });
    },
    refresh: function () { if (!state.pending) request("refresh"); },
    close: function () { send("storeKits::close"); }
  };
  function initialize() { render(); send("storeKits::ready"); }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", initialize, { once: true });
  else initialize();
})();
