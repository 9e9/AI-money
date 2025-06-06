//
//  ChartView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct ChartView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @StateObject private var vm: ChartViewModel

    init(viewModel: ExpenseViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _vm = StateObject(wrappedValue: ChartViewModel(expenseViewModel: viewModel))
    }

    var body: some View {
        VStack {
            Text("원형 차트")
                .font(.headline)

            if vm.filteredExpenses.isEmpty {
                DottedPieChartView()
                    .frame(height: 200)
            } else {
                PieChartView(data: Dictionary(uniqueKeysWithValues: vm.sortedCategoryTotals))
                    .frame(height: 200)
            }

            Divider()
                .padding(.vertical, 10)
            
            HStack {
                Text("카테고리별 총 지출")
                    .font(.headline)

                Spacer()

                Menu {
                    Button(action: { vm.sortOrder = .defaultOrder }) {
                        Label("기본순", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    Button(action: { vm.sortOrder = .highToLow }) {
                        Label("높은 순", systemImage: "arrow.down")
                    }
                    Button(action: { vm.sortOrder = .lowToHigh }) {
                        Label("낮은 순", systemImage: "arrow.up")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                }
            }
            .padding(.horizontal)

            HStack {
                Button(action: {
                    vm.isShowingYearMonthPicker = true
                }) {
                    Text("\(vm.formatYear(vm.selectedYear))년 \(vm.selectedMonth)월")
                        .foregroundColor(.black)
                }
                
                Button(action: {
                    vm.resetToCurrentDate()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                Spacer()
            }
            .padding(.horizontal)

            List {
                ForEach(vm.sortedCategoryTotals, id: \.0) { category, total in
                    HStack {
                        Text(category)
                            .font(.body)
                        Spacer()
                        Text("\(Int(total)) 원")
                            .fontWeight(.bold)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .padding()
        .sheet(isPresented: $vm.isShowingYearMonthPicker) {
            YearMonthPickerView(
                viewModel: viewModel,
                selectedYear: $vm.selectedYear,
                selectedMonth: $vm.selectedMonth,
                showingPicker: $vm.isShowingYearMonthPicker
            )
        }
    }
}

struct DottedPieChartView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(.gray)
                .padding()
            Text("지출 없음")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
}
