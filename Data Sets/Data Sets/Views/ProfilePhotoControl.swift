import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import ImageIO
import UIKit

/// Shared avatar upload entry. Only the selected image is read; no full-library
/// permission or network upload is required in the local demo.
struct ProfilePhotoControl: View {
    let displayName: String
    @Binding var avatarData: Data?
    var size: CGFloat = 100
    @State private var chooseSource = false
    @State private var showLibrary = false
    @State private var showFiles = false
    @State private var photo: PhotosPickerItem?
    @State private var loading = false
    @State private var error: String?

    private var preview: DatingProfile {
        var profile = DatingProfile()
        profile.name = displayName
        profile.avatarData = avatarData
        return profile
    }

    var body: some View {
        VStack(spacing: 11) {
            Button { chooseSource = true } label: {
                VStack(spacing: 13) {
                    ProfileAvatar(profile: preview, size: size)
                        .overlay { Circle().stroke(Color.vibePink.opacity(0.55), lineWidth: 2).padding(-5) }
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.fill").font(.system(size: 13, weight: .semibold))
                                .padding(9).background(Color.vibePink, in: Circle())
                                .overlay { Circle().stroke(Color(red: 0.12, green: 0.06, blue: 0.18), lineWidth: 3) }
                        }
                    HStack(spacing: 6) {
                        if loading { ProgressView().tint(.vibePink).scaleEffect(0.7) }
                        Text(loading ? "Saving your photo…" : avatarData == nil ? "Add your photo" : "Change photo")
                            .font(.caption.weight(.semibold)).foregroundStyle(Color.vibePink)
                    }
                }
            }
            .buttonStyle(.plain).disabled(loading)
            .accessibilityLabel(avatarData == nil ? "Upload profile photo" : "Change profile photo")
            .accessibilityIdentifier("profile-photo-upload")
            if let error { Text(error).font(.caption).foregroundStyle(Color.vibePink).multilineTextAlignment(.center) }
        }
        .confirmationDialog("Your profile photo", isPresented: $chooseSource, titleVisibility: .visible) {
            Button("Photo library") { showLibrary = true }
            Button("Choose from Files") { showFiles = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showLibrary, selection: $photo, matching: .images)
        .task(id: photo) {
            guard let photo else { return }
            loading = true
            error = nil
            defer { loading = false }
            do {
                guard let original = try await photo.loadTransferable(type: Data.self) else { throw PhotoError.unreadable }
                let thumbnail = try await Task.detached(priority: .userInitiated) {
                    try AvatarImageImport.jpeg(from: original)
                }.value
                guard !Task.isCancelled else { return }
                avatarData = thumbnail
            } catch { if !Task.isCancelled { self.error = "Couldn't open this photo. Try another image or choose from Files." } }
        }
        .fileImporter(isPresented: $showFiles, allowedContentTypes: [.image]) { result in
            guard case .success(let url) = result else { return }
            loading = true
            error = nil
            Task {
                defer { loading = false }
                do {
                    let data = try await Task.detached(priority: .userInitiated) {
                        let scoped = url.startAccessingSecurityScopedResource()
                        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                        return try AvatarImageImport.jpeg(from: Data(contentsOf: url))
                    }.value
                    guard !Task.isCancelled else { return }
                    avatarData = data
                } catch { self.error = "Couldn't open this image. Please choose another photo." }
            }
        }
    }

    private enum PhotoError: Error { case unreadable }
}

/// Downsample before decoding a large original. The persisted avatar is at most
/// 400 pixels on its longest edge, rather than a full-resolution phone photo.
enum AvatarImageImport {
    enum ImportError: Error { case unreadable }

    nonisolated static func jpeg(from data: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 400,
                kCGImageSourceShouldCacheImmediately: true,
              ] as CFDictionary),
              let result = UIImage(cgImage: image).jpegData(compressionQuality: 0.82) else {
            throw ImportError.unreadable
        }
        return result
    }
}
