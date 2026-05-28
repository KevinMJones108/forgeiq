// ForgeIQ Product Library ViewModel
// Session 12 — Manages products API calls

import Foundation
import Combine

@MainActor
class ProductLibraryViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let baseURL = Constants.API_BASE_URL

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "\(baseURL)/api/v1/products") else {
            errorMessage = "Invalid API URL"
            isLoading = false
            return
        }

        guard let token = AuthTokenManager.shared.getToken() else {
            errorMessage = "Not authenticated"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                errorMessage = "Failed to load products"
                isLoading = false
                return
            }

            let apiResponse = try JSONDecoder().decode(APIResponse<[Product]>.self, from: data)
            products = apiResponse.data ?? []
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Create Product
    func createProduct(_ product: Product) async {
        guard let url = URL(string: "\(baseURL)/api/v1/products") else { return }
        guard let token = AuthTokenManager.shared.getToken() else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "name": product.name,
            "category": product.category as Any,
            "specs": product.specs
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 201 else {
                errorMessage = "Failed to create product"
                return
            }

            let apiResponse = try JSONDecoder().decode(APIResponse<Product>.self, from: data)
            if let newProduct = apiResponse.data {
                products.insert(newProduct, at: 0)
            }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Update Product
    func updateProduct(_ product: Product) async {
        guard let url = URL(string: "\(baseURL)/api/v1/products/\(product.id)") else { return }
        guard let token = AuthTokenManager.shared.getToken() else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "name": product.name,
            "category": product.category as Any,
            "specs": product.specs
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                errorMessage = "Failed to update product"
                return
            }

            let apiResponse = try JSONDecoder().decode(APIResponse<Product>.self, from: data)
            if let updatedProduct = apiResponse.data,
               let index = products.firstIndex(where: { $0.id == product.id }) {
                products[index] = updatedProduct
            }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete Product
    func deleteProduct(_ id: UUID) async {
        guard let url = URL(string: "\(baseURL)/api/v1/products/\(id)") else { return }
        guard let token = AuthTokenManager.shared.getToken() else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                errorMessage = "Failed to delete product"
                return
            }

            products.removeAll { $0.id == id }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - API Response Wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
}
