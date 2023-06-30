//
//  CoinDataService.swift
//  Crypto
//
//  Created by Rosa Meijers on 02/06/2023.
//

import Foundation
import Combine

// about FRP/Combine framework: https://medium.com/proximity-labs/getting-started-with-combine-in-swift-1d6a5b53b216

class CoinDataService {
    // published because the allcoins will be a publisher, which can have subscribers, viewmodel for example will subscribe
    // if this gets updated with data, the subscribers will get updated too
    @Published var allCoins: [CoinModel] = []
    
    var coinSubscription: AnyCancellable?
    
    init() {
        getCoins()
    }
    
    // get url, get the data, check for valid response, decode the good data in coin models, print errors, append returned coins to coin array
    func getCoins() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=250&page=1&sparkline=true&price_change_percentage=24h") else { return
        }
        
        // the data service uses the networkingmanager to download from the internet
        coinSubscription = NetworkingManager.download(url: url)
            // decode the array of coinmodels
            .decode(type: [CoinModel].self, decoder: JSONDecoder())
            // sink array
            .sink(receiveCompletion: NetworkingManager.handleCompletion, receiveValue: { [weak self] (returnedCoins) in
                // this self will create a strong reference to the class, so make it weak
                // if you need to de allocate this class a weak self is necessary
                self?.allCoins = returnedCoins
                self?.coinSubscription?.cancel()
            })
    }
}
