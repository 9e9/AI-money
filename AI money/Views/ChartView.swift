//
//  ChartView.swift
//  AI money
//
//  Created by 조준희 on 3/30/25.
//

import SwiftUI

struct ChartView: View {
    @ObservedObject var viewModel: ExpenseCalendarViewModel
    @StateObject private var vm: ChartViewModel
    @State private var showChart = true
    @State private var showList = true

    init(viewModel: ExpenseCalendarViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _vm = StateObject(wrappedValue: ChartViewModel(expenseViewModel: viewModel))
    }

    var body: some View {
        VStack {
            Text("원형 차트")
                .font(.headline)
            ZStack {
                if vm.filteredExpenses.isEmpty {
                    DottedPieChartView()
                        .frame(height: 200)
                        .opacity(showChart ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: showChart)
                } else {
                    PieChartView(
                        data: Dictionary(uniqueKeysWithValues: vm.sortedCategoryTotals.map { ($0.category, $0.total) })
                    )
                        .frame(height: 200)
                        .opacity(showChart ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: showChart)
                }
            }

            Divider()
                .padding(.vertical, 10)
            
            HStack {
                Text("카테고리별 총 지출")
                    .font(.headline)
                Spacer()
                Menu {
                    Button(action: { animateSortChange(to: .defaultOrder) }) {
                        Label("기본순", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    Button(action: { animateSortChange(to: .highToLow) }) {
                        Label("높은 순", systemImage: "arrow.down")
                    }
                    Button(action: { animateSortChange(to: .lowToHigh) }) {
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
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showChart = false
                        showList = false
                    }
                    withAnimation(.easeInOut) {
                        vm.resetToCurrentDate()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showChart = true
                            showList = true
                        }
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                Spacer()
            }
            .padding(.horizontal)

            List {
                ForEach(vm.sortedCategoryTotals, id: \.self) { item in
                    HStack {
                        Text(item.category)
                            .font(.body)
                        Spacer()
                        Text("\(Int(item.total)) 원")
                            .fontWeight(.bold)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .opacity(showList ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: showList)

        }
        .padding()
        .sheet(isPresented: $vm.isShowingYearMonthPicker) {
            YearMonthPickerView(
                viewModel: viewModel,
                selectedYear: $vm.selectedYear,
                selectedMonth: $vm.selectedMonth,
                showingPicker: $vm.isShowingYearMonthPicker,
                onComplete: { year, month in
                    vm.setYearMonth(year: year, month: month)
                }
            )
        }
        .onAppear {
            showChart = true
        }
    }
    
    private func animateSortChange(to order: ChartViewModel.SortOrder) {
        withAnimation(.easeInOut(duration: 0.3)) {
            showList = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            vm.sortOrder = order
            withAnimation(.easeInOut(duration: 0.3)) {
                showList = true
            }
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
