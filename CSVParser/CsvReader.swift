//
//  csvReader.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 10.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation

/**
 Really basic csv parser, thats loads the whole file into memory, splits it into substrings and filters the content based on the passed search string
 */
public class CsvReader {
    
    public static let shared = CsvReader()
    
    private init() {
        
    }
    
    public func getStationInfo(withContent content: String) -> Array<(ibnr: String,stationName: String)>? {
        
        do {
            let path = Bundle(for: type(of: self)).path(forResource: "D_Bahnhof_2020_alle", ofType: "CSV")!
            let data = try String(contentsOfFile: path, encoding: .utf8)
            return data
                .components(separatedBy: .newlines)
                .filter { (line) -> Bool in
                    line.lowercased().contains(content.lowercased())
            }.map { (csvRow) -> Array<Substring> in
                csvRow.split(separator: ";")
            }.map { (entries) -> (String,String) in
                (ibnr: String(entries[0]), stationName:  String(entries[3]))
            }
           
        } catch {
            // Catch errors from trying to load files
            Log.error(error)
            return nil
        }
    }
    
    public func getAll() -> Array<(ibnr: String,stationName: String)>? {
        
        do {
            let path = Bundle(for: type(of: self)).path(forResource: "D_Bahnhof_2020_alle", ofType: "CSV")!
            let data = try String(contentsOfFile: path, encoding: .utf8)
            return data
                .components(separatedBy: .newlines)
                .map { (csvRow) -> Array<Substring> in
                    csvRow.split(separator: ";")
            }
            .filter({ $0.count > 0})
            .map { (entries) -> (String,String) in
                (ibnr: String(entries[0]), stationName:  String(entries[3]))
            }
            
        } catch {
            // Catch errors from trying to load files
            Log.error(error)
            return nil
        }
    }
}
