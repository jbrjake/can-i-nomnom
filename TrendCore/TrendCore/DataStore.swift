//
//  DataStore.swift
//  TrendCore
//
//  Created by Jonathon Rubin on 8/28/15.
//  Copyright © 2015 Jonathon Rubin. All rights reserved.
//

import Foundation
import CoreData

public struct DataSample {
    var value :Double
    var trend :Double?
    var dateSampled :NSDate
    var dateImported :NSDate
    var source :TrendCoreImporterType
}
// Equatable
extension DataSample : Equatable {}
public func == (lhs: DataSample, rhs: DataSample) -> Bool {
    return  lhs.value == rhs.value &&
        lhs.dateSampled.isEqualToDate(rhs.dateSampled) &&
        lhs.source == rhs.source
}

private class ManagedSample: NSManagedObject {
    @NSManaged var value        :Double
    @NSManaged var dateSampled  :NSDate
    @NSManaged var dateImported :NSDate
    @NSManaged var source       :String
}

internal protocol DataStoreProtocol {
    func add(samples :[DataSample], completion: Completion)
    func remove(samples :[DataSample], completion: Completion)
    func fetch(fromDate :NSDate, toDate :NSDate, callback: FetchWeightsCallback)
}

internal class DataStore :DataStoreProtocol {
    
    // MARK: Private Core Data Stack
    // Using Marcus Zarra's strategy of keeping two mocs, with the store talking to a private
    // moc and the main thread moc being a child of it, instead of the way Apple sets it up
    // with one main moc that handles both the DB and the UI
    // http://martiancraft.com/blog/2015/03/core-data-stack/

    private var mom         :NSManagedObjectModel?          = nil
    private var store       :NSPersistentStoreCoordinator?  = nil
    private var mainMoc     :NSManagedObjectContext?        = nil
    private var privateMoc  :NSManagedObjectContext?        = nil

    init() {
        guard let modelURL = NSBundle.mainBundle().URLForResource("TrendCore", withExtension: "mom") 
        else {
            print("Couldn't build model URL")
            return
        }
        
        self.mom = NSManagedObjectModel(contentsOfURL: modelURL)
        self.store = NSPersistentStoreCoordinator(managedObjectModel: self.mom!)
        self.privateMoc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.privateMoc?.persistentStoreCoordinator = self.store
        self.mainMoc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.mainMoc?.parentContext = self.privateMoc
        
        
        let fileManager = NSFileManager.defaultManager()
        let docsURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last
        let storeURL = docsURL?.URLByAppendingPathComponent("TrendCore.sqlite")
        let options = 
        [
            NSMigratePersistentStoresAutomaticallyOption : true,
            NSInferMappingModelAutomaticallyOption : true,
            NSSQLitePragmasOption : ["journal_mode" : "delete"] 
        ]

        do {
            try self.store?.addPersistentStoreWithType(
                NSSQLiteStoreType, 
                configuration: nil, 
                URL: storeURL, 
                options: options)
        }
        catch { print("Error reading store \(error)") }

    }
    
    private func save() {
        guard
            let mainMoc     = self.mainMoc      where      mainMoc.hasChanges == true, 
            let privateMoc  = self.privateMoc   where   privateMoc.hasChanges == true 
        else { return }
        
        mainMoc.performBlockAndWait() {
            do { try mainMoc.save() }
            catch { print("Error saving main moc: \(error)") }
            
            privateMoc.performBlock() {
                do { try privateMoc.save() }
                catch { print("Error saving private moc: \(error)") }
            }
        }        
    }
    
// MARK: Public DataStore Protocol Implementation
    
    func add(samples :[DataSample], completion: Completion) {
        
    }
    
    func fetch(fromDate :NSDate, toDate :NSDate, callback: FetchWeightsCallback) {
        
    }
    
    func remove(samples :[DataSample], completion: Completion) {
        
    }
    
}