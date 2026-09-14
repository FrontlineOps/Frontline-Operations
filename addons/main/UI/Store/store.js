(function () {
  var state = {
    categories: [],
    checkoutPending: false,
    currentCategory: "",
    items: [],
    cart: [],
    pendingAttachmentAdd: null,
    selectedItem: null,
    activeContainer: "auto",
    balance: 0,
    totalBalance: 0,
    committed: 0,
    throughput: 0,
    throughputMax: 0,
    query: "",
  };

  var MAX_CONCURRENT_TEXTURES = 6;
  var textureCache = {};
  var textureRequests = {};
  var queuedTexturePaths = [];
  var queuedTextureLookup = {};
  var visibleTexturePaths = {};
  var activeTextureRequests = 0;
  var textureObserver = null;
  var textureObserverRoot = null;
  var textureObservationTimer = 0;
  var messageTimer = 0;
  var pendingServerScrollRestore = null;
  var scrollContainerIds = [
    "categoryList",
    "itemList",
    "cartList",
    "attachmentList",
    "itemDetails",
  ];

  var containerLabels = {
    auto: "Equip",
    uniform: "Uniform",
    vest: "Vest",
    backpack: "Backpack",
  };

  var packableCategories = {
    uniforms: true,
    vests: true,
    headgear: true,
    facewear: true,
    ammo: true,
    mines: true,
    attachments: true,
    misc: true,
  };

  var vehicleCategories = {
    cars: true,
    armor: true,
    helis: true,
    planes: true,
    naval: true,
    static: true,
    other: true,
  };

  function send(event, data) {
    var payload = JSON.stringify({ event: event, data: data || {} });

    if (typeof A3API !== "undefined" && A3API.SendAlert) {
      A3API.SendAlert(payload);
    }
  }

  function node(id) {
    return document.getElementById(id);
  }

  function text(id, value) {
    var target = node(id);
    if (target) {
      target.textContent = value;
    }
  }

  function clear(target) {
    while (target.firstChild) {
      target.removeChild(target.firstChild);
    }
  }

  function focusedButtonIndex(root) {
    return Array.prototype.indexOf.call(root.querySelectorAll("button"), document.activeElement);
  }
  function restoreButtonFocus(root, index) {
    if (index < 0) return;
    var buttons = root.querySelectorAll("button");
    var target = buttons[Math.min(index, buttons.length - 1)] || node("itemSearch");
    target.focus({preventScroll:true});
  }

  function message(value, kind) {
    var target = node("message");

    if (messageTimer) {
      window.clearTimeout(messageTimer);
      messageTimer = 0;
    }

    target.textContent = value;
    target.className = "message" + (kind ? " " + kind : "");

    if (kind === "good") {
      messageTimer = window.setTimeout(function () {
        target.className = "message good dismiss";

        messageTimer = window.setTimeout(function () {
          target.textContent = "";
          target.className = "message idle";
          messageTimer = 0;
        }, 470);
      }, 1800);
    }
  }

  function groupDigits(value) {
    return String(value).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  }

  function formatMoney(value) {
    var number = Number(value);
    var raw;

    if (!isNaN(number)) {
      return "$" + groupDigits(Math.round(number));
    }

    raw = String(value || "0").replace(/^\$/, "");
    return "$" + raw;
  }

  function itemPrice(item) {
    if (typeof item.priceValue === "number") {
      return item.priceValue;
    }

    return item.price;
  }

  function empty(value) {
    var target = document.createElement("div");
    target.className = "empty";
    target.textContent = value;
    return target;
  }

  function isBrowserTextureSource(path) {
    var value = String(path || "")
      .replace(/^\s+|\s+$/g, "")
      .toLowerCase();
    return (
      value.indexOf("data:image/") === 0 ||
      value.indexOf("blob:") === 0 ||
      value.indexOf("http://") === 0 ||
      value.indexOf("https://") === 0
    );
  }

  function normalizeTexturePath(path) {
    var normalized = String(path || "").replace(/^\s+|\s+$/g, "");

    if (!normalized) {
      return "";
    }

    while (normalized.charAt(0) === "\\" || normalized.charAt(0) === "/") {
      normalized = normalized.slice(1);
    }

    if (!/\.[A-Za-z0-9]+$/.test(normalized)) {
      normalized += ".paa";
    }

    return normalized;
  }

  function drawTextureNode(target, source) {
    var symbol = target.getAttribute("data-symbol") || "";
    clear(target);

    if (source) {
      var image = document.createElement("img");
      image.className = "texture-img";
      image.alt = "";
      image.src = source;
      target.appendChild(image);
      return;
    }

    var fallback = document.createElement("div");
    fallback.className = "media-fallback";
    fallback.textContent = symbol;
    target.appendChild(fallback);

    var status = document.createElement("div");
    status.className = "media-status";
    status.textContent = target.getAttribute("data-texture-path")
      ? "Loading"
      : "No Image";
    target.appendChild(status);
  }

  function applyTextureToVisibleNodes(path, source) {
    var targets = document.querySelectorAll("[data-texture-path]");
    var i;

    for (i = 0; i < targets.length; i += 1) {
      if (targets[i].getAttribute("data-texture-path") === path) {
        drawTextureNode(targets[i], source);
      }
    }
  }

  function finishTextureRequest(path, source) {
    var textureSource = String(source || "").replace(/^\s+|\s+$/g, "");

    if (!isBrowserTextureSource(textureSource)) {
      textureSource = "";
    }

    textureCache[path] = textureSource;
    applyTextureToVisibleNodes(path, textureSource);
  }

  function completeTextureRequest(path) {
    activeTextureRequests = Math.max(0, activeTextureRequests - 1);
    delete textureRequests[path];
    pumpTextureQueue();
  }

  function startTextureRequest(path) {
    var result;

    activeTextureRequests += 1;
    textureRequests[path] = true;

    try {
      result = A3API.RequestTexture(path, 512);
    } catch (error) {
      finishTextureRequest(path, "");
      completeTextureRequest(path);
      return;
    }

    if (result && typeof result.then === "function") {
      result.then(
        function (resolvedPath) {
          finishTextureRequest(path, resolvedPath);
          completeTextureRequest(path);
        },
        function () {
          finishTextureRequest(path, "");
          completeTextureRequest(path);
        },
      );
    } else {
      finishTextureRequest(path, result);
      completeTextureRequest(path);
    }
  }

  function pumpTextureQueue() {
    if (
      typeof A3API === "undefined" ||
      typeof A3API.RequestTexture !== "function"
    ) {
      return;
    }

    while (
      activeTextureRequests < MAX_CONCURRENT_TEXTURES &&
      queuedTexturePaths.length > 0
    ) {
      var path = queuedTexturePaths.shift();

      delete queuedTextureLookup[path];

      if (!path || textureCache[path] !== undefined || textureRequests[path]) {
        continue;
      }

      startTextureRequest(path);
    }
  }

  function queueTextureRequest(path) {
    if (
      !path ||
      queuedTextureLookup[path] ||
      textureRequests[path] ||
      textureCache[path] !== undefined
    ) {
      return;
    }

    queuedTextureLookup[path] = true;
    queuedTexturePaths.push(path);
    pumpTextureQueue();
  }

  function markTextureVisible(path) {
    var normalized = normalizeTexturePath(path);

    if (!normalized || visibleTexturePaths[normalized]) {
      return;
    }

    visibleTexturePaths[normalized] = true;

    if (
      textureCache[normalized] === undefined &&
      !textureRequests[normalized]
    ) {
      queueTextureRequest(normalized);
    }
  }

  function ensureTextureObserver() {
    var currentRoot = node("itemList");

    if (typeof IntersectionObserver !== "function") {
      return null;
    }

    if (textureObserver && textureObserverRoot === currentRoot) {
      return textureObserver;
    }

    if (textureObserver) {
      textureObserver.disconnect();
    }

    textureObserverRoot = currentRoot;
    textureObserver = new IntersectionObserver(
      function (entries) {
        var i;

        for (i = 0; i < entries.length; i += 1) {
          if (!entries[i].isIntersecting) {
            continue;
          }

          markTextureVisible(
            entries[i].target.getAttribute("data-raw-texture"),
          );
          textureObserver.unobserve(entries[i].target);
        }
      },
      {
        root: currentRoot,
        rootMargin: "260px 0px",
        threshold: 0.01,
      },
    );

    return textureObserver;
  }

  function observeTextureTargets() {
    var targets = document.querySelectorAll("[data-raw-texture]");
    var observer = ensureTextureObserver();
    var i;

    for (i = 0; i < targets.length; i += 1) {
      if (targets[i].getAttribute("data-observed") === "1") {
        continue;
      }

      targets[i].setAttribute("data-observed", "1");

      if (!observer) {
        markTextureVisible(targets[i].getAttribute("data-raw-texture"));
      } else {
        observer.observe(targets[i]);
      }
    }
  }

  function scheduleTextureObservation() {
    if (textureObservationTimer) {
      return;
    }

    textureObservationTimer = window.setTimeout(function () {
      textureObservationTimer = 0;
      observeTextureTargets();
    }, 0);
  }

  function getTextureSource(path) {
    var normalized = normalizeTexturePath(path);

    if (!normalized) {
      return "";
    }

    if (isBrowserTextureSource(path)) {
      textureCache[normalized] = String(path).replace(/^\s+|\s+$/g, "");
      return textureCache[normalized];
    }

    if (textureCache[normalized] !== undefined) {
      return textureCache[normalized];
    }

    if (visibleTexturePaths[normalized]) {
      queueTextureRequest(normalized);
    }

    return "";
  }

  function canPack(item) {
    return item.entryKind === "gear" && !!packableCategories[item.category];
  }

  function isVehicle(item) {
    return item.entryKind === "vehicle" || !!vehicleCategories[item.category];
  }

  function includedAttachments(item) {
    if (
      !item ||
      !item.includedAttachments ||
      !item.includedAttachments.length
    ) {
      return [];
    }

    return item.includedAttachments;
  }

  function hasIncludedAttachments(item) {
    return (
      item.entryKind === "gear" &&
      (item.category === "primary" ||
        item.category === "secondary" ||
        item.category === "handgun") &&
      includedAttachments(item).length > 0
    );
  }

  function sameItem(left, right) {
    return (
      !!left &&
      !!right &&
      left.entryKind === right.entryKind &&
      String(left.className).toLowerCase() ===
        String(right.className).toLowerCase()
    );
  }

  function itemSymbol(item) {
    if (!item) {
      return "";
    }

    if (isVehicle(item)) {
      return "V";
    }

    switch (item.category) {
      case "primary":
        return "R";
      case "secondary":
        return "L";
      case "handgun":
        return "P";
      case "uniforms":
        return "U";
      case "vests":
        return "A";
      case "backpacks":
        return "B";
      case "headgear":
        return "H";
      case "facewear":
        return "F";
      case "attachments":
        return "+";
      case "ammo":
        return "M";
      case "mines":
        return "X";
      default:
        return "I";
    }
  }

  function scrollSnapshotFor(preserveScroll) {
    var snapshot = {};
    var hasSnapshot = false;
    var i;
    var target;

    if (preserveScroll && typeof preserveScroll === "object") {
      return preserveScroll;
    }

    if (!preserveScroll) {
      return null;
    }

    for (i = 0; i < scrollContainerIds.length; i += 1) {
      target = node(scrollContainerIds[i]);

      if (target) {
        snapshot[scrollContainerIds[i]] = target.scrollTop;
        hasSnapshot = true;
      }
    }

    snapshot.category = state.currentCategory;
    snapshot.query = state.query;

    return hasSnapshot ? snapshot : null;
  }

  function restoreScrollSnapshot(snapshot, onlyIds) {
    var i;
    var target;
    var id;
    var ids = onlyIds || scrollContainerIds;

    if (!snapshot) {
      return;
    }

    window.setTimeout(function () {
      for (i = 0; i < ids.length; i += 1) {
        id = ids[i];
        target = node(id);

        if (target && snapshot[id] !== undefined) {
          target.scrollTop = snapshot[id];
        }
      }
    }, 0);
  }

  function wheelDelta(event, target) {
    var delta = 0;

    if (typeof event.deltaY === "number" && event.deltaY !== 0) {
      delta = event.deltaY;

      if (event.deltaMode === 1) {
        delta *= 34;
      } else if (event.deltaMode === 2 && target) {
        delta *= target.clientHeight;
      }
    } else if (typeof event.wheelDelta === "number" && event.wheelDelta !== 0) {
      delta = -event.wheelDelta;
    } else if (typeof event.detail === "number" && event.detail !== 0) {
      delta = event.detail * 34;
    }

    return delta;
  }

  function scrollableForWheel(start, delta) {
    var target =
      start && start.nodeType === 1
        ? start
        : start
          ? start.parentElement
          : null;
    var style;
    var overflowY;
    var canScroll;
    var canScrollDirection;

    while (
      target &&
      target !== document.body &&
      target !== document.documentElement
    ) {
      style = window.getComputedStyle
        ? window.getComputedStyle(target)
        : target.currentStyle;
      overflowY = style ? style.overflowY : "";
      canScroll =
        (overflowY === "auto" || overflowY === "scroll") &&
        target.scrollHeight > target.clientHeight + 1;

      if (canScroll) {
        canScrollDirection =
          delta > 0
            ? target.scrollTop + target.clientHeight < target.scrollHeight - 1
            : target.scrollTop > 0;

        if (canScrollDirection) {
          return target;
        }
      }

      target = target.parentElement;
    }

    return null;
  }

  function routeWheelToScrollContainer(event) {
    var rawTarget = event.target || event.srcElement;
    var delta = wheelDelta(event, rawTarget);
    var target;

    if (delta === 0) {
      return;
    }

    target = scrollableForWheel(rawTarget, delta);

    if (!target) {
      return;
    }

    target.scrollTop += delta;

    if (event.preventDefault) {
      event.preventDefault();
    }

    if (event.stopPropagation) {
      event.stopPropagation();
    }

    event.cancelBubble = true;
    event.returnValue = false;
  }

  function installWheelScrollRouting() {
    document.addEventListener("wheel", routeWheelToScrollContainer, true);
    document.addEventListener("mousewheel", routeWheelToScrollContainer, true);
    document.addEventListener(
      "DOMMouseScroll",
      routeWheelToScrollContainer,
      true,
    );
  }

  function targetForLine(line) {
    if (normalizeContainer(line, line.container) !== "auto") {
      return "";
    }

    if (line.category === "uniforms") {
      return "uniform";
    }

    if (line.category === "vests") {
      return "vest";
    }

    if (line.category === "backpacks") {
      return "backpack";
    }

    return "";
  }

  function normalizeContainer(item, container) {
    if (item.entryKind !== "gear") {
      return "auto";
    }

    if (
      container === "uniform" ||
      container === "vest" ||
      container === "backpack"
    ) {
      return container;
    }

    return "auto";
  }

  function cartKey(item) {
    return (
      item.entryKind +
      ":" +
      String(item.className).toLowerCase() +
      ":" +
      normalizeContainer(item, item.container) +
      ":" +
      String(item.slot || "")
    );
  }

  function categoryLabel(category) {
    var label = category;
    var i;

    for (i = 0; i < state.categories.length; i += 1) {
      if (state.categories[i].id === category) {
        label = state.categories[i].label;
      }
    }

    return label;
  }

  function hasCategory(category) {
    var i;

    if (!category) {
      return false;
    }

    for (i = 0; i < state.categories.length; i += 1) {
      if (state.categories[i].id === category) {
        return true;
      }
    }

    return false;
  }

  function hydrateCategory(payload) {
    var category = state.currentCategory;

    if (
      pendingServerScrollRestore &&
      hasCategory(pendingServerScrollRestore.category)
    ) {
      category = pendingServerScrollRestore.category;
    }

    if (!hasCategory(category)) {
      category = payload.firstCategory || "";
    }

    if (!hasCategory(category) && state.categories.length > 0) {
      category = state.categories[0].id;
    }

    return category;
  }

  function lineSubtitle(line) {
    var parts = [categoryLabel(line.category)];

    if (canPack(line)) {
      parts.push(containerLabels[normalizeContainer(line, line.container)]);
    }

    return parts.join(" / ");
  }

  function previewTarget(item) {
    if (canPack(item)) {
      return containerLabels[state.activeContainer];
    }

    if (isVehicle(item)) {
      return "Base Spawn";
    }

    return "Equip";
  }

  function copyCartLine(line) {
    var quantity = typeof line.quantity === "number" ? line.quantity : 1;
    var priceValue = typeof line.priceValue === "number" ? line.priceValue : 0;

    return {
      className: line.className,
      name: line.name,
      entryKind: line.entryKind,
      category: line.category,
      priceValue: priceValue,
      throughputCost: line.throughputCost || 0,
      quantity: quantity,
      container: normalizeContainer(line, line.container),
      slot: typeof line.slot === "string" ? line.slot : "",
      source: typeof line.source === "string" ? line.source : "",
    };
  }

  function cartTotal() {
    var total = 0;
    var i;

    for (i = 0; i < state.cart.length; i += 1) {
      total += state.cart[i].priceValue * state.cart[i].quantity;
    }

    return total;
  }

  function cartQuantity() {
    var total = 0;
    var i;

    for (i = 0; i < state.cart.length; i += 1) {
      total += state.cart[i].quantity;
    }

    return total;
  }

  function cartVehicleQuantity() {
    var total = 0;
    var i;

    for (i = 0; i < state.cart.length; i += 1) {
      if (isVehicle(state.cart[i])) {
        total += state.cart[i].quantity;
      }
    }

    return total;
  }

  function updateSummary() {
    var total = cartTotal();
    var supplies = state.cart.reduce(function (sum, line) {
      return sum + (line.throughputCost || 0) * line.quantity;
    }, 0);
    text("cartSupply", groupDigits(supplies));
    node("checkoutButton").disabled =
      state.checkoutPending ||
      !state.cart.length ||
      total > state.balance ||
      supplies > state.throughput;
    node("checkoutButton").textContent = state.checkoutPending
      ? "Pending\u2026"
      : "Purchase";
    text(
      "checkoutReason",
      !state.cart.length
        ? ""
        : total > state.balance
          ? "Insufficient shared funds."
          : supplies > state.throughput
            ? "Insufficient local supplies."
            : "",
    );
    text("totalBalance", formatMoney(state.totalBalance));
    text("committed", formatMoney(state.committed));
    text("balance", formatMoney(state.balance));
    text(
      "throughput",
      groupDigits(state.throughput) + " / " + groupDigits(state.throughputMax),
    );
    text("cartSummary", String(cartQuantity()) + " / " + formatMoney(total));
    text("activeTarget", containerLabels[state.activeContainer]);
    text("itemCount", String(cartQuantity()));
    text("vehicleCount", String(cartVehicleQuantity()));

  }

  function applyResourcePayload(payload) {
    state.balance =
      typeof payload.balance === "number" ? payload.balance : state.balance;
    state.totalBalance =
      typeof payload.totalBalance === "number"
        ? payload.totalBalance
        : state.totalBalance;
    state.committed =
      typeof payload.committed === "number"
        ? payload.committed
        : state.committed;
    state.throughput =
      typeof payload.throughput === "number"
        ? payload.throughput
        : state.throughput;
    state.throughputMax =
      typeof payload.throughputMax === "number"
        ? payload.throughputMax
        : state.throughputMax;
  }

  function filteredItems() {
    var query = String(state.query || "")
      .replace(/^\s+|\s+$/g, "")
      .toLowerCase();

    if (!query) {
      return state.items.slice(0);
    }

    return state.items.filter(function (item) {
      return (
        String(item.name || "")
          .toLowerCase()
          .indexOf(query) >= 0 ||
        categoryLabel(item.category).toLowerCase().indexOf(query) >= 0
      );
    });
  }

  function renderTextureBox(item) {
    var box = document.createElement("div");
    var normalized = normalizeTexturePath(item.image || "");
    var source = getTextureSource(item.image || "");

    box.className = "card-media";
    box.setAttribute("data-symbol", itemSymbol(item));
    box.setAttribute("data-raw-texture", item.image || "");
    box.setAttribute("data-texture-path", normalized);
    drawTextureNode(box, source);

    return box;
  }

  function renderAttachmentMedia(attachment) {
    var box = document.createElement("div");
    var image = attachment.image || "";
    var normalized = normalizeTexturePath(image);
    var source = getTextureSource(image);

    box.className = "attachment-media";
    box.setAttribute("data-symbol", "+");
    box.setAttribute("data-raw-texture", image);
    box.setAttribute("data-texture-path", normalized);
    drawTextureNode(box, source);
    markTextureVisible(image);

    return box;
  }

  var attachmentReturnFocus = null;
  function hideAttachmentModal() {
    var modal = node("attachmentModal");

    state.pendingAttachmentAdd = null;

    if (modal) {
      modal.className = "modal-backdrop hidden";
      document.querySelector(".store-workspace").inert = false;
      document.querySelector(".footer").inert = false;
      var target = attachmentReturnFocus && attachmentReturnFocus.isConnected ? attachmentReturnFocus : node("itemSearch");
      target.focus({preventScroll:true});
      attachmentReturnFocus = null;
    }
  }

  function showAttachmentModal(item, container) {
    var modal = node("attachmentModal");
    var list = node("attachmentList");
    var attachments = includedAttachments(item);
    var i;

    state.pendingAttachmentAdd = {
      item: item,
      container: container,
    };

    text("attachmentWeaponName", item.name || "Weapon");
    text(
      "attachmentWeaponMeta",
      String(attachments.length) +
        " mounted attachment" +
        (attachments.length === 1 ? "" : "s") +
        " included with this weapon variant.",
    );
    text("attachmentWeaponPrice", formatMoney(itemPrice(item)));
    clear(list);

    for (i = 0; i < attachments.length; i += 1) {
      (function (attachment) {
        var row = document.createElement("div");
        var info = document.createElement("div");
        var slot = document.createElement("div");
        var name = document.createElement("div");

        row.className = "attachment-row";
        slot.className = "attachment-slot";
        name.className = "attachment-name";
        slot.textContent = attachment.slotName || "Attachment";
        name.textContent = attachment.name || "Mounted Item";

        info.appendChild(slot);
        info.appendChild(name);
        row.appendChild(renderAttachmentMedia(attachment));
        row.appendChild(info);
        list.appendChild(row);
      })(attachments[i]);
    }

    attachmentReturnFocus = document.activeElement;
    modal.className = "modal-backdrop";
    document.querySelector(".store-workspace").inert = true;
    document.querySelector(".footer").inert = true;
    modal.querySelector("button").focus();
  }

  function renderTargetButtons() {
    var target = node("targetRow");
    var focusIndex = focusedButtonIndex(target);
    var containers = ["auto", "uniform", "vest", "backpack"];
    var i;

    clear(target);

    for (i = 0; i < containers.length; i += 1) {
      (function (container) {
        var button = document.createElement("button");
        button.type = "button";
        button.className =
          "chip" + (container === state.activeContainer ? " selected" : "");
        button.title = containerLabels[container];
        button.setAttribute("aria-label", containerLabels[container]);
        button.setAttribute("aria-pressed", String(container === state.activeContainer));
        button.appendChild(categoryIcon({id: {auto:"recruits",uniform:"uniforms",vest:"vests",backpack:"backpacks"}[container], label:containerLabels[container]}));
        button.onclick = function () {
          FLOStore.selectTarget(container);
        };
        target.appendChild(button);
      })(containers[i]);
    }
    restoreButtonFocus(target, focusIndex);
  }

  function refreshStoreState() {
    renderTargetButtons();
    updateSummary();
  }

  var categoryIcons = {
    primary: "PrimaryWeapon", handgun: "Handgun", secondary: "SecondaryWeapon",
    uniforms: "Uniform", vests: "Vest", headgear: "Headgear", facewear: "Goggles",
    backpacks: "Backpack", ammo: "CargoMagAll", mines: "CargoPut", misc: "CargoMisc",
    attachments: "ItemOptic", recruits: "Face"
  };
  var vehicleIcons = {
    cars: "iconCar", armor: "iconTank", helis: "iconHelicopter", planes: "iconPlane",
    naval: "iconShip", static: "iconStaticMG", other: "iconTruck", logistics: "iconCrate"
  };
  function categoryIcon(category) {
    var path = categoryIcons[category.id]
      ? "a3\\ui_f\\data\\GUI\\Rsc\\RscDisplayArsenal\\" + categoryIcons[category.id] + "_ca.paa"
      : "a3\\ui_f\\data\\map\\vehicleicons\\" + (vehicleIcons[category.id] || "iconObject") + "_ca.paa";
    var icon = document.createElement("span");
    icon.className = "category-icon";
    icon.setAttribute("aria-hidden", "true");
    icon.setAttribute("data-symbol", category.label.slice(0, 2));
    icon.setAttribute("data-texture-path", normalizeTexturePath(path));
    drawTextureNode(icon, getTextureSource(path));
    markTextureVisible(path);
    return icon;
  }

  function renderCategories(preserveScroll) {
    var list = node("categoryList");
    var focusIndex = focusedButtonIndex(list);
    var scrollSnapshot = scrollSnapshotFor(preserveScroll);
    var i;

    clear(list);

    if (state.categories.length === 0) {
      list.appendChild(empty("No categories."));
      restoreButtonFocus(list, focusIndex);
      restoreScrollSnapshot(scrollSnapshot, ["categoryList"]);
      return;
    }

    for (i = 0; i < state.categories.length; i += 1) {
      (function (category) {
        var button = document.createElement("button");

        button.type = "button";
        button.title = category.label;
        button.setAttribute("aria-label", category.label);
        button.setAttribute("aria-pressed", String(category.id === state.currentCategory));
        button.className =
          "category" +
          (category.id === state.currentCategory ? " selected" : "");
        button.onclick = function () {
          state.query = "";
          node("itemSearch").value = "";
          state.currentCategory = category.id;
          clearCategory();
          text("categoryTitle", category.label);
          renderCategories(true);
          send("store::category", { category: category.id });
        };

        button.appendChild(categoryIcon(category));
        list.appendChild(button);
      })(state.categories[i]);
    }

    restoreButtonFocus(list, focusIndex);
    restoreScrollSnapshot(scrollSnapshot, ["categoryList"]);
  }

  var previewKey = null;
  var previewStatus = "";
  function syncPreview() {
    var item = state.selectedItem;
    var key = item ? [item.className, item.category, item.entryKind].join("|") : "";
    if (key === previewKey) return;
    previewKey = key;
    send("store::preview", item ? {className:item.className, category:item.category, entryKind:item.entryKind} : {});
  }
  function renderDetails() {
    var panel = node("itemDetails");
    var item = state.selectedItem;
    clear(panel);
    var title = document.createElement("h2");
    title.textContent = item ? item.name : "";
    panel.appendChild(title);
    if (item) {
      var price = document.createElement("div");
      price.className = "detail-price";
      price.textContent = formatMoney(itemPrice(item));
      panel.appendChild(price);
      var meta = document.createElement("p");
      meta.textContent = "Supplies: " + groupDigits(Number(item.throughputCost || 0));
      panel.appendChild(meta);
      if (item.description || item.locked) {
        var description = document.createElement("p");
        description.textContent = item.locked ? item.lockReason || "Unavailable at this base" : item.description;
        panel.appendChild(description);
      }
      if (hasIncludedAttachments(item)) {
        var attachments = document.createElement("p");
        attachments.textContent = "Included: " + item.includedAttachments.map(function (entry) {return entry.name || entry.className;}).join(", ");
        panel.appendChild(attachments);
      }
      var actions = document.createElement("div");
      actions.className = "detail-actions";
      var add = document.createElement("button");
      add.className = "primary";
      add.textContent = item.locked ? "Unavailable" : "Add to cart";
      add.disabled = !!item.locked || state.checkoutPending;
      add.onclick = function () {
        if (hasIncludedAttachments(item)) showAttachmentModal(item, undefined);
        else FLOStore.add(item);
      };
      actions.appendChild(add);
      if (canPack(item) && !item.locked) {
        var pack = document.createElement("button");
        pack.textContent = "Pack in backpack";
        pack.disabled = state.checkoutPending;
        pack.onclick = function () { FLOStore.add(item, "backpack"); };
        actions.appendChild(pack);
      }
      panel.appendChild(actions);
    }
    var status = document.createElement("div");
    status.id = "previewStatus";
    status.setAttribute("role", "status");
    status.textContent = previewStatus;
    panel.appendChild(status);
    syncPreview();
  }
  function renderItems(preserveScroll) {
    var list = node("itemList");
    var focusIndex = focusedButtonIndex(list);
    var items = filteredItems();
    var scrollSnapshot = scrollSnapshotFor(preserveScroll);
    clear(list);
    if (!items.some(function (item) { return sameItem(item, state.selectedItem); })) state.selectedItem = items.length ? items[0] : null;
    if (!items.length) list.appendChild(empty(state.items.length ? "No matching equipment." : "No equipment in this category."));
    items.forEach(function (item) {
      var row = document.createElement("button");
      var selected = sameItem(item, state.selectedItem);
      row.type = "button";
      row.className = "armory-row" + (selected ? " selected" : "") + (item.locked ? " locked" : "");
      row.setAttribute("role", "option");
      row.setAttribute("aria-selected", String(selected));
      row.onclick = function () {
        state.selectedItem = item;
        Array.prototype.forEach.call(list.children, function (entry) {
          entry.classList.toggle("selected", entry === row);
          entry.setAttribute("aria-selected", String(entry === row));
        });
        renderDetails();
      };
      row.onkeydown = function (event) {
        if (event.key !== "ArrowDown" && event.key !== "ArrowUp") return;
        event.preventDefault();
        var next = event.key === "ArrowDown" ? row.nextElementSibling : row.previousElementSibling;
        if (next) {next.click(); var current = list.querySelector('[aria-selected="true"]'); current.focus(); current.scrollIntoView({block:"nearest"});}
      };
      row.appendChild(renderTextureBox(item));
      var copy = document.createElement("span"); copy.className = "item-copy";
      var name = document.createElement("span"); name.className = "item-name"; name.textContent = item.name;
      var price = document.createElement("span"); price.className = "item-price";
      price.textContent = item.locked ? "Unavailable" : formatMoney(itemPrice(item));
      copy.appendChild(name); copy.appendChild(price); row.appendChild(copy); list.appendChild(row);
    });
    renderDetails();
    scheduleTextureObservation();
    restoreButtonFocus(list, focusIndex);
    restoreScrollSnapshot(scrollSnapshot);
  }
  function clearCategory() {
    state.items = []; state.selectedItem = null;
    renderItems(false);
    node("itemList").textContent = "Loading equipment...";
  }
  function installPreviewControls() {
    var viewport = node("previewViewport");
    var drag = null, pendingX = 0, pendingY = 0, frame = 0;
    function flush() {
      frame = 0;
      if (pendingX || pendingY) FLOStore.previewControl({action:"orbit", x:pendingX, y:pendingY});
      pendingX = 0; pendingY = 0;
    }
    viewport.addEventListener("pointerdown", function (event) {
      if (event.button !== 0) return;
      drag = [event.clientX, event.clientY]; viewport.setPointerCapture(event.pointerId);
    });
    viewport.addEventListener("pointermove", function (event) {
      if (!drag) return;
      pendingX += (event.clientX-drag[0])*.5; pendingY += (event.clientY-drag[1])*.3;
      drag = [event.clientX,event.clientY];
      if (!frame) frame = window.requestAnimationFrame(flush);
    });
    viewport.addEventListener("pointerup", function () {drag = null;});
    viewport.addEventListener("pointercancel", function () {drag = null;});
    viewport.addEventListener("wheel", function (event) {
      event.preventDefault(); event.stopPropagation(); FLOStore.previewControl({action:"zoom",value:event.deltaY > 0 ? .1 : -.1});
    }, {passive:false});
    viewport.addEventListener("keydown", function (event) {
      var action = {ArrowLeft:{action:"orbit",x:-10,y:0},ArrowRight:{action:"orbit",x:10,y:0},ArrowUp:{action:"orbit",x:0,y:-5},ArrowDown:{action:"orbit",x:0,y:5},"+":{action:"zoom",value:-.1},"-":{action:"zoom",value:.1}}[event.key];
      if (action) {event.preventDefault(); FLOStore.previewControl(action);}
    });
    function resize() {
      var rect = viewport.getBoundingClientRect();
      FLOStore.previewControl({action:"viewport", rect:[rect.left/innerWidth,rect.top/innerHeight,rect.width/innerWidth,rect.height/innerHeight]});
    }
    new ResizeObserver(resize).observe(viewport);
    window.addEventListener("resize", resize);
    resize();
  }

  function renderContainerButtons(row, line) {
    var containers = ["auto", "uniform", "vest", "backpack"];
    var active;
    var holder;
    var i;

    if (!canPack(line)) {
      return;
    }

    active = normalizeContainer(line, line.container);
    holder = document.createElement("div");
    holder.className = "container-row";

    for (i = 0; i < containers.length; i += 1) {
      (function (container) {
        var button = document.createElement("button");
        button.type = "button";
        button.className = "chip" + (container === active ? " selected" : "");
        button.title = containerLabels[container];
        button.setAttribute("aria-label", containerLabels[container]);
        button.setAttribute("aria-pressed", String(container === active));
        button.textContent = containerLabels[container];
        button.onclick = function (event) {
          event.stopPropagation();
          FLOStore.setContainer(line, container);
        };
        holder.appendChild(button);
      })(containers[i]);
    }

    row.appendChild(holder);
  }

  function renderCart(preserveScroll) {
    var list = node("cartList");
    var focusIndex = focusedButtonIndex(list);
    var scrollSnapshot = scrollSnapshotFor(preserveScroll);
    var i;

    clear(list);

    if (state.cart.length === 0) {
      list.appendChild(empty("Cart is empty."));
      refreshStoreState();
      restoreButtonFocus(list, focusIndex);
      restoreScrollSnapshot(scrollSnapshot);
      return;
    }

    for (i = 0; i < state.cart.length; i += 1) {
      (function (line) {
        var row = document.createElement("div");
        var lineTarget = targetForLine(line);
        var info = document.createElement("div");
        var title = document.createElement("div");
        var name = document.createElement("div");
        var meta = document.createElement("div");
        var qty = document.createElement("div");
        var minus = document.createElement("button");
        var amount = document.createElement("span");
        var plus = document.createElement("button");

        row.className =
          "cart-line" +
          (lineTarget !== "" ? " targetable" : "") +
          (lineTarget !== "" && lineTarget === state.activeContainer
            ? " active-target"
            : "");

        if (lineTarget !== "") {
          row.onclick = function () {
            FLOStore.selectTarget(lineTarget);
          };
        }

        title.className = "line-title";
        name.className = "name";
        name.textContent = line.name;
        title.appendChild(name);

        meta.className = "meta";
        meta.textContent = lineSubtitle(line);

        info.appendChild(title);
        info.appendChild(meta);
        renderContainerButtons(info, line);

        if (lineTarget !== "") {
          var targetRow = document.createElement("div");
          var targetButton = document.createElement("button");
          targetRow.className = "container-row";
          targetButton.type = "button";
          targetButton.className =
            "chip" + (lineTarget === state.activeContainer ? " selected" : "");
          targetButton.textContent = "Target";
          targetButton.onclick = function (event) {
            event.stopPropagation();
            FLOStore.selectTarget(lineTarget);
          };
          targetRow.appendChild(targetButton);
          info.appendChild(targetRow);
        }

        qty.className = "qty";
        minus.type = "button";
        minus.textContent = "-";
        minus.onclick = function (event) {
          event.stopPropagation();
          FLOStore.adjust(line, -1);
        };

        amount.textContent = String(line.quantity);

        plus.type = "button";
        plus.textContent = "+";
        plus.onclick = function (event) {
          event.stopPropagation();
          FLOStore.adjust(line, 1);
        };

        qty.appendChild(minus);
        qty.appendChild(amount);
        qty.appendChild(plus);
        row.appendChild(info);
        row.appendChild(qty);
        list.appendChild(row);
      })(state.cart[i]);
    }

    refreshStoreState();
    restoreButtonFocus(list, focusIndex);
    restoreScrollSnapshot(scrollSnapshot);
  }

  window.FLOStore = {
    previewStatus: function (value) { previewStatus = value; text("previewStatus", value); },
    previewControl: function (data) {send("store::previewControl", data);},
    previewMode: function (mode) {
      node("characterMode").classList.toggle("active", mode === "character");
      node("equipmentMode").classList.toggle("active", mode === "equipment");
      FLOStore.previewControl({action:"mode",value:mode});
    },
    receive: function (event, payload) {
      if (event === "store::hydrate") {
        if (!payload.success) {
          message(payload.message || "Store unavailable.", "error");
          return;
        }

        state.categories = payload.categories || [];
        applyResourcePayload(payload);
        var nextCategory = hydrateCategory(payload);
        if (nextCategory !== state.currentCategory) {state.currentCategory = nextCategory; clearCategory();}
        updateSummary();
        renderCategories(pendingServerScrollRestore);
        renderCart(pendingServerScrollRestore);
        message("");

        if (state.currentCategory) {
          send("store::category", { category: state.currentCategory });
        }
      }

      if (event === "store::category") {
        if (payload.category !== state.currentCategory) {
          return;
        }
        if (!payload.success) {
          message(payload.message || "Category unavailable.", "error");
          return;
        }

        state.currentCategory = payload.category;
        state.items = payload.items || [];
        state.selectedItem = state.items.length > 0 ? state.items[0] : null;
        applyResourcePayload(payload);
        text("categoryTitle", payload.label || "Items");
        updateSummary();
        var scrollSnapshot = null;

        if (
          pendingServerScrollRestore &&
          pendingServerScrollRestore.category === payload.category
        ) {
          scrollSnapshot = pendingServerScrollRestore;
          pendingServerScrollRestore = null;
        }

        renderCategories(scrollSnapshot || true);
        renderItems(scrollSnapshot);
      }

      if (event === "store::checkout") {
        state.checkoutPending = false;
        if (payload.success) {
          state.cart = [];
          applyResourcePayload(payload);
          renderCart(true);
          message(payload.message || "Checkout complete.", "good");
        } else {
          pendingServerScrollRestore = null;
          applyResourcePayload(payload);
          updateSummary();
          message(payload.message || "Checkout failed.", "error");
        }
      }

      if (event === "store::kitLoaded") {
        if (payload.success && payload.kit) {
          FLOStore.loadKit(payload.kit);
        } else {
          message(payload.message || "Saved kit unavailable.", "error");
        }
      }
    },
    add: function (item, container) {
      if (state.checkoutPending) {
        return;
      }
      var target =
        typeof container === "string" ? container : state.activeContainer;
      var line = {
        className: item.className,
        name: item.name,
        entryKind: item.entryKind,
        category: item.category,
        priceValue: item.priceValue,
        throughputCost: item.throughputCost,
        quantity: 1,
        container: normalizeContainer(item, target),
      };
      var key = cartKey(line);
      var existing = null;
      var i;

      for (i = 0; i < state.cart.length; i += 1) {
        if (cartKey(state.cart[i]) === key) {
          existing = state.cart[i];
        }
      }

      if (existing) {
        existing.quantity += 1;
      } else {
        state.cart.push(line);
      }

      renderCart(true);
    },
    confirmAttachmentAdd: function () {
      var pending = state.pendingAttachmentAdd;
      var item;
      var container;

      if (!pending) {
        return;
      }

      item = pending.item;
      container = pending.container;
      hideAttachmentModal();
      FLOStore.add(item, container);
    },
    cancelAttachmentAdd: function () {
      hideAttachmentModal();
    },
    adjust: function (line, delta) {
      if (state.checkoutPending) {
        return;
      }
      line.quantity += delta;

      if (line.quantity <= 0) {
        state.cart = state.cart.filter(function (candidate) {
          return candidate !== line;
        });
      }

      renderCart(true);
    },
    setContainer: function (line, container) {
      if (state.checkoutPending) {
        return;
      }
      line.container = normalizeContainer(line, container);
      if (line.container !== "auto") {
        line.slot = "";
      }
      renderCart(true);
    },
    selectTarget: function (container) {
      state.activeContainer = container;
      renderCart(true);
      message("Target " + containerLabels[container] + ".", "good");
    },
    filter: function (value) {
      state.query = value || "";
      renderItems(false);
    },
    openKits: function () {
      if (state.checkoutPending) {
        return;
      }
      send("store::kitsOpen", {});
    },
    loadKit: function (kit) {
      if (state.checkoutPending) {
        return;
      }
      state.cart = [];

      (kit.items || []).forEach(function (line) {
        var copy = copyCartLine(line);
        copy.source = "savedKit";
        state.cart.push(copy);
      });

      renderCart(false);
      message(
        "Saved kit loaded. Checkout validates current faction availability.",
        "good",
      );
    },
    clearCart: function () {
      if (state.checkoutPending) {
        return;
      }
      state.cart = [];
      state.activeContainer = "auto";
      renderCart(true);
      message("Cart cleared.", "");
    },
    checkout: function () {
      if (state.checkoutPending) {
        return;
      }
      if (state.cart.length === 0) {
        message("Cart is empty.", "error");
        return;
      }

      pendingServerScrollRestore = scrollSnapshotFor(true);

      state.checkoutPending = true;
      updateSummary();
      send("store::checkout", {
        items: state.cart.map(function (line) {
          return {
            className: line.className,
            name: line.name,
            entryKind: line.entryKind,
            category: line.category,
            quantity: line.quantity,
            container: normalizeContainer(line, line.container),
            slot: typeof line.slot === "string" ? line.slot : "",
            source: typeof line.source === "string" ? line.source : "",
          };
        }),
      });
    },
    refresh: function () {
      send("store::refresh", {});
    },
    back: function () {
      var first = null;
      var i;

      for (i = 0; i < state.categories.length; i += 1) {
        if (state.categories[i].count > 0) {
          first = state.categories[i];
          break;
        }
      }

      if (!first && state.categories.length > 0) {
        first = state.categories[0];
      }

      state.query = "";
      node("itemSearch").value = "";

      if (first && first.id !== state.currentCategory) {
        state.currentCategory = first.id;
        clearCategory();
        text("categoryTitle", first.label);
        renderCategories(true);
        send("store::category", { category: first.id });
        return;
      }

      send("store::refresh", {});
      message("Refreshing store state.", "");
    },
    close: function () {
      send("store::close", {});
    },
  };

  function initialize() {
    installWheelScrollRouting();
    installPreviewControls();
    renderDetails();
    renderTargetButtons();
    updateSummary();
    send("store::ready", {});
  }
  if (document.readyState === "loading")
    document.addEventListener("DOMContentLoaded", initialize, { once: true });
  else initialize();

  window.addEventListener("keydown", function (event) {
    var modal = node("attachmentModal");

    if (!modal || modal.className.indexOf("hidden") >= 0) {
      return;
    }

    if (event.key === "Tab") {
      var buttons = modal.querySelectorAll("button:not(:disabled)");
      var first = buttons[0], last = buttons[buttons.length - 1];
      if (event.shiftKey && document.activeElement === first) {event.preventDefault(); last.focus();}
      else if (!event.shiftKey && document.activeElement === last) {event.preventDefault(); first.focus();}
    }
    if (event.key === "Escape" || event.key === "Esc") {
      event.preventDefault();
      hideAttachmentModal();
    }
  });
})();
