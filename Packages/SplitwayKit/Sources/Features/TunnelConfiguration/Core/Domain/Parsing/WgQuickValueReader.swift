struct WgQuickValueReader {
    let values: WgQuickSectionValues

    func single<Value>(
        _ key: WgQuickKey,
        issues: inout [ConfigurationIssue],
        conversion: (String) throws(ConfigurationValueError) -> Value
    ) -> Value? {
        guard let entry = values.first(key) else { return nil }
        return convert(entry, as: key, issues: &issues, conversion: conversion)
    }

    func everyLine<Value>(
        _ key: WgQuickKey,
        issues: inout [ConfigurationIssue],
        conversion: (String) throws(ConfigurationValueError) -> Value
    ) -> [Value] {
        values.all(key).compactMap { entry in convert(entry, as: key, issues: &issues, conversion: conversion) }
    }

    private func convert<Value>(
        _ entry: WgQuickRawEntry,
        as key: WgQuickKey,
        issues: inout [ConfigurationIssue],
        conversion: (String) throws(ConfigurationValueError) -> Value
    ) -> Value? {
        do {
            return try conversion(entry.value)
        } catch {
            issues.append(ConfigurationIssue(line: entry.line, kind: .invalidValue(key, error)))
            return nil
        }
    }
}
