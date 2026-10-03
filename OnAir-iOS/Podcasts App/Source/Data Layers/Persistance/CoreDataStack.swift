import CoreData
import Foundation

/// The Core Data store for favorites (`FavoritePodcastEntity`) and listening history
/// (`HistoryEpisodeEntity`). Repositories are its only users; nothing above them sees managed objects.
///
/// The schema is `Podcasts.xcdatamodeld`. To change it, add a new model version and make it current;
/// never edit a version that has shipped. Lightweight migration upgrades existing stores.
final class CoreDataStack {

    /// The app's store. On first use it also imports the database the app kept before Core Data.
    static let shared: CoreDataStack = {
        let stack = CoreDataStack()
        LegacyDatabaseImporter().importIfNeeded(into: stack)
        return stack
    }()

    static let modelName = "Podcasts"

    /// Loaded once per process: two loaded copies of the model would both claim the entity classes.
    static let model: NSManagedObjectModel = {
        guard let url = Bundle(for: CoreDataStack.self).url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("The \(modelName) Core Data model is missing from the app bundle.")
        }
        return model
    }()

    static var defaultStoreURL: URL {
        let support = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                     appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        return support.appendingPathComponent("\(modelName).sqlite")
    }

    private let container: NSPersistentContainer

    /// - Parameter inMemory: Keeps the store in memory, for tests. It is still SQLite, so uniqueness
    ///   constraints behave as they do on disk.
    init(storeURL: URL = CoreDataStack.defaultStoreURL, inMemory: Bool = false) {
        container = NSPersistentContainer(name: Self.modelName, managedObjectModel: Self.model)
        let description = NSPersistentStoreDescription(url: inMemory ? URL(fileURLWithPath: "/dev/null") : storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                err("Core Data store failed to load", error.localizedDescription)
            }
        }
    }

    /// Runs `block` on a new background context and saves anything it changed.
    func perform<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = newContext()
        return try await context.perform {
            let result = try block(context)
            if context.hasChanges { try context.save() }
            return result
        }
    }

    /// Blocking version of `perform(_:)`, for work that must finish before the stack is used.
    func performAndWait<T>(_ block: (NSManagedObjectContext) throws -> T) throws -> T {
        let context = newContext()
        return try context.performAndWait {
            let result = try block(context)
            if context.hasChanges { try context.save() }
            return result
        }
    }

    private func newContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        // A row saved by a concurrent context (same feed or stream URL) is updated, not duplicated.
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}

enum PersistenceError: LocalizedError {
    case missingIdentifier

    var errorDescription: String? {
        switch self {
        case .missingIdentifier: return "This item can't be saved because it has no address."
        }
    }
}
