//
//  persistentDAO.swift
//  Weather
//
//  Created by sento kiryu on 2/8/25.
//

import UIKit
import CoreData

class PersistentDAO{
    static let shared = PersistentDAO()
    
    private let context: NSManagedObjectContext
    
    private init(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError()
        }
        context = appDelegate.persistentContainer.viewContext
    }
    
    
    func addCity(name: String){
        let place = PlaceEntity(context: context)
        place.name = name
        
        saveContext()
    }
    
    func fetchPlaces() -> [PlaceEntity] {
        let request: NSFetchRequest<PlaceEntity> = PlaceEntity.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching places: \(error)")
            return []
        }
    }

    func removePlace(named name: String) {
        let request: NSFetchRequest<PlaceEntity> = PlaceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let placesToDelete = try context.fetch(request)
            for place in placesToDelete {
                context.delete(place)
            }
            saveContext()
        } catch {
            print("Error deleting place: \(error)")
        }
    }

    func clearPlaces() {
        let request: NSFetchRequest<NSFetchRequestResult> = PlaceEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            self.saveContext()
        } catch {
            print("Error clearing places: \(error)")
        }
    }
    
    func saveContext(){
        do {
            try context.save()
        } catch {
        }
    }
}
