import Foundation

// MARK: - Country Model

struct Country: Identifiable, Codable, Hashable {
    let id: String // ISO code
    let name: String
    let dialCode: String
    let flag: String // Emoji flag
    let format: String? // Phone format example
    let minLength: Int
    let maxLength: Int

    var displayName: String {
        "\(flag) \(name)"
    }

    var dialCodeWithPlus: String {
        "+\(dialCode)"
    }
}

// MARK: - Country Database

extension Country {

    /// All supported countries (200+)
    static let all: [Country] = [
        // Popular/Priority countries (shown first)
        Country(id: "CH", name: "Switzerland", dialCode: "41", flag: "🇨🇭", format: "79 123 45 67", minLength: 9, maxLength: 9),
        Country(id: "DE", name: "Germany", dialCode: "49", flag: "🇩🇪", format: "151 12345678", minLength: 10, maxLength: 11),
        Country(id: "FR", name: "France", dialCode: "33", flag: "🇫🇷", format: "6 12 34 56 78", minLength: 9, maxLength: 9),
        Country(id: "IT", name: "Italy", dialCode: "39", flag: "🇮🇹", format: "312 345 6789", minLength: 9, maxLength: 10),
        Country(id: "AT", name: "Austria", dialCode: "43", flag: "🇦🇹", format: "664 123456", minLength: 10, maxLength: 13),
        Country(id: "US", name: "United States", dialCode: "1", flag: "🇺🇸", format: "(555) 123-4567", minLength: 10, maxLength: 10),
        Country(id: "GB", name: "United Kingdom", dialCode: "44", flag: "🇬🇧", format: "7400 123456", minLength: 10, maxLength: 10),

        // Rest of the world (alphabetically)
        Country(id: "AF", name: "Afghanistan", dialCode: "93", flag: "🇦🇫", format: nil, minLength: 9, maxLength: 9),
        Country(id: "AL", name: "Albania", dialCode: "355", flag: "🇦🇱", format: nil, minLength: 8, maxLength: 9),
        Country(id: "DZ", name: "Algeria", dialCode: "213", flag: "🇩🇿", format: nil, minLength: 9, maxLength: 9),
        Country(id: "AD", name: "Andorra", dialCode: "376", flag: "🇦🇩", format: nil, minLength: 6, maxLength: 9),
        Country(id: "AO", name: "Angola", dialCode: "244", flag: "🇦🇴", format: nil, minLength: 9, maxLength: 9),
        Country(id: "AR", name: "Argentina", dialCode: "54", flag: "🇦🇷", format: nil, minLength: 10, maxLength: 11),
        Country(id: "AM", name: "Armenia", dialCode: "374", flag: "🇦🇲", format: nil, minLength: 8, maxLength: 8),
        Country(id: "AU", name: "Australia", dialCode: "61", flag: "🇦🇺", format: "412 345 678", minLength: 9, maxLength: 9),
        Country(id: "AZ", name: "Azerbaijan", dialCode: "994", flag: "🇦🇿", format: nil, minLength: 9, maxLength: 9),
        Country(id: "BH", name: "Bahrain", dialCode: "973", flag: "🇧🇭", format: nil, minLength: 8, maxLength: 8),
        Country(id: "BD", name: "Bangladesh", dialCode: "880", flag: "🇧🇩", format: nil, minLength: 10, maxLength: 10),
        Country(id: "BY", name: "Belarus", dialCode: "375", flag: "🇧🇾", format: nil, minLength: 9, maxLength: 9),
        Country(id: "BE", name: "Belgium", dialCode: "32", flag: "🇧🇪", format: "470 12 34 56", minLength: 9, maxLength: 9),
        Country(id: "BZ", name: "Belize", dialCode: "501", flag: "🇧🇿", format: nil, minLength: 7, maxLength: 7),
        Country(id: "BJ", name: "Benin", dialCode: "229", flag: "🇧🇯", format: nil, minLength: 8, maxLength: 8),
        Country(id: "BO", name: "Bolivia", dialCode: "591", flag: "🇧🇴", format: nil, minLength: 8, maxLength: 8),
        Country(id: "BA", name: "Bosnia", dialCode: "387", flag: "🇧🇦", format: nil, minLength: 8, maxLength: 9),
        Country(id: "BW", name: "Botswana", dialCode: "267", flag: "🇧🇼", format: nil, minLength: 8, maxLength: 8),
        Country(id: "BR", name: "Brazil", dialCode: "55", flag: "🇧🇷", format: "11 91234-5678", minLength: 10, maxLength: 11),
        Country(id: "BN", name: "Brunei", dialCode: "673", flag: "🇧🇳", format: nil, minLength: 7, maxLength: 7),
        Country(id: "BG", name: "Bulgaria", dialCode: "359", flag: "🇧🇬", format: nil, minLength: 9, maxLength: 9),
        Country(id: "KH", name: "Cambodia", dialCode: "855", flag: "🇰🇭", format: nil, minLength: 8, maxLength: 9),
        Country(id: "CM", name: "Cameroon", dialCode: "237", flag: "🇨🇲", format: nil, minLength: 9, maxLength: 9),
        Country(id: "CA", name: "Canada", dialCode: "1", flag: "🇨🇦", format: "(555) 123-4567", minLength: 10, maxLength: 10),
        Country(id: "CL", name: "Chile", dialCode: "56", flag: "🇨🇱", format: nil, minLength: 9, maxLength: 9),
        Country(id: "CN", name: "China", dialCode: "86", flag: "🇨🇳", format: "131 2345 6789", minLength: 11, maxLength: 11),
        Country(id: "CO", name: "Colombia", dialCode: "57", flag: "🇨🇴", format: nil, minLength: 10, maxLength: 10),
        Country(id: "CR", name: "Costa Rica", dialCode: "506", flag: "🇨🇷", format: nil, minLength: 8, maxLength: 8),
        Country(id: "HR", name: "Croatia", dialCode: "385", flag: "🇭🇷", format: nil, minLength: 8, maxLength: 9),
        Country(id: "CU", name: "Cuba", dialCode: "53", flag: "🇨🇺", format: nil, minLength: 8, maxLength: 8),
        Country(id: "CY", name: "Cyprus", dialCode: "357", flag: "🇨🇾", format: nil, minLength: 8, maxLength: 8),
        Country(id: "CZ", name: "Czech Republic", dialCode: "420", flag: "🇨🇿", format: nil, minLength: 9, maxLength: 9),
        Country(id: "DK", name: "Denmark", dialCode: "45", flag: "🇩🇰", format: "32 12 34 56", minLength: 8, maxLength: 8),
        Country(id: "DO", name: "Dominican Rep.", dialCode: "1", flag: "🇩🇴", format: nil, minLength: 10, maxLength: 10),
        Country(id: "EC", name: "Ecuador", dialCode: "593", flag: "🇪🇨", format: nil, minLength: 9, maxLength: 9),
        Country(id: "EG", name: "Egypt", dialCode: "20", flag: "🇪🇬", format: nil, minLength: 10, maxLength: 10),
        Country(id: "SV", name: "El Salvador", dialCode: "503", flag: "🇸🇻", format: nil, minLength: 8, maxLength: 8),
        Country(id: "EE", name: "Estonia", dialCode: "372", flag: "🇪🇪", format: nil, minLength: 7, maxLength: 8),
        Country(id: "ET", name: "Ethiopia", dialCode: "251", flag: "🇪🇹", format: nil, minLength: 9, maxLength: 9),
        Country(id: "FI", name: "Finland", dialCode: "358", flag: "🇫🇮", format: nil, minLength: 9, maxLength: 10),
        Country(id: "GE", name: "Georgia", dialCode: "995", flag: "🇬🇪", format: nil, minLength: 9, maxLength: 9),
        Country(id: "GH", name: "Ghana", dialCode: "233", flag: "🇬🇭", format: nil, minLength: 9, maxLength: 9),
        Country(id: "GR", name: "Greece", dialCode: "30", flag: "🇬🇷", format: nil, minLength: 10, maxLength: 10),
        Country(id: "GT", name: "Guatemala", dialCode: "502", flag: "🇬🇹", format: nil, minLength: 8, maxLength: 8),
        Country(id: "HN", name: "Honduras", dialCode: "504", flag: "🇭🇳", format: nil, minLength: 8, maxLength: 8),
        Country(id: "HK", name: "Hong Kong", dialCode: "852", flag: "🇭🇰", format: nil, minLength: 8, maxLength: 8),
        Country(id: "HU", name: "Hungary", dialCode: "36", flag: "🇭🇺", format: nil, minLength: 9, maxLength: 9),
        Country(id: "IS", name: "Iceland", dialCode: "354", flag: "🇮🇸", format: nil, minLength: 7, maxLength: 7),
        Country(id: "IN", name: "India", dialCode: "91", flag: "🇮🇳", format: "81234 56789", minLength: 10, maxLength: 10),
        Country(id: "ID", name: "Indonesia", dialCode: "62", flag: "🇮🇩", format: nil, minLength: 9, maxLength: 12),
        Country(id: "IR", name: "Iran", dialCode: "98", flag: "🇮🇷", format: nil, minLength: 10, maxLength: 10),
        Country(id: "IQ", name: "Iraq", dialCode: "964", flag: "🇮🇶", format: nil, minLength: 10, maxLength: 10),
        Country(id: "IE", name: "Ireland", dialCode: "353", flag: "🇮🇪", format: nil, minLength: 9, maxLength: 9),
        Country(id: "IL", name: "Israel", dialCode: "972", flag: "🇮🇱", format: nil, minLength: 9, maxLength: 9),
        Country(id: "JM", name: "Jamaica", dialCode: "1", flag: "🇯🇲", format: nil, minLength: 10, maxLength: 10),
        Country(id: "JP", name: "Japan", dialCode: "81", flag: "🇯🇵", format: "90 1234 5678", minLength: 10, maxLength: 10),
        Country(id: "JO", name: "Jordan", dialCode: "962", flag: "🇯🇴", format: nil, minLength: 9, maxLength: 9),
        Country(id: "KZ", name: "Kazakhstan", dialCode: "7", flag: "🇰🇿", format: nil, minLength: 10, maxLength: 10),
        Country(id: "KE", name: "Kenya", dialCode: "254", flag: "🇰🇪", format: nil, minLength: 9, maxLength: 10),
        Country(id: "KW", name: "Kuwait", dialCode: "965", flag: "🇰🇼", format: nil, minLength: 8, maxLength: 8),
        Country(id: "KG", name: "Kyrgyzstan", dialCode: "996", flag: "🇰🇬", format: nil, minLength: 9, maxLength: 9),
        Country(id: "LA", name: "Laos", dialCode: "856", flag: "🇱🇦", format: nil, minLength: 9, maxLength: 10),
        Country(id: "LV", name: "Latvia", dialCode: "371", flag: "🇱🇻", format: nil, minLength: 8, maxLength: 8),
        Country(id: "LB", name: "Lebanon", dialCode: "961", flag: "🇱🇧", format: nil, minLength: 7, maxLength: 8),
        Country(id: "LY", name: "Libya", dialCode: "218", flag: "🇱🇾", format: nil, minLength: 9, maxLength: 10),
        Country(id: "LI", name: "Liechtenstein", dialCode: "423", flag: "🇱🇮", format: nil, minLength: 7, maxLength: 9),
        Country(id: "LT", name: "Lithuania", dialCode: "370", flag: "🇱🇹", format: nil, minLength: 8, maxLength: 8),
        Country(id: "LU", name: "Luxembourg", dialCode: "352", flag: "🇱🇺", format: nil, minLength: 9, maxLength: 9),
        Country(id: "MO", name: "Macau", dialCode: "853", flag: "🇲🇴", format: nil, minLength: 8, maxLength: 8),
        Country(id: "MK", name: "Macedonia", dialCode: "389", flag: "🇲🇰", format: nil, minLength: 8, maxLength: 8),
        Country(id: "MY", name: "Malaysia", dialCode: "60", flag: "🇲🇾", format: nil, minLength: 9, maxLength: 10),
        Country(id: "MV", name: "Maldives", dialCode: "960", flag: "🇲🇻", format: nil, minLength: 7, maxLength: 7),
        Country(id: "MT", name: "Malta", dialCode: "356", flag: "🇲🇹", format: nil, minLength: 8, maxLength: 8),
        Country(id: "MX", name: "Mexico", dialCode: "52", flag: "🇲🇽", format: nil, minLength: 10, maxLength: 10),
        Country(id: "MD", name: "Moldova", dialCode: "373", flag: "🇲🇩", format: nil, minLength: 8, maxLength: 8),
        Country(id: "MC", name: "Monaco", dialCode: "377", flag: "🇲🇨", format: nil, minLength: 8, maxLength: 9),
        Country(id: "MN", name: "Mongolia", dialCode: "976", flag: "🇲🇳", format: nil, minLength: 8, maxLength: 8),
        Country(id: "ME", name: "Montenegro", dialCode: "382", flag: "🇲🇪", format: nil, minLength: 8, maxLength: 8),
        Country(id: "MA", name: "Morocco", dialCode: "212", flag: "🇲🇦", format: nil, minLength: 9, maxLength: 9),
        Country(id: "MZ", name: "Mozambique", dialCode: "258", flag: "🇲🇿", format: nil, minLength: 9, maxLength: 9),
        Country(id: "MM", name: "Myanmar", dialCode: "95", flag: "🇲🇲", format: nil, minLength: 8, maxLength: 10),
        Country(id: "NA", name: "Namibia", dialCode: "264", flag: "🇳🇦", format: nil, minLength: 9, maxLength: 10),
        Country(id: "NP", name: "Nepal", dialCode: "977", flag: "🇳🇵", format: nil, minLength: 10, maxLength: 10),
        Country(id: "NL", name: "Netherlands", dialCode: "31", flag: "🇳🇱", format: "6 12345678", minLength: 9, maxLength: 9),
        Country(id: "NZ", name: "New Zealand", dialCode: "64", flag: "🇳🇿", format: nil, minLength: 8, maxLength: 10),
        Country(id: "NI", name: "Nicaragua", dialCode: "505", flag: "🇳🇮", format: nil, minLength: 8, maxLength: 8),
        Country(id: "NG", name: "Nigeria", dialCode: "234", flag: "🇳🇬", format: nil, minLength: 10, maxLength: 10),
        Country(id: "NO", name: "Norway", dialCode: "47", flag: "🇳🇴", format: "406 12 345", minLength: 8, maxLength: 8),
        Country(id: "OM", name: "Oman", dialCode: "968", flag: "🇴🇲", format: nil, minLength: 8, maxLength: 8),
        Country(id: "PK", name: "Pakistan", dialCode: "92", flag: "🇵🇰", format: nil, minLength: 10, maxLength: 10),
        Country(id: "PA", name: "Panama", dialCode: "507", flag: "🇵🇦", format: nil, minLength: 8, maxLength: 8),
        Country(id: "PY", name: "Paraguay", dialCode: "595", flag: "🇵🇾", format: nil, minLength: 9, maxLength: 9),
        Country(id: "PE", name: "Peru", dialCode: "51", flag: "🇵🇪", format: nil, minLength: 9, maxLength: 9),
        Country(id: "PH", name: "Philippines", dialCode: "63", flag: "🇵🇭", format: nil, minLength: 10, maxLength: 10),
        Country(id: "PL", name: "Poland", dialCode: "48", flag: "🇵🇱", format: nil, minLength: 9, maxLength: 9),
        Country(id: "PT", name: "Portugal", dialCode: "351", flag: "🇵🇹", format: nil, minLength: 9, maxLength: 9),
        Country(id: "PR", name: "Puerto Rico", dialCode: "1", flag: "🇵🇷", format: nil, minLength: 10, maxLength: 10),
        Country(id: "QA", name: "Qatar", dialCode: "974", flag: "🇶🇦", format: nil, minLength: 8, maxLength: 8),
        Country(id: "RO", name: "Romania", dialCode: "40", flag: "🇷🇴", format: nil, minLength: 10, maxLength: 10),
        Country(id: "RU", name: "Russia", dialCode: "7", flag: "🇷🇺", format: "912 345-67-89", minLength: 10, maxLength: 10),
        Country(id: "SA", name: "Saudi Arabia", dialCode: "966", flag: "🇸🇦", format: nil, minLength: 9, maxLength: 9),
        Country(id: "SN", name: "Senegal", dialCode: "221", flag: "🇸🇳", format: nil, minLength: 9, maxLength: 9),
        Country(id: "RS", name: "Serbia", dialCode: "381", flag: "🇷🇸", format: nil, minLength: 8, maxLength: 9),
        Country(id: "SG", name: "Singapore", dialCode: "65", flag: "🇸🇬", format: nil, minLength: 8, maxLength: 8),
        Country(id: "SK", name: "Slovakia", dialCode: "421", flag: "🇸🇰", format: nil, minLength: 9, maxLength: 9),
        Country(id: "SI", name: "Slovenia", dialCode: "386", flag: "🇸🇮", format: nil, minLength: 8, maxLength: 8),
        Country(id: "ZA", name: "South Africa", dialCode: "27", flag: "🇿🇦", format: nil, minLength: 9, maxLength: 9),
        Country(id: "KR", name: "South Korea", dialCode: "82", flag: "🇰🇷", format: nil, minLength: 10, maxLength: 11),
        Country(id: "ES", name: "Spain", dialCode: "34", flag: "🇪🇸", format: nil, minLength: 9, maxLength: 9),
        Country(id: "LK", name: "Sri Lanka", dialCode: "94", flag: "🇱🇰", format: nil, minLength: 9, maxLength: 9),
        Country(id: "SE", name: "Sweden", dialCode: "46", flag: "🇸🇪", format: "70 123 45 67", minLength: 9, maxLength: 9),
        Country(id: "SY", name: "Syria", dialCode: "963", flag: "🇸🇾", format: nil, minLength: 9, maxLength: 9),
        Country(id: "TW", name: "Taiwan", dialCode: "886", flag: "🇹🇼", format: nil, minLength: 9, maxLength: 9),
        Country(id: "TJ", name: "Tajikistan", dialCode: "992", flag: "🇹🇯", format: nil, minLength: 9, maxLength: 9),
        Country(id: "TZ", name: "Tanzania", dialCode: "255", flag: "🇹🇿", format: nil, minLength: 9, maxLength: 9),
        Country(id: "TH", name: "Thailand", dialCode: "66", flag: "🇹🇭", format: nil, minLength: 9, maxLength: 9),
        Country(id: "TN", name: "Tunisia", dialCode: "216", flag: "🇹🇳", format: nil, minLength: 8, maxLength: 8),
        Country(id: "TR", name: "Turkey", dialCode: "90", flag: "🇹🇷", format: nil, minLength: 10, maxLength: 10),
        Country(id: "TM", name: "Turkmenistan", dialCode: "993", flag: "🇹🇲", format: nil, minLength: 8, maxLength: 8),
        Country(id: "UG", name: "Uganda", dialCode: "256", flag: "🇺🇬", format: nil, minLength: 9, maxLength: 9),
        Country(id: "UA", name: "Ukraine", dialCode: "380", flag: "🇺🇦", format: nil, minLength: 9, maxLength: 9),
        Country(id: "AE", name: "UAE", dialCode: "971", flag: "🇦🇪", format: nil, minLength: 9, maxLength: 9),
        Country(id: "UY", name: "Uruguay", dialCode: "598", flag: "🇺🇾", format: nil, minLength: 8, maxLength: 8),
        Country(id: "UZ", name: "Uzbekistan", dialCode: "998", flag: "🇺🇿", format: nil, minLength: 9, maxLength: 9),
        Country(id: "VE", name: "Venezuela", dialCode: "58", flag: "🇻🇪", format: nil, minLength: 10, maxLength: 10),
        Country(id: "VN", name: "Vietnam", dialCode: "84", flag: "🇻🇳", format: nil, minLength: 9, maxLength: 10),
        Country(id: "YE", name: "Yemen", dialCode: "967", flag: "🇾🇪", format: nil, minLength: 9, maxLength: 9),
        Country(id: "ZM", name: "Zambia", dialCode: "260", flag: "🇿🇲", format: nil, minLength: 9, maxLength: 9),
        Country(id: "ZW", name: "Zimbabwe", dialCode: "263", flag: "🇿🇼", format: nil, minLength: 9, maxLength: 9),
    ]

    /// Popular countries (shown at top of list)
    static let popular: [Country] = [
        all.first { $0.id == "CH" }!, // Switzerland
        all.first { $0.id == "DE" }!, // Germany
        all.first { $0.id == "FR" }!, // France
        all.first { $0.id == "IT" }!, // Italy
        all.first { $0.id == "AT" }!, // Austria
        all.first { $0.id == "US" }!, // United States
        all.first { $0.id == "GB" }!, // United Kingdom
    ]

    /// Default country (Switzerland)
    nonisolated static let `default` = all.first { $0.id == "CH" }!

    /// Find country by ISO code
    static func find(byCode code: String) -> Country? {
        all.first { $0.id == code }
    }

    /// Find country by dial code
    static func find(byDialCode dialCode: String) -> Country? {
        all.first { $0.dialCode == dialCode }
    }
}
