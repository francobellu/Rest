import Foundation

public protocol ApiRequestConfigProtocol{
  var baseEndpointString: String { get }
  var publicKey: String { get }
  var privateKey: String { get }
}

/// All requests must conform to this protocol
/// - Discussion: You must conform to Encodable too, so that all stored public parameters
///   of types conforming this protocol will be encoded as parameters.
public protocol APIRequest {
	/// Response (will be wrapped with a DataContainer)
	associatedtype Response: Decodable

  var apiRequestConfig: ApiRequestConfigProtocol { get set}

	/// Endpoint for this request (the last part of the URL)
	var resourceName: String { get }
  var method: Method { get }
  var parameters: [String: String]? { get }
//  var decode: (Data) throws -> Response { get }

}

extension APIRequest {
  // Encodes a URL based on the given request using
  // Create a URLComponents url composing:
  // 1) baseUrl = baseEndpointUrl +  request.resourceName
  // 2) commonQueryItems
  // 3) customQueryItems a partir de request object
  func endpoint() -> URL? { //swiftlint:disable:this function_body_length
    guard let baseUrl = URL(string: resourceName, relativeTo: URL(string: apiRequestConfig.baseEndpointString) ) else {
      fatalError("Bad resourceName: \(resourceName)")
    }
    guard var components = URLComponents(url: baseUrl, resolvingAgainstBaseURL: true) else { return nil }

    // Common query items needed for all Marvel requests
    let timestamp = "\(Date().timeIntervalSince1970)"

    let str = "\(timestamp)\(apiRequestConfig.privateKey)\(apiRequestConfig.publicKey)"

    guard let digest =  str.insecureMD5Hash() else { return nil }
    let commonQueryItems = [
      URLQueryItem(name: "ts", value: timestamp),
      URLQueryItem(name: "hash", value: digest),
      URLQueryItem(name: "apikey", value: apiRequestConfig.publicKey)
    ]

    // Custom query items needed for this specific request
    var customQueryItems = [URLQueryItem]()

    if let params = parameters, !params.isEmpty {
      customQueryItems = params.map { item, value in
        URLQueryItem(name: item, value: value)
      }
    }

    components.queryItems = commonQueryItems + customQueryItems

    // Construct the final URL with all the previous data
    return components.url
  }

  var decode: (Data) throws -> Response { {
    try JSONDecoder().decode(Response.self, from: $0)
    }
  }
}

public enum Method {
    case get, post, put, patch, delete
}
