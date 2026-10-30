function run() {
  const process = Application("System Events").processes.byName("Splitway");
  const outline = process.windows[0].groups[0].splitterGroups[0].groups[0].scrollAreas[0].outlines[0];
  const label = row => { try { return row.uiElements[0].staticTexts[0].value(); } catch (error) { return ""; } };
  return outline.rows().map(label).join(" | ");
}
