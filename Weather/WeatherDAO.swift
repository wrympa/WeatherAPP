import Foundation

struct WeatherResponse: Codable {
    let name: String
    let main: Main
    let weather: [Weather]
    let clouds: Clouds
    let wind: Wind
}

struct Clouds: Codable {
    let all: Int
}

struct Wind: Codable {
    let speed: Double
    let deg: Int
}

struct Main: Codable {
    let temp: Double
    let humidity: Int
}

struct Weather: Codable {
    let description: String
    let main: String
}

struct CityResponse: Codable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String
}

struct FiveDayForecastResponse: Codable {
    let list: [ForecastItem]
    let city: City
}

struct ForecastItem: Codable {
    let dt: Int
    let main: Main
    let weather: [Weather]
    let clouds: Clouds
    let wind: Wind
    let dt_txt: String
}

struct City: Codable {
    let id: Int
    let name: String
    let coord: Coordinates
    let country: String
}

struct Coordinates: Codable {
    let lat: Double
    let lon: Double
}

class WeatherDAO {
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    private let forecastURL = "https://api.openweathermap.org/data/2.5/forecast"
    private let cityInfoURL = "https://api.openweathermap.org/geo/1.0/direct?q=[CITY_NAME]&limit=5&appid=[API_KEY]"
    private let apiKey = "f3697d438ab70b83aaf6b0053007b1d0"
    
    func fetchWeather(lat: Double, lon: Double) -> WeatherResponse? {
        let urlString = "\(baseURL)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        var result: WeatherResponse?
        let semaphore = DispatchSemaphore(value: 0)
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return nil
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                semaphore.signal()
                return
            }
            
            guard let data = data else {
                print("No data received")
                semaphore.signal()
                return
            }
            
            do {
                let decoder = JSONDecoder()
                result = try decoder.decode(WeatherResponse.self, from: data)
            } catch {
                print("Decoding error: \(error)")
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        return result
    }
    
    func fetch5DaysWeather(lat: Double, lon: Double) -> FiveDayForecastResponse? {
        let urlString = "\(forecastURL)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        var result: FiveDayForecastResponse?
        let semaphore = DispatchSemaphore(value: 0)
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return nil
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                semaphore.signal()
                return
            }
            
            guard let data = data else {
                print("No data received")
                semaphore.signal()
                return
            }
            
            do {
                let decoder = JSONDecoder()
                result = try decoder.decode(FiveDayForecastResponse.self, from: data)
            } catch {
                print("Decoding error: \(error)")
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        return result
    }
    
    func fetchCityInfo(name: String) -> [CityResponse]? {
        let urlString = cityInfoURL
            .replacingOccurrences(of: "[API_KEY]", with: apiKey)
            .replacingOccurrences(of: "[CITY_NAME]", with: name)
        
        var result: [CityResponse]?
        let semaphore = DispatchSemaphore(value: 0)
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return []
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                semaphore.signal()
                return
            }
            
            guard let data = data else {
                print("No data received")
                semaphore.signal()
                return
            }
            
            do {
                let decoder = JSONDecoder()
                result = try decoder.decode([CityResponse].self, from: data)
            } catch {
                print("Decoding error: \(error)")
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        return result ?? []
    }
}


