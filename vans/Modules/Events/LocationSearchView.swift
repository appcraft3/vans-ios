import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LocationSearchViewModel()
    let onSelect: (LocationResult) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.textTertiary)

                        TextField("Search for a location...", text: $viewModel.searchText)
                            .foregroundColor(AppTheme.textPrimary)
                            .autocorrectionDisabled()
                    }
                    .padding(12)
                    .background(AppTheme.card)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Results
                    if viewModel.isSearching {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                        Spacer()
                    } else if viewModel.results.isEmpty && !viewModel.searchText.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "mappin.slash")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.textTertiary)
                            Text("No locations found")
                                .font(.headline)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textTertiary)
                        }
                        Spacer()
                    } else if viewModel.results.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.textTertiary)
                            Text("Search for a location")
                                .font(.headline)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("Parks, cities, landmarks, etc.")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textTertiary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.results) { result in
                                    LocationResultRow(result: result) {
                                        onSelect(result)
                                        dismiss()
                                    }

                                    if result.id != viewModel.results.last?.id {
                                        Divider()
                                            .background(AppTheme.divider)
                                            .padding(.leading, 56)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
    }
}

struct LocationResultRow: View {
    let result: LocationResult
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: result.icon)
                    .font(.title3)
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.primary.opacity(0.2))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(result.address)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - View Model

@MainActor
final class LocationSearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var results: [LocationResult] = []
    @Published var isSearching = false

    private var searchTask: Task<Void, Never>?

    init() {
        // Debounce search
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.search(query: text)
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func search(query: String) {
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }

        isSearching = true

        searchTask = Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = query
                request.resultTypes = [.pointOfInterest, .address]

                let search = MKLocalSearch(request: request)
                let response = try await search.start()

                guard !Task.isCancelled else { return }

                results = response.mapItems.compactMap { item -> LocationResult? in
                    guard let name = item.name else { return nil }

                    let placemark = item.placemark
                    var addressParts: [String] = []

                    if let locality = placemark.locality {
                        addressParts.append(locality)
                    }
                    if let adminArea = placemark.administrativeArea {
                        addressParts.append(adminArea)
                    }
                    if let country = placemark.country {
                        addressParts.append(country)
                    }

                    let address = addressParts.joined(separator: ", ")
                    let region = [placemark.locality, placemark.administrativeArea]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                    let country = placemark.country ?? ""

                    return LocationResult(
                        name: name,
                        address: address.isEmpty ? "Unknown location" : address,
                        coordinate: placemark.coordinate,
                        region: region.isEmpty ? country : region,
                        country: country
                    )
                }

                isSearching = false
            } catch {
                guard !Task.isCancelled else { return }
                print("Search error: \(error)")
                results = []
                isSearching = false
            }
        }
    }
}

import Combine
