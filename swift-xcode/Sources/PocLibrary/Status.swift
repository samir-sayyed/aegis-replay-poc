public enum Status {
    case active
    case paused

    public var isRunnable: Bool {
        self == .active
    }
}
