import Foundation

/// The Home tab's stations from the last successful load, kept as JSON so the next launch can show them right
/// away, while the On Air API wakes up.
///
/// The file lives in Caches: the stations can always be loaded again, so it's fine if iOS removes it.
struct StationsCache {
    let fileURL: URL

    static let standard: StationsCache = {
        let caches = (try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask,
                                                    appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        return StationsCache(fileURL: caches.appendingPathComponent("HomeStations.json"))
    }()

    /// The saved stations, in the order they were listed. Empty if none were saved or the file can't be read.
    func load() -> [Podcast] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Podcast].self, from: data)) ?? []
    }

    /// Replaces the saved stations. Failing to save only means the next launch waits for the network.
    func save(_ podcasts: [Podcast]) {
        guard let data = try? JSONEncoder().encode(podcasts) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
