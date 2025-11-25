import Foundation
import PDFKit
import SwiftUI

class ExportService {
    static func createPDF(from products: [Product]) -> URL? {
        let format = UIGraphicsPDFRendererFormat()
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            let titleAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)]
            let title = "Expiration Inventory - \(Date().formattedString())"
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            var yPosition: CGFloat = 100
            let bodyAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]
            
            for product in products {
                if yPosition > pageHeight - 50 {
                    context.beginPage()
                    yPosition = 50
                }
                
                let line = "\(product.name) - Expires: \(product.expirationDate.formattedString()) - \(product.category)"
                line.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
                yPosition += 20
            }
        }
        
        let fileName = "Inventory-\(Date().timeIntervalSince1970).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: url)
            return url
        } catch {
            print("Could not create PDF: \(error)")
            return nil
        }
    }
    
    static func createCSV(from products: [Product]) -> URL? {
        var csvString = "Name,Category,Expiration Date,Location,Quantity\n"
        
        for product in products {
            let row = "\"\(product.name)\",\"\(product.category)\",\"\(product.expirationDate.formattedString())\",\"\(product.storageLocation)\",\"\(product.quantity)\"\n"
            csvString.append(row)
        }
        
        let fileName = "Inventory-\(Date().timeIntervalSince1970).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Could not create CSV: \(error)")
            return nil
        }
    }
}

