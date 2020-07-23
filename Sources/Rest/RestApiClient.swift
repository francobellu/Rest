//
//  RestApiClient.swift
//  MarvelApiClient
//
//  Created by BELLU Franco on 14/05/2020.
//  Copyright © 2020 BELLU Franco. All rights reserved.
//

import Foundation

public enum NetworkError: Error{
  case dataCorrupted

  case authenticationError
  case badRequest
  case outdated
  case failed
  case noData
  case unableToDecode
}

//case authenticationError = "You need to be authenticated first."
//case badRequest = "Bad request"
//case outdated = "The url you requested is outdated."
//case failed = "Network request failed."
//case noData = "Response returned with no data to decode."
//case unableToDecode = "We could not decode the response."

public enum NetworkResponse: String {
    case success
    case authenticationError = "You need to be authenticated first."
    case badRequest = "Bad request"
    case outdated = "The url you requested is outdated."
    case failed = "Network request failed."
    case noData = "Response returned with no data to decode."
    case unableToDecode = "We could not decode the response."
}

// Protocol for MOCK/Real session
public protocol URLSessionProtocol {
    typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void

    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol
}

public protocol URLSessionDataTaskProtocol {
    func resume()
}

// MARK: Conform the protocol
extension URLSession: URLSessionProtocol {
  public func dataTask(with request: URLRequest, completionHandler: @escaping URLSessionProtocol.DataTaskResult) -> URLSessionDataTaskProtocol {
        return dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask
    }
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

public class RestApiClient {

  private let session: URLSessionProtocol

  public init(session: URLSessionProtocol = URLSession(configuration: .default)) {
    self.session = session
  }

  public typealias NetworkCompletion = (Result<(URLResponse, Data), Error>) -> Void
  public typealias NetworkCompletionResult = Result<(URLResponse, Data), Error>

  fileprivate func resultForValidResponse(_ data: Data, _ response: HTTPURLResponse) -> NetworkCompletionResult{
    // debug: print json data before to decode
    var result: NetworkCompletionResult
    print(data)
    if let jsonData = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers){
      print("Data: \(data),  responseHeaders : \(response), json: \(jsonData)")
    }
    if let error = self.handleStatusCode(response.statusCode){
      result = .failure(error)
    }
    result = .success((response, data))

    return result
  }

  /// Sends a request to Marvel servers, calling the completion method when finished
  public func send<T: APIRequest>(_ request: T, completion: @escaping NetworkCompletion) {
    // CREATE THE URL INCLUDING THE PARAMETERS
    guard let endpoint = request.endpoint() else { return }
    print("Request: \(endpoint)")
    let task = session.dataTask(with: URLRequest(url: endpoint)) { data, response, error in
      var result: NetworkCompletionResult
      if let error = error {
        result = .failure(error)
      }
      if let response = response as? HTTPURLResponse, let data = data {
        result = self.resultForValidResponse(data, response)
      } else{
        result = .failure(NetworkError.dataCorrupted)
      }
      completion(result)
    }
    task.resume()
  }

  fileprivate func handleStatusCode(_ statusCode: Int) -> NetworkError?{
      switch statusCode {
      case 200...299: return nil
      case 401...500: return NetworkError.authenticationError
      case 501...599: return NetworkError.badRequest
      case 600: return NetworkError.outdated
      default: return NetworkError.failed
      }
  }
}
