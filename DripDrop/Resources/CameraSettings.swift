//
//  CameraSettings.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/18/24.
//

import SwiftUI
import UIKit
import PhotosUI
struct accessCameraView: UIViewControllerRepresentable {
    
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var isPresented
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(picker: self)
    }
}

// Coordinator will help to preview the selected image in the View.
class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var picker: accessCameraView
    
    init(picker: accessCameraView) {
        self.picker = picker
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        self.picker.selectedImage = selectedImage
        self.picker.isPresented.wrappedValue.dismiss()
    }
}

struct TesterStripCameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var onImageCaptured: (() -> Void)? = nil
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        imagePicker.showsCameraControls = false
        imagePicker.cameraCaptureMode = .photo
        imagePicker.delegate = context.coordinator
        if UIImagePickerController.isFlashAvailable(for: imagePicker.cameraDevice) {
            imagePicker.cameraFlashMode = .auto
        }

        let overlay = TesterStripCameraOverlayView(frame: UIScreen.main.bounds)
        let coordinator = context.coordinator
        overlay.onCapture = { [weak imagePicker] in
            imagePicker?.takePicture()
        }
        overlay.onCancel = {
            coordinator.cancel()
        }
        overlay.onUsePhoto = { image in
            coordinator.usePhoto(image)
        }
        imagePicker.cameraOverlayView = overlay
        applyFullScreenCameraPreview(to: imagePicker)

        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        applyFullScreenCameraPreview(to: uiViewController)

        if let overlay = uiViewController.cameraOverlayView as? TesterStripCameraOverlayView {
            overlay.frame = uiViewController.view.bounds
            overlay.setNeedsDisplay()
        }
    }

    func makeCoordinator() -> TesterStripCameraCoordinator {
        TesterStripCameraCoordinator(picker: self)
    }

    private func applyFullScreenCameraPreview(to imagePicker: UIImagePickerController) {
        let bounds = imagePicker.view.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        let cameraAspectRatio: CGFloat = 4.0 / 3.0
        let screenAspectRatio = bounds.height / bounds.width
        let scale = max(1, screenAspectRatio / cameraAspectRatio)
        imagePicker.cameraViewTransform = CGAffineTransform(scaleX: scale, y: scale)
    }
}

final class TesterStripCameraCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var picker: TesterStripCameraView

    init(picker: TesterStripCameraView) {
        self.picker = picker
    }

    func imagePickerController(_ imagePicker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else {
            self.picker.presentationMode.wrappedValue.dismiss()
            return
        }

        if let overlay = imagePicker.cameraOverlayView as? TesterStripCameraOverlayView {
            overlay.showPreview(image: selectedImage)
        } else {
            usePhoto(selectedImage)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.picker.presentationMode.wrappedValue.dismiss()
    }

    func cancel() {
        picker.presentationMode.wrappedValue.dismiss()
    }

    func usePhoto(_ image: UIImage) {
        picker.selectedImage = image
        picker.onImageCaptured?()
        picker.presentationMode.wrappedValue.dismiss()
    }
}

private enum TesterStripGuideMetrics {
    static let padCenterRatios: [CGFloat] = [0.17, 0.28, 0.39, 0.50, 0.61, 0.72]

    static func stripGuideRect(in bounds: CGRect) -> CGRect {
        guard bounds.width > 0, bounds.height > 0 else { return .zero }

        let guideWidth = min(max(bounds.width * 0.15, 48), 72)
        let topReserve = max(bounds.height * 0.075, 56)
        let bottomReserve = max(bounds.height * 0.20, 160)
        let availableHeight = max(bounds.height - topReserve - bottomReserve, 1)
        let guideHeight = min(max(bounds.height * 0.72, 500), availableHeight)
        let yOffset = max((availableHeight - guideHeight) * 0.08, 0)

        return CGRect(
            x: bounds.midX - guideWidth / 2,
            y: topReserve + yOffset,
            width: guideWidth,
            height: guideHeight
        )
    }
}

private final class TesterStripCameraOverlayView: UIView {
    var onCapture: (() -> Void)?
    var onCancel: (() -> Void)?
    var onUsePhoto: ((UIImage) -> Void)?

    private let captureButton = UIButton(type: .custom)
    private let cancelButton = UIButton(type: .system)
    private let previewImageView = UIImageView()
    private let retakeButton = UIButton(type: .system)
    private let usePhotoButton = UIButton(type: .system)
    private var previewImage: UIImage?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutControls()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard !bounds.isEmpty else { return }
        guard previewImage == nil else { return }

        let guideRect = TesterStripGuideMetrics.stripGuideRect(in: bounds)
        drawDimmedBackground(cutoutRect: guideRect)
        drawStripGuide(in: guideRect)
        drawPadMarkers(in: guideRect)
    }

    private func configure() {
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = true

        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.backgroundColor = .black
        previewImageView.isHidden = true
        addSubview(previewImageView)

        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 37
        captureButton.layer.borderColor = UIColor.white.withAlphaComponent(0.34).cgColor
        captureButton.layer.borderWidth = 6
        captureButton.addTarget(self, action: #selector(captureTapped), for: .touchUpInside)
        captureButton.accessibilityLabel = "Take tester strip photo"
        addSubview(captureButton)

        let cancelImage = UIImage(systemName: "xmark")
        cancelButton.setImage(cancelImage, for: .normal)
        cancelButton.tintColor = .white
        cancelButton.backgroundColor = UIColor.black.withAlphaComponent(0.58)
        cancelButton.layer.cornerRadius = 28
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.accessibilityLabel = "Cancel tester strip photo"
        addSubview(cancelButton)

        configureReviewButton(retakeButton, title: "Retake", foregroundColor: .white, backgroundColor: UIColor.black.withAlphaComponent(0.58))
        retakeButton.addTarget(self, action: #selector(retakeTapped), for: .touchUpInside)
        retakeButton.accessibilityLabel = "Retake tester strip photo"
        retakeButton.isHidden = true
        addSubview(retakeButton)

        configureReviewButton(usePhotoButton, title: "Use Photo", foregroundColor: .black, backgroundColor: .white)
        usePhotoButton.addTarget(self, action: #selector(usePhotoTapped), for: .touchUpInside)
        usePhotoButton.accessibilityLabel = "Use tester strip photo"
        usePhotoButton.isHidden = true
        addSubview(usePhotoButton)
    }

    private func layoutControls() {
        previewImageView.frame = bounds

        let buttonBottomPadding = safeAreaInsets.bottom + 26
        let captureSize: CGFloat = 74
        captureButton.frame = CGRect(
            x: bounds.midX - captureSize / 2,
            y: bounds.maxY - buttonBottomPadding - captureSize,
            width: captureSize,
            height: captureSize
        )
        captureButton.layer.cornerRadius = captureSize / 2

        let cancelSize: CGFloat = 56
        cancelButton.frame = CGRect(
            x: max(bounds.minX + 28, safeAreaInsets.left + 18),
            y: captureButton.frame.midY - cancelSize / 2,
            width: cancelSize,
            height: cancelSize
        )
        cancelButton.layer.cornerRadius = cancelSize / 2

        let reviewButtonHeight: CGFloat = 48
        let reviewButtonSpacing: CGFloat = 14
        let sideInset: CGFloat = max(safeAreaInsets.left, safeAreaInsets.right) + 24
        let availableWidth = bounds.width - (sideInset * 2) - reviewButtonSpacing
        let reviewButtonWidth = min(max(availableWidth / 2, 124), 170)
        let reviewButtonsTotalWidth = (reviewButtonWidth * 2) + reviewButtonSpacing
        let reviewButtonY = bounds.maxY - safeAreaInsets.bottom - 24 - reviewButtonHeight

        retakeButton.frame = CGRect(
            x: bounds.midX - reviewButtonsTotalWidth / 2,
            y: reviewButtonY,
            width: reviewButtonWidth,
            height: reviewButtonHeight
        )
        retakeButton.layer.cornerRadius = reviewButtonHeight / 2

        usePhotoButton.frame = CGRect(
            x: retakeButton.frame.maxX + reviewButtonSpacing,
            y: reviewButtonY,
            width: reviewButtonWidth,
            height: reviewButtonHeight
        )
        usePhotoButton.layer.cornerRadius = reviewButtonHeight / 2
    }

    private func configureReviewButton(
        _ button: UIButton,
        title: String,
        foregroundColor: UIColor,
        backgroundColor: UIColor
    ) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(foregroundColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = backgroundColor
        button.layer.masksToBounds = true
    }

    func showPreview(image: UIImage) {
        previewImage = image
        previewImageView.image = image
        previewImageView.isHidden = false
        captureButton.isHidden = true
        cancelButton.isHidden = true
        retakeButton.isHidden = false
        usePhotoButton.isHidden = false
        setNeedsDisplay()
    }

    private func hidePreview() {
        previewImage = nil
        previewImageView.image = nil
        previewImageView.isHidden = true
        captureButton.isHidden = false
        cancelButton.isHidden = false
        retakeButton.isHidden = true
        usePhotoButton.isHidden = true
        setNeedsDisplay()
    }

    @objc private func captureTapped() {
        onCapture?()
    }

    @objc private func cancelTapped() {
        onCancel?()
    }

    @objc private func retakeTapped() {
        hidePreview()
    }

    @objc private func usePhotoTapped() {
        guard let previewImage else { return }
        onUsePhoto?(previewImage)
    }

    private func drawDimmedBackground(cutoutRect: CGRect) {
        let dimPath = UIBezierPath(rect: bounds)
        dimPath.append(UIBezierPath(roundedRect: cutoutRect, cornerRadius: 16))
        dimPath.usesEvenOddFillRule = true

        UIColor.black.withAlphaComponent(0.34).setFill()
        dimPath.fill()
    }

    private func drawStripGuide(in guideRect: CGRect) {
        let guidePath = UIBezierPath(roundedRect: guideRect, cornerRadius: 16)
        guidePath.lineWidth = 3

        UIColor.white.withAlphaComponent(0.96).setStroke()
        guidePath.stroke()

        let dashPath = UIBezierPath(roundedRect: guideRect.insetBy(dx: 7, dy: 7), cornerRadius: 11)
        dashPath.setLineDash([8, 6], count: 2, phase: 0)
        dashPath.lineWidth = 1.5

        UIColor.white.withAlphaComponent(0.72).setStroke()
        dashPath.stroke()
    }

    private func drawPadMarkers(in guideRect: CGRect) {
        let markerWidth = guideRect.width * 0.66
        let markerHeight = markerWidth * 0.62

        for ratio in TesterStripGuideMetrics.padCenterRatios {
            let markerRect = CGRect(
                x: guideRect.midX - markerWidth / 2,
                y: guideRect.minY + (guideRect.height * ratio) - (markerHeight / 2),
                width: markerWidth,
                height: markerHeight
            )

            let markerPath = UIBezierPath(roundedRect: markerRect, cornerRadius: 4)
            UIColor.white.withAlphaComponent(0.18).setFill()
            markerPath.fill()

            UIColor.white.withAlphaComponent(0.58).setStroke()
            markerPath.lineWidth = 1
            markerPath.stroke()
        }
    }
}

struct TesterStripImageSample {
    let observedPads: [[String: Any]]
    let calibration: [String: Any]
}

enum TesterStripImageSampler {
    private struct PadDetection {
        let center: CGPoint
        let score: CGFloat
    }

    private struct PadBand {
        let centerY: CGFloat
        let score: CGFloat
    }

    private struct StripGeometry {
        let centerX: CGFloat
        let topY: CGFloat
        let height: CGFloat
        let confidence: CGFloat

        func center(for ratio: CGFloat) -> CGPoint {
            CGPoint(x: centerX, y: topY + (height * ratio))
        }

        func searchRect(in bounds: CGRect, guideWidth: CGFloat) -> CGRect {
            CGRect(
                x: centerX - guideWidth * 0.62,
                y: topY,
                width: guideWidth * 1.24,
                height: height
            )
            .insetBy(dx: -guideWidth * 0.18, dy: -height * 0.035)
            .intersection(bounds)
        }
    }

    private static let minimumPadDetectionScore: CGFloat = 0.075

    static func sample(from image: UIImage) -> TesterStripImageSample {
        let padIds = [
            "total_hardness",
            "total_chlorine_bromine",
            "free_chlorine",
            "ph",
            "total_alkalinity",
            "cyanuric_acid",
        ]

        guard let pixelBuffer = PixelBuffer(image: image) else {
            return TesterStripImageSample(observedPads: [], calibration: [:])
        }

        let imageBounds = CGRect(
            x: 0,
            y: 0,
            width: CGFloat(pixelBuffer.width),
            height: CGFloat(pixelBuffer.height)
        )
        let guideRect = TesterStripGuideMetrics.stripGuideRect(in: imageBounds)
        let sampleWidth = max(CGFloat(pixelBuffer.width) * 0.045, 18)
        let sampleHeight = max(CGFloat(pixelBuffer.height) * 0.018, 18)
        let padSampleSize = CGSize(
            width: max(min(sampleWidth, guideRect.width * 0.48), 14),
            height: max(min(sampleHeight, guideRect.height * 0.022), 12)
        )

        let roughDetections = TesterStripGuideMetrics.padCenterRatios.compactMap { ratio in
            detectPadCenter(
                in: pixelBuffer,
                expectedCenter: CGPoint(
                    x: guideRect.midX,
                    y: guideRect.minY + (guideRect.height * ratio)
                ),
                guideRect: guideRect,
                sampleSize: padSampleSize
            )
        }
        let stripCenterX = centeredStripX(
            from: roughDetections,
            fallback: guideRect.midX
        )
        let detectedCenterX = detectStripCenterX(
            in: pixelBuffer,
            guideRect: guideRect,
            fallbackCenterX: stripCenterX,
            sampleSize: padSampleSize
        )
        let detectedBands = detectPadBands(
            in: pixelBuffer,
            guideRect: guideRect,
            centerX: detectedCenterX,
            sampleSize: padSampleSize
        )
        let stripGeometry = fitStripGeometry(
            from: detectedBands,
            guideRect: guideRect,
            centerX: detectedCenterX
        )
        let geometryScale = max(0.72, min(1.35, stripGeometry.height / max(guideRect.height, 1)))
        let alignedPadSampleSize = CGSize(
            width: max(min(padSampleSize.width * geometryScale, guideRect.width * 0.58), 12),
            height: max(min(padSampleSize.height * geometryScale, stripGeometry.height * 0.026), 10)
        )

        let padTargets = padSampleTargets(
            in: pixelBuffer,
            ratios: TesterStripGuideMetrics.padCenterRatios,
            geometry: stripGeometry,
            bands: detectedBands,
            guideRect: guideRect,
            imageBounds: imageBounds,
            sampleSize: alignedPadSampleSize
        )

        let observedPads: [[String: Any]] = padIds.enumerated().compactMap { index, padId -> [String: Any]? in
            let target = padTargets[index]
            let center = target.center
            let color = pixelBuffer.averageHexColor(
                centeredAt: center,
                sampleSize: alignedPadSampleSize
            )

            guard let color else { return nil }
            return [
                "padId": padId,
                "hex": color,
                "sampleCenterXRatio": center.x / CGFloat(pixelBuffer.width),
                "sampleCenterYRatio": center.y / CGFloat(pixelBuffer.height),
                "sampleConfidence": target.score,
                "stripGeometryConfidence": stripGeometry.confidence,
            ]
        }

        return TesterStripImageSample(
            observedPads: observedPads,
            calibration: stripWhiteCalibration(
                from: pixelBuffer,
                geometry: stripGeometry,
                guideWidth: guideRect.width,
                sampleSize: CGSize(width: sampleWidth * 0.66 * geometryScale, height: sampleHeight * geometryScale)
            )
        )
    }

    static func observedPads(from image: UIImage) -> [[String: Any]] {
        sample(from: image).observedPads
    }

    private static func stripWhiteCalibration(
        from pixelBuffer: PixelBuffer,
        geometry: StripGeometry,
        guideWidth: CGFloat,
        sampleSize: CGSize
    ) -> [String: Any] {
        let whiteCandidateRatios: [CGFloat] = [0.105, 0.225, 0.335, 0.445, 0.555, 0.665, 0.82, 0.90]
        let candidates = whiteCandidateRatios.compactMap { ratio -> (hex: String, score: CGFloat)? in
            let center = geometry.center(for: ratio)

            guard let hex = pixelBuffer.averageHexColor(centeredAt: center, sampleSize: sampleSize),
                  let score = whiteCandidateScore(for: hex)
            else {
                return nil
            }

            return (hex, score)
        }

        guard let bestWhite = candidates.max(by: { $0.score < $1.score }) else {
            return [:]
        }

        return [
            "observedWhiteHex": bestWhite.hex,
            "referenceWhiteHex": "#FFFFFF",
            "calibrationSource": "stripBacking",
        ]
    }

    private static func whiteCandidateScore(for hex: String) -> CGFloat? {
        guard let components = rgbComponents(from: hex) else { return nil }
        let maxChannel = max(components.red, components.green, components.blue)
        let minChannel = min(components.red, components.green, components.blue)
        let brightness = ((components.red + components.green + components.blue) / 3) / 255
        let saturation = maxChannel == 0 ? 0 : (maxChannel - minChannel) / maxChannel

        guard brightness > 0.38, saturation < 0.35 else { return nil }

        return brightness - (saturation * 0.45)
    }

    private static func centeredStripX(from detections: [PadDetection], fallback: CGFloat) -> CGFloat {
        let detectedXs = detections
            .filter { $0.score >= minimumPadDetectionScore }
            .map(\.center.x)
            .sorted()

        guard !detectedXs.isEmpty else { return fallback }

        let middleIndex = detectedXs.count / 2
        if detectedXs.count.isMultiple(of: 2) {
            return (detectedXs[middleIndex - 1] + detectedXs[middleIndex]) / 2
        }

        return detectedXs[middleIndex]
    }

    private static func detectStripCenterX(
        in pixelBuffer: PixelBuffer,
        guideRect: CGRect,
        fallbackCenterX: CGFloat,
        sampleSize: CGSize
    ) -> CGFloat {
        let searchRect = clamped(
            guideRect.insetBy(dx: -guideRect.width * 1.45, dy: -guideRect.height * 0.16),
            to: CGRect(x: 0, y: 0, width: pixelBuffer.width, height: pixelBuffer.height)
        )
        let xStep = max(sampleSize.width * 0.34, 4)
        let yStep = max(sampleSize.height * 1.12, 8)
        var scoredColumns: [(x: CGFloat, score: CGFloat)] = []

        for x in stride(from: searchRect.minX, through: searchRect.maxX, by: xStep) {
            var columnScore: CGFloat = 0

            for y in stride(from: searchRect.minY, through: searchRect.maxY, by: yStep) {
                guard let color = pixelBuffer.averageColor(
                    centeredAt: CGPoint(x: x, y: y),
                    sampleSize: CGSize(width: max(sampleSize.width * 0.58, 8), height: max(sampleSize.height * 0.58, 8))
                ) else {
                    continue
                }

                let score = padColorScore(for: color)
                if score >= minimumPadDetectionScore {
                    columnScore += score
                }
            }

            let guideDistancePenalty = abs(x - guideRect.midX) / max(guideRect.width * 3.5, 1)
            let weightedScore = columnScore - guideDistancePenalty
            if weightedScore > minimumPadDetectionScore {
                scoredColumns.append((x, weightedScore))
            }
        }

        guard let bestScore = scoredColumns.map(\.score).max() else {
            return fallbackCenterX
        }

        let strongColumns = scoredColumns.filter { $0.score >= bestScore * 0.78 }
        let totalWeight = strongColumns.reduce(CGFloat(0)) { $0 + max($1.score, 0.001) }
        guard totalWeight > 0 else { return fallbackCenterX }

        return strongColumns.reduce(CGFloat(0)) { partial, column in
            partial + (column.x * max(column.score, 0.001))
        } / totalWeight
    }

    private static func detectPadBands(
        in pixelBuffer: PixelBuffer,
        guideRect: CGRect,
        centerX: CGFloat,
        sampleSize: CGSize
    ) -> [PadBand] {
        let searchRect = clamped(
            guideRect.insetBy(dx: -guideRect.width * 0.12, dy: -guideRect.height * 0.24),
            to: CGRect(x: 0, y: 0, width: pixelBuffer.width, height: pixelBuffer.height)
        )
        let xOffsets: [CGFloat] = [
            -sampleSize.width * 0.86,
            -sampleSize.width * 0.43,
            0,
            sampleSize.width * 0.43,
            sampleSize.width * 0.86,
        ]
        let yStep = max(sampleSize.height * 0.42, 4)
        var activeBandSamples: [(y: CGFloat, score: CGFloat)] = []
        var bands: [PadBand] = []

        func finishBand() {
            guard !activeBandSamples.isEmpty else { return }

            let totalScore = activeBandSamples.reduce(CGFloat(0)) { $0 + max($1.score, 0.001) }
            guard totalScore > 0 else {
                activeBandSamples.removeAll()
                return
            }

            let weightedY = activeBandSamples.reduce(CGFloat(0)) { partial, sample in
                partial + (sample.y * max(sample.score, 0.001))
            } / totalScore
            let bestScore = activeBandSamples.map(\.score).max() ?? 0

            bands.append(PadBand(centerY: weightedY, score: bestScore))
            activeBandSamples.removeAll()
        }

        for y in stride(from: searchRect.minY, through: searchRect.maxY, by: yStep) {
            let rowScores = xOffsets.compactMap { offset -> CGFloat? in
                let x = min(max(centerX + offset, searchRect.minX), searchRect.maxX)
                guard let color = pixelBuffer.averageColor(
                    centeredAt: CGPoint(x: x, y: y),
                    sampleSize: CGSize(width: max(sampleSize.width * 0.5, 8), height: max(sampleSize.height * 0.5, 8))
                ) else {
                    return nil
                }

                return padColorScore(for: color)
            }
            .filter { $0 >= minimumPadDetectionScore * 0.72 }
            .sorted(by: >)
            let rowScore: CGFloat

            if rowScores.count >= 2 {
                rowScore = (rowScores[0] * 0.62) + (rowScores[1] * 0.38)
            } else {
                rowScore = rowScores.first ?? 0
            }

            if rowScore >= minimumPadDetectionScore {
                activeBandSamples.append((y, rowScore))
            } else {
                finishBand()
            }
        }
        finishBand()

        return bands
            .filter { $0.score >= minimumPadDetectionScore }
            .sorted { $0.centerY < $1.centerY }
    }

    private static func fitStripGeometry(
        from bands: [PadBand],
        guideRect: CGRect,
        centerX: CGFloat
    ) -> StripGeometry {
        let ratios = TesterStripGuideMetrics.padCenterRatios
        guard bands.count >= 2 else {
            return StripGeometry(centerX: centerX, topY: guideRect.minY, height: guideRect.height, confidence: 0)
        }

        var bestGeometry: StripGeometry?
        var bestScore: CGFloat = -.greatestFiniteMagnitude
        let minHeight = guideRect.height * 0.62
        let maxHeight = guideRect.height * 1.48

        for leftBandIndex in 0..<(bands.count - 1) {
            for rightBandIndex in (leftBandIndex + 1)..<bands.count {
                for leftRatioIndex in 0..<(ratios.count - 1) {
                    for rightRatioIndex in (leftRatioIndex + 1)..<ratios.count {
                        let ratioDelta = ratios[rightRatioIndex] - ratios[leftRatioIndex]
                        guard ratioDelta > 0 else { continue }

                        let height = (bands[rightBandIndex].centerY - bands[leftBandIndex].centerY) / ratioDelta
                        guard height >= minHeight, height <= maxHeight else { continue }

                        let topY = bands[leftBandIndex].centerY - (height * ratios[leftRatioIndex])
                        let geometry = StripGeometry(centerX: centerX, topY: topY, height: height, confidence: 0)
                        let score = geometryScore(geometry, bands: bands, guideRect: guideRect)

                        if score > bestScore {
                            bestScore = score
                            let confidence = max(0, min(1, score / 62))
                            bestGeometry = StripGeometry(centerX: centerX, topY: topY, height: height, confidence: confidence)
                        }
                    }
                }
            }
        }

        guard let bestGeometry, bestScore > 8 else {
            return StripGeometry(centerX: centerX, topY: guideRect.minY, height: guideRect.height, confidence: 0)
        }

        return bestGeometry
    }

    private static func geometryScore(_ geometry: StripGeometry, bands: [PadBand], guideRect: CGRect) -> CGFloat {
        let ratios = TesterStripGuideMetrics.padCenterRatios
        let rowTolerance = max(geometry.height * 0.036, 12)
        var matchedBandIndexes = Set<Int>()
        var score: CGFloat = 0

        for ratio in ratios {
            let expectedY = geometry.topY + (geometry.height * ratio)
            let match = bands.enumerated()
                .map { index, band in
                    (index: index, band: band, distance: abs(band.centerY - expectedY))
                }
                .filter { $0.distance <= rowTolerance }
                .min { $0.distance < $1.distance }

            if let match {
                matchedBandIndexes.insert(match.index)
                score += 9 + (match.band.score * 6) - ((match.distance / rowTolerance) * 3)
            }
        }

        score += CGFloat(matchedBandIndexes.count) * 3
        score -= abs(geometry.height - guideRect.height) / max(guideRect.height, 1) * 5
        score -= abs(geometry.topY - guideRect.minY) / max(guideRect.height, 1) * 3

        return score
    }

    private static func padSampleTargets(
        in pixelBuffer: PixelBuffer,
        ratios: [CGFloat],
        geometry: StripGeometry,
        bands: [PadBand],
        guideRect: CGRect,
        imageBounds: CGRect,
        sampleSize: CGSize
    ) -> [PadDetection] {
        var availableBands = bands
            .filter { $0.score >= minimumPadDetectionScore }
            .sorted { $0.centerY < $1.centerY }
        let searchRect = geometry.searchRect(in: imageBounds, guideWidth: guideRect.width)
        let bandTolerance = max(
            min(geometry.height * 0.052, geometry.height * 0.11 * 0.48),
            sampleSize.height * 1.8
        )

        return ratios.map { ratio in
            let expectedCenter = geometry.center(for: ratio)
            let matchedBandIndex = availableBands
                .enumerated()
                .map { index, band in
                    (index: index, band: band, distance: abs(band.centerY - expectedCenter.y))
                }
                .filter { $0.distance <= bandTolerance }
                .min { $0.distance < $1.distance }?.index
            let matchedBand = matchedBandIndex.map { availableBands.remove(at: $0) }
            let rowAnchoredCenter = CGPoint(
                x: geometry.centerX,
                y: matchedBand?.centerY ?? expectedCenter.y
            )
            let detection = detectPadCenter(
                in: pixelBuffer,
                expectedCenter: rowAnchoredCenter,
                guideRect: searchRect,
                sampleSize: sampleSize
            )

            if let detection,
               abs(detection.center.y - rowAnchoredCenter.y) <= bandTolerance {
                return PadDetection(
                    center: detection.center,
                    score: max(detection.score, matchedBand?.score ?? 0)
                )
            }

            if let matchedBand {
                return PadDetection(
                    center: CGPoint(x: geometry.centerX, y: matchedBand.centerY),
                    score: matchedBand.score
                )
            }

            return PadDetection(center: expectedCenter, score: 0)
        }
    }

    private static func detectPadCenter(
        in pixelBuffer: PixelBuffer,
        expectedCenter: CGPoint,
        guideRect: CGRect,
        sampleSize: CGSize
    ) -> PadDetection? {
        let rowSpacing = guideRect.height * 0.11
        let halfSearchWidth = max(guideRect.width * 0.82, sampleSize.width * 1.8)
        let halfSearchHeight = min(
            max(rowSpacing * 0.42, sampleSize.height * 1.8),
            rowSpacing * 0.48
        )
        let scoreSampleSize = CGSize(
            width: max(sampleSize.width * 0.52, 8),
            height: max(sampleSize.height * 0.52, 8)
        )
        let step = max(min(scoreSampleSize.width, scoreSampleSize.height) * 0.55, 4)
        let minX = max(expectedCenter.x - halfSearchWidth, 0)
        let maxX = min(expectedCenter.x + halfSearchWidth, CGFloat(pixelBuffer.width - 1))
        let minY = max(expectedCenter.y - halfSearchHeight, guideRect.minY)
        let maxY = min(expectedCenter.y + halfSearchHeight, guideRect.maxY)

        guard minX <= maxX, minY <= maxY else { return nil }

        var candidates: [(center: CGPoint, score: CGFloat)] = []
        var bestScore: CGFloat = 0

        for y in stride(from: minY, through: maxY, by: step) {
            for x in stride(from: minX, through: maxX, by: step) {
                let center = CGPoint(x: x, y: y)
                guard let color = pixelBuffer.averageColor(centeredAt: center, sampleSize: scoreSampleSize) else {
                    continue
                }

                let score = padColorScore(for: color)
                let xPenalty = abs(x - expectedCenter.x) / max(halfSearchWidth, 1) * 0.035
                let yPenalty = abs(y - expectedCenter.y) / max(halfSearchHeight, 1) * 0.045
                let weightedScore = score - xPenalty - yPenalty

                if weightedScore >= minimumPadDetectionScore {
                    candidates.append((center, weightedScore))
                    bestScore = max(bestScore, weightedScore)
                }
            }
        }

        guard !candidates.isEmpty else { return nil }

        let strongScoreThreshold = max(minimumPadDetectionScore, bestScore * 0.72)
        let strongCandidates = candidates.filter { $0.score >= strongScoreThreshold }
        var weightedX: CGFloat = 0
        var weightedY: CGFloat = 0
        var totalWeight: CGFloat = 0

        strongCandidates.forEach { candidate in
            let weight = max(candidate.score - minimumPadDetectionScore, 0.001)
            weightedX += candidate.center.x * weight
            weightedY += candidate.center.y * weight
            totalWeight += weight
        }

        guard totalWeight > 0 else { return nil }

        return PadDetection(
            center: CGPoint(x: weightedX / totalWeight, y: weightedY / totalWeight),
            score: bestScore
        )
    }

    private static func padColorScore(for color: PixelColor) -> CGFloat {
        let maxChannel = max(color.red, color.green, color.blue)
        let minChannel = min(color.red, color.green, color.blue)
        let saturation = maxChannel <= 0 ? 0 : (maxChannel - minChannel) / maxChannel
        let chroma = (maxChannel - minChannel) / 255
        let distanceFromWhite = sqrt(
            pow((255 - color.red) / 255, 2) +
            pow((255 - color.green) / 255, 2) +
            pow((255 - color.blue) / 255, 2)
        ) / sqrt(3)
        let brightNeutralPenalty = max(color.brightness - 0.92, 0) * max(1 - saturation, 0)
        let darkBackgroundPenalty = max(0.32 - color.brightness, 0) * 0.55

        return (saturation * 0.70) +
            (chroma * 0.25) +
            (distanceFromWhite * 0.15) -
            (brightNeutralPenalty * 0.35) -
            darkBackgroundPenalty
    }

    private static func clamped(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        rect.intersection(bounds)
    }

    private static func rgbComponents(from hex: String) -> (red: CGFloat, green: CGFloat, blue: CGFloat)? {
        let trimmedHex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard trimmedHex.count == 6,
              let value = UInt32(trimmedHex, radix: 16)
        else {
            return nil
        }

        return (
            red: CGFloat((value >> 16) & 0xFF),
            green: CGFloat((value >> 8) & 0xFF),
            blue: CGFloat(value & 0xFF)
        )
    }
}

private struct PixelColor {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat

    var brightness: CGFloat {
        (red + green + blue) / (3 * 255)
    }

    var hex: String {
        String(
            format: "#%02X%02X%02X",
            Int(red.rounded()),
            Int(green.rounded()),
            Int(blue.rounded())
        )
    }
}

private struct PixelBuffer {
    let width: Int
    let height: Int
    private let bytesPerPixel = 4
    private let bytesPerRow: Int
    private let data: [UInt8]

    init?(image: UIImage) {
        let normalizedImage = image.normalizedForTesterStripSampling()
        guard let cgImage = normalizedImage.cgImage else { return nil }

        let maxWidth: CGFloat = 720
        let scale = min(1, maxWidth / CGFloat(cgImage.width))
        let bufferWidth = max(Int(CGFloat(cgImage.width) * scale), 1)
        let bufferHeight = max(Int(CGFloat(cgImage.height) * scale), 1)
        let bufferBytesPerRow = bufferWidth * 4

        var pixelData = [UInt8](repeating: 0, count: bufferHeight * bufferBytesPerRow)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        let didDraw = pixelData.withUnsafeMutableBytes { bufferPointer -> Bool in
            guard
                let baseAddress = bufferPointer.baseAddress,
                let context = CGContext(
                    data: baseAddress,
                    width: bufferWidth,
                    height: bufferHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: bufferBytesPerRow,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                )
            else {
                return false
            }

            context.interpolationQuality = .medium
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: bufferWidth, height: bufferHeight))
            return true
        }

        guard didDraw else { return nil }
        self.width = bufferWidth
        self.height = bufferHeight
        self.bytesPerRow = bufferBytesPerRow
        self.data = pixelData
    }

    func averageHexColor(centeredAt center: CGPoint, sampleSize: CGSize) -> String? {
        averageColor(centeredAt: center, sampleSize: sampleSize)?.hex
    }

    func averageColor(centeredAt center: CGPoint, sampleSize: CGSize) -> PixelColor? {
        let minX = max(Int(center.x - sampleSize.width / 2), 0)
        let maxX = min(Int(center.x + sampleSize.width / 2), width - 1)
        let minY = max(Int(center.y - sampleSize.height / 2), 0)
        let maxY = min(Int(center.y + sampleSize.height / 2), height - 1)

        guard minX <= maxX, minY <= maxY else { return nil }

        var red = 0
        var green = 0
        var blue = 0
        var count = 0

        for y in minY...maxY {
            for x in minX...maxX {
                let index = (y * bytesPerRow) + (x * bytesPerPixel)
                red += Int(data[index])
                green += Int(data[index + 1])
                blue += Int(data[index + 2])
                count += 1
            }
        }

        guard count > 0 else { return nil }
        return PixelColor(
            red: CGFloat(red) / CGFloat(count),
            green: CGFloat(green) / CGFloat(count),
            blue: CGFloat(blue) / CGFloat(count)
        )
    }
}

private extension UIImage {
    func normalizedForTesterStripSampling() -> UIImage {
        guard imageOrientation != .up else { return self }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? self
    }
}
