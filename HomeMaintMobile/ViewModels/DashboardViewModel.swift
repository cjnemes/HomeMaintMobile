import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {

    @Published var totalAssets = 0
    @Published var recentMaintenance: [MaintenanceRecord] = []
    @Published var upcomingTasks: [MaintenanceTask] = []
    @Published var overdueTasks: [MaintenanceTask] = []
    @Published var expiringWarranties: [Asset] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let assetRepo = AssetRepository()
    private let maintenanceRepo = MaintenanceRecordRepository()
    private let taskRepo = MaintenanceTaskRepository()
    private let seedService = SeedDataService.shared

    // MARK: - Initialization

    init() {
        Task {
            await loadDashboardData()
        }
    }

    // MARK: - Load Data

    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil

        do {
            let home = try seedService.getOrCreateHome()

            // Ensure home has an ID
            guard let homeId = home.id else {
                errorMessage = "Home does not have a valid ID"
                print("❌ Error: Home missing ID")
                isLoading = false
                return
            }

            // Load stats
            let assets = try assetRepo.findByHomeId(homeId)
            totalAssets = assets.count

            // Load recent maintenance (last 5)
            recentMaintenance = try maintenanceRepo.findRecent(limit: 5)

            // Load upcoming tasks (next 30 days)
            upcomingTasks = try taskRepo.findUpcoming(days: 30)

            // Load overdue tasks
            overdueTasks = try taskRepo.findOverdue()

            // Load expiring warranties (next 30 days)
            expiringWarranties = try assetRepo.findExpiringWarranties(homeId: homeId, withinDays: 30)

            print("✅ Dashboard data loaded")
        } catch {
            errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
            print("❌ Error loading dashboard: \(error)")
        }

        isLoading = false
    }

    // MARK: - Computed Properties

    var maintenanceCount: Int {
        recentMaintenance.count
    }

    var pendingTasksCount: Int {
        upcomingTasks.count + overdueTasks.count
    }

    var alertsCount: Int {
        overdueTasks.count + expiringWarranties.count
    }
}
