//
//  EditDogView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/7/25.
//

import SwiftUI
import PhotosUI

struct EditDogView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dogProfileViewModel: DogProfileViewModel
    
    let dog: Dog
    
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
    
    // Photo and Gallery Management
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImageData: Data?
    @State private var selectedGalleryPhotos: [PhotosPickerItem] = []
    @State private var newGalleryImages: [Data] = []
    @State private var galleryImages: [String] = []
    @State private var currentProfileImageUrl: String?
    @State private var selectedProfileImageFromGallery: String?
    
    // Form state
    @State private var isSubmitting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingProfilePhotoSelector = false
    
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
                // Profile Photo Section with Gallery Selection
                ProfilePhotoEditSection(
                    currentProfileImageUrl: currentProfileImageUrl,
                    selectedPhoto: $selectedPhoto,
                    profileImageData: $profileImageData,
                    galleryImages: galleryImages,
                    selectedProfileImageFromGallery: $selectedProfileImageFromGallery,
                    showingProfilePhotoSelector: $showingProfilePhotoSelector
                )
                
                // Gallery Management Section
                GalleryManagementSection(
                    selectedGalleryPhotos: $selectedGalleryPhotos,
                    newGalleryImages: $newGalleryImages,
                    galleryImages: $galleryImages
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
                
                // Save Button Section
                Section {
                    Button {
                        submitChanges()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isSubmitting ? "Saving..." : "Save Changes")
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
            .navigationTitle("Edit \(dog.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        submitChanges()
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingProfilePhotoSelector) {
                ProfilePhotoSelectorSheet(
                    galleryImages: galleryImages,
                    currentProfileImageUrl: currentProfileImageUrl,
                    selectedProfileImageFromGallery: $selectedProfileImageFromGallery
                )
            }
        }
        .onAppear {
            populateFields()
        }
    }
    
    private func populateFields() {
        name = dog.name
        breed = dog.breed ?? ""
        
        // Parse birthday
        if let birthdayString = dog.birthday {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            birthday = formatter.date(from: birthdayString) ?? Date()
        } else {
            birthday = Date()
        }
        
        weight = dog.weight.map { String(format: "%.1f", $0) } ?? ""
        gender = dog.gender
        sizeCategory = dog.sizeCategory
        energyLevel = dog.energyLevel
        friendlinessDogs = dog.friendlinessDogs
        friendlinessPeople = dog.friendlinessPeople
        trainingLevel = dog.trainingLevel
        favoriteActivities = Set(dog.favoriteActivities)
        isVaccinated = dog.isVaccinated
        isSpayedNeutered = dog.isSpayedNeutered
        specialNeeds = dog.specialNeeds ?? ""
        bio = dog.bio ?? ""
        
        // Photo and gallery
        currentProfileImageUrl = dog.profileImageUrl
        galleryImages = dog.galleryImages
    }
    
    private func toggleActivity(_ activity: String) {
        if favoriteActivities.contains(activity) {
            favoriteActivities.remove(activity)
        } else {
            favoriteActivities.insert(activity)
        }
    }
    
    private func submitChanges() {
        isSubmitting = true
        
        Task {
            // Create update request
            let updateRequest = UpdateDogRequest(
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
            
            // Update the dog first
            guard await dogProfileViewModel.updateDog(dog.id, updateRequest) else {
                alertMessage = dogProfileViewModel.errorMessage ?? "Failed to update dog profile"
                showingAlert = true
                isSubmitting = false
                return
            }
            
            // Handle profile photo changes
            if let imageData = profileImageData {
                // New photo selected from photo picker
                let uploadSuccess = await dogProfileViewModel.uploadProfileImage(for: dog, imageData: imageData)
                if !uploadSuccess {
                    alertMessage = "Dog profile updated, but photo upload failed: \(dogProfileViewModel.errorMessage ?? "Unknown error")"
                    showingAlert = true
                }
            } else if let selectedGalleryImage = selectedProfileImageFromGallery {
                // Profile photo selected from gallery
                let setSuccess = await dogProfileViewModel.setProfileImageFromGallery(dogId: dog.id, imageUrl: selectedGalleryImage)
                if !setSuccess {
                    alertMessage = "Dog profile updated, but setting profile photo failed: \(dogProfileViewModel.errorMessage ?? "Unknown error")"
                    showingAlert = true
                }
            }
            
            // Upload new gallery images
            if !newGalleryImages.isEmpty {
                let uploadSuccess = await dogProfileViewModel.uploadGalleryImages(for: dog, imageDataArray: newGalleryImages)
                if !uploadSuccess {
                    alertMessage = "Dog profile updated, but gallery upload failed: \(dogProfileViewModel.errorMessage ?? "Unknown error")"
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

struct ProfilePhotoEditSection: View {
    let currentProfileImageUrl: String?
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var profileImageData: Data?
    let galleryImages: [String]
    @Binding var selectedProfileImageFromGallery: String?
    @Binding var showingProfilePhotoSelector: Bool
    
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
                } else if let currentUrl = currentProfileImageUrl {
                    AsyncImage(url: URL(string: currentUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 40))
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.5))
                    }
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
                        Text("Choose New Photo")
                            .font(BarkParkDesign.Typography.callout)
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                    }
                    
                    if !galleryImages.isEmpty {
                        Button("Choose from Gallery") {
                            showingProfilePhotoSelector = true
                        }
                        .font(BarkParkDesign.Typography.callout)
                        .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                    }
                    
                    if profileImage != nil || currentProfileImageUrl != nil {
                        Button("Remove Photo") {
                            resetPhoto()
                        }
                        .font(BarkParkDesign.Typography.caption)
                        .foregroundColor(BarkParkDesign.Colors.error)
                    }
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
                        selectedProfileImageFromGallery = nil
                    }
                }
            }
        }
        .onChange(of: selectedProfileImageFromGallery) { oldValue, newValue in
            if newValue != nil {
                // Clear new photo selection when choosing from gallery
                selectedPhoto = nil
                profileImageData = nil
                profileImage = nil
            }
        }
    }
    
    private func resetPhoto() {
        selectedPhoto = nil
        profileImageData = nil
        profileImage = nil
        selectedProfileImageFromGallery = nil
    }
}

struct GalleryManagementSection: View {
    @Binding var selectedGalleryPhotos: [PhotosPickerItem]
    @Binding var newGalleryImages: [Data]
    @Binding var galleryImages: [String]
    
    var body: some View {
        Section("Photo Gallery") {
            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.md) {
                // Current gallery images
                if !galleryImages.isEmpty {
                    Text("Current Photos")
                        .font(BarkParkDesign.Typography.headline)
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: BarkParkDesign.Spacing.sm) {
                        ForEach(Array(galleryImages.enumerated()), id: \.offset) { index, imageUrl in
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .foregroundColor(BarkParkDesign.Colors.tertiaryBackground)
                                        .overlay(
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: BarkParkDesign.Colors.dogPrimary))
                                        )
                                }
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.small))
                                
                                Button {
                                    removeGalleryImage(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.red))
                                        .font(.system(size: 20))
                                }
                                .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
                
                // New images to be uploaded
                if !newGalleryImages.isEmpty {
                    Text("New Photos to Upload")
                        .font(BarkParkDesign.Typography.headline)
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: BarkParkDesign.Spacing.sm) {
                        ForEach(Array(newGalleryImages.enumerated()), id: \.offset) { index, imageData in
                            ZStack(alignment: .topTrailing) {
                                if let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.small))
                                }
                                
                                Button {
                                    removeNewImage(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.red))
                                        .font(.system(size: 20))
                                }
                                .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
                
                // Add photos button
                PhotosPicker(
                    selection: $selectedGalleryPhotos,
                    maxSelectionCount: 5 - galleryImages.count - newGalleryImages.count,
                    matching: .images
                ) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Photos to Gallery")
                    }
                    .font(BarkParkDesign.Typography.callout)
                    .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                }
                .disabled(galleryImages.count + newGalleryImages.count >= 5)
                
                if galleryImages.count + newGalleryImages.count >= 5 {
                    Text("Gallery is full (5 photos maximum)")
                        .font(BarkParkDesign.Typography.caption)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                }
            }
        }
        .onChange(of: selectedGalleryPhotos) { oldValue, newValue in
            Task {
                for item in newValue {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        newGalleryImages.append(data)
                    }
                }
                selectedGalleryPhotos.removeAll()
            }
        }
    }
    
    private func removeGalleryImage(at index: Int) {
        galleryImages.remove(at: index)
    }
    
    private func removeNewImage(at index: Int) {
        newGalleryImages.remove(at: index)
    }
}

struct ProfilePhotoSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let galleryImages: [String]
    let currentProfileImageUrl: String?
    @Binding var selectedProfileImageFromGallery: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BarkParkDesign.Spacing.md) {
                    ForEach(galleryImages, id: \.self) { imageUrl in
                        Button {
                            selectedProfileImageFromGallery = imageUrl
                            dismiss()
                        } label: {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .foregroundColor(BarkParkDesign.Colors.tertiaryBackground)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: BarkParkDesign.Colors.dogPrimary))
                                    )
                            }
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium)
                                    .stroke(
                                        currentProfileImageUrl == imageUrl ? BarkParkDesign.Colors.dogPrimary : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Profile Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EditDogView(dog: Dog(
        id: 1,
        name: "Buddy",
        breed: "Golden Retriever",
        birthday: "2020-05-15",
        age: 5,
        weight: 65.5,
        gender: "male",
        sizeCategory: "large",
        energyLevel: "high",
        friendlinessDogs: 5,
        friendlinessPeople: 4,
        trainingLevel: "advanced",
        favoriteActivities: ["fetch", "swimming", "hiking"],
        isVaccinated: true,
        isSpayedNeutered: true,
        specialNeeds: nil,
        bio: "Buddy is a friendly and energetic Golden Retriever who loves to play fetch and swim.",
        profileImageUrl: nil,
        galleryImages: ["https://example.com/image1.jpg", "https://example.com/image2.jpg"],
        userId: 1,
        createdAt: "2023-01-01T00:00:00.000Z",
        updatedAt: "2023-01-01T00:00:00.000Z"
    ))
    .environmentObject(DogProfileViewModel())
}