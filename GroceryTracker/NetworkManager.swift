import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case unknown(Error)
}

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL: URL

    init() {
        guard
            let urlString = Bundle.main.object(
                forInfoDictionaryKey: "BackendBaseURL") as? String
        else {
            fatalError("Backend URL environment variable not configured.")
        }
        if urlString.isEmpty {
            fatalError("Backend URL environment variable was empty.")
        }
        guard let url = URL(string: urlString) else {
            fatalError("Backend URL environment variable was invalid.")
        }
        self.baseURL = url
    }

    private func performPostRequest<T: Encodable, U: Decodable>(
        endpoint: String, body: T
    )
        async throws -> U
    {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(body)
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        let datefmt = DateFormatter()
        datefmt.dateFormat = "yyyy-MM-dd"

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(datefmt)
        let decoded = try decoder.decode(U.self, from: data)
        return decoded
    }

    func uploadProduct(_ product: ProductData) async throws -> PricesResponse {
        return try await performPostRequest(endpoint: "/prices", body: product)
    }

    struct StoreResponse: Decodable {
        let id: Int
    }

    func uploadStore(_ store: StoreRecord) async throws -> Int {
        let response: StoreResponse = try await performPostRequest(
            endpoint: "/stores", body: store)
        return response.id
    }
}
