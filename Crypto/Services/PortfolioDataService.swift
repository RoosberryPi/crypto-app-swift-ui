//
//  PortfolioDataService.swift
//  Crypto
//
//  Created by Rosa Meijers on 21/06/2023.
//

import Foundation
import CoreData

// not via api but via coredata
class PortfolioDataService {
    private let container: NSPersistentContainer
    private let containerName: String = "PortfolioContainer"
    private let entityName: String = "PortfolioEntity"
    
    // this will be funnelling into the rest of our app, by subscribing to this array
    @Published var savedEntities: [PortfolioEntity] = []
    
    // load container in the file
    init() {
        container = NSPersistentContainer(name: containerName)
        container.loadPersistentStores { [self] (_, error) in
            if let error = error {
                print("error loading core data: \(error)")
            }
            getPortfolio()
        }
    }
    
    // MARK: PUBLIC
    
    func updatePortfolio(coin: CoinModel, amount: Double) {
        // looking for the coin in our entities that has the same coin id that is passed here
        if let entity = savedEntities.first(where: { $0.coinId == coin.id}) {
            // are we updating or deleting?
            if amount > 0 {
                update(entity: entity, amount: amount)
            } else {
                delete(entity: entity)
            }
        } else {
            // cannot find entitity in our saved ones, so save
            add(coin: coin, amount: amount)
        }
   }
                                            
    // MARK: PRIVATE
    
    // get the whole saved portfolio from core data
    private func getPortfolio() {
        let request = NSFetchRequest<PortfolioEntity>(entityName: entityName)
        do {
            savedEntities = try container.viewContext.fetch(request)
        } catch let error {
            print("error fetching portfolio entities \(error)")
        }
    }
    
    private func add(coin: CoinModel, amount: Double) {
        let entity = PortfolioEntity(context: container.viewContext)
        entity.coinId = coin.id
        entity.amount = amount
        applyChanges()
    }
    
    private func update(entity: PortfolioEntity, amount: Double) {
        entity.amount = amount
        applyChanges()
    }
    
    private func delete(entity: PortfolioEntity){
        container.viewContext.delete(entity)
        applyChanges()
    }
    
    private func save() {
        do {
            try container.viewContext.save()
        } catch let error {
            print("error saving to core data: \(error)")
        }
    }
    
    // save context and then refetch all coins of our context and set them into our saved entities
    private func applyChanges(){
        save()
        getPortfolio()
    }
}
