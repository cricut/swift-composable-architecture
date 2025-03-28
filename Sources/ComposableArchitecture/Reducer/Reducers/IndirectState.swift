@_spi(Reflection) import CasePaths
import Combine

/// A property wrapper for state that should be stored on the heap rather than the stack.
///
/// Use this property wrapper for offloading large reducer non-child state onto the heap.
///
/// For example, if you have a `ChildFeature` reducer that encapsulates the logic and behavior for a
/// feature, then any feature that wants to present that feature will hold onto `ChildFeature.State`
/// like so:
///
/// ```swift
/// @Reducer
/// struct ParentFeature {
///   struct State {
///     @IndirectState var heapState: HeapState
///      // ...
///   }
///   // ...
/// }
/// ```
@dynamicMemberLookup
@propertyWrapper
public struct IndirectState<State> {
  private class Storage: @unchecked Sendable {
    var state: State
    init(state: State) {
      self.state = state
    }
  }

  private var storage: Storage

  public init(wrappedValue: State) {
    self.storage = Storage(state: wrappedValue)
  }

  public var wrappedValue: State {
    get { self.storage.state }
    set {
      if !isKnownUniquelyReferenced(&self.storage) {
        self.storage = Storage(state: newValue)
      } else {
        self.storage.state = newValue
      }
    }
  }

  public var projectedValue: Self {
    get { self }
    set { self = newValue }
  }

  public subscript<Case>(
    dynamicMember keyPath: CaseKeyPath<State, Case>
  ) -> IndirectState<Case>?
  where State: CasePathable {
    if let newCase = self.wrappedValue[case: keyPath] {
      return IndirectState<Case>(wrappedValue: newCase)
    } else {
      return nil
    }
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<State, Member>
  ) -> IndirectState<Member> {
    IndirectState<Member>(wrappedValue: self.wrappedValue[keyPath: keyPath])
  }

  func sharesStorage(with other: Self) -> Bool {
    self.storage === other.storage
  }
}

extension IndirectState: Equatable where State: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.sharesStorage(with: rhs)
      || lhs.wrappedValue == rhs.wrappedValue
  }
}

extension IndirectState: Hashable where State: Hashable {
  public func hash(into hasher: inout Hasher) {
    self.wrappedValue.hash(into: &hasher)
  }
}

extension IndirectState: Sendable where State: Sendable {}

extension IndirectState: Decodable where State: Decodable {
  public init(from decoder: any Decoder) throws {
    do {
      self.init(wrappedValue: try decoder.singleValueContainer().decode(State.self))
    } catch {
      self.init(wrappedValue: try .init(from: decoder))
    }
  }
}

extension IndirectState: Encodable where State: Encodable {
  public func encode(to encoder: any Encoder) throws {
    do {
      var container = encoder.singleValueContainer()
      try container.encode(self.wrappedValue)
    } catch {
      try self.wrappedValue.encode(to: encoder)
    }
  }
}

extension IndirectState: CustomReflectable {
  public var customMirror: Mirror {
    Mirror(reflecting: self.wrappedValue as Any)
  }
}
