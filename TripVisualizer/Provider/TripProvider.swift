//
//  TripProvider.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 05.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//
//https://medium.com/@vhart/a-swift-walk-through-type-erasure-12fbe3827a10
import Foundation

public class TripProvider<T> : TrainDataProviderProtocol {
    
    var trips: Array<T> = []
    
    private let providerBox: BaseTrainDataProvider<T>
        
    public init<P: TrainDataProviderProtocol>(_ provider: P) where P.TripData == T {
        let box = TrainDataProviderBox(concreteProvider: provider)
        self.providerBox = box
    }
    
    public func getAllTrips() -> Array<T> {
        return self.providerBox.getAllTrips()
    }
    
    public func update() {
        self.providerBox.update()
    }
    
    public func setDeleate(delegate: TrainDataProviderDelegate) {
        self.providerBox.setDeleate(delegate: delegate)
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
    
    func setDeleate(delegate: TrainDataProviderDelegate) {
        fatalError("Do not initialize this abstract class directly")
    }
}

private class TrainDataProviderBox<P: TrainDataProviderProtocol>: BaseTrainDataProvider<P.TripData> {
    private let provider: P
    
    init(concreteProvider: P) {
        self.provider = concreteProvider
    }
    
    override func getAllTrips() -> Array<P.TripData> {
        return provider.getAllTrips()
    }
    
    override func update() {
        self.provider.update()
    }
    
    override func setDeleate(delegate: TrainDataProviderDelegate) {
        self.provider.setDeleate(delegate: delegate)
    }
}
