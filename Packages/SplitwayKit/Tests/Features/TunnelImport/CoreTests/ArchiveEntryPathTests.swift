import Testing
import TunnelImport

@Suite
struct ArchiveEntryPathTests {
    @Test(arguments: [
        ("Office.conf", "Office.conf"),
        ("Exported/2026/Prague.conf", "Prague.conf"),
        (#"Exported\Windows\Office.conf"#, "Office.conf"),
        ("OFFICE.CONF", "OFFICE.CONF"),
        ("Офис.conf", "Офис.conf"),
    ])
    func recognizesConfigurationFiles(path: String, fileName: String) {
        let entryPath = ArchiveEntryPath(path)

        #expect(entryPath.isConfigurationFile)
        #expect(entryPath.fileName == fileName)
    }

    @Test(arguments: [
        "__MACOSX/Exported/._Office.conf",
        "Exported/__MACOSX/Office.conf",
        "._Office.conf",
        ".hidden.conf",
        "Exported/.DS_Store",
        "README.txt",
        "Office.conf.bak",
        "Office.conf/",
        "",
    ])
    func skipsEverythingElse(path: String) {
        #expect(!ArchiveEntryPath(path).isConfigurationFile)
    }
}
