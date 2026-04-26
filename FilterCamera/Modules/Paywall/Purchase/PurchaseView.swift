//
//  PurchaseView.swift
//  FilterCamera
//
//  Created by binh on 26/4/26.
//

import SwiftUI
import StoreKit

struct PurchaseView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PurchaseViewModel()

    var body: some View {
        ZStack {

            // MARK: - Background
            Image("paywall_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.8),
                    Color.black.opacity(0.8),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {

                Spacer()

                // MARK: - Title
                Text("Go Premium")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Unlock all features & remove ads")
                    .foregroundColor(.white.opacity(0.8))

                // MARK: - Products
                VStack(spacing: 12) {
                    ForEach(viewModel.products, id: \.id) { product in
                        productCell(product)
                    }
                }
                .padding(.horizontal)

                // MARK: - Continue
                Button {
                    Task {
                        let success = await viewModel.purchase()
                        if success {
                            appState.route = .camera
                        }
                    }
                } label: {
                    Text(viewModel.isLoading ? "Processing..." : "Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo)
                        .cornerRadius(30)
                }
                .padding(.horizontal)
                .disabled(viewModel.isLoading)

                // MARK: - Continue with Ads
                Button {
                    appState.route = .camera
                } label: {
                    Text("Continue with Ads")
                        .foregroundColor(.white.opacity(0.7))
                        .underline()
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .task {
            await viewModel.load()
        }
    }
}

extension PurchaseView {
    @ViewBuilder
    func productCell(_ product: Product) -> some View {

        let isSelected = viewModel.selectedProduct?.id == product.id

        Button {
            viewModel.selectedProduct = product
        } label: {
            ZStack(alignment: .topTrailing) {

                HStack {
                    VStack(alignment: .leading, spacing: 4) {

                        Text(product.displayName)
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(product.displayPrice)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.indigo.opacity(0.4) : Color.white.opacity(0.1))
                )

                // BEST badge (auto cho cái đắt nhất)
                if product.id.contains("yearly") {
                    Text("BEST")
                        .font(.caption)
                        .padding(6)
                        .background(Color.orange)
                        .cornerRadius(8)
                        .offset(x: -8, y: 8)
                }
            }
        }
    }
}

#Preview {
    PurchaseView()
}
