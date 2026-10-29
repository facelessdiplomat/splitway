import Settings
import Testing

@Suite
struct ThirdPartyNoticeParagraphsTests {
    @Test
    func joinsWrappedLinesIntoParagraphs() {
        let notice = notice(text: "Copyright 2009 Authors.\n\nPermission is hereby\ngranted, free of\ncharge.\n")

        #expect(notice.paragraphs == ["Copyright 2009 Authors.", "Permission is hereby granted, free of charge."])
    }

    @Test
    func startsAParagraphAtEveryListItem() {
        let notice = notice(text: "are\nmet:\n\n   * Redistributions of source\nmust retain.\n   * Neither the name.\n")

        #expect(notice.paragraphs == ["are met:", "* Redistributions of source must retain.", "* Neither the name."])
    }

    @Test
    func skipsRepeatedAndTrailingBlankLines() {
        let notice = notice(text: "\nMIT License\n\n\n\nCopyright (c) 2017\n\n\n")

        #expect(notice.paragraphs == ["MIT License", "Copyright (c) 2017"])
    }

    private func notice(text: String) -> ThirdPartyNotice {
        ThirdPartyNotice(name: "Example", licenseName: "MIT", dependencies: [], text: text)
    }
}
