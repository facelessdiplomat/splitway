struct GoModuleFile {
    let requiredModules: [String]
    let declaresGoVersion: Bool

    init(contents: String) {
        let lines = contents.split(whereSeparator: \.isNewline).map { line in
            line.trimmingCharacters(in: .whitespaces)
        }
        declaresGoVersion = lines.contains { line in line.hasPrefix("go ") }
        requiredModules = Self.requiredModules(in: lines)
    }

    private static func requiredModules(in lines: [String]) -> [String] {
        var isInsideRequireBlock = false
        var modules: [String] = []
        for line in lines {
            let fields = line.split(separator: " ")
            switch line {
            case "require (":
                isInsideRequireBlock = true
            case ")":
                isInsideRequireBlock = false
            default:
                if isInsideRequireBlock, let module = fields.first {
                    modules.append(String(module))
                } else if fields.first == "require", fields.count >= 3 {
                    modules.append(String(fields[1]))
                }
            }
        }
        return modules
    }
}
