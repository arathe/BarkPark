//
//  AddDogView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI
import PhotosUI

struct AddDogView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dogProfileViewModel: DogProfileViewModel
    
    // Basic Info
    @State private var name = ""
    @State private var breed = ""
    @State private var birthday = Date()
    @State private var weight = ""
    @State private var gender = "male"
    @State private var sizeCategory = "medium"
    
    // Personality
    @State private var energyLevel = "medium"
    @State private var friendlinessDogs = 3
    @State private var friendlinessPeople = 3
    @State private var trainingLevel = "basic"
    @State private var favoriteActivities: Set<String> = []
    
    // Health
    @State private var isVaccinated = true
    @State private var isSpayedNeutered = false
    @State private var specialNeeds = ""
    @State private var bio = ""
    
    // Photo
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImageData: Data?
    @State private var showingImagePicker = false
    
    // Form state
    @State private var isSubmitting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let genderOptions = ["male", "female"]
    private let sizeOptions = ["small", "medium", "large"]
    private let energyOptions = ["low", "medium", "high"]
    private let trainingOptions = ["puppy", "basic", "advanced"]
    private let activityOptions = ["fetch", "walking", "running", "swimming", "hiking", "agility", "tricks", "socializing"]
    
    private var isFormValid: Bool {
        !name.isEmpty && !breed.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Photo Section
                ProfilePhotoSection(
                    selectedPhoto: $selectedPhoto,
                    profileImageData: $profileImageData
                )
                
                // Basic Information
                Section("Basic Information") {
                    TextField("Dog's name", text: $name)
                    TextField("Breed", text: $breed)
                    
                    DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                    
                    HStack {
                        TextField("Weight (optional)", text: $weight)
                            .keyboardType(.decimalPad)
                        Text("lbs")
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) { option in
                            Text(option.capitalized).tag(option)
                        }
                    }
                    
                    Picker("Size", selection: $sizeCategory) {
                        ForEach(sizeOptions, id: \.self) { option in
                            Text(formatSizeOption(option)).tag(option)
                        }
                    }
                }
                
                // Personality
                Section("Personality") {
                    Picker("Energy Level", selection: $energyLevel) {
                        ForEach(energyOptions, id: \.self) { option in
                            Text(formatEnergyOption(option)).tag(option)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                        HStack {
                            Text("Friendliness with Dogs")
                            Spacer()
                            Text("\(friendlinessDogs)/5")
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        }
                        Slider(value: Binding(
                            get: { Double(friendlinessDogs) },
                            set: { friendlinessDogs = Int($0) }
                        ), in: 1...5, step: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                        HStack {
                            Text("Friendliness with People")
                            Spacer()
                            Text("\(friendlinessPeople)/5")
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        }
                        Slider(value: Binding(
                            get: { Double(friendlinessPeople) },
                            set: { friendlinessPeople = Int($0) }
                        ), in: 1...5, step: 1)
                    }
                    
                    Picker("Training Level", selection: $trainingLevel) {
                        ForEach(trainingOptions, id: \.self) { option in
                            Text(formatTrainingOption(option)).tag(option)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                        Text("Favorite Activities")
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BarkParkDesign.Spacing.sm) {
                            ForEach(activityOptions, id: \.self) { activity in
                                Button {
                                    toggleActivity(activity)
                                } label: {
                                    Text(activity.capitalized)
                                        .font(BarkParkDesign.Typography.caption)
                                        .padding(.horizontal, BarkParkDesign.Spacing.sm)
                                        .padding(.vertical, BarkParkDesign.Spacing.xs)
                                        .background(
                                            favoriteActivities.contains(activity) ?
                                            BarkParkDesign.Colors.dogPrimary :
                                            BarkParkDesign.Colors.tertiaryBackground
                                        )
                                        .foregroundColor(
                                            favoriteActivities.contains(activity) ?
                                            .white :
                                            BarkParkDesign.Colors.primaryText
                                        )
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                // Health
                Section("Health") {
                    Toggle("Vaccinated", isOn: $isVaccinated)
                    Toggle("Spayed/Neutered", isOn: $isSpayedNeutered)
                    
                    TextField("Special needs (optional)", text: $specialNeeds, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
                
                // Bio
                Section("About") {
                    TextField("Tell us about your dog (optional)", text: $bio, axis: .vertical)
                        .lineLimit(5, reservesSpace: true)
                }
                
                // Submit Button Section
                Section {
                    Button {
                        submitForm()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isSubmitting ? "Adding..." : "Add \(name.isEmpty ? "Dog" : name)")
                                .font(BarkParkDesign.Typography.callout)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isFormValid && !isSubmitting ? 
                            BarkParkDesign.Colors.dogPrimary : 
                            BarkParkDesign.Colors.dogPrimary.opacity(0.5)
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium))
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
            .navigationTitle("Add Dog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add \(name.isEmpty ? "Dog" : name)") {
                        submitForm()
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func toggleActivity(_ activity: String) {
        if favoriteActivities.contains(activity) {
            favoriteActivities.remove(activity)
        } else {
            favoriteActivities.insert(activity)
        }
    }
    
    private func submitForm() {
        isSubmitting = true
        
        Task {
            // Create dog request
            let dogRequest = CreateDogRequest(
                name: name,
                breed: breed,
                birthday: formatDate(birthday),
                weight: Double(weight),
                gender: gender,
                sizeCategory: sizeCategory,
                energyLevel: energyLevel,
                friendlinessDogs: friendlinessDogs,
                friendlinessPeople: friendlinessPeople,
                trainingLevel: trainingLevel,
                favoriteActivities: Array(favoriteActivities),
                isVaccinated: isVaccinated,
                isSpayedNeutered: isSpayedNeutered,
                specialNeeds: specialNeeds.isEmpty ? nil : specialNeeds,
                bio: bio.isEmpty ? nil : bio
            )
            
            // Create the dog first
            guard let newDog = await dogProfileViewModel.createDog(dogRequest) else {
                alertMessage = dogProfileViewModel.errorMessage ?? "Failed to create dog profile"
                showingAlert = true
                isSubmitting = false
                return
            }
            
            // Upload profile photo if selected
            if let imageData = profileImageData {
                let uploadSuccess = await dogProfileViewModel.uploadProfileImage(for: newDog, imageData: imageData)
                if !uploadSuccess {
                    // Dog was created but photo upload failed
                    alertMessage = "Dog profile created, but photo upload failed: \(dogProfileViewModel.errorMessage ?? "Unknown error")"
                    showingAlert = true
                }
            }
            
            isSubmitting = false
            dismiss()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formatSizeOption(_ option: String) -> String {
        switch option {
        default: return option.capitalized
        }
    }
    
    private func formatEnergyOption(_ option: String) -> String {
        switch option {
        default: return option.capitalized
        }
    }
    
    private func formatTrainingOption(_ option: String) -> String {
        switch option {
        case "puppy": return "Puppy"
        default: return option.capitalized
        }
    }
}

struct ProfilePhotoSection: View {
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var profileImageData: Data?
    @State private var profileImage: UIImage?
    
    var body: some View {
        Section("Profile Photo") {
            HStack {
                // Photo Display
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(BarkParkDesign.Colors.dogPrimary, lineWidth: 2)
                        )
                } else {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 40))
                        .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.5))
                        .frame(width: 80, height: 80)
                        .background(BarkParkDesign.Colors.tertiaryBackground)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(BarkParkDesign.Colors.dogPrimary.opacity(0.3), lineWidth: 2)
                        )
                }
                
                VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images
                    ) {
                        Text(profileImage == nil ? "Add Profile Photo" : "Change Photo")
                            .font(BarkParkDesign.Typography.callout)
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                    }
                    
                    if profileImage != nil {
                        Button("Remove Photo") {
                            resetPhoto()
                        }
                        .font(BarkParkDesign.Typography.caption)
                        .foregroundColor(BarkParkDesign.Colors.error)
                    }
                    
                    Text("Optional: Add a photo to make your dog's profile stand out!")
                        .font(BarkParkDesign.Typography.caption)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                }
                
                Spacer()
            }
        }
        .onChange(of: selectedPhoto) { oldValue, newValue in
            Task {
                if let newValue = newValue {
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        profileImageData = data
                        profileImage = UIImage(data: data)
                    }
                }
            }
        }
    }
    
    private func resetPhoto() {
        selectedPhoto = nil
        profileImageData = nil
        profileImage = nil
    }
}

#Preview {
    AddDogView()
        .environmentObject(DogProfileViewModel())
}