//
//  CoinImageService.swift
//  Crypto
//
//  Created by Rosa Meijers on 04/06/2023.
//

import Foundation
import SwiftUI
import Combine

class CoinImageService {
    
    @Published var image: UIImage? = nil
    
    private let coin: CoinModel
    private var imageSubscription: AnyCancellable?
    private let fileManager = LocalFileManager.instance
    private let folderName = "coin_images"
    private let imageName: String
    
    init(coin: CoinModel) {
        self.coin = coin
        self.imageName = coin.id
        getCoinImage()
    }
    
    private func getCoinImage(){
        // try first the file manager if it can get the image
        if let savedImage = fileManager.getImage(imageName: imageName, folderName: folderName) {
            image = savedImage
            // print("retrieved image from file manager")
        } else {
            // not found in file manager so download the image
            downloadCoinImage()
            // efficient developers don't want to download excess data, use data that is already downloaded by using a filemanager
            // print("Downloading image...")
        }
    }
    
    private func downloadCoinImage() {
        guard let url = URL(string: coin.image) else { return
        }
        
        // the data service uses the networkingmanager to download from the internet
        imageSubscription = NetworkingManager.download(url: url)
            // try transfrom data into some type
            .tryMap({ (data) -> UIImage? in
                return UIImage(data: data)
            })
            // sink array
            .sink(receiveCompletion: NetworkingManager.handleCompletion, receiveValue: { [weak self] (returnedImage) in
                // this self will create a strong reference to the class, so make it weak
                // if you need to de allocate this class a weak self is necessary
                guard let self = self, let downloadedImage = returnedImage else { return }
                self.image = downloadedImage
                self.imageSubscription?.cancel()
                self.fileManager.saveImage(image: downloadedImage, imageName: imageName, folderName: folderName)
            })
    }
}
