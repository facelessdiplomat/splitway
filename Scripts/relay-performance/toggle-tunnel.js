function run(argv) {
  const name = argv[0];
  const p = Application("System Events").processes.byName("Splitway");
  const rows = p.windows[0].groups[0].splitterGroups[0].groups[0].scrollAreas[0].outlines[0].rows();
  const label = r => { try { return r.uiElements[0].staticTexts[0].value(); } catch (e) { return ""; } };
  const row = rows.find(r => label(r).startsWith(name));
  row.uiElements[0].checkboxes[0].click();
  delay(Number(argv[1] || 6));
  return rows.map(label).join(" | ");
}
