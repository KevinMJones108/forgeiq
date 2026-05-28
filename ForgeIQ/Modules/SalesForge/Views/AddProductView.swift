// ForgeIQ Add Product View
// Session 12 — Create new product with specs

import SwiftUI

struct AddProductView: View {
    let onSave: (Product) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = ""
    @State private var specs: [SpecEntry] = [SpecEntry(key: "", value: "")]

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#1C2B2B").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Product Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Product Name")
                                .font(.headline)
                                .foregroundColor(.white)
                            TextField("e.g., CAT 320 Excavator", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category (Optional)")
                                .font(.headline)
                                .foregroundColor(.white)
                            TextField("e.g., Heavy Equipment", text: $category)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        // Specs
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Specifications")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Spacer()

                                Button {
                                    specs.append(SpecEntry(key: "", value: ""))
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(Color(hex: "#00C853"))
                                }
                            }

                            ForEach(specs.indices, id: \.self) { index in
                                HStack(spacing: 8) {
                                    TextField("Key (e.g., Horsepower)", text: $specs[index].key)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())

                                    TextField("Value (e.g., 168 HP)", text: $specs[index].value)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())

                                    Button {
                                        specs.remove(at: index)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }

                        // Save Button
                        Button {
                            saveProduct()
                        } label: {
                            Text("Save Product")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(canSave ? Color(hex: "#00C853") : Color.gray)
                                .cornerRadius(12)
                        }
                        .disabled(!canSave)
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
    }

    // MARK: - Computed Properties
    private var canSave: Bool {
        !name.isEmpty && specs.allSatisfy { !$0.key.isEmpty && !$0.value.isEmpty }
    }

    // MARK: - Actions
    private func saveProduct() {
        let specsDict = Dictionary(uniqueKeysWithValues: specs.map { ($0.key, $0.value) })
        let product = Product(
            name: name,
            category: category.isEmpty ? nil : category,
            specs: specsDict
        )
        onSave(product)
        dismiss()
    }
}

// MARK: - Supporting Types
struct SpecEntry: Identifiable {
    let id = UUID()
    var key: String
    var value: String
}

// MARK: - Preview
struct AddProductView_Previews: PreviewProvider {
    static var previews: some View {
        AddProductView(onSave: { _ in })
    }
}
