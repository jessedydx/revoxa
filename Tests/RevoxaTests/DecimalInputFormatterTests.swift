import Foundation
import Testing
@testable import Revoxa

struct DecimalInputFormatterTests {
    private let turkish = Locale(identifier: "tr_TR")
    private let english = Locale(identifier: "en_US")

    @Test
    func parsesCommaDecimalForTurkishLocale() {
        UserDefaults.standard.set(AppLanguage.turkish.rawValue, forKey: PreferenceKey.appLanguage)
        defer { UserDefaults.standard.removeObject(forKey: PreferenceKey.appLanguage) }

        #expect(DecimalInputFormatter.decimal(from: "15,49", locale: turkish) == Decimal(string: "15.49"))
        #expect(DecimalInputFormatter.decimal(from: "1.234,56", locale: turkish) == Decimal(string: "1234.56"))
    }

    @Test
    func parsesDotDecimalForEnglishLocale() {
        UserDefaults.standard.set(AppLanguage.english.rawValue, forKey: PreferenceKey.appLanguage)
        defer { UserDefaults.standard.removeObject(forKey: PreferenceKey.appLanguage) }

        #expect(DecimalInputFormatter.decimal(from: "8.50", locale: english) == Decimal(string: "8.50"))
    }

    @Test
    func editingStringUsesLocaleDecimalSeparator() {
        UserDefaults.standard.set(AppLanguage.turkish.rawValue, forKey: PreferenceKey.appLanguage)
        defer { UserDefaults.standard.removeObject(forKey: PreferenceKey.appLanguage) }

        let text = DecimalInputFormatter.editingString(from: Decimal(string: "15.49")!, locale: turkish)
        #expect(text == "15,49")
    }

    @Test
    func formStateAcceptsCommaAmount() throws {
        UserDefaults.standard.set(AppLanguage.turkish.rawValue, forKey: PreferenceKey.appLanguage)
        defer { UserDefaults.standard.removeObject(forKey: PreferenceKey.appLanguage) }

        var state = SubscriptionFormState()
        state.name = "Spotify"
        state.amountText = "15,49"
        state.currencyCode = "TRY"

        let subscription = try #require(state.makeSubscription())
        #expect(subscription.amount == Decimal(string: "15.49"))
    }
}
