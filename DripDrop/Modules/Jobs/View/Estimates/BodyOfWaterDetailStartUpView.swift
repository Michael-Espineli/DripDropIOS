//
//  BodyOfWaterDetailStartUpView.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/29/24.
//

import SwiftUI

struct BodyOfWaterDetailStartUpView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var bodiesOfWater:[BodyOfWater]
    @Binding var selectedBodyOfWater:BodyOfWater
    @Binding var equipmentList:[Equipment]
    @Binding var photos:[String:[DripDropImage]]

    @State var shapes:[String] = ["Square","Rectangle","Kidney","Circular"]
    @State var material:BodyOfWaterMaterial = .plaster
    @State var name:String = ""

    @State var gallons:String = "0"
    @State var length1:String = ""
    @State var depth1:String = ""
    @State var width1:String = ""
    
    @State var length2:String = ""
    @State var depth2:String = ""
    @State var width2:String = ""
    @State var selectedPhotos:[DripDropImage] = []
    @State var shape:String = ""
    @State var showDimensions:Bool = true
    @State private var selectedPoolVolumePhotoStep: PoolVolumePhotoStep?
    @State private var showPoolVolumePhotoSourceDialog = false
    @State private var showPoolVolumePhotoPicker = false
    @State private var poolVolumePhotoSource: DripDropPicker.Source = .camera
    @State private var poolVolumePickerImage: UIImage?
    @State private var showPoolVolumePhotoError = false
    @State private var poolVolumePhotoErrorMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if bodiesOfWater.isEmpty {
                startupEmptyState(
                    title: "No Bodies Of Water",
                    message: "Add a pool, spa, or other body of water to start the survey.",
                    systemImage: "drop.triangle"
                )
            }

            ForEach($bodiesOfWater) { $BOW in
                if BOW.id == selectedBodyOfWater.id {
                    bodyOfWaterDetailCard($BOW)
                }
            }
        }
        .onAppear(perform: {
            print("")

            print("On Appear selectedEquipmentId")
            selectedPhotos = []
            if let preselectedPhotos = photos[selectedBodyOfWater.id] {
                selectedPhotos = preselectedPhotos
                print(preselectedPhotos)
            } else {
                selectedPhotos = []
            }
        })
        .onChange(of: selectedBodyOfWater, perform: { BOW in
            print("")
            selectedPhotos = []
            print("Change of selected Equipment Id")
            if let preselectedPhotos = photos[BOW.id] {
                selectedPhotos = preselectedPhotos
                print("selectedPhotos")

                print(selectedPhotos)

            } else {
                selectedPhotos = []
                print("selectedPhotos")
                print(selectedPhotos)

            }
        })
        .onChange(of: selectedPhotos, perform: { images in
            print("")
            print("Change Of Selected Photos")
            print(images)
            photos[selectedBodyOfWater.id] = images
        })
        .confirmationDialog(
            selectedPoolVolumePhotoStep.map { "Add photo for step \($0.number)" } ?? "Add Photo",
            isPresented: $showPoolVolumePhotoSourceDialog,
            titleVisibility: .visible
        ) {
            Button("Take Photo") {
                openPoolVolumePhotoPicker(source: .camera)
            }

            Button("Choose From Library") {
                openPoolVolumePhotoPicker(source: .library)
            }

            Button("Cancel", role: .cancel) {
                selectedPoolVolumePhotoStep = nil
            }
        } message: {
            if let selectedPoolVolumePhotoStep {
                Text(selectedPoolVolumePhotoStep.title)
            }
        }
        .sheet(isPresented: $showPoolVolumePhotoPicker, onDismiss: savePoolVolumeStepPhotoIfNeeded) {
            DripDropImagePicker(
                sourceType: poolVolumePhotoSource == .library ? .photoLibrary : .camera,
                selectedImage: $poolVolumePickerImage
            )
            .ignoresSafeArea()
        }
        .alert("Photo Error", isPresented: $showPoolVolumePhotoError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(poolVolumePhotoErrorMessage)
        }
    }
}

//#Preview {
//    BodyOfWaterDetailStartUpView()
//}

private extension BodyOfWaterDetailStartUpView {
    func bodyOfWaterDetailCard(_ bodyOfWater: Binding<BodyOfWater>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            bodyOfWaterHeader(bodyOfWater)

            VStack(spacing: 10) {
                startupTextField(title: "Name", text: bodyOfWater.name)

                LazyVGrid(
                    columns: fieldColumns,
                    spacing: 10
                ) {
                    materialPicker(bodyOfWater)
                    shapePicker(bodyOfWater)
                }

                startupTextField(
                    title: "Gallons",
                    text: bodyOfWater.gallons,
                    keyboardType: .numberPad
                )

                startupTextField(
                    title: "Notes",
                    text: optionalStringBinding(bodyOfWater.notes),
                    lineLimit: 3...6
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Dimensions", systemImage: "ruler")
                        .font(.headline.weight(.semibold))

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDimensions.toggle()
                        }
                    } label: {
                        Label(showDimensions ? "Hide" : "Add", systemImage: showDimensions ? "chevron.up" : "plus")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                if showDimensions {
                    LazyVGrid(
                        columns: fieldColumns,
                        spacing: 10
                    ) {
                        dimensionRow(title: "Length 1", text: dimensionBinding(bodyOfWater.length, index: 0))
                        dimensionRow(title: "Length 2", text: dimensionBinding(bodyOfWater.length, index: 1))
                        dimensionRow(title: "Depth 1", text: dimensionBinding(bodyOfWater.depth, index: 0))
                        dimensionRow(title: "Depth 2", text: dimensionBinding(bodyOfWater.depth, index: 1))
                        dimensionRow(title: "Width 1", text: dimensionBinding(bodyOfWater.width, index: 0))
                        dimensionRow(title: "Width 2", text: dimensionBinding(bodyOfWater.width, index: 1))
                    }
                }
            }
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            poolVolumeGuide(for: bodyOfWater)

            if let storedImages = bodyOfWater.wrappedValue.photoUrls, !storedImages.isEmpty {
                DripDropStoredImageRow(images: storedImages)
            }

            VStack(alignment: .leading, spacing: 10) {
                Label("Body Photos", systemImage: "camera.fill")
                    .font(.headline.weight(.semibold))

                Text("Use the guide rows above for volume photos. Add any extra body-of-water photos here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                PhotoContentView(selectedImages: $selectedPhotos)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func bodyOfWaterHeader(_ bodyOfWater: Binding<BodyOfWater>) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "drop.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 36, height: 36)
                .background(Color.poolBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(bodyOfWater.wrappedValue.name.isEmpty ? "Body Of Water" : bodyOfWater.wrappedValue.name)
                    .font(.headline.weight(.semibold))
                    .lineLimit(2)

                Text("Capture structure, volume, and photos for the service agreement estimate.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button(role: .destructive) {
                deleteBodyOfWater(bodyOfWater.wrappedValue)
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(Color.red.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete body of water")
        }
    }

    func materialPicker(_ bodyOfWater: Binding<BodyOfWater>) -> some View {
        menuField(
            title: "Material",
            value: bodyOfWater.wrappedValue.material,
            placeholder: "Select material"
        ) {
            Button("Select material") {
                bodyOfWater.wrappedValue.material = ""
            }

            ForEach(BodyOfWaterMaterial.allCases, id: \.self) { material in
                Button {
                    bodyOfWater.wrappedValue.material = material.rawValue
                } label: {
                    Text(material.rawValue)
                }
            }
        }
    }

    func shapePicker(_ bodyOfWater: Binding<BodyOfWater>) -> some View {
        menuField(
            title: "Shape",
            value: bodyOfWater.wrappedValue.shape ?? "",
            placeholder: "Select shape"
        ) {
            Button("Select shape") {
                bodyOfWater.wrappedValue.shape = ""
            }

            ForEach(shapes, id: \.self) { shape in
                Button {
                    bodyOfWater.wrappedValue.shape = shape
                } label: {
                    Text(shape)
                }
            }
        }
    }

    func menuField<Content: View>(
        title: String,
        value: String,
        placeholder: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Menu {
                content()
            } label: {
                HStack(spacing: 8) {
                    Text(trimmedValue.isEmpty ? placeholder : trimmedValue)
                        .foregroundStyle(trimmedValue.isEmpty ? .secondary : .primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    func startupTextField(
        title: String,
        text: Binding<String>,
        lineLimit: ClosedRange<Int>? = nil,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let lineLimit {
                TextField(title, text: text, axis: .vertical)
                    .lineLimit(lineLimit)
                    .keyboardType(keyboardType)
                    .padding(10)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .foregroundColor(Color.basicFontText)
            } else {
                TextField(title, text: text)
                    .keyboardType(keyboardType)
                    .padding(10)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .foregroundColor(Color.basicFontText)
            }
        }
    }

    var fieldColumns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible(), spacing: 10)]
        }

        return [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    func deleteBodyOfWater(_ bodyOfWater: BodyOfWater) {
        equipmentList.removeAll { $0.bodyOfWaterId == bodyOfWater.id }
        bodiesOfWater.removeAll { $0.id == bodyOfWater.id }

        if selectedBodyOfWater.id == bodyOfWater.id, let nextBodyOfWater = bodiesOfWater.first {
            selectedBodyOfWater = nextBodyOfWater
        }
    }

    func startupEmptyState(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    var poolVolumePhotoSteps: [PoolVolumePhotoStep] {
        [
            PoolVolumePhotoStep(
                number: 1,
                title: "Shallow end overview",
                instruction: "Stand centered at the shallow end and shoot straight down the pool length. Include both side walls and the waterline.",
                systemImage: "arrow.up.forward"
            ),
            PoolVolumePhotoStep(
                number: 2,
                title: "Deep end overview",
                instruction: "Stand centered at the deep end and shoot back toward the shallow end so the two overview photos connect.",
                systemImage: "arrow.down.backward"
            ),
            PoolVolumePhotoStep(
                number: 3,
                title: "Long side profile",
                instruction: "Stand halfway down the longest side. Capture curves, benches, attached spa edges, and the opposite wall.",
                systemImage: "rectangle.compress.vertical"
            ),
            PoolVolumePhotoStep(
                number: 4,
                title: "Widest width view",
                instruction: "Stand at the widest point and shoot across the pool. This helps confirm the width used in the estimate.",
                systemImage: "arrow.left.and.right"
            ),
            PoolVolumePhotoStep(
                number: 5,
                title: "Depth reference",
                instruction: "Take a close photo of depth markers, steps, tile line, or any known reference that supports the shallow and deep depth guess.",
                systemImage: "ruler"
            )
        ]
    }

    func poolVolumeGuide(for bodyOfWater: Binding<BodyOfWater>) -> some View {
        let estimate = estimatedGallons(for: bodyOfWater.wrappedValue)
        let capturedPhotoCount = poolVolumePhotoSteps
            .filter { poolVolumePhoto(for: $0) != nil }
            .count

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Pool Volume Guide", systemImage: "camera.viewfinder")
                        .font(.headline)

                    Text("Take the photos clockwise around the pool, then use the measurements above to calculate a starting gallon estimate.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(capturedPhotoCount)/\(poolVolumePhotoSteps.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.12))
                    .cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(poolVolumePhotoSteps) { step in
                    Button {
                        selectedPoolVolumePhotoStep = step
                        showPoolVolumePhotoSourceDialog = true
                    } label: {
                        photoGuideRow(step, capturedPhotoCount: capturedPhotoCount)
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                if let estimate {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Estimated gallons")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(estimate.formatted()) gal")
                                .font(.title3.bold())
                        }

                        Spacer()

                        Button {
                            bodyOfWater.wrappedValue.gallons = "\(estimate)"
                        } label: {
                            Text("Use Estimate")
                                .modifier(AddButtonModifier())
                        }
                    }
                } else {
                    Label("Enter length, width, and at least one depth to calculate gallons.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(volumeConfidenceText(for: bodyOfWater.wrappedValue, photoCount: capturedPhotoCount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color.listColor.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func photoGuideRow(_ step: PoolVolumePhotoStep, capturedPhotoCount: Int) -> some View {
        let stepPhoto = poolVolumePhoto(for: step)
        let isCaptured = stepPhoto != nil
        let isNext = capturedPhotoCount + 1 == step.number

        return HStack(alignment: .top, spacing: 10) {
            if let stepPhoto {
                Image(uiImage: stepPhoto.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 46, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.green)
                            .background(Color.white, in: Circle())
                            .offset(x: 4, y: -4)
                    }
            } else {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(isNext ? 0.18 : 0.08))
                        .frame(width: 40, height: 40)

                    Image(systemName: step.systemImage)
                        .font(.caption.bold())
                        .foregroundColor(.accentColor)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isCaptured ? "Photo assigned" : (isNext ? "Tap to add next photo" : "Tap to add photo"))
                    .font(.caption2.bold())
                    .foregroundColor(isCaptured ? .green : .secondary)

                Text("\(step.number). \(step.title)")
                    .font(.subheadline.bold())

                Text(step.instruction)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: isCaptured ? "camera.rotate" : "camera.fill")
                .font(.caption.weight(.semibold))
                .foregroundColor(.accentColor)
                .frame(width: 34, height: 34)
                .background(Color.accentColor.opacity(0.10), in: Circle())
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(isNext ? Color.accentColor.opacity(0.08) : Color.white.opacity(0.55))
        .cornerRadius(10)
    }

    func poolVolumePhotoName(for step: PoolVolumePhotoStep) -> String {
        "Pool Volume Step \(step.number): \(step.title)"
    }

    func poolVolumeStepNumber(for image: DripDropImage) -> Int? {
        let prefix = "Pool Volume Step "
        guard image.name.hasPrefix(prefix) else {
            return nil
        }

        let remainder = image.name.dropFirst(prefix.count)
        let numberText = remainder.prefix { $0.isNumber }
        return Int(numberText)
    }

    func poolVolumePhoto(for step: PoolVolumePhotoStep) -> DripDropImage? {
        if let taggedPhoto = selectedPhotos.first(where: { poolVolumeStepNumber(for: $0) == step.number }) {
            return taggedPhoto
        }

        let fallbackIndex = step.number - 1
        guard selectedPhotos.indices.contains(fallbackIndex) else {
            return nil
        }

        let fallbackPhoto = selectedPhotos[fallbackIndex]
        return poolVolumeStepNumber(for: fallbackPhoto) == nil ? fallbackPhoto : nil
    }

    func openPoolVolumePhotoPicker(source: DripDropPicker.Source) {
        do {
            if source == .camera {
                try DripDropPicker.checkPermissions()
            }

            poolVolumePhotoSource = source
            poolVolumePickerImage = nil
            showPoolVolumePhotoPicker = true
        } catch {
            poolVolumePhotoErrorMessage = "Camera access is needed to take this photo. You can also choose one from the library."
            showPoolVolumePhotoError = true
        }
    }

    func savePoolVolumeStepPhotoIfNeeded() {
        guard let uiImage = poolVolumePickerImage, let step = selectedPoolVolumePhotoStep else {
            selectedPoolVolumePhotoStep = nil
            poolVolumePickerImage = nil
            return
        }

        let stepImage = DripDropImage(name: poolVolumePhotoName(for: step))

        do {
            try FileManager().saveImage("\(stepImage.id)", image: uiImage)

            if let existingIndex = selectedPhotos.firstIndex(where: { poolVolumeStepNumber(for: $0) == step.number }) {
                selectedPhotos[existingIndex] = stepImage
            } else {
                selectedPhotos.append(stepImage)
            }
        } catch {
            poolVolumePhotoErrorMessage = "The photo could not be saved to this survey step."
            showPoolVolumePhotoError = true
        }

        selectedPoolVolumePhotoStep = nil
        poolVolumePickerImage = nil
    }

    func estimatedGallons(for bodyOfWater: BodyOfWater) -> Int? {
        guard
            let length = averageDimension(bodyOfWater.length),
            let width = averageDimension(bodyOfWater.width),
            let depth = averageDimension(bodyOfWater.depth),
            length > 0,
            width > 0,
            depth > 0
        else {
            return nil
        }

        let shape = (bodyOfWater.shape ?? "").lowercased()
        let surfaceArea: Double

        if shape.contains("circular") {
            surfaceArea = Double.pi * (length / 2) * (width / 2)
        } else if shape.contains("kidney") {
            surfaceArea = length * width * 0.8
        } else {
            surfaceArea = length * width
        }

        return Int((surfaceArea * depth * 7.48052).rounded())
    }

    func averageDimension(_ values: [String]?) -> Double? {
        let dimensions = values?
            .compactMap({ dimensionValue($0) })
            .filter({ $0 > 0 }) ?? []

        guard !dimensions.isEmpty else {
            return nil
        }

        return dimensions.reduce(0, +) / Double(dimensions.count)
    }

    func dimensionValue(_ value: String) -> Double? {
        let cleanedValue = value
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(cleanedValue)
    }

    func volumeConfidenceText(for bodyOfWater: BodyOfWater, photoCount: Int) -> String {
        guard estimatedGallons(for: bodyOfWater) != nil else {
            return "Confidence: Low until length, width, and depth are entered."
        }

        if photoCount >= poolVolumePhotoSteps.count {
            return "Confidence: High for service setup. Photos and measurements are both captured."
        }

        if photoCount >= 3 {
            return "Confidence: Medium. Add the remaining guided photos to support the estimate."
        }

        return "Confidence: Medium from measurements. Add guided photos before saving the visit."
    }

    func optionalStringBinding(_ value: Binding<String?>) -> Binding<String> {
        Binding(
            get: { value.wrappedValue ?? "" },
            set: { value.wrappedValue = $0 }
        )
    }

    func dimensionBinding(_ values: Binding<[String]?>, index: Int) -> Binding<String> {
        Binding(
            get: {
                guard let dimensions = values.wrappedValue, dimensions.indices.contains(index) else {
                    return ""
                }

                return dimensions[index]
            },
            set: { newValue in
                var dimensions = values.wrappedValue ?? []

                while dimensions.count <= index {
                    dimensions.append("")
                }

                dimensions[index] = newValue
                values.wrappedValue = dimensions
            }
        )
    }

    func dimensionRow(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(title, text: text)
                .keyboardType(.decimalPad)
                .padding(10)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundColor(Color.basicFontText)
        }
    }
}

private struct PoolVolumePhotoStep: Identifiable {
    let number: Int
    let title: String
    let instruction: String
    let systemImage: String

    var id: Int {
        number
    }
}
