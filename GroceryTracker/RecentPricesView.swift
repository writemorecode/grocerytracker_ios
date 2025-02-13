import SwiftUI

struct Price: Identifiable, Decodable {
    let id = UUID()
    let name: String
    let price: Double
    let absolutePriceChange: Double
    let relativePriceChange: Double

    let storeName: String
    let date: Date

    private enum CodingKeys: String, CodingKey {
        case price
        case name
        case absolutePriceChange
        case relativePriceChange
        case storeName
        case date
    }

    private func formatNumberAsCurrency(_ number: Double) -> String? {
        let fmt = NumberFormatter()
        fmt.locale = Locale.current
        fmt.numberStyle = .currency
        let number = NSNumber(value: price)
        return fmt.string(from: number)
    }

    func printDate() -> String {
        let fmt = RelativeDateTimeFormatter()
        fmt.dateTimeStyle = .numeric
        return fmt.localizedString(for: date, relativeTo: Date.now)
    }

    func printPrice() -> String {
        return formatNumberAsCurrency(price) ?? ""
    }

    func printAbsolutePriceChange() -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.positivePrefix = "+"
        fmt.negativePrefix = "-"
        let number = NSNumber(value: absolutePriceChange)
        let currencyString = fmt.string(from: number)
        return currencyString ?? ""
    }
    func printRelativePriceChange() -> String {
        let fmt = NumberFormatter()
        fmt.positivePrefix = "+"
        fmt.negativePrefix = "-"
        fmt.numberStyle = .percent
        let number = NSNumber(value: relativePriceChange)
        return fmt.string(from: number) ?? ""
    }

}

typealias PricesResponse = [Price]

struct RecentPricesView: View {
    let prices: [Price]

    var body: some View {
        NavigationView {
            List(prices, id: \.id) { priceInfo in
                VStack(alignment: .leading) {
                    Text(priceInfo.name)
                    HStack {
                        Text(priceInfo.storeName)
                        Text(priceInfo.printDate())

                    }
                    HStack {
                        Text(priceInfo.printPrice())
                        Text(priceInfo.printRelativePriceChange())
                            .foregroundStyle(
                                priceInfo.relativePriceChange >= 0
                                    ? .red : .green
                            )
                        Text(priceInfo.printAbsolutePriceChange())
                            .foregroundStyle(
                                priceInfo.absolutePriceChange >= 0
                                    ? .red : .green
                            )
                    }
                }
            }
            .navigationTitle("Recent Nearby Prices")
        }
    }
}

