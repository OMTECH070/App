import SwiftUI
import CoreData

struct SubjectsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var subjectsViewModel = SubjectsViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if subjectsViewModel.subjects.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("No Subjects Added")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Add your first subject to start tracking your study time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Add Subject") {
                            subjectsViewModel.showAddSubject = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(subjectsViewModel.subjects, id: \.id) { subject in
                            SubjectRow(subject: subject) {
                                subjectsViewModel.toggleSubjectActivation(subject: subject)
                            }
                        }
                        .onDelete(perform: subjectsViewModel.deleteSubjects)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        subjectsViewModel.loadSubjects(context: viewContext)
                    }
                }
            }
            .navigationTitle("Subjects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        subjectsViewModel.showAddSubject = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                subjectsViewModel.loadSubjects(context: viewContext)
            }
            .sheet(isPresented: $subjectsViewModel.showAddSubject) {
                AddSubjectView { subject in
                    subjectsViewModel.addSubject(subject, context: viewContext)
                }
            }
        }
    }
}

struct SubjectRow: View {
    let subject: UserSubject
    let onToggle: () -> Void

    var body: some View {
        HStack {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: subject.color ?? "#007AFF"))
                .frame(width: 8, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(subject.name ?? "Unknown Subject")
                        .font(.headline)
                        .foregroundColor(subject.isActive ? .primary : .secondary)

                    Spacer()

                    // Mastery level indicator
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(subject.masteryLevel * 5) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }

                HStack {
                    Label("\(Int(subject.totalStudyTime / 3600))h", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(subject.isActive ? "Active" : "Inactive")
                        .font(.caption)
                        .foregroundColor(subject.isActive ? .green : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background((subject.isActive ? Color.green : Color.gray).opacity(0.1))
                        .cornerRadius(4)
                }

                // Progress bar for mastery level
                ProgressView(value: subject.masteryLevel)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: subject.color ?? "#007AFF")))
                    .scaleEffect(x: 1, y: 0.5)
            }

            // Toggle button
            Button(action: onToggle) {
                Image(systemName: subject.isActive ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(subject.isActive ? .blue : .gray)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddSubjectView: View {
    let onSave: (UserSubject) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedColor = "#007AFF"
    @State private var difficulty = 1
    @State private var priority = 1

    let colors = [
        "#007AFF", "#FF3B30", "#34C759", "#FF9500", "#AF52DE",
        "#FF2D92", "#5AC8FA", "#FFCC00", "#8E8E93", "#007AFF"
    ]

    var body: some View {
        NavigationView {
            Form {
                Section("Subject Details") {
                    TextField("Subject Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }

                Section("Settings") {
                    VStack(alignment: .leading) {
                        Text("Difficulty: \(difficulty)")
                        Picker("Difficulty", selection: $difficulty) {
                            Text("Easy").tag(1)
                            Text("Medium").tag(2)
                            Text("Hard").tag(3)
                            Text("Very Hard").tag(4)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    VStack(alignment: .leading) {
                        Text("Priority: \(priority)")
                        Stepper(value: $priority, in: 1...5) {
                            Text("Priority Level")
                        }
                    }
                }
            }
            .navigationTitle("Add Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let subject = UserSubject(context: PersistenceController.shared.container.viewContext)
                        subject.id = UUID()
                        subject.name = name
                        subject.color = selectedColor
                        subject.difficulty = Int32(difficulty)
                        subject.priority = Int32(priority)
                        subject.isActive = true
                        subject.masteryLevel = 0.0
                        subject.totalStudyTime = 0
                        subject.createdAt = Date()

                        onSave(subject)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    SubjectsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}