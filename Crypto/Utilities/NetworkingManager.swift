//
//  NetworkingManager.swift
//  Crypto
//
//  Created by Rosa Meijers on 03/06/2023.
//

import Foundation
import Combine

class NetworkingManager {
    
    enum NetworkingError: LocalizedError {
        case badUrlResponse(url: URL)
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .badUrlResponse(url: let url): return "[😨]Bad response from URL \(url)"
            case .unknown: return "[😐]Unknown error occurred"
            }
        }
    }
    
    // static func because this will be always the same function, otherwise you have to initialize the class
    static func download(url: URL) -> AnyPublisher<Data, Error>{
        return URLSession.shared.dataTaskPublisher(for: url)
            // get on the background thread
            .subscribe(on: DispatchQueue.global(qos: .default))
            // map the results of the publisher
            .tryMap({ try handleURLResponse(output: $0, url: url)})
            // return to the main thread
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    static func handleURLResponse(output: URLSession.DataTaskPublisher.Output, url: URL) throws -> Data {
        guard let response = output.response as? HTTPURLResponse,
              response.statusCode >= 200 && response.statusCode < 300 else {
            print(output.response, output.data)
            throw NetworkingError.badUrlResponse(url: url)
        }

        return output.data
    }
    
    static func handleCompletion(completion: Subscribers.Completion<Error>) {
        switch completion {
        case .finished:
            break
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
}
