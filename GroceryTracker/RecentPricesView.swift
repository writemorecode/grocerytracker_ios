import SwiftUI

struct RecentPricesView: View {
    let prices: [NetworkManager.Price]

    var body: some View {
        NavigationView {
            List(prices, id: \.price) { priceInfo in
                VStack(alignment: .leading) {
                    Text("Price: \(priceInfo.price)")
                    if let storeName = priceInfo.store_name {
                        Text("Store: \(storeName)")
                    }
                    if let distance = priceInfo.distance {
                        Text("Distance: \(distance, specifier: "%.2f") km")
                    }
                }
            }
            .navigationTitle("Recent Nearby Prices")
        }
    }
}
