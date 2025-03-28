import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public enum IndirectsMacro {
}

extension IndirectsMacro: AccessorMacro {
  public static func expansion<D: DeclSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: D,
    in context: C
  ) throws -> [AccessorDeclSyntax] {
    guard let property = declaration.as(VariableDeclSyntax.self) else { return [] }

    guard !property.isImmutable else {
      var fixItProperty = property
      fixItProperty.bindingSpecifier = .keyword(.var, trailingTrivia: " ")

      context.diagnose(
        Diagnostic(
          node: property.bindingSpecifier,
          message: MacroExpansionErrorMessage("'@Indirects' cannot be used with an immutable property"),
          fixIt: .replace(
            message: MacroExpansionFixItMessage("Use 'var' instead"),
            oldNode: property,
            newNode: fixItProperty
          )
        )
      )

      return []
    }

    guard !property.bindings.isInferredAssignment else {
      // If the binding has explicit types, then we can do a fix-it
      if property.bindings.hasExplicitTypes {
        var fixItProperty = property
        fixItProperty.bindings = fixItProperty.bindings.withExplicitTypes

        context.diagnose(
          Diagnostic(
            node: property.identifier ?? TokenSyntax(""),
            message: MacroExpansionErrorMessage("'@Indirects' properties must have an explicit type"),
            fixIt: .replace(
              message: MacroExpansionFixItMessage("Insert explicit type"),
              oldNode: property,
              newNode: fixItProperty
            )
          )
        )
      } else {
        // Otherwise we just emit a diagnostic
        context.diagnose(
          Diagnostic(
            node: property.identifier ?? TokenSyntax(""),
            message: MacroExpansionErrorMessage("'@Indirects' properties must have an explicit type")
          )
        )
      }

      return []
    }

    guard property.isValidForIndirectState,
          let identifier = property.identifier?.trimmed
    else {
      return []
    }

    let initAccessor: AccessorDeclSyntax =
      """
      @storageRestrictions(initializes: _\(identifier))
      init(initialValue) {
      _\(identifier) = IndirectState(wrappedValue: initialValue)
      }
      """

    let getAccessor: AccessorDeclSyntax =
      """
      get {
      _$observationRegistrar.access(self, keyPath: \\.\(identifier))
      return _\(identifier).wrappedValue
      }
      """

    let setAccessor: AccessorDeclSyntax =
      """
      set {
      _$observationRegistrar.mutate(self, keyPath: \\.\(identifier), &_\(identifier).wrappedValue, newValue, _$isIdentityEqual)
      }
      """

    return [initAccessor, getAccessor, setAccessor]
  }
}

extension IndirectsMacro: PeerMacro {
  public static func expansion<D: DeclSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    providingPeersOf declaration: D,
    in context: C
  ) throws -> [DeclSyntax] {
    guard
      let property = declaration.as(VariableDeclSyntax.self),
      property.isValidForIndirectState
    else {
      return []
    }

    let wrapped = DeclSyntax(
      property.privateWrapped(addingAttribute: ObservableStateMacro.ignoredAttribute)
    )
    let projected = DeclSyntax(property.projected)
    return [
      projected,
      wrapped,
    ]
  }
}

extension VariableDeclSyntax {
  fileprivate func privateWrapped(
    addingAttribute attribute: AttributeSyntax
  ) -> VariableDeclSyntax {
    var attributes = self.attributes
    for index in attributes.indices.reversed() {
      let attribute = attributes[index]
      switch attribute {
      case let .attribute(attribute):
        if attribute.attributeName.tokens(viewMode: .all).map(\.tokenKind) == [
          .identifier("Indirects")
        ] {
          attributes.remove(at: index)
        }
      default:
        break
      }
    }
    let newAttributes = attributes + [.attribute(attribute)]
    return VariableDeclSyntax(
      leadingTrivia: leadingTrivia,
      attributes: newAttributes,
      modifiers: modifiers.privatePrefixed("_"),
      bindingSpecifier: TokenSyntax(
        bindingSpecifier.tokenKind, trailingTrivia: .space,
        presence: .present
      ),
      bindings: bindings.privateWrapped,
      trailingTrivia: trailingTrivia
    )
  }

  fileprivate var projected: VariableDeclSyntax {
    return VariableDeclSyntax(
      leadingTrivia: leadingTrivia,
      modifiers: modifiers,
      bindingSpecifier: TokenSyntax(
        bindingSpecifier.tokenKind, trailingTrivia: .space,
        presence: .present
      ),
      bindings: bindings.projected,
      trailingTrivia: trailingTrivia
    )
  }

  fileprivate var isValidForIndirectState: Bool {
    !isComputed && isInstance && !isImmutable && identifier != nil
  }
}

extension PatternBindingListSyntax {
  fileprivate var isInferredAssignment: Bool {
    let bindings = self
    for index in bindings.indices {
      let binding = bindings[index]
      if binding.typeAnnotation == nil && binding.pattern.is(IdentifierPatternSyntax.self) {
        return true
      }
    }

    return false
  }
}

extension PatternBindingListSyntax {
  fileprivate var hasExplicitTypes: Bool {
    let bindings = self
    for index in bindings.indices {
      let binding = bindings[index]
      if !binding.pattern.is(IdentifierPatternSyntax.self) || !(binding.initializer?.value.is(FunctionCallExprSyntax.self) ?? false) {
        return false
      }
    }
    
    return true
  }
}

extension PatternBindingListSyntax {
  fileprivate var withExplicitTypes: PatternBindingListSyntax {
    var bindings = self
    for index in bindings.indices {
      var binding = bindings[index]
      if let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
         let initializer = binding.initializer?.value.as(FunctionCallExprSyntax.self),
         let calledExpression = initializer.calledExpression.as(DeclReferenceExprSyntax.self),
         binding.typeAnnotation == nil {
        let type = TypeSyntax(IdentifierTypeSyntax(leadingTrivia: " ", name: calledExpression.baseName))
        let typeAnnotation = TypeAnnotationSyntax(leadingTrivia: "", type: type, trailingTrivia: " ")
        binding.typeAnnotation = typeAnnotation

        var newPattern = pattern
        newPattern.identifier = newPattern.identifier.trimmed
        binding.pattern = PatternSyntax.self(newPattern)

        bindings[index] = binding
      }
    }

    return bindings
  }
}

extension PatternBindingListSyntax {
  fileprivate var privateWrapped: PatternBindingListSyntax {
    var bindings = self
    for index in bindings.indices {
      var binding = bindings[index]
      if let type = binding.typeAnnotation?.type {
        if type.is(OptionalTypeSyntax.self) || binding.initializer != nil {
          binding.typeAnnotation = nil
          binding.initializer = InitializerClauseSyntax(
            value: FunctionCallExprSyntax(
              calledExpression: type.indirectStateWrapped,
              leftParen: .leftParenToken(),
              arguments: [
                LabeledExprSyntax(
                  label: "wrappedValue",
                  expression: binding.initializer?.value ?? ExprSyntax(NilLiteralExprSyntax())
                )
              ],
              rightParen: .rightParenToken()
            )
          )
        } else {
          let indirectStateWrapped = type.indirectStateWrapped
          let wrappedType = IdentifierTypeSyntax(name: .identifier(indirectStateWrapped.trimmedDescription))
          let annotation = TypeAnnotationSyntax(type: wrappedType)
          binding.typeAnnotation = annotation
        }
      }
      if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
        bindings[index] = PatternBindingSyntax(
          leadingTrivia: binding.leadingTrivia,
          pattern: IdentifierPatternSyntax(
            leadingTrivia: identifier.leadingTrivia,
            identifier: identifier.identifier.privatePrefixed("_"),
            trailingTrivia: identifier.trailingTrivia
          ),
          typeAnnotation: binding.typeAnnotation,
          initializer: binding.initializer,
          accessorBlock: binding.accessorBlock,
          trailingComma: binding.trailingComma,
          trailingTrivia: binding.trailingTrivia
        )
      }
    }

    return bindings
  }

  fileprivate var projected: PatternBindingListSyntax {
    var bindings = self

    for index in bindings.indices {
      var binding = bindings[index]
      if let type = binding.typeAnnotation?.type {
        binding.typeAnnotation?.type = TypeSyntax(
          IdentifierTypeSyntax(
            name: .identifier(type.indirectStateWrapped.trimmedDescription)
          )
        )
      }
      else if let initializer = binding.initializer,
              let value = initializer.value.as(FunctionCallExprSyntax.self),
              let calledExpression = value.calledExpression.as(DeclReferenceExprSyntax.self) {
        let type = TypeSyntax(IdentifierTypeSyntax(name: calledExpression.baseName))
        let indirectStateWrapped = type.indirectStateWrapped
        let wrappedType = IdentifierTypeSyntax(name: .identifier(indirectStateWrapped.trimmedDescription))
        let annotation = TypeAnnotationSyntax(type: wrappedType)
        binding.typeAnnotation = annotation
      }

      if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
        let trailingTrivia = identifier.trailingTrivia
        let newTrivia: Trivia
        if trailingTrivia.allSatisfy(\.isWhitespace) {
          newTrivia = []
        } else {
          newTrivia = trailingTrivia
        }

        bindings[index] = PatternBindingSyntax(
          leadingTrivia: binding.leadingTrivia,
          pattern: IdentifierPatternSyntax(
            leadingTrivia: identifier.leadingTrivia,
            identifier: identifier.identifier.privatePrefixed("$"),
            trailingTrivia: newTrivia
          ),
          typeAnnotation: binding.typeAnnotation,
          accessorBlock: AccessorBlockSyntax(
            accessors: .accessors([
              """
              get {
              _$observationRegistrar.access(self, keyPath: \\.\(identifier))
              return _\(identifier.identifier).projectedValue
              }
              """,
              """
              set {
              _$observationRegistrar.mutate(self, keyPath: \\.\(identifier), &_\(identifier).projectedValue, newValue, _$isIdentityEqual)
              }
              """
            ])
          )
        )
      }
    }

    return bindings
  }
}

extension TypeSyntax {
  fileprivate var indirectStateWrapped: GenericSpecializationExprSyntax {
    GenericSpecializationExprSyntax(
      expression: MemberAccessExprSyntax(
        base: DeclReferenceExprSyntax(baseName: "ComposableArchitecture"),
        name: "IndirectState"
      ),
      genericArgumentClause: GenericArgumentClauseSyntax(
        arguments: [
          GenericArgumentSyntax(
            argument: self.trimmed
          )
        ]
      )
    )
  }
}
