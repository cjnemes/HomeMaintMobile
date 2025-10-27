import Foundation
import SwiftUI
import Combine

/// ViewModel for displaying and filtering maintenance records
@MainActor
class MaintenanceRecordListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var records: [MaintenanceRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var filterAssetId: Int64? = nil
    @Published var filterProviderId: Int64? = nil
    @Published var startDate: Date? = nil
    @Published var endDate: Date? = nil

    // MARK: - Dependencies

    private let recordRepo = MaintenanceRecordRepository()

    // MARK: - Computed Properties

    var totalCost: Decimal {
        records.reduce(Decimal(0)) { sum, record in
            sum + (record.costDecimal ?? Decimal(0))
        }
    }

    var recordCount: Int {
        records.count
    }

    var averageCost: Decimal {
        guard recordCount > 0 else { return Decimal(0) }
        return totalCost / Decimal(recordCount)
    }

    var filteredRecords: [MaintenanceRecord] {
        var filtered = records

        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { record in
                record.type.localizedCaseInsensitiveContains(searchQuery) ||
                (record.description?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
                (record.notes?.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }

        return filtered
    }

    // MARK: - Public Methods

    /// Load all maintenance records
    func loadRecords() async {
        isLoading = true
        errorMessage = nil

        do {
            records = try await loadRecordsForFilters()
        } catch {
            errorMessage = "Failed to load maintenance records: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Load records for a specific asset
    func loadRecords(forAssetId assetId: Int64) async {
        filterAssetId = assetId
        filterProviderId = nil
        startDate = nil
        endDate = nil
        await loadRecords()
    }

    /// Load records for a specific service provider
    func loadRecords(forProviderId providerId: Int64) async {
        filterProviderId = providerId
        filterAssetId = nil
        startDate = nil
        endDate = nil
        await loadRecords()
    }

    /// Load records within a date range
    func loadRecords(from start: Date, to end: Date) async {
        startDate = start
        endDate = end
        filterAssetId = nil
        filterProviderId = nil
        await loadRecords()
    }

    /// Load recent records
    func loadRecentRecords(limit: Int = 10) async {
        isLoading = true
        errorMessage = nil

        do {
            records = try await Task {
                try recordRepo.findRecent(limit: limit)
            }.value
        } catch {
            errorMessage = "Failed to load recent records: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Clear all filters
    func clearFilters() async {
        filterAssetId = nil
        filterProviderId = nil
        startDate = nil
        endDate = nil
        searchQuery = ""
        await loadRecords()
    }

    /// Delete a maintenance record
    func deleteRecord(_ record: MaintenanceRecord) async {
        guard let id = record.id else { return }

        do {
            _ = try await Task {
                try recordRepo.delete(id)
            }.value
            await loadRecords()
        } catch {
            errorMessage = "Failed to delete record: \(error.localizedDescription)"
        }
    }

    /// Get total cost for a specific asset
    func getTotalCost(forAssetId assetId: Int64) async -> Decimal {
        do {
            return try await Task {
                try recordRepo.getTotalCost(assetId: assetId)
            }.value
        } catch {
            return Decimal(0)
        }
    }

    // MARK: - Private Methods

    private func loadRecordsForFilters() async throws -> [MaintenanceRecord] {
        return try await Task {
            // Apply filters based on what's set
            if let assetId = filterAssetId {
                return try recordRepo.findByAssetId(assetId)
            } else if let providerId = filterProviderId {
                return try recordRepo.findByServiceProviderId(providerId)
            } else if let start = startDate, let end = endDate {
                return try recordRepo.findByDateRange(from: start, to: end)
            } else {
                return try recordRepo.findAll()
            }
        }.value
    }
}
