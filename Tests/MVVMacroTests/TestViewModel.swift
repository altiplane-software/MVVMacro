import MVVMacroAPI

@MainActor
@ActionHandlingViewModel
final class TestViewModel {
    @Action
    enum Action {
        case increment(Int)
        case decrement(Int)
        case reset
    }

    var counter = 0

    private func increment(value: Int) {
        counter += value
    }

    private func decrement(value: Int) {
        counter -= value
    }

    private func reset() {
        counter = 0
    }
}
