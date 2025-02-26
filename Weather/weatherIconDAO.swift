//
//  weatherIconDAO.swift
//  Weather
//
//  Created by sento kiryu on 2/16/25.
//

import Foundation
import UIKit
import Kingfisher

class WeatherImageService {
    
    private let baseImageUrl = "https://openweathermap.org/img/wn/"
    
    private let weatherIconMapping: [String: String] = [
        "clear": "01d",
        "clear sky": "01d",
        "sunny": "01d",
        "few clouds": "02d",
        "partly cloudy": "02d",
        "partly sunny": "02d",
        "scattered clouds": "03d",
        "broken clouds": "04d",
        "cloudy": "04d",
        "overcast": "04d",
        "overcast clouds": "04d",
        "shower rain": "09d",
        "light rain": "09d",
        "light intensity shower rain": "09d",
        "rain": "10d",
        "moderate rain": "10d",
        "heavy rain": "10d",
        "light intensity drizzle": "09d",
        "drizzle": "09d",
        "heavy intensity drizzle": "09d",
        "thunderstorm": "11d",
        "thunder": "11d",
        "lightning": "11d",
        "thunderstorm with rain": "11d",
        "thunderstorm with heavy rain": "11d",
        "thunderstorm with light rain": "11d",
        "snow": "13d",
        "light snow": "13d",
        "heavy snow": "13d",
        "sleet": "13d",
        "light shower sleet": "13d",
        "shower sleet": "13d",
        "light rain and snow": "13d",
        "rain and snow": "13d",
        "mist": "50d",
        "fog": "50d",
        "haze": "50d",
        "smoke": "50d",
        "dust": "50d",
        "sand": "50d",
        "squall": "50d",
        "tornado": "50d",
        "clear night": "01n",
        "night": "01n",
        "few clouds night": "02n",
        "partly cloudy night": "02n",
        "scattered clouds night": "03n",
        "broken clouds night": "04n",
        "rain night": "10n",
        "thunderstorm night": "11n",
        "snow night": "13n",
        "mist night": "50n"
    ]
    
    private var idToImageMap: [String: UIImage] = [:]
    
    func prepCache(){
        for key in weatherIconMapping.keys{
            fetchWeatherImage(for: key){image in
                if let actImage = image{
                    self.idToImageMap[key] = actImage
                }
            }
        }
    }
    
    func getFromCache(for description: String) -> UIImage?{
        return self.idToImageMap[description]
    }
    
    func fetchWeatherImage(for description: String, completion: @escaping (UIImage?) -> Void) {
        let lowercasedDescription = description.lowercased()
        
        let iconCode = weatherIconMapping[lowercasedDescription] ?? "01d"
        
        let imageUrlString = "\(baseImageUrl)\(iconCode)@2x.png"
        guard let imageUrl = URL(string: imageUrlString) else {
            completion(nil)
            return
        }
        
        KingfisherManager.shared.retrieveImage(with: imageUrl) { result in
            switch result {
            case .success(let imageResult):
                completion(imageResult.image)
            case .failure(let error):
                print("Error fetching weather image: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
}
