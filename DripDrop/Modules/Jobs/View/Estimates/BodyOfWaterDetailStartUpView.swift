//
//  BodyOfWaterDetailStartUpView.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/29/24.
//

import SwiftUI

struct BodyOfWaterDetailStartUpView: View {
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
    
    var body: some View {
        VStack{
            ForEach($bodiesOfWater){ $BOW in
                if BOW.id == selectedBodyOfWater.id {
                    VStack{
                        HStack{
                            Spacer()
                            Button(action: {
                                equipmentList.removeAll(where: {$0.bodyOfWaterId == selectedBodyOfWater.id})
                                bodiesOfWater.removeAll(where: {$0.id == selectedBodyOfWater.id})
                                
                            }, label: {
                                Text("Delete")
                                    .modifier(DeleteButtonModifier())
                            })
                        }
                        HStack{
                            Text("Name: ")
                                .bold(true)
                            
                            TextField("Name", text: $BOW.name, prompt: Text("Name"), axis: .vertical)
                                .padding(5)
                                .background(Color.white)
                                .foregroundColor(Color.basicFontText)
                                .cornerRadius(5)
                                .padding(5)
                        }
                        HStack{
                            Text("Material")
                                .bold(true)
                            Picker("Pool Material", selection: $BOW.material, content: {
                                ForEach(BodyOfWaterMaterial.allCases,id:\.self){ material in
                                    Text(material.rawValue).tag(material.rawValue)
                                }
                            })
                            Spacer()
                        }
                        HStack{
                            Text("Shape")
                                .bold(true)
                            Picker("Shape", selection: optionalStringBinding($BOW.shape)) {
                                ForEach(shapes,id: \.self){ shape in
                                    Text(shape).tag(shape)
                                }
                            }
                            Spacer()
                        }
                        
                        HStack{
                            Text("Gallons: ")
                                .bold(true)
                            
                            TextField("Gallons", text: $BOW.gallons, prompt: Text("Gallons"), axis: .vertical)
                                .padding(5)
                                .background(Color.white)
                                .foregroundColor(Color.basicFontText)
                                .cornerRadius(5)
                                .padding(5)
                            Button(action: {
                                showDimensions.toggle()
                            }, label: {
                                Text(showDimensions ? "Hide Dimensions" : "Add Dimensions")
                                    .modifier(AddButtonModifier())
                            })
                        }
                        HStack(alignment: .top){
                            Text("Notes")
                                .bold(true)

                            TextField("Notes", text: optionalStringBinding($BOW.notes), axis: .vertical)
                                .lineLimit(2...5)
                                .padding(5)
                                .background(Color.white)
                                .foregroundColor(Color.basicFontText)
                                .cornerRadius(5)
                                .padding(5)
                        }
                        if showDimensions {
                            VStack{
                                dimensionRow(title: "Length 1", text: dimensionBinding($BOW.length, index: 0))
                                dimensionRow(title: "Length 2", text: dimensionBinding($BOW.length, index: 1))
                                dimensionRow(title: "Depth 1", text: dimensionBinding($BOW.depth, index: 0))
                                dimensionRow(title: "Depth 2", text: dimensionBinding($BOW.depth, index: 1))
                                dimensionRow(title: "Width 1", text: dimensionBinding($BOW.width, index: 0))
                                dimensionRow(title: "Width 2", text: dimensionBinding($BOW.width, index: 1))
                            }
                        }
                        poolVolumeGuide(for: $BOW)
                        PhotoContentView(selectedImages: $selectedPhotos)
                    }
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
    }
}

//#Preview {
//    BodyOfWaterDetailStartUpView()
//}

private extension BodyOfWaterDetailStartUpView {
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
        let capturedPhotoCount = min(selectedPhotos.count, poolVolumePhotoSteps.count)

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
                    photoGuideRow(step, capturedPhotoCount: capturedPhotoCount)
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

                Text(volumeConfidenceText(for: bodyOfWater.wrappedValue, photoCount: selectedPhotos.count))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color.white.opacity(0.65))
            .cornerRadius(10)
        }
        .padding(12)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }

    func photoGuideRow(_ step: PoolVolumePhotoStep, capturedPhotoCount: Int) -> some View {
        let isCaptured = capturedPhotoCount >= step.number
        let isNext = capturedPhotoCount + 1 == step.number

        return HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(isCaptured ? Color.green.opacity(0.16) : Color.accentColor.opacity(isNext ? 0.18 : 0.08))
                    .frame(width: 32, height: 32)

                Image(systemName: isCaptured ? "checkmark" : step.systemImage)
                    .font(.caption.bold())
                    .foregroundColor(isCaptured ? .green : .accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isCaptured ? "Captured" : (isNext ? "Next photo" : "Upcoming"))
                    .font(.caption2.bold())
                    .foregroundColor(isCaptured ? .green : .secondary)

                Text("\(step.number). \(step.title)")
                    .font(.subheadline.bold())

                Text(step.instruction)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(isNext ? Color.accentColor.opacity(0.08) : Color.clear)
        .cornerRadius(10)
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
        HStack{
            Text(title)
                .bold(true)

            TextField(title, text: text)
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
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
