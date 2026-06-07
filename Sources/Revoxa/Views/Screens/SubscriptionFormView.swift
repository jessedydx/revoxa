import SwiftData
import SwiftUI

struct SubscriptionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(PreferenceKey.defaultCurrencyCode) private var defaultCurrencyCode = PreferenceKey.defaultCurrencyCodeValue
    @AppStorage(PreferenceKey.defaultReminderDays) private var defaultReminderDays = 3
    @AppStorage(PreferenceKey.notificationsEnabled) private var notificationsEnabled = false

    let subscription: Subscription?
    let onDelete: ((Subscription) -> Void)?

    @State private var formState: SubscriptionFormState
    @State private var validationErrors: [String] = []
    @State private var isConfirmingDelete = false
    @State private var didApplyDefaults = false
    @State private var templateSearchText = ""
    private let notificationService = NotificationSchedulingService()

    private var isEditing: Bool {
        subscription != nil
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    private var formWidth: CGFloat? {
        isCompactLayout ? nil : 680
    }

    private var formHeight: CGFloat? {
        isCompactLayout ? nil : 760
    }

    init(subscription: Subscription? = nil, onDelete: ((Subscription) -> Void)? = nil) {
        self.subscription = subscription
        self.onDelete = onDelete
        _formState = State(initialValue: SubscriptionFormState(subscription: subscription))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .overlay(RevoxaColor.border)

            ScrollView {
                VStack(alignment: .leading, spacing: RevoxaSpacing.large) {
                    if isEditing == false {
                        templatePicker
                    }

                    if validationErrors.isEmpty == false {
                        validationSummary
                    }

                    formFields

                    if isEditing {
                        quickActions
                    }
                }
                .padding(isCompactLayout ? RevoxaSpacing.medium : RevoxaSpacing.xLarge)
            }

            Divider()
                .overlay(RevoxaColor.border)

            footer
        }
        .frame(width: formWidth, height: formHeight)
        .background(RevoxaColor.appBackground)
        .onAppear(perform: applyDefaultsIfNeeded)
        .confirmationDialog(L10n.t("form.delete.confirm"), isPresented: $isConfirmingDelete) {
            Button(RevoxaStrings.delete, role: .destructive) {
                deleteSubscription()
            }
            Button(RevoxaStrings.cancel, role: .cancel) {}
        } message: {
            Text(L10n.t("form.delete.message"))
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
                Text(isEditing ? RevoxaStrings.editSubscription : RevoxaStrings.addSubscription)
                    .font(RevoxaFont.pageTitle)
                    .foregroundStyle(RevoxaColor.textPrimary)

                Text(isEditing ? L10n.t("form.edit.subtitle") : L10n.t("form.add.subtitle"))
                    .font(RevoxaFont.body)
                    .foregroundStyle(RevoxaColor.textSecondary)
            }

            Spacer()
        }
        .padding(isCompactLayout ? RevoxaSpacing.medium : RevoxaSpacing.xLarge)
    }

    @ViewBuilder
    private var formFields: some View {
        if isCompactLayout {
            mobileFormFields
        } else {
            Grid(alignment: .leading, horizontalSpacing: RevoxaSpacing.large, verticalSpacing: RevoxaSpacing.large) {
                labeledTextField(L10n.t("form.name"), text: $formState.name, prompt: L10n.t("form.prompt.netflix"))
                labeledDecimalField(L10n.t("form.amount"), text: $formState.amountText, prompt: L10n.t("form.prompt.amount"))

                GridRow {
                    fieldLabel(L10n.t("form.currency"))
                    Picker(L10n.t("form.currency"), selection: currencyBinding) {
                        ForEach(RevoxaCurrency.allCases) { currency in
                            Text(currency.pickerLabel).tag(currency)
                        }
                    }
                    .labelsHidden()
                }

                labeledDecimalField(L10n.t("form.cashback"), text: $formState.cashbackAmountText, prompt: L10n.t("form.prompt.cashback"))

                GridRow {
                    fieldLabel(L10n.t("form.billingCycle"))
                    Picker(L10n.t("form.billingCycle"), selection: $formState.billingCycle) {
                        ForEach(BillingCycle.allCases) { cycle in
                            Text(cycle.title).tag(cycle)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if formState.billingCycle == .customDays {
                    GridRow {
                        fieldLabel(L10n.t("form.customDayCount"))
                        Stepper(value: $formState.customBillingDays, in: 1...3650) {
                            Text(RevoxaStrings.daysCount(formState.customBillingDays))
                                .foregroundStyle(RevoxaColor.textPrimary)
                        }
                    }
                }

                GridRow {
                    fieldLabel(L10n.t("form.nextBillingDate"))
                    DatePicker(
                        L10n.t("form.nextBillingDate"),
                        selection: nextBillingDateBinding,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                    .environment(\.locale, RevoxaLanguageSettings.resolvedLocale)
                }

                pickerRow(L10n.t("form.category"), selection: $formState.category, values: SubscriptionCategory.allCases)
                pickerRow(L10n.t("form.paymentMethod"), selection: $formState.paymentMethod, values: PaymentMethod.allCases)
                pickerRow(L10n.t("form.status"), selection: $formState.status, values: SubscriptionStatus.allCases)

                GridRow {
                    fieldLabel(L10n.t("form.reminderDaysBefore"))
                    Stepper(value: $formState.reminderDaysBefore, in: 0...365) {
                        Text(RevoxaStrings.daysCount(formState.reminderDaysBefore))
                            .foregroundStyle(RevoxaColor.textPrimary)
                    }
                }

                labeledTextField(L10n.t("form.cancellationURL"), text: $formState.cancellationURLText, prompt: L10n.t("form.prompt.cancelURL"))

                valueReviewFields

                GridRow(alignment: .top) {
                    fieldLabel(L10n.t("form.notes"))
                    TextEditor(text: $formState.notes)
                        .font(RevoxaFont.body)
                        .foregroundStyle(RevoxaColor.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(RevoxaColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.small))
                        .overlay {
                            RoundedRectangle(cornerRadius: RevoxaRadius.small)
                                .stroke(RevoxaColor.border, lineWidth: 1)
                        }
                        .frame(height: 96)
                }
            }
        }
    }

    private var mobileFormFields: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
            mobileTextField(L10n.t("form.name"), text: $formState.name, prompt: L10n.t("form.prompt.netflix"))
            mobileDecimalField(L10n.t("form.amount"), text: $formState.amountText, prompt: L10n.t("form.prompt.amount"))
            mobileCurrencyPicker
            mobileDecimalField(L10n.t("form.cashback"), text: $formState.cashbackAmountText, prompt: L10n.t("form.prompt.cashback"))
            mobilePicker(L10n.t("form.billingCycle"), selection: $formState.billingCycle, values: BillingCycle.allCases)

            if formState.billingCycle == .customDays {
                mobileStepper(L10n.t("form.customDayCount"), value: $formState.customBillingDays, range: 1...3650)
            }

            mobileDatePicker
            mobilePicker(L10n.t("form.category"), selection: $formState.category, values: SubscriptionCategory.allCases)
            mobilePicker(L10n.t("form.paymentMethod"), selection: $formState.paymentMethod, values: PaymentMethod.allCases)
            mobilePicker(L10n.t("form.status"), selection: $formState.status, values: SubscriptionStatus.allCases)
            mobileStepper(L10n.t("form.reminderDaysBefore"), value: $formState.reminderDaysBefore, range: 0...365)
            mobileTextField(L10n.t("form.cancellationURL"), text: $formState.cancellationURLText, prompt: L10n.t("form.prompt.cancelURL"))
            mobileValueReviewFields
            mobileNotesField
        }
    }

    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
            VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
                Text(L10n.t("form.templates.title"))
                    .font(RevoxaFont.sectionTitle)
                    .foregroundStyle(RevoxaColor.textPrimary)

                Text(L10n.t("form.templates.subtitle"))
                    .font(RevoxaFont.caption)
                    .foregroundStyle(RevoxaColor.textSecondary)
            }

            TextField(L10n.t("form.templates.searchPrompt"), text: $templateSearchText)
                .textFieldStyle(.roundedBorder)

            if filteredTemplates.isEmpty {
                Text(L10n.t("form.templates.noResults"))
                    .font(RevoxaFont.caption)
                    .foregroundStyle(RevoxaColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 136), spacing: RevoxaSpacing.small)],
                    alignment: .leading,
                    spacing: RevoxaSpacing.small
                ) {
                    ForEach(filteredTemplates) { template in
                        templateButton(template)
                    }
                }
            }
        }
        .padding(RevoxaSpacing.medium)
        .background(RevoxaColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: RevoxaRadius.medium)
                .stroke(RevoxaColor.border, lineWidth: 1)
        }
    }

    private var filteredTemplates: [SubscriptionTemplate] {
        let normalizedQuery = normalizedTemplateSearch(templateSearchText)
        guard normalizedQuery.isEmpty == false else {
            return SubscriptionTemplates.all
        }

        return SubscriptionTemplates.all.filter { template in
            template.searchTerms.contains { term in
                normalizedTemplateSearch(term).contains(normalizedQuery)
            }
        }
    }

    private func normalizedTemplateSearch(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }
    }

    private func templateButton(_ template: SubscriptionTemplate) -> some View {
        Button {
            applyTemplate(template)
        } label: {
            HStack(spacing: RevoxaSpacing.small) {
                SubscriptionLogoView(
                    subscriptionName: template.displayName,
                    iconAssetName: template.iconAssetName,
                    size: 34
                )

                Text(template.displayName)
                    .font(RevoxaFont.caption)
                    .foregroundStyle(RevoxaColor.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, RevoxaSpacing.small)
            .padding(.vertical, RevoxaSpacing.xSmall)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(templateBackground(for: template))
            .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.small))
            .overlay {
                RoundedRectangle(cornerRadius: RevoxaRadius.small)
                    .stroke(templateBorderColor(for: template), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func templateBackground(for template: SubscriptionTemplate) -> Color {
        formState.templateID == template.id ? RevoxaColor.accent.opacity(0.14) : RevoxaColor.elevatedSurface
    }

    private func templateBorderColor(for template: SubscriptionTemplate) -> Color {
        formState.templateID == template.id ? RevoxaColor.accent.opacity(0.45) : RevoxaColor.border
    }

    private var valueReviewFields: some View {
        Group {
            pickerRow(L10n.t("form.usageFrequency"), selection: $formState.usageFrequency, values: UsageFrequency.allCases)
            pickerRow(L10n.t("form.valueRating"), selection: $formState.valueRating, values: ValueRating.allCases)

            GridRow {
                fieldLabel(L10n.t("form.cancelReason"))
                Picker(L10n.t("form.cancelReason"), selection: cancelReasonBinding) {
                    Text(L10n.t("form.unspecified")).tag(CancelReason?.none)
                    ForEach(CancelReason.allCases) { reason in
                        Text(reason.title).tag(Optional(reason))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            labeledDecimalField(
                L10n.t("form.potentialSaving"),
                text: $formState.potentialMonthlySavingText,
                prompt: L10n.t("form.prompt.autoCalculated")
            )

            if let lastReviewedAt = formState.lastReviewedAt {
                GridRow {
                    fieldLabel(L10n.t("form.lastReviewed"))
                    Text(RevoxaDateFormatter.mediumDate(lastReviewedAt))
                        .font(RevoxaFont.body)
                        .foregroundStyle(RevoxaColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var mobileCurrencyPicker: some View {
        mobileFieldContainer(L10n.t("form.currency")) {
            Picker(L10n.t("form.currency"), selection: currencyBinding) {
                ForEach(RevoxaCurrency.allCases) { currency in
                    Text(currency.pickerLabel).tag(currency)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var mobileDatePicker: some View {
        mobileFieldContainer(L10n.t("form.nextBillingDate")) {
            DatePicker(
                L10n.t("form.nextBillingDate"),
                selection: nextBillingDateBinding,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .environment(\.locale, RevoxaLanguageSettings.resolvedLocale)
        }
    }

    private var mobileValueReviewFields: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
            mobilePicker(L10n.t("form.usageFrequency"), selection: $formState.usageFrequency, values: UsageFrequency.allCases)
            mobilePicker(L10n.t("form.valueRating"), selection: $formState.valueRating, values: ValueRating.allCases)

            mobileFieldContainer(L10n.t("form.cancelReason")) {
                Picker(L10n.t("form.cancelReason"), selection: cancelReasonBinding) {
                    Text(L10n.t("form.unspecified")).tag(CancelReason?.none)
                    ForEach(CancelReason.allCases) { reason in
                        Text(reason.title).tag(Optional(reason))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            mobileDecimalField(
                L10n.t("form.potentialSaving"),
                text: $formState.potentialMonthlySavingText,
                prompt: L10n.t("form.prompt.autoCalculated")
            )

            if let lastReviewedAt = formState.lastReviewedAt {
                mobileReadOnlyField(
                    L10n.t("form.lastReviewed"),
                    value: RevoxaDateFormatter.mediumDate(lastReviewedAt)
                )
            }
        }
    }

    private var mobileNotesField: some View {
        mobileFieldContainer(L10n.t("form.notes")) {
            TextEditor(text: $formState.notes)
                .font(RevoxaFont.body)
                .foregroundStyle(RevoxaColor.textPrimary)
                .scrollContentBackground(.hidden)
                .background(RevoxaColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.small))
                .overlay {
                    RoundedRectangle(cornerRadius: RevoxaRadius.small)
                        .stroke(RevoxaColor.border, lineWidth: 1)
                }
                .frame(minHeight: 112)
        }
    }

    private var cancelReasonBinding: Binding<CancelReason?> {
        Binding {
            formState.cancelReason
        } set: { newValue in
            formState.cancelReason = newValue
        }
    }

    private var validationSummary: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
            ForEach(validationErrors, id: \.self) { error in
                Text(error)
                    .font(RevoxaFont.caption)
                    .foregroundStyle(RevoxaColor.accent)
            }
        }
        .padding(RevoxaSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RevoxaColor.accent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: RevoxaRadius.medium)
                .stroke(RevoxaColor.accent.opacity(0.45), lineWidth: 1)
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.medium) {
            Text(L10n.t("form.quickActions"))
                .font(RevoxaFont.sectionTitle)
                .foregroundStyle(RevoxaColor.textPrimary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: RevoxaSpacing.small) {
                    quickActionButtons
                }

                VStack(alignment: .leading, spacing: RevoxaSpacing.small) {
                    quickActionButtons
                }
            }
        }
        .padding(RevoxaSpacing.medium)
        .background(RevoxaColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: RevoxaRadius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: RevoxaRadius.medium)
                .stroke(RevoxaColor.border, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var quickActionButtons: some View {
        Button(L10n.t("form.archive")) {
            setStatus(.archived)
        }

        Button(L10n.t("form.markCancelSoon")) {
            setStatus(.cancelSoon)
        }

        Button(L10n.t("form.markCancelled")) {
            setStatus(.cancelled)
        }

        if isCompactLayout == false {
            Spacer()
        }

        Button(RevoxaStrings.delete, role: .destructive) {
            isConfirmingDelete = true
        }
        .tint(.red)
    }

    private var footer: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                footerButtons
            }

            VStack(spacing: RevoxaSpacing.small) {
                footerButtons
            }
        }
        .padding(isCompactLayout ? RevoxaSpacing.medium : RevoxaSpacing.large)
    }

    @ViewBuilder
    private var footerButtons: some View {
        Button(RevoxaStrings.cancel) {
            dismiss()
        }
        .keyboardShortcut(.cancelAction)

        if isCompactLayout == false {
            Spacer()
        }

        Button(RevoxaStrings.save) {
            save()
        }
        .revoxaPrimaryButton()
        .keyboardShortcut(.defaultAction)
    }

    private var nextBillingDateBinding: Binding<Date> {
        Binding {
            formState.nextBillingDate ?? .now
        } set: { newValue in
            formState.nextBillingDate = newValue
        }
    }

    private func labeledTextField(_ label: String, text: Binding<String>, prompt: String) -> some View {
        GridRow {
            fieldLabel(label)
            TextField(prompt, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func labeledDecimalField(_ label: String, text: Binding<String>, prompt: String) -> some View {
        GridRow {
            fieldLabel(label)
            TextField(prompt, text: text)
                .textFieldStyle(.roundedBorder)
                .environment(\.locale, RevoxaLanguageSettings.resolvedLocale)
        }
    }

    private func pickerRow<Value: CaseIterable & Hashable & Identifiable>(
        _ label: String,
        selection: Binding<Value>,
        values: Value.AllCases
    ) -> some View where Value.AllCases: RandomAccessCollection, Value: TitledOption {
        GridRow {
            fieldLabel(label)
            Picker(label, selection: selection) {
                ForEach(values) { value in
                    Text(value.title).tag(value)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(RevoxaFont.caption)
            .foregroundStyle(RevoxaColor.textSecondary)
            .frame(width: 150, alignment: .trailing)
    }

    private func mobileTextField(_ label: String, text: Binding<String>, prompt: String) -> some View {
        mobileFieldContainer(label) {
            TextField(prompt, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func mobileDecimalField(_ label: String, text: Binding<String>, prompt: String) -> some View {
        mobileFieldContainer(label) {
            TextField(prompt, text: text)
                .textFieldStyle(.roundedBorder)
                .environment(\.locale, RevoxaLanguageSettings.resolvedLocale)
        }
    }

    private func mobilePicker<Value: CaseIterable & Hashable & Identifiable>(
        _ label: String,
        selection: Binding<Value>,
        values: Value.AllCases
    ) -> some View where Value.AllCases: RandomAccessCollection, Value: TitledOption {
        mobileFieldContainer(label) {
            Picker(label, selection: selection) {
                ForEach(values) { value in
                    Text(value.title).tag(value)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func mobileStepper(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        mobileFieldContainer(label) {
            Stepper(value: value, in: range) {
                Text(RevoxaStrings.daysCount(value.wrappedValue))
                    .foregroundStyle(RevoxaColor.textPrimary)
            }
        }
    }

    private func mobileReadOnlyField(_ label: String, value: String) -> some View {
        mobileFieldContainer(label) {
            Text(value)
                .font(RevoxaFont.body)
                .foregroundStyle(RevoxaColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func mobileFieldContainer<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: RevoxaSpacing.xSmall) {
            Text(label)
                .font(RevoxaFont.caption)
                .foregroundStyle(RevoxaColor.textSecondary)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func save() {
        let errors = formState.validationErrors()
        guard errors.isEmpty else {
            validationErrors = errors
            return
        }

        if let subscription {
            _ = formState.apply(to: subscription)
            notificationService.syncNotification(for: subscription, enabled: notificationsEnabled)
        } else if let newSubscription = formState.makeSubscription() {
            modelContext.insert(newSubscription)
            notificationService.syncNotification(for: newSubscription, enabled: notificationsEnabled)
        }

        dismiss()
    }

    private func setStatus(_ status: SubscriptionStatus) {
        formState.status = status
    }

    private func applyTemplate(_ template: SubscriptionTemplate) {
        formState.apply(template: template, defaultCurrencyCode: defaultCurrencyCode)
        validationErrors = []
    }

    private func deleteSubscription() {
        guard let subscription else { return }
        notificationService.cancelNotification(for: subscription)
        onDelete?(subscription)
        dismiss()
    }

    private var currencyBinding: Binding<RevoxaCurrency> {
        Binding {
            RevoxaCurrency.resolved(from: formState.currencyCode)
        } set: { newValue in
            formState.currencyCode = newValue.code
        }
    }

    private func applyDefaultsIfNeeded() {
        guard isEditing == false, didApplyDefaults == false else { return }
        formState.currencyCode = RevoxaCurrency.resolved(from: defaultCurrencyCode).code
        formState.reminderDaysBefore = Subscription.sanitizedReminderDays(defaultReminderDays)
        didApplyDefaults = true
    }
}

protocol TitledOption {
    var title: String { get }
}

extension BillingCycle: TitledOption {}
extension SubscriptionCategory: TitledOption {}
extension PaymentMethod: TitledOption {}
extension SubscriptionStatus: TitledOption {}
extension UsageFrequency: TitledOption {}
extension ValueRating: TitledOption {}
extension CancelReason: TitledOption {}
extension RevoxaCurrency: TitledOption {}
