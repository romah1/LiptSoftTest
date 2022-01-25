import Foundation

class TheCatApi {
    private let apiKey: String
    
    init() {
        self.apiKey = "c9c0a923-5c8f-46d9-a3bf-a898b2314138"
    }
    
    func makeGetCatsRequest(
        page: Int,
        limit: Int,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        var urlBuilder = URLComponents(
            string: "https://api.thecatapi.com/v1/images/search"
        )
        urlBuilder?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        guard let url = urlBuilder?.url else {
            fatalError("Wrong url")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(self.apiKey, forHTTPHeaderField: "x-api-key")
        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: completionHandler
        )
        task.resume()
    }
}

struct Cat: Codable, Identifiable, Hashable {
    let id: String
    let url: String
    let width: Int
    let height: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case url
        case width
        case height
    }
    
    func jsonStringRepresentation() -> String {
        guard let json = try? JSONEncoder().encode(self),
              let object = try? JSONSerialization.jsonObject(with: json, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding: .utf8) else {
                  return ""
              }
        return prettyPrintedString
    }
}
