//
//  UIimageExtention.swift
//  OTFUtilities
//
//  Created by Arslan Raza on 05/05/2023.
//

import UIKit

extension Data {

    public func saveFileToDocument(data: Data, filename: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL)
        } catch {
            print("error saving file to documents:", error)
        }
    }
    
    public func retriveFile(fileName: String) -> Data? {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!;
        let fileURL = documentsUrl.appendingPathComponent(fileName)
        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {}
        return nil
    }
}

public func deleteFile(filename: String) {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let fileURL = documentsDirectory.appendingPathComponent(filename)
    do {
        try FileManager.default.removeItem(at: fileURL)
    }
    catch {
        print("Error")
    }
}

