//
//  DataController.swift
//  VirtualTourist
//
//  Created by Ashish Nautiyal on 2/13/19.
//  Copyright © 2019 Ashish  Nautiyal. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistentDataContainer: NSPersistentContainer
    var backgroundContext: NSManagedObjectContext!
    init(modelName: String) {
        persistentDataContainer = NSPersistentContainer(name: modelName)
    }
    var viewContext : NSManagedObjectContext {
        return persistentDataContainer.viewContext
    }
    
    func configureContexts(){
        backgroundContext = persistentDataContainer.newBackgroundContext()
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentDataContainer.loadPersistentStores{ storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
        }
        //self.autoSaveViewContext(interval: 3)
        configureContexts()
        completion?()
        
    }
}
