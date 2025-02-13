import SwiftUI

struct Price: Identifiable, Decodable {
    let id = UUID()
    let name: String
    let price: Decimal
    let absolutePriceChange: Decimal
    let relativePriceChange: Decimal

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

    func printDate() -> String {
        let fmt = RelativeDateTimeFormatter()
        fmt.dateTimeStyle = .numeric
        return fmt.localizedString(for: date, relativeTo: Date.now)
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
                        Text(
                            priceInfo.price.formatted(.currency(code: "SEK"))
                        )

                        Text(
                            priceInfo.relativePriceChange.formatted(
                                .percent
                                    .precision(.fractionLength(2))
                                    .sign(strategy: .always())
                            )
                        )
                        .foregroundStyle(
                            priceInfo.relativePriceChange >= 0
                                ? .red : .green
                        )
                        Text(
                            priceInfo.absolutePriceChange.formatted(
                                .currency(code: "SEK")
                                    .sign(strategy: .always())

                            )
                        ).foregroundStyle(
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

func get_date() -> Date {
    var date = DateComponents()
    date.year = 2025
    date.month = 2
    date.day = 5
    date.timeZone = TimeZone(secondsFromGMT: 0)
    let calendar = Calendar(identifier: .gregorian)
    return calendar.date(from: date)!
}

#Preview {
    RecentPricesView(prices: [
        Price(
            name: "Coffee", price: 12.34, absolutePriceChange: 3.12,
            relativePriceChange: 0.0765, storeName: "Cool Store",
            date: get_date()
        )
    ])
}
