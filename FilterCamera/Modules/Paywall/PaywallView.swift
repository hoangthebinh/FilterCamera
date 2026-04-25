//
//  PaywallView.swift
//  FilterCamera
//
//  Created by binh on 25/04/2026.
//

import SwiftUI

struct PaywallView: View {
    
    @StateObject private var viewModel = PaywallViewModel()
    
    var body: some View {
        ZStack {
            
            Image("paywall_background")
                .resizable()
                .scaledToFill()
                .offset(x: -30)
                .ignoresSafeArea()
            
            LinearGradient(
                colors: [
                    Color.black.opacity(0.8),
                    Color.black.opacity(0.6),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Text("Choose your plan")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                HStack(spacing: 20) {
                    ForEach(viewModel.plans.indices, id: \.self) { index in
                        
                        PlanCard(
                            plan: viewModel.plans[index],
                            isSelected: viewModel.selectedIndex == index
                        )
                        .onTapGesture {
                            viewModel.selectedIndex = index
                        }
                    }
                }
                .padding(.top, 20)
                
                Text(viewModel.plans[viewModel.selectedIndex].info)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .cornerRadius(24)
                    .padding(.top, 10)

                Button(action: {
                    print("Selected: \(viewModel.selectedIndex)")
                }) {
                    Text("Continue")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo)
                        .cornerRadius(24)
                }
                .padding(.top, 10)
                
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    struct PlanCard: View {
        let plan: Plan
        let isSelected: Bool
        
        var body: some View {
            VStack(spacing: 12) {
                
                Text(plan.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .indigo)
                
                ForEach(plan.features, id: \.self) { feature in
                    HStack {
                        Text(feature)
                    }
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .black)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.indigo : Color.white)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    PaywallView()
}
