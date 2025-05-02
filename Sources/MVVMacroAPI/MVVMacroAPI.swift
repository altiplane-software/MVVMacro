/// A macro that produces a `Key` and `associatedValue`, used for powering viewModel actions.
@attached(member, names: named(Key), named(key), named(associatedValue))
@attached(extension, conformances: ActionProtocol)
public macro Action() = #externalMacro(module: "MVVMacroImpl", type: "ActionProtocolMacro")

/// A macro that produces action handling capabilities for a ViewModel
@attached(member, names: named(SendableAction), named(actionHandlers))
@attached(extension, conformances: ActionHandlingViewModel)
public macro ActionHandlingViewModel() = #externalMacro(module: "MVVMacroImpl", type: "ActionHandlingViewModelMacro")
