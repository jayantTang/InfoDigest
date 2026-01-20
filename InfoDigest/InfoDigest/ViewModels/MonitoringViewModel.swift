import Foundation
import Combine

@MainActor
class MonitoringViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var monitoringStatus: MonitoringStatus?
    @Published var monitoringMetrics: MonitoringMetrics?
    @Published var isRefreshing = false
    @Published var hasError = false

    private let apiService = APIService.shared

    func loadMonitoringStatus() async {
        isRefreshing = true
        hasError = false
        errorMessage = nil

        do {
            let status = try await apiService.getMonitoringStatus()
            monitoringStatus = status
            hasError = false
        } catch {
            print("加载监控状态失败: \(error)")
            hasError = true
        }

        isRefreshing = false
    }

    func loadMonitoringMetrics() async {
        isRefreshing = true
        hasError = false
        errorMessage = nil

        do {
            let metrics = try await apiService.getMonitoringMetrics()
            monitoringMetrics = metrics
            hasError = false
        } catch {
            print("加载监控指标失败: \(error)")
            hasError = true
        }

        isRefreshing = false
    }

    func refreshAll() {
        isRefreshing = true

        Task {
            async let status = loadMonitoringStatus()
            async let metrics = loadMonitoringMetrics()

            await status
            await metrics
            isRefreshing = false
        }
    }
}
