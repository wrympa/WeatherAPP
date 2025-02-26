//
//  5dayVC.swift
//  Weather
//
//  Created by sento kiryu on 2/11/25.
//
import UIKit
class ForecastViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var forecastsGrid: [[ForecastItem]]!
    private var navBar: UINavigationBar!
    var message: String!
    private var errorView: UIView!
    private var weatherIcons: WeatherImageService!

    func setName(cityName: String) {
        self.message = cityName
    }
    
    func tryToLoad() {
        let spinningCircle = UIActivityIndicatorView(style: .large)
        spinningCircle.color = .yellow
        spinningCircle.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(spinningCircle)
        NSLayoutConstraint.activate([
            spinningCircle.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            spinningCircle.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        spinningCircle.startAnimating()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.weatherIcons = WeatherImageService()
            self.weatherIcons.prepCache()
            self.loadCitydata()
            
            DispatchQueue.main.async {
                spinningCircle.stopAnimating()
                spinningCircle.removeFromSuperview()
                
                if self.forecastsGrid?.isEmpty ?? true {
                    self.showNoWifiError()
                } else {
                    self.setupUI()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpBckgGradient()
        setupCustomNavigationBar()
        
        tryToLoad()
    }
    
    func showNoWifiError(){
        let errorImageView = UIImageView(image: UIImage(systemName: "cloud.bolt.rain"))
        errorImageView.tintColor = .orange
        let errorMsgLabel = UILabel()
        errorMsgLabel.text = "Could not load data"
        errorMsgLabel.textColor = .white
        errorMsgLabel.textAlignment = .center
        let retryButton = UIButton()
        retryButton.setTitle("Retry", for: .normal)
        retryButton.backgroundColor = .orange
        retryButton.tintColor = .white
        retryButton.layer.cornerRadius = 10
        retryButton.addTarget(self, action: #selector(self.retryWifiConnection), for: .touchUpInside)
        
        errorImageView.translatesAutoresizingMaskIntoConstraints = false
        errorMsgLabel.translatesAutoresizingMaskIntoConstraints = false
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.errorView = UIView()
        self.errorView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.errorView)
        NSLayoutConstraint.activate([
            self.errorView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.errorView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.errorView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            self.errorView.heightAnchor.constraint(equalTo: self.view.heightAnchor),
        ])
        
        self.errorView.addSubview(errorImageView)
        self.errorView.addSubview(errorMsgLabel)
        self.errorView.addSubview(retryButton)
        
        NSLayoutConstraint.activate([
            errorImageView.widthAnchor.constraint(equalTo: self.errorView.widthAnchor, multiplier: 0.3),
            errorImageView.heightAnchor.constraint(equalTo: errorImageView.widthAnchor),
            errorImageView.centerXAnchor.constraint(equalTo: self.errorView.centerXAnchor),
            errorImageView.centerYAnchor.constraint(equalTo: self.errorView.centerYAnchor),
            
            errorMsgLabel.widthAnchor.constraint(equalTo: self.errorView.widthAnchor, multiplier: 0.5),
            errorMsgLabel.centerXAnchor.constraint(equalTo: self.errorView.centerXAnchor),
            errorMsgLabel.topAnchor.constraint(equalTo: errorImageView.bottomAnchor, constant: 20),
        
            retryButton.widthAnchor.constraint(equalTo: self.errorView.widthAnchor, multiplier: 0.2),
            retryButton.heightAnchor.constraint(equalTo: self.errorView.heightAnchor, multiplier: 0.05),
            retryButton.centerXAnchor.constraint(equalTo: self.errorView.centerXAnchor),
            retryButton.topAnchor.constraint(equalTo: errorMsgLabel.bottomAnchor, constant: 20),
        ])
    }
    
    
    @objc func retryWifiConnection() {
        errorView?.subviews.forEach { $0.removeFromSuperview() }
        errorView?.removeFromSuperview()
        
        forecastsGrid = nil
        collectionView?.removeFromSuperview()
        collectionView = nil
        
        tryToLoad()
    }
    
    func loadCitydata() {
        let weatherDAO = WeatherDAO()
        let cities = weatherDAO.fetchCityInfo(name: message)
        
        guard let city = cities?.first else {
            forecastsGrid = []
            return
        }
        
        let curlat = city.lat
        let curlon = city.lon
        
        guard let forecasts = weatherDAO.fetch5DaysWeather(lat: curlat, lon: curlon) else {
            forecastsGrid = []
            return
        }
        
        var predGrid: [[ForecastItem]] = []
        var currentList: [ForecastItem] = []
        var currentPrefix = forecasts.list.first?.dt_txt.prefix(10)
        
        for forecast in forecasts.list {
            let forecastPrefix = forecast.dt_txt.prefix(10)
            
            if forecastPrefix == currentPrefix {
                currentList.append(forecast)
            } else {
                predGrid.append(currentList)
                currentList = [forecast]
                currentPrefix = forecastPrefix
            }
        }
        predGrid.append(currentList)
        
        forecastsGrid = predGrid
    }
    
    func setupCustomNavigationBar() {
        let navigationBar = UINavigationBar()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(navigationBar)
        NSLayoutConstraint.activate([
            navigationBar.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            navigationBar.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.1),
            navigationBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 60),
            navigationBar.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
        ])
        
        let statusBarHeight = UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        navigationBar.frame.origin.y = statusBarHeight
        
        let navigationItem = UINavigationItem()
        
        let titleLabel = UILabel()
        titleLabel.text = "Forecast"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        navigationItem.titleView = titleLabel
        
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        backButton.tintColor = .yellow
        backButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        let backBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = backBarButtonItem
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        
        navigationBar.items = [navigationItem]
        
        view.addSubview(navigationBar)
        navBar = navigationBar
    }


    @objc func backButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func setUpBckgGradient(){
        let gradientLayer = CAGradientLayer()
        let botColor = CGColor(red: 60/255, green: 80/255, blue: 115/255, alpha: 1.0)
        let topColor = getLighterColor(baseColor: botColor)
        gradientLayer.colors = [
            topColor,
            botColor
        ]
        gradientLayer.frame = self.view.bounds
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupUI() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(ForecastHeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderCell")
        collectionView.register(ForecastItemCell.self, forCellWithReuseIdentifier: "ItemCell")
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collectionView.widthAnchor.constraint(equalTo: view.widthAnchor),
            collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.8)
        ])
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension ForecastViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in colectionView: UICollectionView) -> Int {
        return forecastsGrid.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return forecastsGrid[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let forecast = forecastsGrid[indexPath.section][indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as! ForecastItemCell
        cell.configure(with: forecast, with: self.weatherIcons)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                    withReuseIdentifier: "HeaderCell",
                                                                    for: indexPath) as! ForecastHeaderCell
        let dayForecast = forecastsGrid[indexPath.section].first
        header.configure(with: dayForecast!.dt_txt)
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 40)
    }
}

class ForecastItemCell: UICollectionViewCell {
    private let timeLabel = UILabel()
    private let weatherIcon = UIImageView()
    private let conditionLabel = UILabel()
    private let temperatureLabel = UILabel()
    private var weattherIcons: WeatherImageService! = WeatherImageService()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 0.1525
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        [timeLabel, weatherIcon, conditionLabel, temperatureLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        timeLabel.textColor = .white
        conditionLabel.textColor = .white
        temperatureLabel.textColor = UIColor(red: 1, green: 1, blue: 0, alpha: 1.0)
        
        NSLayoutConstraint.activate([
            weatherIcon.widthAnchor.constraint(equalToConstant: 50),
            weatherIcon.heightAnchor.constraint(equalToConstant: 50),
            weatherIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            weatherIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            timeLabel.leadingAnchor.constraint(equalTo: weatherIcon.trailingAnchor, constant: 16),
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            
            conditionLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 5),
            conditionLabel.leadingAnchor.constraint(equalTo: weatherIcon.trailingAnchor, constant: 16),
            
            temperatureLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            temperatureLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with forecast: ForecastItem, with icons: WeatherImageService) {
        let fullDate = forecast.dt_txt
        let cutHour = fullDate.components(separatedBy: " ")[1]
        let trueHour = String(cutHour.prefix(5))
        
        self.weattherIcons = icons
        timeLabel.text = trueHour
        conditionLabel.text = forecast.weather.first?.description
        temperatureLabel.text = "\(forecast.main.temp)°C"
        weatherIcon.image = weatherIcon(condition: conditionLabel.text!)
        weatherIcon.tintColor = .yellow
    }
    
    func weatherIcon(condition: String) -> UIImage? {
        return self.weattherIcons!.getFromCache(for: condition)
    }

}

class ForecastHeaderCell: UICollectionViewCell {
    private let dayLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dayLabel)
        
        dayLabel.textColor = UIColor(red: 1, green: 1, blue: 0, alpha: 1.0)
        dayLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        
        NSLayoutConstraint.activate([
            dayLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dayLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func configure(with date: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let cutDate = date.components(separatedBy: " ").first
        if let dateStruct = formatter.date(from: cutDate!){
            let calendar = Calendar(identifier: .gregorian)
            let weekday = calendar.component(.weekday, from: dateStruct)
            let weekdaySymbols = calendar.weekdaySymbols
            dayLabel.text = weekdaySymbols[weekday-1] + " " + cutDate!
        } else {
            dayLabel.text = "Huh?"
        }
    }
}
