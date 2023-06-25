//
//  HomeViewModel.swift
//  Crypto
//
//  Created by Rosa Meijers on 02/06/2023.
//

import Foundation
import Combine

// observe this from our view
// the vm ha s a dataservice
class HomeViewModel: ObservableObject {
    
    @Published var statistics: [StatisticModel] = []
    
    // first tab
    @Published var allCoins: [CoinModel] = []
    // second tab
    @Published var portfolioCoins: [CoinModel] = []
    
    @Published var searchText: String = ""
    
    private let coinDataService = CoinDataService()
    private let marketDataService = MarketDataService()
    private let portfolioDataService = PortfolioDataService()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        addSubscribers()
    }
    
    // the subscribers is subscribing to the dataservice coins array, the data published there wil also be published here and append the data to viewmodel coins array
    func addSubscribers() {
        // this subscriber of the viewmodel subscribes to the searchtext and allcoins
        // when either of these changes, it gets published
        // updates all coins
        $searchText
            .combineLatest(coinDataService.$allCoins) // when the allcoins get published, the map + sink is going to run
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main) // will wait 0.5 seconds before running the rest of the code, so the function won't get executed all the time
            .map(filteredCoins)
            .sink { [weak self] (returnedCoins) in
                self?.allCoins = returnedCoins
            }
            .store(in: &cancellables)
        
        // updates market data
        // download data, decode it in market data model, put it into statistics view
        marketDataService.$marketData // variable that is set after downloading
            .map { (marketDataModel) -> [StatisticModel] in
                var stats: [StatisticModel] = []
                
                guard let data = marketDataModel else { return stats }
                
                let marketCap = StatisticModel(title: "Market Cap", value: data.marketCap, percentageChange: data.marketCapChangePercentage24HUsd)
                
                let volume = StatisticModel(title: "24h Volume", value: data.volume)
                
                let btcDominance = StatisticModel(title: "BTC Dominance", value: data.btcDominance)
                
                let portfolio = StatisticModel(title: "Portfolio Value", value: "$0.00", percentageChange: 0)
                
                stats.append(contentsOf: [marketCap, volume, btcDominance, portfolio])
                
                return stats
                        
            }
            .sink { [weak self] (returnedStats) in
                self?.statistics = returnedStats
            }
            .store(in: &cancellables)
        
        // updates portfolio
        // we want to convert the portfoliocoins to coinmodels so we can add them to the coin model array
        // therefore we want to subscribe to allcoins and portfoliocoins
        $allCoins // take latest array of filtered coins of type coin model
            .combineLatest(portfolioDataService.$savedEntities) // type portfolio entity
            .map { (coinmodels, portfolioEntities) -> [CoinModel] in
                coinmodels
                    .compactMap { (coin) -> CoinModel? in
                        guard let entity = portfolioEntities.first(where: { $0.coinId == coin.id }) else {
                            return nil // this means we dont have this coin in our portfolio
                        }
                        return coin.updateHoldings(amount: entity.amount) //it will take the current coin and return the coin with the same values except for the holdings with a new amount
                    } // the result is optional, because a bunch of coins we dont need to use, only the ones we have in our portfolio
            }
            .sink { [weak self] (returnedCoins) in
                self?.portfolioCoins = returnedCoins
            }
            .store(in: &cancellables)
    }
    
    func updatePortfolio(coin: CoinModel, amount: Double) {
        portfolioDataService.updatePortfolio(coin: coin, amount: amount)
    }
    
    private func filteredCoins(text: String, coins: [CoinModel]) -> [CoinModel] {
        guard !text.isEmpty else {
            return coins
        }
        
        let lowercasedText = text.lowercased()
        
        // return filtered array of coinmodels
        return coins.filter { (coin) -> Bool in
            return coin.name.lowercased().contains(lowercasedText) || coin.symbol.lowercased().contains(lowercasedText) || coin.id.lowercased().contains(lowercasedText)
        }
    }
}
