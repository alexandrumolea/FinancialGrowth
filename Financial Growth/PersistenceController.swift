//
//  PersistenceController.swift
//  Financial Growth
//
//  Created by Alexandru Molea on 19.02.2026.
//

import CoreData

struct PersistenceController {

    static let shared = PersistenceController()

    // MARK: - Preview store (in-memory, with sample data)
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext

        // Sample client
        let client = Client(context: ctx)
        client.id = UUID()
        client.name = "Acme Corp"
        client.email = "contact@acme.com"
        client.phone = "+40 700 000 000"
        client.createdAt = Date()

        // Sample activity
        let activity = Activity(context: ctx)
        activity.id = UUID()
        activity.activityType = ActivityType.systemTypes[0].id
        activity.startDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        activity.endDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        activity.hours = 2.0
        activity.costPerHour = 150.0
        activity.totalAmount = 300.0
        activity.notes = "Sesiune introductivă de coaching"
        activity.createdAt = Date()
        activity.client = client

        try? ctx.save()
        return controller
    }()

    // MARK: - Container
    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "FinancialGrowth")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Enable iCloud sync
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve persistent store description.")
            }
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber,
                                  forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        // Load stores on a background queue to satisfy main thread I/O checks
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In production, handle this gracefully
                fatalError("Unresolved CoreData error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save helper
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("CoreData save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // MARK: - Profile Settings helper
    func getOrCreateSettings(in context: NSManagedObjectContext) -> ProfileSettings {
        let request: NSFetchRequest<ProfileSettings> = NSFetchRequest(entityName: "ProfileSettings")
        do {
            let results = try context.fetch(request)
            if let settings = results.first {
                return settings
            } else {
                let settings = ProfileSettings(context: context)
                settings.id = UUID()
                settings.weeklyHoursGoal = 40.0
                settings.monthlyHoursGoal = 160.0
                settings.dailyEarningsGoalValue = 300.0
                settings.customActivityTypesJSON = "[]"
                try? context.save()
                return settings
            }
        } catch {
            let settings = ProfileSettings(context: context)
            settings.id = UUID()
            return settings
        }
    }
}
