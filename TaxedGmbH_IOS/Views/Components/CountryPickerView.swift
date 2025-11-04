import SwiftUI

struct CountryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCountry: Country
    @State private var searchText = ""

    private var filteredCountries: [Country] {
        if searchText.isEmpty {
            return Country.popular + Country.all.filter { country in
                !Country.popular.contains(where: { $0.id == country.id })
            }
        } else {
            return Country.all.filter { country in
                country.name.localizedCaseInsensitiveContains(searchText) ||
                country.dialCode.contains(searchText) ||
                country.id.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                if searchText.isEmpty {
                    // Popular countries section
                    Section(header: Text("country_picker.popular_countries".localized)) {
                        ForEach(Country.popular) { country in
                            CountryRow(country: country, isSelected: country.id == selectedCountry.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCountry = country
                                    dismiss()
                                }
                        }
                    }

                    // All other countries
                    Section(header: Text("country_picker.all_countries".localized)) {
                        ForEach(Country.all.filter { country in
                            !Country.popular.contains(where: { $0.id == country.id })
                        }) { country in
                            CountryRow(country: country, isSelected: country.id == selectedCountry.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCountry = country
                                    dismiss()
                                }
                        }
                    }
                } else {
                    // Search results
                    ForEach(filteredCountries) { country in
                        CountryRow(country: country, isSelected: country.id == selectedCountry.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedCountry = country
                                dismiss()
                            }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "country_picker.search_placeholder".localized)
            .navigationTitle("country_picker.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CountryRow: View {
    let country: Country
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(country.flag)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text(country.name)
                    .font(.body)

                if let format = country.format {
                    Text("+\(country.dialCode) \(format)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("+\(country.dialCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.taxedPrimary)
            }
        }
        .padding(.vertical, 4)
    }
}
