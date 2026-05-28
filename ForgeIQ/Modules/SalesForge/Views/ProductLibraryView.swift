// ForgeIQ Product Library View
// Session 12 — Product spec management for sales reps

import SwiftUI

struct ProductLibraryView: View {
    @StateObject private var viewModel = ProductLibraryViewModel()
    @State private var showingAddProduct = false

    var body: some View {
        NavigationView {
            ZStack {
                // FORGE dark background
                Color(hex: "#1C2B2B")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView("Loading products...")
                            .foregroundColor(.white)
                            .padding()
                    } else if viewModel.products.isEmpty {
                        emptyStateView
                    } else {
                        productsList
                    }
                }
            }
            .navigationTitle("Product Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddProduct = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(hex: "#00C853")) // ForgeGreen
                    }
                }
            }
            .sheet(isPresented: $showingAddProduct) {
                AddProductView(onSave: { product in
                    Task {
                        await viewModel.createProduct(product)
                    }
                })
            }
            .task {
                await viewModel.loadProducts()
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "shippingbox")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Products Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("Add product specs to reference during sales calls")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showingAddProduct = true
            } label: {
                Text("Add Your First Product")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#00C853")) // ForgeGreen
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
    }

    // MARK: - Products List
    private var productsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.products) { product in
                    NavigationLink(destination: ProductDetailView(product: product, onUpdate: { updated in
                        Task {
                            await viewModel.updateProduct(updated)
                        }
                    }, onDelete: {
                        Task {
                            await viewModel.deleteProduct(product.id)
                        }
                    })) {
                        ProductCard(product: product)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(product.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if let category = product.category {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            }

            Text("\(product.specs.count) specs")
                .font(.caption)
                .foregroundColor(.gray)

            // Show first 3 specs as preview
            let previewSpecs = Array(product.specs.prefix(3))
            ForEach(previewSpecs, id: \.key) { key, value in
                HStack {
                    Text(key)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(value)
                        .font(.caption)
                        .foregroundColor(Color(hex: "#00C853")) // ForgeGreen
                }
            }

            Text(product.createdAt, style: .date)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct ProductLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        ProductLibraryView()
    }
}
