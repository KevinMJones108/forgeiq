// ForgeIQ Product Detail View
// Session 12 — View and edit product specs

import SwiftUI

struct ProductDetailView: View {
    let product: Product
    let onUpdate: (Product) -> Void
    let onDelete: () -> Void

    @State private var editedProduct: Product
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    init(product: Product, onUpdate: @escaping (Product) -> Void, onDelete: @escaping () -> Void) {
        self.product = product
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _editedProduct = State(initialValue: product)
    }

    var body: some View {
        ZStack {
            Color(hex: "#1C2B2B").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Name and Category
                    if isEditing {
                        TextField("Product Name", text: Binding(
                            get: { editedProduct.name },
                            set: { editedProduct = Product(id: editedProduct.id, name: $0, category: editedProduct.category, specs: editedProduct.specs) }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Category (optional)", text: Binding(
                            get: { editedProduct.category ?? "" },
                            set: { editedProduct = Product(id: editedProduct.id, name: editedProduct.name, category: $0.isEmpty ? nil : $0, specs: editedProduct.specs) }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text(product.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        if let category = product.category {
                            Text(category)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    Divider()
                        .background(.gray)

                    // Specs
                    Text("Specifications")
                        .font(.headline)
                        .foregroundColor(.white)

                    ForEach(Array(product.specs.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        HStack(alignment: .top) {
                            Text(key)
                                .font(.body)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(value)
                                .font(.body)
                                .foregroundColor(Color(hex: "#00C853")) // ForgeGreen
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.vertical, 4)
                    }

                    Spacer(minLength: 40)

                    // Delete Button
                    Button {
                        showingDeleteAlert = true
                    } label: {
                        Text("Delete Product")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
        }
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Product?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

// MARK: - Preview
struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProductDetailView(
                product: Product.sampleExcavator,
                onUpdate: { _ in },
                onDelete: { }
            )
        }
    }
}
