/* Shared presentation and Arma bridge; never render server strings as HTML. */
window.FLOUI = (function () {
  "use strict";
  function el(tag, className, text) {
    var n = document.createElement(tag);
    if (className) n.className = className;
    if (text !== undefined) n.textContent = String(text);
    return n;
  }
  function send(event, data) {
    if (window.A3API && typeof A3API.SendAlert === "function")
      A3API.SendAlert(JSON.stringify({ event: event, data: data || {} }));
  }
  function number(v) {
    return Math.round(Number(v) || 0).toLocaleString("en-US");
  }
  function readable(v) {
    return String(v || "Unknown")
      .toLowerCase()
      .replace(/_/g, " ")
      .replace(/^./, function (c) {
        return c.toUpperCase();
      });
  }
  function age(v) {
    return v < 60 ? Math.floor(v) + "s" : Math.floor(v / 60) + "m";
  }
  function row(parent, label, value) {
    var r = el("div", "row");
    r.appendChild(el("span", "", label));
    r.appendChild(el("strong", "", value));
    parent.appendChild(r);
    return r;
  }
  function metric(parent, label, value) {
    var m = el("div", "metric");
    m.appendChild(el("strong", "", value));
    m.appendChild(el("span", "", label));
    parent.appendChild(m);
  }
  function button(label, callback, className) {
    var b = el("button", className, label);
    b.type = "button";
    b.addEventListener("click", callback);
    return b;
  }
  // Live reports may replace rows while the player is using the keyboard.
  function keepFocus(root, render) {
    var active = document.activeElement;
    var key = root.contains(active) ? active.dataset.focusKey : null;
    var id = root.contains(active) ? active.id : "";
    var scrolls = Array.from(root.querySelectorAll(".scroll"), function (n) {
      return [n, n.scrollTop];
    });
    render();
    if (key || id) {
      var next = key
        ? Array.from(root.querySelectorAll("[data-focus-key]")).find(function (n) {
            return n.dataset.focusKey === key;
          })
        : document.getElementById(id);
      if (next && !next.disabled) next.focus({ preventScroll: true });
    }
    scrolls.forEach(function (entry) { entry[0].scrollTop = entry[1]; });
  }
  return {
    el: el,
    send: send,
    number: number,
    readable: readable,
    age: age,
    row: row,
    metric: metric,
    button: button,
    keepFocus: keepFocus,
  };
})();
