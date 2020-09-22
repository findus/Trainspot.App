//
//  TripProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 05.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//
//https://medium.com/@vhart/a-swift-walk-through-type-erasure-12fbe3827a10
import Foundation

public class TripProvider<T> : TrainDataProviderProtocol where T: Hashable {
    
    var trips: Set<T> = []
    
    private let providerBox: BaseTrainDataProvider<T>
        
    public init<P: TrainDataProviderProtocol>(_ provider: P) where P.TripData == T {
        let box = TrainDataProviderBox(concreteProvider: provider)
        self.providerBox = box
    }
    
    public func getAllTrips() -> Set<T> {
        return self.providerBox.getAllTrips()
    }
    
    public func update() {
        self.providerBox.update()
    }
    
    public func setDeleate(delegate: TrainDataProviderDelegate) {
        self.providerBox.setDeleate(delegate: delegate)
    }
    
    public func updateExistingTrips(_ trips: Array<T>) {
        self.providerBox.updateExistingTrips(trips)
    }

}

private class BaseTrainDataProvider<T>: TrainDataProviderProtocol where T: Hashable {
   
    var delegate: TrainDataProviderDelegate?
    
    init() {
        guard type(of: self) != BaseTrainDataProvider.self else {
            fatalError("Do not initialize this abstract class directly")
        }
    }
    
    func getAllTrips() -> Set<T> {
        fatalError("Abstract class, you  must override this")
    }
    
    func update() {
        fatalError("Abstract class, you must override this")
    }
    
    func setDeleate(delegate: TrainDataProviderDelegate) {
        fatalError("Do not initialize this abstract class directly")
    }
    
    public func updateExistingTrips(_ trips: Array<T>) {
        fatalError("Do not initialize this abstract class directly")
      }
}

private class TrainDataProviderBox<P: TrainDataProviderProtocol>: BaseTrainDataProvider<P.TripData> {
    private let provider: P
    
    init(concreteProvider: P) {
        self.provider = concreteProvider
    }
    
    override func getAllTrips() -> Set<P.TripData> {
        return provider.getAllTrips()
    }
    
    override func update() {
        self.provider.update()
    }
    
    override func setDeleate(delegate: TrainDataProviderDelegate) {
        self.provider.setDeleate(delegate: delegate)
    }
    
    override public func updateExistingTrips(_ trips: Array<P.TripData>) {
        self.provider.updateExistingTrips(trips)
    }
}
