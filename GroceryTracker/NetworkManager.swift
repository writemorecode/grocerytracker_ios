//
//  NetworkManager.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-01-18.
//

// NetworkManager.swift
import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case unknown(Error)
}

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://192.168.0.6:3000";
    
    func uploadProduct(_ product: ProductData) async throws {
        guard let url = URL(string: "\(baseURL)/products") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(product)
        request.httpBody = jsonData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
    
    struct StoreResponse: Decodable {
        let id: Int
    }

    func uploadStore(_ store: StoreRecord) async throws -> Int {
        guard let url = URL(string: "\(baseURL)/stores") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(store)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let storeResponse = try decoder.decode(StoreResponse.self, from: data)
        return storeResponse.id
    }
}
