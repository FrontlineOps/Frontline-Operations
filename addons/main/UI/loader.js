/* Load packaged resources through Arma's virtual filesystem. Local previews use
   ordinary elements, so the same maintained CSS and JavaScript are exercised. */
window.FLOUILoad = async function (resources) {
  const root = "\\z\\flo\\addons\\main\\UI\\";
  const nativeFiles = window.A3API && typeof A3API.RequestFile === "function";
  for (const entry of resources) {
    const style = entry.endsWith(".css");
    const node = document.createElement(
      style ? (nativeFiles ? "style" : "link") : "script",
    );
    if (nativeFiles) {
      const content = await A3API.RequestFile(
        root + entry.replace(/\//g, "\\"),
      );
      if (!content.trim())
        throw new Error("Missing interface resource: " + entry);
      node.textContent = content;
      document.head.appendChild(node);
    } else {
      await new Promise((resolve, reject) => {
        node.onload = resolve;
        node.onerror = () => reject(new Error("Could not load " + entry));
        if (style) {
          node.rel = "stylesheet";
          node.href = "../" + entry;
        } else node.src = "../" + entry;
        document.head.appendChild(node);
      });
    }
  }
};
