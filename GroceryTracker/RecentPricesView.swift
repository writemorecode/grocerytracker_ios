import SwiftUI

struct Price: Identifiable, Decodable {
    let id = UUID()
    let price: Decimal
    let absolutePriceChange: Decimal
    let relativePriceChange: Decimal

    let storeName: String
    let date: Date

    private enum CodingKeys: String, CodingKey {
        case price
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

struct PricesResponse: Decodable {
    let name: String
    let prices: [Price]
}

struct RecentPricesView: View {
    let prices: PricesResponse

    var body: some View {
        NavigationView {
            VStack {
                Text(prices.name)
                    .bold()

                List(prices.prices, id: \.id) { priceInfo in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(priceInfo.storeName)
                            Text(priceInfo.printDate())
                        }

                        HStack {
                            Text(
                                priceInfo.price.formatted(
                                    .currency(code: "SEK"))
                            )

                            if priceInfo.relativePriceChange != 0 {
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
                            }

                            if priceInfo.absolutePriceChange != 0 {
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
                }
            }
            .navigationTitle("Recent Nearby Prices")
        }
    }
}
