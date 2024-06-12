//
//  PdfDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/4/23.
//

import SwiftUI
#if os(iOS)
import PDFKit

struct PdfDetailView: View {
    var pdfUrl:URL
    var body: some View {
        // some content here
        PDFKitView(url: pdfUrl)
            .scaledToFill()
    }
}

// Add this:
struct PDFKitView: UIViewRepresentable {
    let url: URL // new variable to get the URL of the document

    func makeUIView(context: UIViewRepresentableContext<PDFKitView>) -> PDFView {
        // Creating a new PDFVIew and adding a document to it
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: self.url)//DEVELOPER THIS SHOULD NOT BE CALLED ON the MAIN THREAD
        return pdfView
        
    }
    
    func updateUIView(_ uiView: PDFView, context: UIViewRepresentableContext<PDFKitView>) {
        // TODO
    }
}
#endif
