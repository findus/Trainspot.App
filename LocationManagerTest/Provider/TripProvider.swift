//
//  TripProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 05.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

//https://medium.com/@vhart/a-swift-walk-through-type-erasure-12fbe3827a10
import Foundation

class TripProvider<T> : TrainDataProviderProtocol {

    var delegate: TrainDataProviderDelegate? = nil
 
    var trips: Array<T> = []
    
    private let providerBox: BaseTrainDataProvider<T>
        
    init<P: TrainDataProviderProtocol>(_ provider: P) where P.TripData == T {
        let box = TrainDataProviderBox(concreteProvider: provider)
        self.providerBox = box
    }
    
    func getAllTrips() -> Array<T> {
        return self.providerBox.getAllTrips()
    }
    
    func update() {
        self.providerBox.update()
    }

}

private class BaseTrainDataProvider<T>: TrainDataProviderProtocol {
    
    var delegate: TrainDataProviderDelegate?
    
    init() {
        guard type(of: self) != BaseTrainDataProvider.self else {
            fatalError("Do not initialize this abstract class directly")
        }
    }
    
    func getAllTrips() -> Array<T> {
        fatalError("Abstract class, you  must override this")
    }
    
    func update() {
        fatalError("Abstract class, you must override this")
    }
}

private class TrainDataProviderBox<B: TrainDataProviderProtocol>: BaseTrainDataProvider<B.TripData> {
    private let provider: B
    
    init(concreteProvider: B) {
        self.provider = concreteProvider
    }
    
    override func getAllTrips() -> Array<B.TripData> {
        return provider.getAllTrips()
    }
    
    override func update() {
        self.provider.update()
    }
}
