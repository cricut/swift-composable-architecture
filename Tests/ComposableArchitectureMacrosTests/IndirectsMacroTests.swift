#if canImport(ComposableArchitectureMacros)
  import ComposableArchitectureMacros
  import MacroTesting
  import SwiftSyntaxMacros
  import SwiftSyntaxMacrosTestSupport
  import XCTest

  final class IndirectsMacroTests: XCTestCase {
    override func invokeTest() {
      withMacroTesting(
        // isRecording: true,
        macros: [IndirectsMacro.self]
      ) {
        super.invokeTest()
      }
    }

    // TODO: Make a diagnostic for inferred initialization
    // TODO: Make a diagnostic for "let"
    // TODO: Note "let" limitation?
    // TODO: Note inferred type initialization limitation!!
    func testBasics() {
      assertMacro {
        """
        struct State {
          @Indirects var indirectState: SomeState = SomeState()
        }
        """
      } expansion: {
        #"""
        struct State {
          var indirectState: SomeState {
            @storageRestrictions(initializes: _indirectState)
            init(initialValue) {
              _indirectState = IndirectState(wrappedValue: initialValue)
            }
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.wrappedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.wrappedValue, newValue, _$isIdentityEqual)
            }
          }
        
          var $indirectState: ComposableArchitecture.IndirectState<SomeState> {
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.projectedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.projectedValue, newValue, _$isIdentityEqual)
            }
          }
        
          @ObservationStateIgnored private var _indirectState = ComposableArchitecture.IndirectState<SomeState>(wrappedValue: SomeState())
        }
        """#
      }

      assertMacro {
          """
          struct State {
            @Indirects var indirectState: SomeState
          }
          """
      } expansion: {
          #"""
          struct State {
            var indirectState: SomeState {
              @storageRestrictions(initializes: _indirectState)
              init(initialValue) {
                _indirectState = IndirectState(wrappedValue: initialValue)
              }
              get {
                _$observationRegistrar.access(self, keyPath: \.indirectState)
                return _indirectState.wrappedValue
              }
              set {
                _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.wrappedValue, newValue, _$isIdentityEqual)
              }
            }
          
            var $indirectState: ComposableArchitecture.IndirectState<SomeState> {
              get {
                _$observationRegistrar.access(self, keyPath: \.indirectState)
                return _indirectState.projectedValue
              }
              set {
                _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.projectedValue, newValue, _$isIdentityEqual)
              }
            }
          
            @ObservationStateIgnored private var _indirectState: ComposableArchitecture.IndirectState<SomeState>
          }
          """#
      }

      assertMacro {
        """
        struct State {
          @Indirects var indirectState: SomeState?
        }
        """
      } expansion: {
        #"""
        struct State {
          var indirectState: SomeState? {
            @storageRestrictions(initializes: _indirectState)
            init(initialValue) {
              _indirectState = IndirectState(wrappedValue: initialValue)
            }
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.wrappedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.wrappedValue, newValue, _$isIdentityEqual)
            }
          }
        
          var $indirectState: ComposableArchitecture.IndirectState<SomeState?> {
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.projectedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.projectedValue, newValue, _$isIdentityEqual)
            }
          }
        
          @ObservationStateIgnored private var _indirectState = ComposableArchitecture.IndirectState<SomeState?>(wrappedValue: nil)
        }
        """#
      }

      assertMacro {
        """
        struct State {
          @Indirects var indirectState: SomeState = SomeState(argument: someArgument)
        }
        """
      } expansion: {
        #"""
        struct State {
          var indirectState: SomeState {
            @storageRestrictions(initializes: _indirectState)
            init(initialValue) {
              _indirectState = IndirectState(wrappedValue: initialValue)
            }
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.wrappedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.wrappedValue, newValue, _$isIdentityEqual)
            }
          }
        
          var $indirectState: ComposableArchitecture.IndirectState<SomeState> {
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.projectedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.projectedValue, newValue, _$isIdentityEqual)
            }
          }
        
          @ObservationStateIgnored private var _indirectState = ComposableArchitecture.IndirectState<SomeState>(wrappedValue: SomeState(argument: someArgument))
        }
        """#
      }
    }

    func testScopedState() {
      assertMacro {
        """
        struct State {
          @Indirects var indirectState: Scoped.State = Scoped.State()
        }
        """
      } expansion: {
        #"""
        struct State {
          var indirectState: Scoped.State {
            @storageRestrictions(initializes: _indirectState)
            init(initialValue) {
              _indirectState = IndirectState(wrappedValue: initialValue)
            }
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.wrappedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.wrappedValue, newValue, _$isIdentityEqual)
            }
          }
        
          var $indirectState: ComposableArchitecture.IndirectState<Scoped.State> {
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.projectedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.projectedValue, newValue, _$isIdentityEqual)
            }
          }
        
          @ObservationStateIgnored private var _indirectState = ComposableArchitecture.IndirectState<Scoped.State>(wrappedValue: Scoped.State())
        }
        """#
      }

      assertMacro {
        """
        struct State {
          @Indirects var indirectState: Scoped.State
        }
        """
      } expansion: {
        #"""
        struct State {
          var indirectState: Scoped.State {
            @storageRestrictions(initializes: _indirectState)
            init(initialValue) {
              _indirectState = IndirectState(wrappedValue: initialValue)
            }
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.wrappedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.wrappedValue, newValue, _$isIdentityEqual)
            }
          }
        
          var $indirectState: ComposableArchitecture.IndirectState<Scoped.State> {
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.projectedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.projectedValue, newValue, _$isIdentityEqual)
            }
          }
        
          @ObservationStateIgnored private var _indirectState: ComposableArchitecture.IndirectState<Scoped.State>
        }
        """#
      }

      assertMacro {
        """
        struct State {
          @Indirects var indirectState: Scoped.State?
        }
        """
      } expansion: {
        #"""
        struct State {
          var indirectState: Scoped.State? {
            @storageRestrictions(initializes: _indirectState)
            init(initialValue) {
              _indirectState = IndirectState(wrappedValue: initialValue)
            }
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.wrappedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.wrappedValue, newValue, _$isIdentityEqual)
            }
          }
        
          var $indirectState: ComposableArchitecture.IndirectState<Scoped.State?> {
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.projectedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.projectedValue, newValue, _$isIdentityEqual)
            }
          }
        
          @ObservationStateIgnored private var _indirectState = ComposableArchitecture.IndirectState<Scoped.State?>(wrappedValue: nil)
        }
        """#
      }
    }

    func testAccessControl() {
      assertMacro {
        """
        public struct State {
          @Indirects public var indirectState: SomeState
        }
        """
      } expansion: {
        #"""
        public struct State {
          public var indirectState: SomeState {
            @storageRestrictions(initializes: _indirectState)
            init(initialValue) {
              _indirectState = IndirectState(wrappedValue: initialValue)
            }
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.wrappedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.wrappedValue, newValue, _$isIdentityEqual)
            }
          }

          public var $indirectState: ComposableArchitecture.IndirectState<SomeState> {
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.projectedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.projectedValue, newValue, _$isIdentityEqual)
            }
          }

          @ObservationStateIgnored private var _indirectState: ComposableArchitecture.IndirectState<SomeState>
        }
        """#
      }
      assertMacro {
        """
        package struct State {
          @Indirects package var indirectState: SomeState
        }
        """
      } expansion: {
        #"""
        package struct State {
          package var indirectState: SomeState {
            @storageRestrictions(initializes: _indirectState)
            init(initialValue) {
              _indirectState = IndirectState(wrappedValue: initialValue)
            }
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.wrappedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.wrappedValue, newValue, _$isIdentityEqual)
            }
          }

          package var $indirectState: ComposableArchitecture.IndirectState<SomeState> {
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.projectedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.projectedValue, newValue, _$isIdentityEqual)
            }
          }

          @ObservationStateIgnored private var _indirectState: ComposableArchitecture.IndirectState<SomeState>
        }
        """#
      }
    }

    func testObservableStateDiagnostic() {
      assertMacro([
        ObservableStateMacro.self,
        ObservationStateIgnoredMacro.self,
        ObservationStateTrackedMacro.self,
        IndirectsMacro.self,
      ]) {
        """
        @ObservableState
        struct State: Equatable {
          @IndirectState var indirectState: SomeState
        }
        """
      } diagnostics: {
        """
        @ObservableState
        struct State: Equatable {
          @IndirectState var indirectState: SomeState
          ┬─────────────
          ╰─ 🛑 '@IndirectState' cannot be used in '@ObservableState'
             ✏️ Use '@Indirects' instead
        }
        """
      } fixes: {
        """
        @ObservableState
        struct State: Equatable {
          @Indirects var indirectState: SomeState
        }
        """
      } expansion: {
        #"""
        struct State: Equatable {
          var indirectState: SomeState {
            @storageRestrictions(initializes: _indirectState)
            init(initialValue) {
              _indirectState = IndirectState(wrappedValue: initialValue)
            }
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.wrappedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.wrappedValue, newValue, _$isIdentityEqual)
            }
          }

          var $indirectState: ComposableArchitecture.IndirectState<SomeState> {
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.projectedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.projectedValue, newValue, _$isIdentityEqual)
            }
          }

          private var _indirectState: ComposableArchitecture.IndirectState<SomeState>

          var _$observationRegistrar = ComposableArchitecture.ObservationStateRegistrar()

          public var _$id: ComposableArchitecture.ObservableStateID {
            _$observationRegistrar.id
          }

          public mutating func _$willModify() {
            _$observationRegistrar._$willModify()
          }
        }
        """#
      }
    }

    func testImmutableDiagnostic() {
      assertMacro([
        IndirectsMacro.self,
      ]) {
        """
        struct State: Equatable {
          @Indirects let indirectState: SomeState
        }
        """
      } diagnostics: {
        """
        struct State: Equatable {
          @Indirects let indirectState: SomeState
                     ┬──
                     ╰─ 🛑 '@Indirects' cannot be used with an immutable property
                        ✏️ Use 'var' instead
        }
        """
      } fixes: {
        """
        struct State: Equatable {
          @Indirects var indirectState: SomeState
        }
        """
      } expansion: {
        #"""
        struct State: Equatable {
          var indirectState: SomeState {
            @storageRestrictions(initializes: _indirectState)
            init(initialValue) {
              _indirectState = IndirectState(wrappedValue: initialValue)
            }
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.wrappedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.wrappedValue, newValue, _$isIdentityEqual)
            }
          }
        
          var $indirectState: ComposableArchitecture.IndirectState<SomeState> {
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.projectedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.projectedValue, newValue, _$isIdentityEqual)
            }
          }
        
          @ObservationStateIgnored private var _indirectState: ComposableArchitecture.IndirectState<SomeState>
        }
        """#
      }
    }

    func testInferredTypeDiagnostic() {
      assertMacro([
        IndirectsMacro.self,
      ]) {
        """
        struct State: Equatable {
          @Indirects var indirectState = 10
        }
        """
      } diagnostics: {
        """
        struct State: Equatable {
          @Indirects var indirectState = 10
                         ┬────────────
                         ╰─ 🛑 '@Indirects' properties must have an explicit type
        }
        """
      }

      assertMacro([
        IndirectsMacro.self,
      ]) {
        """
        struct State: Equatable {
          @Indirects var indirectState = SomeState()
        }
        """
      } diagnostics: {
        """
        struct State: Equatable {
          @Indirects var indirectState = SomeState()
                         ┬────────────
                         ╰─ 🛑 '@Indirects' properties must have an explicit type
                            ✏️ Insert explicit type
        }
        """
      } fixes: {
        """
        struct State: Equatable {
          @Indirects var indirectState: SomeState = SomeState()
        }
        """
      } expansion: {
        #"""
        struct State: Equatable {
          var indirectState: SomeState {
            @storageRestrictions(initializes: _indirectState)
            init(initialValue) {
              _indirectState = IndirectState(wrappedValue: initialValue)
            }
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.wrappedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.wrappedValue, newValue, _$isIdentityEqual)
            }
          }
        
          var $indirectState: ComposableArchitecture.IndirectState<SomeState> {
            get {
              _$observationRegistrar.access(self, keyPath: \.indirectState)
              return _indirectState.projectedValue
            }
            set {
              _$observationRegistrar.mutate(self, keyPath: \.indirectState, &_indirectState.projectedValue, newValue, _$isIdentityEqual)
            }
          }
        
          @ObservationStateIgnored private var _indirectState = ComposableArchitecture.IndirectState<SomeState>(wrappedValue: SomeState())
        }
        """#
      }
    }
  }
#endif
