import SwiftUI
import CoreData

struct ScheduleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var scheduleViewModel = ScheduleViewModel()
    @State private var selectedDate = Date()

    var body: some View {
        NavigationView {
            VStack {
                // Date picker
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .onChange(of: selectedDate) { newDate in
                        scheduleViewModel.loadSchedule(for: newDate, context: viewContext)
                    }

                // Schedule list
                if scheduleViewModel.sessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("No study sessions planned")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Add your first study session to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button("Add Study Session") {
                            scheduleViewModel.showAddSession = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(scheduleViewModel.sessions, id: \.id) { session in
                            ScheduleSessionRow(session: session) {
                                scheduleViewModel.toggleSessionCompletion(session: session)
                            }
                        }
                        .onDelete(perform: scheduleViewModel.deleteSessions)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        scheduleViewModel.showAddSession = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                scheduleViewModel.loadSchedule(for: selectedDate, context: viewContext)
            }
            .sheet(isPresented: $scheduleViewModel.showAddSession) {
                AddStudySessionView(
                    selectedDate: selectedDate,
                    onSave: { session in
                        scheduleViewModel.addSession(session, context: viewContext)
                    }
                )
            }
        }
    }
}

struct ScheduleSessionRow: View {
    let session: StudySession
    let onToggle: () -> Void

    var body: some View {
        HStack {
            // Time indicator
            VStack {
                Circle()
                    .fill(session.isCompleted ? Color.green : Color.blue)
                    .frame(width: 12, height: 12)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2)
            }
            .frame(height: 60)

            // Session details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.subject ?? "Unknown Subject")
                        .font(.headline)
                        .foregroundColor(session.isCompleted ? .secondary : .primary)
                        .strikethrough(session.isCompleted)

                    Spacer()

                    Text(formatTime(session.scheduledFor))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let topics = session.topics, !topics.isEmpty {
                    Text(topics)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("\(Int(session.duration / 60)) minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if session.isCompleted {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            // Completion button
            Button(action: onToggle) {
                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(session.isCompleted ? .green : .gray)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AddStudySessionView: View {
    let selectedDate: Date
    let onSave: (StudySession) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var subject = ""
    @State private var topics = ""
    @State private var duration = 60.0
    @State private var selectedTime = Date()
    @State private var notes = ""

    let subjects = ["Mathematics", "Physics", "Chemistry", "Biology", "Computer Science", "English", "History"]

    var body: some View {
        NavigationView {
            Form {
                Section("Subject") {
                    Picker("Subject", selection: $subject) {
                        Text("Select Subject").tag("")
                        ForEach(subjects, id: \.self) { subject in
                            Text(subject).tag(subject)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Section("Details") {
                    TextField("Topics to cover", text: $topics)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    VStack(alignment: .leading) {
                        Text("Duration: \(Int(duration)) minutes")
                        Slider(value: $duration, in: 15...180, step: 15)
                    }
                }

                Section("Timing") {
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Study Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let session = StudySession(context: PersistenceController.shared.container.viewContext)
                        session.id = UUID()
                        session.subject = subject
                        session.topics = topics
                        session.duration = Int64(duration * 60)
                        session.scheduledFor = combineDateAndTime(date: selectedDate, time: selectedTime)
                        session.notes = notes
                        session.createdAt = Date()
                        session.isCompleted = false

                        onSave(session)
                        dismiss()
                    }
                    .disabled(subject.isEmpty)
                }
            }
        }
    }

    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute

        return calendar.date(from: combinedComponents) ?? date
    }
}

#Preview {
    ScheduleView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}