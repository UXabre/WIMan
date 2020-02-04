function ConvertArchitectureIdToString($architecture) {
    Switch($architecture) {
        0 {
            "arm"
        }
        5 {
            "x86"
        }
        9 {
            "amd64"
        }
        12 {
            "arm64"
        }
    }
}