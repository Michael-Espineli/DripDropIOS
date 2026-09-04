//
//  AddBodyOfWaterView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//


//
//  AddServiceLocationView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI

struct AddBodyOfWaterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @EnvironmentObject var masterDataManager : MasterDataManager
    @State var serviceLocation:ServiceLocation
    @StateObject var bodyofWaterVM : BodyOfWaterViewModel
    init(dataService:any ProductionDataServiceProtocol,serviceLocation:ServiceLocation){
        _bodyofWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
        _serviceLocation = State(wrappedValue: serviceLocation)
    }
    
//Body Of Water
    @State var shapes:[String] = ["Square","Rectangle","Kidney","Circular"]

    @State var name:String = "Main"
    @State var gallons:String = "16000"
    @State var material:String = BodyOfWaterMaterial.plaster.rawValue
    @State var notes:String = ""
    @State var shape:String = ""
    
    @State var length1:String = ""
    @State var depth1:String = ""
    @State var width1:String = ""
    
    @State var length2:String = ""
    @State var depth2:String = ""
    @State var width2:String = ""
    @State var lastFilled:Date = Date()

    //Alerts
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    @State var showBodyOfWaterSheet:Bool = false
    
    @State var showTreeSheet:Bool = false
    @State var showBushSheet:Bool = false
    @State var showOtherSheet:Bool = false
    @State private var showDimensions:Bool = false
    @State private var isSaving:Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        header
                        bodyOfWater
                        dimensions
                        notesSection
                        submitButton
                    }
                    .padding(14)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Add Body of Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

extension AddBodyOfWaterView {
    var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 42, height: 42)
                .background(Color.poolBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("New Body of Water")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(serviceLocationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .addBodyCard()
    }

    var bodyOfWater: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Details", systemImage: "list.bullet.rectangle", tint: .poolBlue)

            formTextField(
                title: "Name",
                placeholder: "Main",
                text: $name
            )

            LazyVGrid(columns: fieldColumns, spacing: 10) {
                formTextField(
                    title: "Gallons",
                    placeholder: "16000",
                    text: $gallons,
                    keyboardType: .numberPad
                )

                shapePicker

                formTextField(
                    title: "Material",
                    placeholder: "Plaster",
                    text: $material
                )

                lastFilledPicker
            }
        }
        .addBodyCard()
    }

    var dimensions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "Measurements", systemImage: "ruler", tint: .poolGreen)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDimensions.toggle()
                    }
                } label: {
                    Label(showDimensions ? "Hide" : "Add", systemImage: showDimensions ? "chevron.up" : "plus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.poolGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.poolGreen.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if showDimensions {
                LazyVGrid(columns: fieldColumns, spacing: 10) {
                    formTextField(title: "Length 1", placeholder: "Feet", text: $length1, keyboardType: .decimalPad)
                    formTextField(title: "Length 2", placeholder: "Feet", text: $length2, keyboardType: .decimalPad)
                    formTextField(title: "Depth 1", placeholder: "Feet", text: $depth1, keyboardType: .decimalPad)
                    formTextField(title: "Depth 2", placeholder: "Feet", text: $depth2, keyboardType: .decimalPad)
                    formTextField(title: "Width 1", placeholder: "Feet", text: $width1, keyboardType: .decimalPad)
                    formTextField(title: "Width 2", placeholder: "Feet", text: $width2, keyboardType: .decimalPad)
                }
            } else {
                Text("Optional length, width, and depth values can support future volume estimates.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .addBodyCard()
    }

    var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Notes", systemImage: "note.text", tint: .orange)

            formTextField(
                title: "Service Notes",
                placeholder: "Add surface, access, or water condition notes...",
                text: $notes,
                lineLimit: 3...6
            )
        }
        .addBodyCard()
    }

    var submitButton: some View {
        Button(action: {
            saveBodyOfWater()
        }, label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                }

                Text(isSaving ? "Saving..." : "Create Body of Water")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSaving ? Color.gray : Color.poolGreen, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        })
        .buttonStyle(.plain)
        .disabled(isSaving)
    }

    var shapePicker: some View {
        menuField(
            title: "Shape",
            value: shape,
            placeholder: "Not specified"
        ) {
            Button("Not specified") {
                shape = ""
            }

            ForEach(shapes, id: \.self) { shapeOption in
                Button(shapeOption) {
                    shape = shapeOption
                }
            }
        }
    }

    var lastFilledPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Last Filled")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.72))

            HStack {
                Image(systemName: "calendar")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)

                DatePicker("", selection: $lastFilled, in: ...Date(), displayedComponents: .date)
                    .labelsHidden()

                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.poolBlue.opacity(0.24), lineWidth: 1)
            )
        }
    }

    var fieldColumns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible(), spacing: 10)]
        }

        return [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var serviceLocationName: String {
        let nickname = serviceLocation.nickName.trimmingCharacters(in: .whitespacesAndNewlines)
        let street = serviceLocation.address.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        if !nickname.isEmpty {
            return nickname
        }

        if !street.isEmpty {
            return street
        }

        return serviceLocation.customerName.isEmpty ? "Service location" : serviceLocation.customerName
    }

    func saveBodyOfWater() {
        guard !isSaving else { return }

        Task {
            do {
                guard let company = masterDataManager.currentCompany else {
                    alertMessage = "No Company Selected"
                    showAlert = true
                    return
                }

                isSaving = true

                try await bodyofWaterVM.addBOWToLocationWithValidation(serviceLocation: serviceLocation,
                                                                       companyId: company.id,
                                                                       name: name,
                                                                       gallons: gallons,
                                                                       material: material,
                                                                       customerId: serviceLocation.customerId,
                                                                       serviceLocationId: serviceLocation.id,
                                                                       notes: notes,
                                                                       shape: shape,
                                                                       length: [length1,length2],
                                                                       depth: [depth1,depth2],
                                                                       width: [width1,width2],
                                                                       lastFilled: lastFilled)
                isSaving = false
                alertMessage = "Successfully Updated"
                print(alertMessage)
                showAlert = true
                dismiss()
            } catch BodyOfWaterError.invalidCustomerId {
                isSaving = false
                alertMessage = "Invalid Customer Selected"
                print(alertMessage)
                showAlert = true
            } catch  {
                isSaving = false
                alertMessage = "Invalid Something"
                print(alertMessage)
                showAlert = true
            }
        }
    }

    func sectionHeader(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12), in: Circle())

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    func formTextField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        lineLimit: ClosedRange<Int>? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.72))

            if let lineLimit {
                TextField(placeholder, text: text, axis: .vertical)
                    .lineLimit(lineLimit)
                    .keyboardType(keyboardType)
                    .padding(10)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.poolBlue.opacity(0.24), lineWidth: 1)
                    )
                    .foregroundColor(Color.basicFontText)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboardType)
                    .padding(10)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.poolBlue.opacity(0.24), lineWidth: 1)
                    )
                    .foregroundColor(Color.basicFontText)
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
                .foregroundStyle(Color.primary.opacity(0.72))

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
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.poolBlue.opacity(0.24), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private extension View {
    func addBodyCard() -> some View {
        self
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
    }
}
