function run(argv) {
  const title = argv[0];
  const process = Application("System Events").processes.byName("Splitway");
  const names = element => {
    const values = [];
    for (const read of [() => element.name(), () => element.title(), () => element.description()]) {
      try { values.push(read()); } catch (error) {}
    }
    return values;
  };
  const find = (element, depth) => {
    let children = [];
    try { children = element.uiElements(); } catch (error) { return null; }
    for (const child of children) {
      let role = "";
      try { role = child.role(); } catch (error) {}
      if (role === "AXButton" && names(child).includes(title)) return child;
    }
    if (depth === 0) return null;
    for (const child of children) {
      const found = find(child, depth - 1);
      if (found) return found;
    }
    return null;
  };
  const windows = process.windows();
  for (const window of windows) {
    const button = find(window, 5);
    if (button) {
      button.click();
      delay(2);
      return `pressed "${title}" in "${window.title()}"; windows: ${windows.map(w => w.title()).join(", ")}`;
    }
  }
  return `not found; windows: ${windows.map(w => w.title()).join(", ")}`;
}
