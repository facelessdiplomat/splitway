function run(argv) {
  const mode = argv[0];
  const names = argv.slice(1);
  const process = Application("System Events").processes.byName("Splitway");
  const window = process.windows[0];
  const outline = window.groups[0].splitterGroups[0].groups[0].scrollAreas[0].outlines[0];
  const label = row => { try { return row.uiElements[0].staticTexts[0].value(); } catch (error) { return ""; } };
  const report = [];
  outline.rows().find(row => label(row).startsWith("cz-prg")).selected = true;
  delay(2);
  window.toolbars[0].buttons().find(button => button.description() === "Edit Tunnel").click();
  delay(3);
  const editor = window.sheets[0];
  const routing = editor.groups[0].scrollAreas[0].groups[2];
  const popup = routing.popUpButtons[0];
  if (popup.value() !== mode) {
    popup.click();
    delay(1);
    popup.menus[0].menuItems.byName(mode).click();
    delay(2);
  }
  if (names.length > 0) {
    routing.buttons[0].click();
    delay(5);
    const picker = editor.sheets[0].groups[0];
    picker.radioGroups[0].radioButtons[0].click();
    delay(1);
    for (const name of names) {
      let rows = [];
      for (let attempt = 0; attempt < 6; attempt++) {
        try { picker.textFields[0].focused = true; } catch (error) {}
        picker.textFields[0].value = name;
        delay(1.5);
        rows = picker.scrollAreas[0].outlines[0].rows();
        if (rows.length > 0 && rows.length < 5) break;
      }
      report.push(`${name}: ${rows.length} rows`);
      if (rows.length === 0 || rows.length >= 5) continue;
      const checkbox = rows[0].uiElements[0].checkboxes[0];
      if (checkbox.value() === 0) {
        checkbox.click();
        delay(2);
      }
      report.push(`${name}: selected=${checkbox.value()}`);
    }
    picker.textFields[0].value = "";
    delay(1);
    picker.radioGroups[0].radioButtons[1].click();
    delay(2);
    report.push(`selected rows: ${picker.scrollAreas[0].outlines[0].rows().length}`);
    picker.buttons()[0].click();
    delay(2);
  }
  routing.staticTexts().forEach(text => report.push(`editor: ${text.value()}`));
  editor.groups[0].buttons()[1].click();
  delay(3);
  report.push(`sheets after save: ${window.sheets().length}`);
  outline.rows().forEach(row => report.push(`row: ${label(row)}`));
  return report.join("\n");
}
