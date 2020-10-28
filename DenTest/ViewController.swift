//
//  ViewController.swift
//  DenTest
//
//  Created by Sohil Bhatia on 10/25/20.
//  Copyright © 2020 Sohil Bhatia. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO

class ViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var photoView: UIImageView!
    
    @IBOutlet weak var analysisText: UILabel!
    @IBAction func uploadPhoto(_ sender: Any) {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = (self as UIImagePickerControllerDelegate & UINavigationControllerDelegate)
        present(vc, animated: true)
    }
    lazy var detectionRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: DenTestML_2().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self!.processDetections(for: request, error: error)
            })
            request.imageCropAndScaleOption = .scaleFit
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    private func updateDetections(for image: UIImage) {

        let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation!)
            do {
                try handler.perform([self.detectionRequest])
            } catch {
                print("Failed to perform detection.\n\(error.localizedDescription)")
            }
        }
    }
    
    private func processDetections(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                print("Unable to detect anything.\n\(error!.localizedDescription)")
                return
            }
        
            let detections = results as! [VNRecognizedObjectObservation]
            self.drawDetectionsOnPreview(detections: detections)
        }
    }
    func drawDetectionsOnPreview(detections: [VNRecognizedObjectObservation]) {
            guard let image = self.photoView.image else {
                print("This started")
                return
            }
            
            let imageSize = image.size
            let scale: CGFloat = 0
            UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)

            image.draw(at: CGPoint.zero)

            for detection in detections {
                
                analysisText.text = (detection.labels.map({"\($0.identifier) confidence: \($0.confidence)"}).joined(separator: "\n"))
               
                
    //            The coordinates are normalized to the dimensions of the processed image, with the origin at the image's lower-left corner.
                let boundingBox = detection.boundingBox
                let rectangle = CGRect(x: boundingBox.minX*image.size.width, y: (1-boundingBox.minY-boundingBox.height)*image.size.height, width: boundingBox.width*image.size.width, height: boundingBox.height*image.size.height)
                UIColor(red: 0, green: 1, blue: 0, alpha: 0.4).setFill()
                UIRectFillUsingBlendMode(rectangle, CGBlendMode.normal)
            }
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        self.photoView.image = newImage
        }
    }

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else {
            return
        }

        self.photoView?.image = image
        updateDetections(for: image)
    }
}

