//
//  ShareDogSheet.swift
//  BarkPark
//
//  Created by OpenAI Assistant on 6/4/25.
//

import SwiftUI

struct ShareDogSheet: View {
    let dog: Dog

    @EnvironmentObject var dogProfileViewModel: DogProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var searchQuery: String = ""
    @State private var selectedRole: DogOwnershipRole = .viewer
    @State private var isInviting = false
    @State private var searchTask: Task<Void, Never>? = nil

    private var currentDog: Dog {
        dogProfileViewModel.dogs.first(where: { $0.id == dog.id }) ?? dog
    }

    private var canManageMembers: Bool {
        dogProfileViewModel.canManageMembers(dog: currentDog)
    }

    var body: some View {
        NavigationView {
            List {
                if let error = dogProfileViewModel.membershipErrorMessage {
                    Section {
                        Text(error)
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(.red)
                    }
                }

                if canManageMembers {
                    inviteSection
                } else {
                    Section("Sharing") {
                        Text("You have view-only access. Only owners can invite or remove members.")
                            .font(BarkParkDesign.Typography.body)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                }

                membersSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Share \(currentDog.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .overlay(alignment: .bottom) {
                if dogProfileViewModel.isManagingMembers {
                    ProgressView("Updating access…")
                        .padding()
                        .background(BarkParkDesign.Colors.tertiaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium))
                        .padding()
                }
            }
            .task {
                await dogProfileViewModel.refreshMembers(for: dog)
            }
            .onDisappear {
                searchTask?.cancel()
            }
        }
        .presentationDetents([.medium, .large])
        .onChange(of: searchQuery) { newValue in
            handleSearchChange(newValue)
        }
    }

    private var inviteSection: some View {
        Section("Invite a friend") {
            TextField("Search by name or email", text: $searchQuery)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)

            Picker("Role", selection: $selectedRole) {
                ForEach(DogOwnershipRole.allCases.filter { $0 != .unknown }, id: \.self) { role in
                    Text(role.displayName).tag(role)
                }
            }

            if !dogProfileViewModel.shareSearchResults.isEmpty {
                ForEach(dogProfileViewModel.shareSearchResults) { user in
                    HStack(spacing: BarkParkDesign.Spacing.md) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.fullName)
                                .font(BarkParkDesign.Typography.body)
                                .foregroundColor(BarkParkDesign.Colors.primaryText)

                            Text(user.email)
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        }

                        Spacer()

                        Button {
                            invite(user: user)
                        } label: {
                            if isInviting {
                                ProgressView()
                            } else {
                                Text("Invite")
                                    .font(BarkParkDesign.Typography.caption)
                                    .padding(.horizontal, BarkParkDesign.Spacing.md)
                                    .padding(.vertical, BarkParkDesign.Spacing.xs)
                                    .background(BarkParkDesign.Colors.dogPrimary)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isInviting)
                    }
                }
            } else if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("No users found. Try a different search term.")
                    .font(BarkParkDesign.Typography.caption)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
            }
        }
    }

    @ViewBuilder
    private var membersSection: some View {
        let activeMembers = currentDog.owners.filter { dogProfileViewModel.isMemberActive($0) }
        let pendingMembers = currentDog.owners.filter { $0.isPending }

        Section("Members") {
            if activeMembers.isEmpty {
                Text("No members yet.")
                    .font(BarkParkDesign.Typography.caption)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
            } else {
                ForEach(activeMembers, id: \.self) { member in
                    memberRow(member)
                }
            }
        }

        if !pendingMembers.isEmpty {
            Section("Pending Invites") {
                ForEach(pendingMembers, id: \.self) { member in
                    memberRow(member)
                }
            }
        }
    }

    @ViewBuilder
    private func memberRow(_ member: DogOwnerSummary) -> some View {
        HStack(spacing: BarkParkDesign.Spacing.md) {
            if let urlString = member.profileImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(BarkParkDesign.Colors.tertiaryBackground)
                        .overlay(
                            Text(member.initials)
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        )
                }
                .frame(width: 34, height: 34)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(BarkParkDesign.Colors.tertiaryBackground)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Text(member.initials)
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(member.fullName)
                    .font(BarkParkDesign.Typography.body)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)

                Text(member.displayRole)
                    .font(BarkParkDesign.Typography.caption)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
            }

            Spacer()

            if member.isPending {
                Text("Pending")
                    .font(BarkParkDesign.Typography.caption)
                    .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                    .padding(.horizontal, BarkParkDesign.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(BarkParkDesign.Colors.dogPrimary.opacity(0.12))
                    .clipShape(Capsule())
            }

            if dogProfileViewModel.canRemove(member: member, from: currentDog) {
                Button(role: .destructive) {
                    remove(member: member)
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(dogProfileViewModel.isManagingMembers)
            }
        }
    }

    private func handleSearchChange(_ newValue: String) {
        searchTask?.cancel()

        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            dogProfileViewModel.shareSearchResults = []
            return
        }

        searchTask = Task { [query = trimmed] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            await dogProfileViewModel.searchShareableUsers(query: query)
        }
    }

    private func invite(user: User) {
        guard !isInviting else { return }
        isInviting = true

        Task {
            let success = await dogProfileViewModel.inviteMember(to: dog, userId: user.id, role: selectedRole)
            if success {
                searchQuery = ""
                dogProfileViewModel.shareSearchResults = []
            }
            isInviting = false
        }
    }

    private func remove(member: DogOwnerSummary) {
        Task {
            _ = await dogProfileViewModel.removeMember(member, from: dog)
        }
    }
}

#Preview {
    let viewModel = DogProfileViewModel()
    viewModel.dogs = [PreviewData.sampleDog]
    return ShareDogSheet(dog: PreviewData.sampleDog)
        .environmentObject(viewModel)
}
