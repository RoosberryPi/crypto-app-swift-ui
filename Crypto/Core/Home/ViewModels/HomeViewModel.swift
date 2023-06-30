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
    @Published var isLoading = false
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
            .map(filteredCoins) // filter the coins
            .sink { [weak self] (returnedCoins) in
                self?.allCoins = returnedCoins
            }
            .store(in: &cancellables)
        
        // updates portfolio
        // we want to convert the portfoliocoins to coinmodels so we can add them to the coin model array
        // therefore we want to subscribe to allcoins and portfoliocoins
        $allCoins // take latest array of filtered coins of type coin model
            .combineLatest(portfolioDataService.$savedEntities) // type portfolio entity, save the coins in core data
            .map(mapAllCoinsToPortfolioCoins) // you get the parameters from the subscribers so no need to pass them explictly here
            .sink { [weak self] (returnedCoins) in
                self?.portfolioCoins = returnedCoins
            }
            .store(in: &cancellables)
        
        // updates market data
        // download data, decode it in market data model, put it into statistics view
        marketDataService.$marketData // variable that is set after downloading
            .combineLatest($portfolioCoins) // every time the portfolioCoins is updated, these functions will re-run
            .map(mapMarketData)
            .sink { [weak self] (returnedStats) in
                self?.statistics = returnedStats
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    func updatePortfolio(coin: CoinModel, amount: Double) {
        portfolioDataService.updatePortfolio(coin: coin, amount: amount)
    }
    
    func reloadData() {
        isLoading = true
        coinDataService.getCoins()
        marketDataService.getMarketData()
        HapticManager.notification(type: .success)
    }
    
    private func mapAllCoinsToPortfolioCoins(allCoins: [CoinModel], portfolioEntities: [PortfolioEntity]) -> [CoinModel] {
        allCoins
            .compactMap { (coin) -> CoinModel? in
                guard let entity = portfolioEntities.first(where: { $0.coinId == coin.id }) else {
                    return nil // this means we dont have this coin in our portfolio
                }
                return coin.updateHoldings(amount: entity.amount) //it will take the current coin and return the coin with the same values except for the holdings with a new amount
            } // the result is optional, because a bunch of coins we dont need to use, only the ones we have in our portfolio
    }
    
    private func mapMarketData(marketDataModel: MarketDataModel?, portfolioCoins: [CoinModel]) -> [StatisticModel] {
        var stats: [StatisticModel] = []
        
        guard let data = marketDataModel else { return stats }
        
        let marketCap = StatisticModel(title: "Market Cap", value: data.marketCap, percentageChange: data.marketCapChangePercentage24HUsd)
        
        let volume = StatisticModel(title: "24h Volume", value: data.volume)
        
        let btcDominance = StatisticModel(title: "BTC Dominance", value: data.btcDominance)
        
        let portfolioValue =
            portfolioCoins
            .map({ $0.currentHoldingsValue})
            .reduce(0, +) // instead of array of Double we want one total number of portfolio value, so use reduce
        
        let previousValue =
            portfolioCoins
            .map { (coin) -> Double in
                let currentValue = coin.currentHoldingsValue
                let percentChange = (coin.priceChangePercentage24H ?? 0) / 100
                let previousValue = currentValue / (1 + percentChange)
                return previousValue
            }
            .reduce(0, +) // you want one single previousValue, so sum up
        
        let percentageChange = ((portfolioValue - previousValue) / previousValue) * 100
        
        let portfolio = StatisticModel(title: "Portfolio Value", value: portfolioValue.asCurrencyWith2Ddecimals(), percentageChange: percentageChange)
        
        stats.append(contentsOf: [marketCap, volume, btcDominance, portfolio])
        
        return stats
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
