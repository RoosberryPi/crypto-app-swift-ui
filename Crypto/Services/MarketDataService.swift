//
//  MarketDataService.swift
//  Crypto
//
//  Created by Rosa Meijers on 10/06/2023.
//

import Foundation
import Combine

// about FRP/Combine framework: https://medium.com/proximity-labs/getting-started-with-combine-in-swift-1d6a5b53b216

class MarketDataService {
    @Published var marketData: MarketDataModel? = nil
    
    var marketDataSubscription: AnyCancellable?
    
    init() {
        getMarketData()
    }
    
    // get url, get the data, check for valid response, decode the good data in market data models, print errors, append returned coins to coin array
    func getMarketData() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/global") else { return
        }

        // the data service uses the networkingmanager to download from the internet
        marketDataSubscription = NetworkingManager.download(url: url)
            // decode the array of data
            .decode(type: GlobalData.self, decoder: JSONDecoder()) // first global data, then data model
            // sink array
            .sink(receiveCompletion: NetworkingManager.handleCompletion, receiveValue: { [weak self] (returnedData) in

                // this self will create a strong reference to the class, so make it weak
                // if you need to de allocate this class a weak self is necessary
                self?.marketData = returnedData.data
                self?.marketDataSubscription?.cancel()
            })
    }
}
