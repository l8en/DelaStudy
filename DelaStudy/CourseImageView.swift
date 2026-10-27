import SwiftUI

@MainActor
private enum CourseImageCache {
    static let images: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 24 * 1024 * 1024
        cache.countLimit = 16
        return cache
    }()
    static func image(_ record: CourseImageRecord) -> UIImage? {
        let key = record.id as NSString
        if let image = images.object(forKey: key) { return image }
        guard let url = CourseMedia.url(for: record), let original = UIImage(contentsOfFile: url.path) else { return nil }
        let image = original.preparingForDisplay() ?? original
        images.setObject(image, forKey: key, cost: Int(image.size.width * image.size.height * image.scale * image.scale * 4))
        return image
    }
}

/// Bounded local images, individually framed. Text and controls live outside the photograph.
struct CourseImageView: View {
    let courseID: String
    var fullImage = false
    var body: some View {
        GeometryReader { geometry in
            if let record = CourseMedia.image(for: courseID), let image = CourseImageCache.image(record) {
                let fit = fullImage || record.fit == "fit"
                let size = image.size
                let scale = fit ? min(geometry.size.width / size.width, geometry.size.height / size.height)
                    : max(geometry.size.width / size.width, geometry.size.height / size.height)
                LensTheme.imageMat.overlay(alignment: .topLeading) {
                    Image(uiImage: image).resizable()
                        .frame(width: size.width * scale, height: size.height * scale)
                        .offset(x: fit ? (geometry.size.width - size.width * scale) / 2 : -(size.width * scale - geometry.size.width) * record.focalX,
                                y: fit ? (geometry.size.height - size.height * scale) / 2 : -(size.height * scale - geometry.size.height) * record.focalY)
                }.frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading).clipped()
            } else {
                ZStack {
                    LensTheme.imageMat
                    VStack(spacing: 6) {
                        LensMark().frame(width: 24, height: 24)
                        Text("First State Lens").font(LensFont.caption2.weight(.medium)).foregroundStyle(LensTheme.slate)
                    }
                }
            }
        }.contentShape(Rectangle()).accessibilityHidden(true)
    }
}

struct ImageInspectionView: View {
    let record: CourseImageRecord
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    CourseImageView(courseID: record.courseIDs[0], fullImage: true).frame(height: 260)
                        .accessibilityHidden(false).accessibilityLabel(record.alt)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(record.medium.uppercased()).font(LensFont.caption2.monospaced().weight(.semibold)).foregroundStyle(LensTheme.teal)
                        Text(record.title).font(LensFont.title2.weight(.semibold))
                        Text(record.creator).font(LensFont.subheadline)
                        Text(record.institution).font(LensFont.caption).foregroundStyle(LensTheme.slate)
                    }
                    Text(record.reason).font(LensFont.body).lineSpacing(3)
                    Divider()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Image record").font(LensFont.headline)
                        Text(record.provenance).font(LensFont.subheadline)
                        Text(record.credit).font(LensFont.caption).textSelection(.enabled)
                        Text(record.modifications).font(LensFont.caption).foregroundStyle(LensTheme.slate)
                        Link("Original record", destination: record.sourceURL).frame(minHeight: 44)
                        Link(record.license, destination: record.licenseURL).frame(minHeight: 44)
                        Text("Source checked \(record.accessedOn)").font(LensFont.caption2).foregroundStyle(LensTheme.slate)
                    }
                }.padding(20)
            }.background(LensTheme.paper).foregroundStyle(LensTheme.navy)
                .navigationTitle("Behind the image").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.tint(LensTheme.teal)
    }
}

struct ImageCreditsView: View {
    @Bindable var model: AppModel
    @State private var query = ""
    @State private var inspecting: CourseImageRecord?
    private var records: [CourseImageRecord] {
        CourseMedia.all.filter { record in
            query.isEmpty || [record.title, record.creator, record.medium, record.institution,
                record.courseIDs.compactMap { model.content.course(id: $0)?.title }.joined(separator: " ")]
                .contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    var body: some View {
        BearingPage(title: "Image credits", eyebrow: "The collection") {
            Text("Photographs, instruments, and archival records. All covers are stored in the app.")
                .font(LensFont.subheadline).foregroundStyle(LensTheme.slate)
            if records.isEmpty { Text("No matching images").font(LensFont.headline) }
            ForEach(records) { record in
                Button { inspecting = record } label: {
                    HStack(alignment: .top, spacing: 14) {
                        CourseImageView(courseID: record.courseIDs[0]).frame(width: 80, height: 72).clipShape(RoundedRectangle(cornerRadius: 5))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.title).font(LensFont.subheadline.weight(.semibold)).foregroundStyle(LensTheme.navy)
                            Text(record.creator).font(LensFont.caption).foregroundStyle(LensTheme.slate).lineLimit(2)
                            Text(record.license).font(LensFont.caption2).foregroundStyle(LensTheme.teal)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "arrow.up.right").font(LensFont.caption).foregroundStyle(LensTheme.teal)
                    }.padding(.vertical, 4)
                }.buttonStyle(.plain).accessibilityIdentifier("credit-\(record.id)")
                Divider()
            }
        }.searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Image, creator, or course")
            .sheet(item: $inspecting) { ImageInspectionView(record: $0) }
    }
}
