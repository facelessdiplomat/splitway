#!/usr/bin/env bash

release_notes_in_language() {
    local notes="$1"
    local language="$2"
    [[ -s "$notes" ]] || return 0
    case "$language" in
        en) awk '/^---$/ { exit } { print }' "$notes" ;;
        ru) awk 'found { print } /^## Русский$/ { found = 1 }' "$notes" ;;
    esac
}

write_release_notes_description() {
    local notes="$1"
    local language="$2"
    local language_attribute=""
    [[ -s "$notes" ]] || return 0
    [[ "$language" == en ]] || language_attribute=" xml:lang=\"$language\""
    printf '      <description sparkle:format="markdown"%s><![CDATA[\n' "$language_attribute"
    release_notes_in_language "$notes" "$language"
    printf ']]></description>\n'
}

write_appcast() {
    local appcast="$1"
    local version="$2"
    local build_number="$3"
    local repository_url="$4"
    local minimum_system_version="$5"
    local enclosure_attributes="$6"
    local notes="$7"
    local published
    published="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')"
    {
        printf '<?xml version="1.0" encoding="utf-8"?>\n'
        printf '<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">\n'
        printf '  <channel>\n'
        printf '    <title>Splitway</title>\n'
        printf '    <link>%s</link>\n' "$repository_url"
        printf '    <item>\n'
        printf '      <title>Splitway %s</title>\n' "$version"
        printf '      <pubDate>%s</pubDate>\n' "$published"
        printf '      <link>%s/releases/tag/v%s</link>\n' "$repository_url" "$version"
        printf '      <sparkle:version>%s</sparkle:version>\n' "$build_number"
        printf '      <sparkle:shortVersionString>%s</sparkle:shortVersionString>\n' "$version"
        printf '      <sparkle:minimumSystemVersion>%s</sparkle:minimumSystemVersion>\n' "$minimum_system_version"
        write_release_notes_description "$notes" en
        write_release_notes_description "$notes" ru
        printf '      <enclosure url="%s/releases/download/v%s/Splitway.dmg" %s type="application/octet-stream"/>\n' \
            "$repository_url" "$version" "$enclosure_attributes"
        printf '    </item>\n'
        printf '  </channel>\n'
        printf '</rss>\n'
    } >"$appcast"
}
