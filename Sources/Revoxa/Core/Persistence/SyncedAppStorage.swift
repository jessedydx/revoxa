import SwiftUI

@propertyWrapper
struct SyncedStringStorage: DynamicProperty {
    @AppStorage private var value: String
    private let key: String

    init(wrappedValue: String, _ key: String) {
        self.key = key
        _value = AppStorage(wrappedValue: wrappedValue, key)
    }

    var wrappedValue: String {
        get { value }
        nonmutating set {
            value = newValue
            RevoxaSyncedPreferences.pushLocalChange(key: key, value: newValue)
        }
    }

    var projectedValue: Binding<String> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

@propertyWrapper
struct SyncedIntStorage: DynamicProperty {
    @AppStorage private var value: Int
    private let key: String

    init(wrappedValue: Int, _ key: String) {
        self.key = key
        _value = AppStorage(wrappedValue: wrappedValue, key)
    }

    var wrappedValue: Int {
        get { value }
        nonmutating set {
            value = newValue
            RevoxaSyncedPreferences.pushLocalChange(key: key, value: newValue)
        }
    }

    var projectedValue: Binding<Int> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}
