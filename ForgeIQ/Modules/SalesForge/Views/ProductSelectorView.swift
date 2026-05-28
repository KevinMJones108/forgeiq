// ForgeIQ Product Selector View
// Session 12 — Select product for call recording

import SwiftUI

struct ProductSelectorView: View {
    @Binding var selectedProduct: Product?
    let products: [Product]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Product (Optional)")
                .font(.headline)
                .foregroundColor(.white)

            if products.isEmpty {
                Text("No products added yet")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // "No product" option
                        ProductChip(
                            name: "None",
                            isSelected: selectedProduct == nil
                        ) {
                            selectedProduct = nil
                        }

                        // Product list
                        ForEach(products) { product in
                            ProductChip(
                                name: product.name,
                                isSelected: selectedProduct?.id == product.id
                            ) {
                                selectedProduct = product
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Product Chip
struct ProductChip: View {
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "#00C853") : Color.gray.opacity(0.2))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color(hex: "#00C853") : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct ProductSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(hex: "#1C2B2B").ignoresSafeArea()
            ProductSelectorView(
                selectedProduct: .constant(nil),
                products: Product.samples
            )
        }
    }
}
