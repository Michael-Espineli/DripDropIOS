//
//  FileLogicManager.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/4/23.
//

import SwiftUI
import Contacts
import Combine
import Foundation
import ContactsUI
#if os(iOS)
import UIKit
struct ImagePicker: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()

        picker.delegate = context.coordinator
        return picker
    }


    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {

    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage

            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
    }
    
}

struct DocumentPicker: UIViewControllerRepresentable {
    
    @Binding var filePath: URL?
    
    func makeCoordinator() -> DocumentPicker.Coordinator {
        return DocumentPicker.Coordinator(parent1: self)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .open)
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true

        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: DocumentPicker.UIViewControllerType, context: UIViewControllerRepresentableContext<DocumentPicker>) {
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        
        var parent: DocumentPicker
        
        init(parent1: DocumentPicker){
            parent = parent1
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.filePath = urls[0]
            print(urls[0].absoluteString)
        }
    }
}


struct ContactPicker: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = EmbeddedContactPickerViewController
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var selectedContact: CNContact?
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    final class Coordinator: NSObject, EmbeddedContactPickerViewControllerDelegate {
    
        let parent: ContactPicker

        init(_ parent: ContactPicker) {
            self.parent = parent
        }
        
        func embeddedContactPickerViewController(_ viewController: EmbeddedContactPickerViewController, didSelect contact: CNContact) {
            parent.selectedContact = contact
            viewController.dismiss(animated: true, completion: nil)
            
        }

        func embeddedContactPickerViewControllerDidCancel(_ viewController: EmbeddedContactPickerViewController) {
            print("Cancelled")
        }
    }

    

    func makeUIViewController(context: UIViewControllerRepresentableContext<ContactPicker>) -> ContactPicker.UIViewControllerType {
        let result = ContactPicker.UIViewControllerType()
        result.delegate = context.coordinator
        return result
    }

    func updateUIViewController(_ uiViewController: ContactPicker.UIViewControllerType, context: UIViewControllerRepresentableContext<ContactPicker>) { }

}

protocol EmbeddedContactPickerViewControllerDelegate: class {
    func embeddedContactPickerViewControllerDidCancel(_ viewController: EmbeddedContactPickerViewController)
    func embeddedContactPickerViewController(_ viewController: EmbeddedContactPickerViewController, didSelect contact: CNContact)
}

class EmbeddedContactPickerViewController: UIViewController, CNContactPickerDelegate {
    weak var delegate: EmbeddedContactPickerViewControllerDelegate?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.open(animated: animated)
    }

    private func open(animated: Bool) {
        let viewController = CNContactPickerViewController()
        viewController.delegate = self
        self.present(viewController, animated: false)
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        self.dismiss(animated: false) {
            self.delegate?.embeddedContactPickerViewControllerDidCancel(self)
        }
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        self.dismiss(animated: false) {
            self.delegate?.embeddedContactPickerViewController(self, didSelect: contact)
        }
    }

}
#endif
