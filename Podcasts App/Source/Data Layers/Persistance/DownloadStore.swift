import CryptoKit
import Foundation

/// Where downloaded episodes live on disk.
///
/// Files are named from a hash of the episode's `streamUrl`, so the local file can always be found
/// from the stream URL alone. Absolute paths are never persisted: the app container's path changes
/// on reinstall and some updates. Each audio file has a `<hash>.json` sidecar with the episode's
/// details, so downloads can be listed without the network.
struct DownloadStore {
    /// A downloaded episode as listed on the Downloads screen.
    struct Item: Identifiable {
        let episode: Episode
        let fileSize: Int64
        let downloadedAt: Date
        var id: String { episode.streamUrl }
    }

    private static let metadataExtension = "json"

    let directory: URL

    static let standard: DownloadStore = {
        let support = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                     appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        return DownloadStore(directory: support.appendingPathComponent("Downloads", isDirectory: true))
    }()

    private static let audioExtensions: Set<String> = ["mp3", "m4a", "m4b", "mp4", "aac", "wav", "aif", "aiff", "caf", "ogg", "opus"]
    private static let extensionsByMimeType = ["audio/mpeg": "mp3", "audio/mp3": "mp3", "audio/mp4": "m4a", "audio/x-m4a": "m4a",
                                               "audio/aac": "aac", "audio/x-aac": "aac", "audio/wav": "wav", "audio/x-wav": "wav",
                                               "video/mp4": "mp4", "audio/ogg": "ogg", "audio/opus": "opus"]

    /// Stable file name stem for an episode.
    static func fileStem(for streamUrl: String) -> String {
        SHA256.hash(data: Data(streamUrl.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// AVPlayer picks a decoder from the file extension, so keep a real audio extension.
    static func fileExtension(for streamUrl: String, mimeType: String?) -> String {
        let fromUrl = URL(string: streamUrl)?.pathExtension.lowercased() ?? ""
        if audioExtensions.contains(fromUrl) { return fromUrl }
        if let mimeType, let fromMime = extensionsByMimeType[mimeType.lowercased()] { return fromMime }
        return "mp3"
    }

    /// Downloaded audio files (not their metadata sidecars).
    private func audioFiles() -> [URL] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])) ?? []
        return files.filter { $0.pathExtension.lowercased() != Self.metadataExtension }
    }

    private func metadataURL(for streamUrl: String) -> URL {
        directory.appendingPathComponent(Self.fileStem(for: streamUrl)).appendingPathExtension(Self.metadataExtension)
    }

    /// The downloaded file for an episode, if there is one.
    func existingFile(for streamUrl: String) -> URL? {
        let stem = Self.fileStem(for: streamUrl)
        return audioFiles().first { $0.deletingPathExtension().lastPathComponent == stem }
    }

    /// Stems of every downloaded file, for cheap "is this downloaded?" checks.
    func downloadedStems() -> Set<String> {
        Set(audioFiles().map { $0.deletingPathExtension().lastPathComponent })
    }

    /// Records the episode's details next to its download. Written when a download starts, so
    /// downloads that finish while the app isn't running can still be listed.
    func saveMetadata(_ episode: Episode) throws {
        try prepareDirectory()
        try JSONEncoder().encode(episode).write(to: metadataURL(for: episode.streamUrl), options: .atomic)
    }

    func metadata(for streamUrl: String) -> Episode? {
        guard let data = try? Data(contentsOf: metadataURL(for: streamUrl)) else { return nil }
        return try? JSONDecoder().decode(Episode.self, from: data)
    }

    /// Every finished download that has episode details, newest first.
    func items() -> [Item] {
        audioFiles().compactMap { file -> Item? in
            let stem = file.deletingPathExtension().lastPathComponent
            let metadataFile = directory.appendingPathComponent(stem).appendingPathExtension(Self.metadataExtension)
            guard let data = try? Data(contentsOf: metadataFile),
                  let episode = try? JSONDecoder().decode(Episode.self, from: data) else { return nil }
            let values = try? file.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
            return Item(episode: episode, fileSize: Int64(values?.fileSize ?? 0),
                        downloadedAt: values?.creationDate ?? .distantPast)
        }
        .sorted { $0.downloadedAt > $1.downloadedAt }
    }

    /// Downloaded audio with no episode details, such as files saved before details were recorded.
    func filesWithoutMetadata() -> [(stem: String, size: Int64)] {
        audioFiles().compactMap { file in
            let stem = file.deletingPathExtension().lastPathComponent
            let metadataFile = directory.appendingPathComponent(stem).appendingPathExtension(Self.metadataExtension)
            guard !FileManager.default.fileExists(atPath: metadataFile.path) else { return nil }
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return (stem, Int64(size))
        }
    }

    /// Deletes downloaded audio that has no episode details.
    func removeFilesWithoutMetadata() {
        let stems = Set(filesWithoutMetadata().map(\.stem))
        for file in audioFiles() where stems.contains(file.deletingPathExtension().lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    /// Bytes used by all downloaded audio, including any without episode details.
    func totalSize() -> Int64 {
        audioFiles().reduce(0) { total, file in
            total + Int64((try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        }
    }

    /// Moves a finished download into place, replacing any earlier copy. Must be called before the
    /// URLSession delegate method returns, because the system deletes the temporary file afterwards.
    @discardableResult
    func store(_ temporaryFile: URL, for streamUrl: String, mimeType: String?) throws -> URL {
        try prepareDirectory()
        // Replace only the audio; the metadata sidecar was written when the download started.
        if let earlier = existingFile(for: streamUrl) { try? FileManager.default.removeItem(at: earlier) }
        let destination = directory
            .appendingPathComponent(Self.fileStem(for: streamUrl))
            .appendingPathExtension(Self.fileExtension(for: streamUrl, mimeType: mimeType))
        try FileManager.default.moveItem(at: temporaryFile, to: destination)
        return destination
    }

    /// Deletes an episode's download and its metadata.
    func remove(_ streamUrl: String) {
        if let file = existingFile(for: streamUrl) { try? FileManager.default.removeItem(at: file) }
        try? FileManager.default.removeItem(at: metadataURL(for: streamUrl))
    }

    /// Deletes every download, keeping the metadata of any listed in `keeping` (downloads in progress).
    func removeAll(keeping inProgress: Set<String> = []) {
        let keep = Set(inProgress.map(Self.fileStem))
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files where !(keep.contains(file.deletingPathExtension().lastPathComponent)
                                  && file.pathExtension.lowercased() == Self.metadataExtension) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private func prepareDirectory() throws {
        guard !FileManager.default.fileExists(atPath: directory.path) else { return }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // Episodes can be downloaded again, so keep them out of iCloud backups.
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var directory = directory
        try? directory.setResourceValues(values)
    }
}
