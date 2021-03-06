//
//  DataStore.swift
//  TrendCore
//
//  Created by Jonathon Rubin on 8/28/15.
//  Copyright © 2015 Jonathon Rubin. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit

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

internal class ManagedSample: NSManagedObject {
    @NSManaged var sampledValue :NSNumber
    @NSManaged var dateSampled  :NSDate
    @NSManaged var dateImported :NSDate
    @NSManaged var source       :String
    
    private init (
        sample  :DataSample,
        entity  :NSEntityDescription,
        context :NSManagedObjectContext ) 
    {
        super.init (
            entity: entity, 
            insertIntoManagedObjectContext: context )
        self.sampledValue   = sample.value
        self.dateSampled    = sample.dateSampled
        self.dateImported   = sample.dateImported
        self.source         = sample.source.rawValue
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    private class func add (
        sample :DataSample, 
        context: NSManagedObjectContext ) 
    {
        guard
            let entity = NSEntityDescription.entityForName( 
                "ManagedSample", 
                inManagedObjectContext: context ) 
        else {
            print("Could not find build entity description")
            return
        }
        
        _ = ManagedSample.init(sample: sample, entity: entity, context: context)        
    }
}

internal protocol DataStoreProtocol {
    func add    ( samples :[DataSample] ) -> Promise< () >
    func remove ( samples :[DataSample] ) -> Promise< () >
    func fetch  ( fromDate :NSDate, toDate :NSDate ) -> Promise< [DataSample] >
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
        guard 
            let modelURL = NSBundle (
                forClass: TrendCoreController.self )
                .URLForResource (
                    "TrendCoreModel", 
                    withExtension: "momd" ) 
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
        let docsURL = fileManager.URLsForDirectory (
            .DocumentDirectory, 
            inDomains: .UserDomainMask )
            .last
        let storeURL = docsURL?.URLByAppendingPathComponent("TrendCore.sqlite")
        let options = 
        [
            NSMigratePersistentStoresAutomaticallyOption : true,
            NSInferMappingModelAutomaticallyOption : true,
            NSSQLitePragmasOption : ["journal_mode" : "delete"] 
        ]

        do {
            try self.store?.addPersistentStoreWithType (
                NSSQLiteStoreType, 
                configuration: nil, 
                URL: storeURL, 
                options: options )
        }
        catch { print("Error reading store \(error)") }

    }
    
    private func save() {
        guard
            let mainMoc     = self.mainMoc, 
            let privateMoc  = self.privateMoc
            where ( (mainMoc.hasChanges == true) || (privateMoc.hasChanges == true) )
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
    
// MARK: Internal DataStore Protocol Implementation
    
    internal func add( samples:[DataSample] ) -> Promise<()> {
        
        let datedSamples = samples.sort { (sampleA, sampleB) -> Bool in
            sampleA.dateSampled.compare(sampleB.dateSampled) == .OrderedSame
        }
        
        return self.fetch(
            datedSamples.first?.dateSampled ?? NSDate.distantPast(), 
            toDate: datedSamples.last?.dateSampled ?? NSDate.distantFuture() ) 
        .then { existingRecords -> Void in
            if let mainMoc = self.mainMoc {
                mainMoc.performBlockAndWait() {
                    for sample in samples {
                        var exists = false
                        for existingSample in existingRecords {
                            if existingSample == sample {
                                exists = true
                                break
                            }
                        }
                        
                        if exists == false {
                            ManagedSample.add(sample, context: mainMoc)
                        }
                    }
                }
                self.save()
            }
        }
    }
    
    internal func fetch (
        fromDate    :NSDate, 
        toDate      :NSDate ) -> Promise < [DataSample] > 
    {
        return Promise< [DataSample] > { fulfill, reject in
            let fetch = NSFetchRequest(entityName: "ManagedSample")
            fetch.predicate = NSPredicate(format: "(dateSampled >= %@) AND (dateSampled <= %@)", fromDate, toDate)
            fetch.sortDescriptors = [ NSSortDescriptor(key: "dateSampled", ascending: true)]
            
            do {
                if let managedSamples = try self.mainMoc?.executeFetchRequest(fetch) {
                    var samples = [DataSample]()
                    for managedSample in managedSamples {
                        if let 
                            sampledValue = managedSample.sampledValue?.doubleValue,
                            source = TrendCoreImporterType(rawValue: managedSample.source) 
                        {
                            let sample = DataSample (
                                value: sampledValue, 
                                trend: nil, 
                                dateSampled: managedSample.dateSampled, 
                                dateImported: managedSample.dateImported, 
                                source:source )
                            
                            samples.append(sample)
                        }
                    }
                    fulfill(samples)
                }
                else {
                    print("Nil samples returned")
                    fulfill([DataSample]())
                }
            }
            catch {
                print("Error getting samples: \(error)")
                fulfill([DataSample]())
            }
        }        
    }
    
    internal func remove ( samples :[DataSample] ) -> Promise< () >
    {
        return Promise { fulfill, reject in
            for sample in samples {
                let fetch = NSFetchRequest(entityName: "ManagedSample")
                fetch.predicate = NSPredicate(format: "dateSampled = %@ AND sampledValue = %@ AND source = %@",
                    sample.dateSampled,  NSNumber(double:sample.value), sample.source.rawValue
                )
                do {
                    if let results = try self.mainMoc?.executeFetchRequest(fetch) as? [NSManagedObject] {
                        for result in results {
                            self.mainMoc?.deleteObject(result)
                        }
                    }
                }
                catch {
                    print("Error fetching objects to remove: \(error)")
                }
            }
            self.save()
            fulfill()
        }
    }
    
}