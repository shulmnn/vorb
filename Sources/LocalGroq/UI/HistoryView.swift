import SwiftUI

struct HistoryView: View {
    @ObservedObject var model: AppModel
    @State private var isConfirmingClear = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if model.history.isEmpty {
                ContentUnavailableView(
                    "No Transcriptions Yet",
                    systemImage: "text.bubble",
                    description: Text("New transcripts appear here when history is enabled.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(model.history) { record in
                    HistoryRow(record: record, model: model)
                        .padding(.vertical, 6)
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 620, minHeight: 500)
        .confirmationDialog(
            "Clear all transcription history?",
            isPresented: $isConfirmingClear
        ) {
            Button("Clear History", role: .destructive) {
                model.clearHistory()
            }
        } message: {
            Text("This removes the locally stored transcript text from this Mac.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Transcription History")
                    .font(.title2.weight(.semibold))
                Text("Stored locally on this Mac")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !model.history.isEmpty {
                Text("\(model.history.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Button("Clear…") {
                    isConfirmingClear = true
                }
            }
        }
        .padding(20)
    }
}

private struct HistoryRow: View {
    let record: TranscriptRecord
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(record.createdAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.caption.weight(.medium))

                Text("\(record.provider) · \(record.model)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                Button {
                    model.copyTranscript(record.text)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy transcript")

                Button {
                    model.deleteHistoryRecord(id: record.id)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete transcript")
            }

            Text(record.text)
                .font(.body)
                .textSelection(.enabled)
                .lineLimit(5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contextMenu {
            Button("Copy") {
                model.copyTranscript(record.text)
            }
            Button("Delete", role: .destructive) {
                model.deleteHistoryRecord(id: record.id)
            }
        }
    }
}
