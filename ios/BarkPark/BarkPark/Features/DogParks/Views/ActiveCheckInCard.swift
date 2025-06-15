import SwiftUI

struct ActiveCheckInCard: View {
    let checkIn: CheckIn
    let parkName: String
    let onCheckOut: () -> Void
    @State private var showingCheckOutConfirmation = false
    
    private var formattedDuration: String {
        let dateFormatter = ISO8601DateFormatter()
        guard let checkedInDate = dateFormatter.date(from: checkIn.checkedInAt) else {
            return "just now"
        }
        
        let duration = Date().timeIntervalSince(checkedInDate)
        
        let componentFormatter = DateComponentsFormatter()
        componentFormatter.allowedUnits = [.hour, .minute]
        componentFormatter.unitsStyle = .abbreviated
        componentFormatter.maximumUnitCount = 2
        
        return componentFormatter.string(from: duration) ?? "just now"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                        
                        Text("Checked in at")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(parkName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingCheckOutConfirmation = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.slash.fill")
                            .font(.system(size: 14))
                        Text("Check Out")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(20)
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
        .alert("Check Out", isPresented: $showingCheckOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Check Out", role: .destructive) {
                onCheckOut()
            }
        } message: {
            Text("Are you sure you want to check out of \(parkName)?")
        }
    }
}

struct ActiveCheckInCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ActiveCheckInCard(
                checkIn: CheckIn(
                    id: 1,
                    userId: 1,
                    dogParkId: 1,
                    checkedInAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
                    checkedOutAt: nil,
                    dogsPresent: [1, 2],
                    createdAt: nil,
                    updatedAt: nil,
                    park: nil
                ),
                parkName: "Central Park Dog Run",
                onCheckOut: { }
            )
            Spacer()
        }
        .padding(.top)
    }
}