import Foundation
import EventKit
import SwiftUI
import EventKitUI

// MARK: - Event Wrapper for Identifiable sheet presentation
struct EventWrapper: Identifiable {
    let id = UUID()
    let event: EKEvent
}

@MainActor
class CalendarService {
    static let shared = CalendarService()
    let eventStore = EKEventStore()
    
    private init() {}
    
    func requestAccess() async -> Bool {
        if #available(iOS 17.0, macOS 14.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                print("EventKit: Full access requested, granted: \(granted)")
                return granted
            } catch {
                print("EventKit: Error requesting full access: \(error)")
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        print("EventKit: Error requesting access: \(error)")
                    }
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func createPlaceholderEvent(title: String, date: Date) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        
        // Round the selected date to :00 for easier use
        let roundedDate = date.roundedToNextHour
        event.startDate = roundedDate
        event.endDate = roundedDate.addingTimeInterval(3600) // Default 1 hour
        
        // Ensure calendar is set, otherwise the edit view might be blank
        if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
            event.calendar = defaultCalendar
        } else {
            // Fallback to first available calendar if default is nil
            let calendars = eventStore.calendars(for: .event)
            print("EventKit: Default calendar nil. Available calendars: \(calendars.count)")
            event.calendar = calendars.first
        }
        
        return event
    }
}

struct EKEventEditView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    let event: EKEvent

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = CalendarService.shared.eventStore
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, EKEventEditViewDelegate {
        let parent: EKEventEditView

        init(_ parent: EKEventEditView) {
            self.parent = parent
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            parent.dismiss()
        }
    }
}
