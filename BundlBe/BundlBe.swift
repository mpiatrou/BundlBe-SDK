import Foundation
import StoreKit

/// `BundlBe` — lightweight SDK for subscription activation and paywall suppression.
public enum BundlBe {
    private static let baseURL = "https://earhvvozazevfifnvwke.supabase.co/functions/v1"
    private static let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let lastVerified = "BundlBe_LastVerified"
        static let paywallSuppress = "BundlBe_PaywallSuppress"
    }
    
    
    // MARK: - 1. Login
    
    /**
     Performs login with a subscription activation code.
     
     - If `lastVerified` is missing or older than 24h → sends `/login` request to backend.
     - Otherwise → returns cached success immediately.
     
     On success:
     - Saves `lastVerified` and `paywallSuppress` in `UserDefaults`.
     - Sends `subscription-duplicate` notification depending on Apple subscription status.
     
     On failure:
     - Clears `lastVerified` and sets `paywallSuppress = false`.
     
     - Parameters:
       - code: User activation code.
       - appID: Application identifier.
       - deviceID: Device identifier.
       - completion: Completion with `BundlBeResponse` or `Error`.
     */
    public static func login(
        code: String,
        appID: String,
        deviceID: String,
        completion: @escaping (Result<BundlBeResponse, Error>) -> Void
    ) {
        let now = Date()
        
        let lastVerified = userDefaults.object(forKey: Keys.lastVerified) as? Date
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now)
        
        if lastVerified == nil || (oneDayAgo != nil && lastVerified! < oneDayAgo!) {
            let body = ["code": code, "app_id": appID, "device_id": deviceID]
            request(path: "/login", body: body) { (result: Result<BundlBeResponse, Error>) in
                switch result {
                case .success(let response):
                    userDefaults.set(now, forKey: Keys.lastVerified)
                    userDefaults.set(response.paywallSuppress, forKey: Keys.paywallSuppress)
                    userDefaults.synchronize()
                    
                    if hasAppleSubscriptions() {
                        postDuplicate(code: code, appID: appID)
                    } else {
                        deleteDuplicate(code: code, appID: appID)
                    }
                    
                    completion(.success(response))
                    
                case .failure(let error):
                    userDefaults.removeObject(forKey: Keys.lastVerified)
                    userDefaults.set(false, forKey: Keys.paywallSuppress)
                    userDefaults.synchronize()
                    completion(.failure(error))
                }
            }
        } else {
            completion(.success(BundlBeResponse(paywallSuppress: isPaywallSuppressed, error: nil)))
        }
    }
    
    
    // MARK: - 2. Logout
    
    /**
     Logs out user and resets paywall suppress.
     
     - Calls `/logout` on backend.
     - Regardless of response, sets `paywallSuppress = false` in `UserDefaults`.
     
     - Parameters:
       - code: User activation code.
       - appID: Application identifier.
       - deviceID: Device identifier.
       - completion: Completion with `BundlBeResponse` or `Error`.
     */
    public static func logout(
        code: String,
        appID: String,
        deviceID: String,
        completion: @escaping (Result<BundlBeResponse, Error>) -> Void
    ) {
        let body = ["code": code, "app_id": appID, "device_id": deviceID]
        request(path: "/logout", body: body) { (result: Result<BundlBeResponse, Error>) in
            switch result {
            case .success(let response):
                userDefaults.set(response.paywallSuppress, forKey: Keys.paywallSuppress)
                userDefaults.removeObject(forKey: Keys.lastVerified)
                userDefaults.synchronize()
                let forced = BundlBeResponse(paywallSuppress: false, error: response.error)
                completion(.success(forced))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    // MARK: - 3. Paywall Suppressor
    
    /**
     Returns current paywall suppression status from `UserDefaults`.
     
     - Returns: `true` if paywall should be hidden, `false` otherwise.
     */
    public static var isPaywallSuppressed: Bool {
        return userDefaults.bool(forKey: Keys.paywallSuppress)
    }
    

    // MARK: - Duplicate Notifications
    
    /**
     Sends `/subscription-duplicate` POST request when Apple subscription exists.
     
     - Parameters:
       - code: User activation code.
       - appID: Application identifier.
     */
    private static func postDuplicate(code: String, appID: String) {
        let body = ["code": code, "app_id": appID]
        request(path: "/subscription-duplicate", method: "POST", body: body) { (result: Result<DuplicateResponse, Error>) in
            switch result {
            case .success(let response):
                print("PostDuplicate success:", response.success ?? false)
            case .failure(let error):
                print("PostDuplicate error:", error.localizedDescription)
            }
        }
    }

    /**
     Sends `/subscription-duplicate` DELETE request when Apple subscription does not exist.
     
     - Parameters:
       - code: User activation code.
       - appID: Application identifier.
     */
    private static func deleteDuplicate(code: String, appID: String) {
        let body = ["code": code, "app_id": appID]
        request(path: "/subscription-duplicate", method: "DELETE", body: body) { (result: Result<DuplicateResponse, Error>) in
            switch result {
            case .success(let response):
                print("DeleteDuplicate success:", response.success ?? false)
            case .failure(let error):
                print("DeleteDuplicate error:", error.localizedDescription)
            }
        }
    }
    
    
    // MARK: - Helpers
    
    /**
     Checks if Apple subscriptions exist using `SKPaymentQueue`.
     
     - Returns: `true` if user has active or restored subscriptions.
     */
    private static func hasAppleSubscriptions() -> Bool {
        let transactions = SKPaymentQueue.default().transactions
        for transaction in transactions {
            if transaction.transactionState == .purchased || transaction.transactionState == .restored {
                return true
            }
        }
        return false
    }
    
    /**
     Universal HTTP request helper.
     
     - Parameters:
       - path: API endpoint path.
       - method: HTTP method (`POST` by default).
       - body: Request body as dictionary.
       - completion: Completion with decoded response `T` or `Error`.
     */
//    private static func request<T: Decodable>(
//        path: String,
//        method: String = "POST",
//        body: [String: Any],
//        completion: @escaping (Result<T, Error>) -> Void
//    ) {
//        guard let url = URL(string: baseURL + path) else {
//            completion(.failure(AuthError.invalidURL))
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = method
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let httpResponse = response as? HTTPURLResponse else {
//                completion(.failure(AuthError.invalidResponse))
//                return
//            }
//            
//            let statusCode = httpResponse.statusCode
//            guard let data = data else {
//                completion(.failure(AuthError.serverError(status: statusCode, message: nil)))
//                return
//            }
//            
//            switch statusCode {
//            case 200...299:
//                do {
//                    let decoded = try JSONDecoder().decode(T.self, from: data)
//                    completion(.success(decoded))
//                } catch {
//                    let raw = String(data: data, encoding: .utf8) ?? "nil"
//                    print("Decoding failed. Raw response: \(raw)")
//                    completion(.failure(error))
//                }
//                
//            default:
//                if let decoded = try? JSONDecoder().decode(BundlBeResponse.self, from: data) {
//                    let apiError = ErrorResponse(
//                        statusCode: statusCode,
//                        paywallSuppress: decoded.paywallSuppress,
//                        message: decoded.error
//                    )
//                    completion(.failure(apiError))
//                } else {
//                    let message = String(data: data, encoding: .utf8)
//                    completion(.failure(AuthError.serverError(status: statusCode, message: message)))
//                }
//            }
//        }.resume()
//    }
    
    private static func request<T: Decodable>(
        path: String,
        method: String = "POST",
        body: [String: Any],
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(AuthError.invalidURL))
            showAlert(message: "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                showAlert(message: "Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                showAlert(message: "Invalid server response")
                completion(.failure(AuthError.invalidResponse))
                return
            }
            
            let statusCode = httpResponse.statusCode
            guard let data = data else {
                showAlert(message: "Empty response (status: \(statusCode))")
                completion(.failure(AuthError.serverError(status: statusCode, message: nil)))
                return
            }
            
            switch statusCode {
            case 200...299:
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    let raw = String(data: data, encoding: .utf8) ?? ""
                    showAlert(message: "✅ Success (\(statusCode)):\n\(raw)")
                    completion(.success(decoded))
                } catch {
                    let raw = String(data: data, encoding: .utf8) ?? ""
                    showAlert(message: "⚠️ Decoding failed: \(error.localizedDescription)\nRaw:\n\(raw)")
                    completion(.failure(error))
                }
                
            default:
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                showAlert(message: "❌ Server error (\(statusCode)):\n\(message)")
                
                if let decoded = try? JSONDecoder().decode(BundlBeResponse.self, from: data) {
                    let apiError = ErrorResponse(statusCode: statusCode,
                                                 paywallSuppress: decoded.paywallSuppress,
                                                 message: decoded.error)
                    completion(.failure(apiError))
                } else {
                    completion(.failure(AuthError.serverError(status: statusCode, message: message)))
                }
            }
        }.resume()
    }

    
    private static func showAlert(message: String) {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
            
            let alert = UIAlertController(title: "Server Response", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            rootVC.present(alert, animated: true)
        }
    }

}
