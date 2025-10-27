import Foundation
import Combine

@MainActor
class AssetDetailViewModel: ObservableObject {

    @Published var asset: Asset
    @Published var category: Category?
    @Published var location: Location?
    @Published var maintenanceRecords: [MaintenanceRecord] = []
    @Published var tasks: [MaintenanceTask] = []
    @Published var attachments: [Attachment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let assetRepo = AssetRepository()
    private let categoryRepo = CategoryRepository()
    private let locationRepo = LocationRepository()
    private let maintenanceRepo = MaintenanceRecordRepository()
    private let taskRepo = MaintenanceTaskRepository()
    private let attachmentRepo = AttachmentRepository()

    // MARK: - Initialization

    init(asset: Asset) {
        self.asset = asset
        Task {
            await loadRelatedData()
        }
    }

    // MARK: - Load Data

    func loadRelatedData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load category
            if let categoryId = asset.categoryId {
                category = try categoryRepo.findById(categoryId)
            }

            // Load location
            if let locationId = asset.locationId {
                location = try locationRepo.findById(locationId)
            }

            // Load maintenance records
            if let assetId = asset.id {
                maintenanceRecords = try maintenanceRepo.findByAssetId(assetId)
                tasks = try taskRepo.findByAssetId(assetId)
                attachments = try attachmentRepo.findByAssetId(assetId)
            }

            print("✅ Loaded related data for asset: \(asset.name)")
        } catch {
            errorMessage = "Failed to load related data: \(error.localizedDescription)"
            print("❌ Error loading related data: \(error)")
        }

        isLoading = false
    }

    // MARK: - Computed Properties

    var warrantyStatusText: String {
        asset.warrantyStatus.displayText
    }

    var warrantyStatusColor: String {
        asset.warrantyStatus.color
    }

    var maintenanceCount: Int {
        maintenanceRecords.count
    }

    var pendingTasksCount: Int {
        tasks.filter { $0.status != MaintenanceTask.TaskStatus.completed.rawValue }.count
    }

    var photoCount: Int {
        attachments.filter { $0.isImage }.count
    }
}
