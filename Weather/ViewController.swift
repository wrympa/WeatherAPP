//
//  ViewController.swift
//  Weather
//
//  Created by sento kiryu on 2/8/25.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return places.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CustomCell
        cell.configure(information:places[indexPath.row])
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        cell.addGestureRecognizer(longPressGestureRecognizer)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        cell.addGestureRecognizer(tapGestureRecognizer)
        
        return cell
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer){
        if gesture.state == .began{
            let alert = UIAlertController(title: "Delete city?", message: "Are you sure?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                PersistentDAO.shared.removePlace(named: self.placesStrings[self.collectionView.indexPath(for: gesture.view as! CustomCell)!.row].name!)
                self.collectionView.removeFromSuperview()
                self.pageControl.removeFromSuperview()
                self.setUpMainViews()
            }))
            present(alert, animated: true, completion: nil)
            
        }
    }
    
    @objc func handleTap(_ gesture: UILongPressGestureRecognizer){
        guard let cell = gesture.view as? CustomCell else {return}
        if let forecastView = storyboard?.instantiateViewController(identifier: "5day") as? ForecastViewController{
            forecastView.modalPresentationStyle = .fullScreen
            forecastView.setName(cityName: cell.cityName)
            present(forecastView, animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        let width = collectionView.frame.width * 0.9
        let height = collectionView.frame.height * 0.95
        return CGSize(width: width, height: height)
    }
    
    
    @IBOutlet var botView: UIView!
    @IBOutlet var topView: UIView!
    
    private var collectionView: UICollectionView!
    private var pageControl: UIPageControl!
    private var places: [(CityResponse, WeatherResponse)]!
    private var placesStrings: [PlaceEntity]!
    private var popupView: UIView!
    private var blurEffectView: UIVisualEffectView!
    private var textField: UITextField!
    private var addErrorView: UIView!
    private var errorView: UIView!
    private let locationManager = LocationManager()
    private var permissionSemaphore: DispatchSemaphore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUpBckgGradient()
        locationManager.setCallable(from: self)
        askForPermission()
    }
    
    @objc func retryWifiConnection(){
        if let cv = collectionView{
            cv.removeFromSuperview()
        }
        if let pg = pageControl{
            pg.removeFromSuperview()
        }
        errorView.subviews.forEach({$0.removeFromSuperview()})
        errorView.removeFromSuperview()
        setUpMainViews()
    }
    
    
    func setUpMainViews(){
        let spinningCircle = UIActivityIndicatorView(style: .large)
        spinningCircle.color = .yellow
        spinningCircle.translatesAutoresizingMaskIntoConstraints = false
        self.botView.addSubview(spinningCircle)
        NSLayoutConstraint.activate([
            spinningCircle.centerXAnchor.constraint(equalTo: self.botView.centerXAnchor),
            spinningCircle.centerYAnchor.constraint(equalTo: self.botView.centerYAnchor)
        ])
        spinningCircle.startAnimating()
        
        var networked = true
        
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                self.places = self.getCityAndWeatherInfo()
                spinningCircle.stopAnimating()
                spinningCircle.removeFromSuperview()
                if self.places.count == 0{
                    networked = false
                    self.showNoWifiError()
                }
            }
            if(!networked){
                return
            }
            
            DispatchQueue.main.async {
                self.setUpCollectionViews()
            }
        }
        if(!networked){
            return
        }
    }
    
    func showNoWifiError(){
        self.botView.subviews.forEach({$0.removeFromSuperview()})
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
    
    @objc func retryPermissions(){
        if let cv = collectionView{
            cv.removeFromSuperview()
        }
        if let pg = pageControl{
            pg.removeFromSuperview()
        }
        errorView.subviews.forEach({$0.removeFromSuperview()})
        errorView.removeFromSuperview()
        askForPermission()
    }
    
    
    func showNoPermissionsError(){
        self.botView.subviews.forEach({$0.removeFromSuperview()})
        let errorImageView = UIImageView(image: UIImage(systemName: "cloud.bolt.rain"))
        errorImageView.tintColor = .orange
        let errorMsgLabel = UILabel()
        errorMsgLabel.text = "We'll need those permissions, sorry :(((("
        errorMsgLabel.textColor = .white
        errorMsgLabel.textAlignment = .center
        
        errorImageView.translatesAutoresizingMaskIntoConstraints = false
        errorMsgLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        NSLayoutConstraint.activate([
            errorImageView.widthAnchor.constraint(equalTo: self.errorView.widthAnchor, multiplier: 0.3),
            errorImageView.heightAnchor.constraint(equalTo: errorImageView.widthAnchor),
            errorImageView.centerXAnchor.constraint(equalTo: self.errorView.centerXAnchor),
            errorImageView.centerYAnchor.constraint(equalTo: self.errorView.centerYAnchor),
            
            errorMsgLabel.widthAnchor.constraint(equalTo: self.errorView.widthAnchor),
            errorMsgLabel.centerXAnchor.constraint(equalTo: self.errorView.centerXAnchor),
            errorMsgLabel.topAnchor.constraint(equalTo: errorImageView.bottomAnchor, constant: 20)
        ])
    }
    
    func setUpCollectionViews() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        let horizontalInset = botView.bounds.width*0.05
        layout.sectionInset = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .none
        
        pageControl = UIPageControl()
        
        setUpScrollView()
        setUpPageControl()
    }
    
    @IBAction func reload(){
        collectionView.removeFromSuperview()
        pageControl.removeFromSuperview()
        botView.subviews.forEach({$0.removeFromSuperview()})
        setUpMainViews()
    }
    
    @IBAction func add(){
        addErrorView = UIView()
        let blurEffect = UIBlurEffect(style: .dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.alpha = 0.6
        let blurTap = UITapGestureRecognizer(target: self, action: #selector(dismissPopup))
        blurEffectView.addGestureRecognizer(blurTap)
        blurEffectView.frame = view.bounds
        view.addSubview(blurEffectView)
        
        popupView = UIView()
        
        let gradientLayer = CAGradientLayer()
        let topColor = CGColor(red: 147/255, green: 219/255, blue: 175/255, alpha: 1.0)
        let botColor = CGColor(red: 91/255, green: 170/255, blue: 151/255, alpha: 1.0)
        gradientLayer.colors = [
            topColor,
            botColor
        ]
        gradientLayer.frame = self.view.bounds
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.cornerRadius = 10
        popupView.layer.insertSublayer(gradientLayer, at: 0)
        
        popupView.layer.cornerRadius = 10
        popupView.layer.masksToBounds = true
        
        let label1 = UILabel()
        label1.font = UIFont.systemFont(ofSize: 20)
        label1.text = "Add city"
        label1.textColor = .white
        label1.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(label1)
        let label2 = UILabel()
        label2.text = "Enter the city's name"
        label2.textColor = .white
        label2.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(label2)
        
        
        textField = UITextField()
        textField.placeholder = "Enter text"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(textField)
        
        
        let plusButton = UIButton()
        plusButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        plusButton.addTarget(self, action: #selector(plusButtonTapped(_:)), for: .touchUpInside)
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        plusButton.tintColor = .white
        plusButton.contentVerticalAlignment = .fill
        plusButton.contentHorizontalAlignment = .fill
        popupView.addSubview(plusButton)
        
        NSLayoutConstraint.activate([
            label1.widthAnchor.constraint(equalTo: popupView.widthAnchor, multiplier: 0.9),
            label1.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 5),
            label1.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            
            label2.widthAnchor.constraint(equalTo: popupView.widthAnchor, multiplier: 0.9),
            label2.topAnchor.constraint(equalTo: label1.bottomAnchor, constant: 10),
            label2.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            
            textField.widthAnchor.constraint(equalTo: popupView.widthAnchor, multiplier: 0.9),
            textField.topAnchor.constraint(equalTo: label2.bottomAnchor, constant: 5),
            textField.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            
            plusButton.widthAnchor.constraint(equalTo: popupView.widthAnchor, multiplier: 0.2),
            plusButton.heightAnchor.constraint(equalTo: plusButton.widthAnchor),
            plusButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 15),
            plusButton.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            
        ])
        
        popupView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(popupView)
        
        NSLayoutConstraint.activate([
            popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popupView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            popupView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2),
        ])
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPopup))
        blurEffectView.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissPopup() {
        UIView.animate(withDuration: 0.3, animations: {
            self.blurEffectView.alpha = 0
            self.popupView.alpha = 0
            self.addErrorView.alpha = 0
        }) { _ in
            self.blurEffectView.removeFromSuperview()
            self.popupView.removeFromSuperview()
            self.addErrorView.removeFromSuperview()
        }
        collectionView.removeFromSuperview()
        pageControl.removeFromSuperview()
        setUpMainViews()
    }
    
    @objc func plusButtonTapped(_ pb: UIButton) {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.center = CGPoint(x: pb.bounds.size.width/2, y: pb.bounds.size.height/2)
        
        pb.setImage(nil, for: .normal)
        pb.isEnabled = false
        
        pb.addSubview(activityIndicator)
        activityIndicator.frame = pb.bounds
        activityIndicator.startAnimating()
        
        
        
        DispatchQueue.main.async {
            let result = self.tryToFindCity()
            Thread.sleep(forTimeInterval: 5)

            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
            pb.isEnabled = true
            pb.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
            if result {
                self.dismissPopup()
            } else {
                self.showAddErrorView()
            }
        }
    }
    
    func tryToFindCity() -> Bool {
        addErrorView.removeFromSuperview()
        if var text = textField.text, !text.isEmpty {
            text = text.replacingOccurrences(of: " ", with: "_")
            let cities = WeatherDAO().fetchCityInfo(name: text)
            if cities!.count == 0{
                return false
            }
            PersistentDAO.shared.addCity(name: cities!.first!.name)
            return true
        }
        return false
    }
    
    func showAddErrorView() {
        addErrorView.removeFromSuperview()
        addErrorView = UIView()
        addErrorView.backgroundColor = .red
        
        let label1 = UILabel()
        label1.font = UIFont.systemFont(ofSize: 20)
        label1.text = "Error Occured"
        label1.textColor = .white
        label1.translatesAutoresizingMaskIntoConstraints = false
        addErrorView.addSubview(label1)
        let label2 = UILabel()
        label2.text = "That city likely doesn't exist or you lost connection"
        label2.numberOfLines = 2
        label2.textColor = .white
        label2.translatesAutoresizingMaskIntoConstraints = false
        addErrorView.addSubview(label2)
        NSLayoutConstraint.activate([
            label1.widthAnchor.constraint(equalTo: addErrorView.widthAnchor, multiplier: 0.9),
            label1.topAnchor.constraint(equalTo: addErrorView.topAnchor, constant: 5),
            label1.leadingAnchor.constraint(equalTo: addErrorView.leadingAnchor, constant: 10),
            
            label2.widthAnchor.constraint(equalTo: addErrorView.widthAnchor, multiplier: 0.9),
            label2.topAnchor.constraint(equalTo: label1.bottomAnchor, constant: 10),
            label2.leadingAnchor.constraint(equalTo: addErrorView.leadingAnchor, constant: 10),
        ])
        
        
        
        addErrorView.layer.cornerRadius = 10
        addErrorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addErrorView)
        
        NSLayoutConstraint.activate([
            addErrorView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            addErrorView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.1),
            addErrorView.bottomAnchor.constraint(equalTo: popupView.topAnchor, constant: -100),
            addErrorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    func setUpPageControl(){
        pageControl.numberOfPages = places.count
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = .yellow
        pageControl.pageIndicatorTintColor = .white
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(pageControl)
        NSLayoutConstraint.activate([
            pageControl.widthAnchor.constraint(equalTo: topView.widthAnchor, multiplier: 0.4),
            pageControl.heightAnchor.constraint(equalTo: topView.heightAnchor),
            pageControl.centerXAnchor.constraint(equalTo: topView.centerXAnchor),
            pageControl.centerYAnchor.constraint(equalTo: topView.centerYAnchor)
        ])
    }
    
    func setUpScrollView(){
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CustomCell.self, forCellWithReuseIdentifier: "cell")
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        botView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.widthAnchor.constraint(equalTo: botView.widthAnchor),
            collectionView.heightAnchor.constraint(equalTo: botView.heightAnchor),
            collectionView.centerXAnchor.constraint(equalTo: botView.centerXAnchor),
            collectionView.centerYAnchor.constraint(equalTo: botView.centerYAnchor)
        ])
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let itemWidth = collectionView.frame.width * 0.9
        let spacing = collectionView.frame.width * 0.05
        let itemSpacing = itemWidth + spacing

        let targetX = targetContentOffset.pointee.x
        let estimatedIndex = (targetX + scrollView.frame.width / 2 - itemWidth / 2) / itemSpacing

        let targetIndex = round(estimatedIndex)

        let maxIndex = round(scrollView.contentSize.width / itemSpacing) - 1
        let clampedIndex = max(0, min(maxIndex, targetIndex))

        let xOffset = clampedIndex * itemSpacing - (scrollView.frame.width - itemWidth) / 2
        targetContentOffset.pointee.x = max(0, min(scrollView.contentSize.width - scrollView.frame.width, xOffset))
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let centerX = collectionView.contentOffset.x + collectionView.frame.size.width / 2
        let visibleRect = CGRect(x: centerX - collectionView.frame.size.width / 2, y: 0, width: collectionView.frame.size.width, height: collectionView.frame.size.height)

        for cell in collectionView.visibleCells {
            let cellCenterX = cell.center.x
            let distance = abs(cellCenterX - centerX)
            let scale: CGFloat = max(0.9, 1 - (distance / collectionView.frame.size.width) * 0.2)
            cell.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        let pageIndex = round(scrollView.contentOffset.x / view.frame.width)
        pageControl.currentPage = Int(pageIndex)
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
    
    func askForPermission(){
        permissionSemaphore = DispatchSemaphore(value: 0)
        locationManager.requestLocationPermission()
    }
    
    func finish(){
        if let cv = collectionView{
            cv.removeFromSuperview()
        }
        if let pg = pageControl{
            pg.removeFromSuperview()
        }
        if let ev = errorView{
            ev.subviews.forEach({
                $0.removeFromSuperview()})
            ev.removeFromSuperview()
        }
        let currentPlace = locationManager.nameOfCity
        if let place = currentPlace {
            let newName = place.replacingOccurrences(of: " ", with: "_")
            PersistentDAO.shared.removePlace(named: newName)
            PersistentDAO.shared.addCity(name: newName)
        } else {
        }
        setUpMainViews()
    }
    
    func getCityAndWeatherInfo() -> [(CityResponse, WeatherResponse)]{
//        permissionSemaphore.wait()
        let weatherDAO = WeatherDAO()
        let places = PersistentDAO.shared.fetchPlaces()
        placesStrings = places
        var result: [(CityResponse, WeatherResponse)] = []
        for place in places{
            place.name = place.name?.replacingOccurrences(of: " ", with: "_")
            guard let cityName = place.name else {continue}
            var curlat = 0.0
            var curlon = 0.0
            let cities = weatherDAO.fetchCityInfo(name: cityName)
            if cities?.count == 0{
                return []
            }
            if let city = cities?.first {
                curlat = city.lat
                curlon = city.lon
                let weather = weatherDAO.fetchWeather(lat: curlat, lon: curlon)
                if let weather = weather {
                    result.append((city, weather))
                }
            }

        }
        return result
    }


}


class CustomCell: UICollectionViewCell {
    private let ovrImage = UIImageView()
    private let locationLabel = UILabel()
    private let weatherLabel = UILabel()
    private let botInfoView1 = UIView()
    private let botInfoView2 = UIView()
    private let botInfoView3 = UIView()
    private let botInfoView4 = UIView()
    public var cityName = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func addToTabView(tabView: UIView, icon: UIImage, param: String, value: String){
        let imageView = UIImageView(image: icon)
        imageView.tintColor = .yellow
        let paramView = UILabel()
        paramView.text = param
        paramView.textColor = .white
        let valueView = UILabel()
        valueView.text = value
        valueView.textColor = .yellow
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        paramView.translatesAutoresizingMaskIntoConstraints = false
        valueView.translatesAutoresizingMaskIntoConstraints = false
        tabView.addSubview(imageView)
        tabView.addSubview(paramView)
        tabView.addSubview(valueView)
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: tabView.centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: tabView.leadingAnchor, constant: 5),
            
            paramView.centerYAnchor.constraint(equalTo: tabView.centerYAnchor),
            paramView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 5),
            
            valueView.centerYAnchor.constraint(equalTo: tabView.centerYAnchor),
            valueView.trailingAnchor.constraint(equalTo: tabView.trailingAnchor, constant: -5),
        ])
    }
    

    
    func configure(information: (CityResponse, WeatherResponse)) {
        [botInfoView1, botInfoView2, botInfoView3, botInfoView4].forEach { view in
            view.subviews.forEach { $0.removeFromSuperview() }
        }
        contentView.subviews.forEach({$0.removeFromSuperview()})
        layer.sublayers?.forEach({
            if $0 is CAGradientLayer{
                $0.removeFromSuperlayer()
            }
        })
        
        let cityResponse = information.0
        let weatherResponse = information.1
        
        ovrImage.image = weatherIcon(for: weatherResponse.weather.first!.main)
        ovrImage.tintColor = .yellow
        ovrImage.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ovrImage)
        
        self.cityName = cityResponse.name.replacingOccurrences(of: " ", with: "_")
        locationLabel.text = cityResponse.name+", "+cityResponse.country
        locationLabel.textAlignment = .center
        locationLabel.font = UIFont.boldSystemFont(ofSize: 24)
        locationLabel.textColor = .white
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(locationLabel)
        
        weatherLabel.text = String(round(weatherResponse.main.temp)) + "°C | " + weatherResponse.weather.first!.main
        weatherLabel.textAlignment = .center
        weatherLabel.font = UIFont.boldSystemFont(ofSize: 24)
        weatherLabel.textColor = .yellow
        weatherLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(weatherLabel)
        
        botInfoView1.translatesAutoresizingMaskIntoConstraints = false
        botInfoView2.translatesAutoresizingMaskIntoConstraints = false
        botInfoView3.translatesAutoresizingMaskIntoConstraints = false
        botInfoView4.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(botInfoView1)
        contentView.addSubview(botInfoView2)
        contentView.addSubview(botInfoView3)
        contentView.addSubview(botInfoView4)
        
        NSLayoutConstraint.activate([
            ovrImage.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.4),
            ovrImage.heightAnchor.constraint(equalTo: ovrImage.widthAnchor),
            ovrImage.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            ovrImage.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            
            locationLabel.widthAnchor.constraint(equalTo: self.widthAnchor),
            locationLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            locationLabel.topAnchor.constraint(equalTo: ovrImage.bottomAnchor, constant: 5),
            
            weatherLabel.widthAnchor.constraint(equalTo: self.widthAnchor),
            weatherLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            weatherLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 5),
            
            botInfoView1.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.9),
            botInfoView1.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.1),
            botInfoView1.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            botInfoView1.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
            
            botInfoView2.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.9),
            botInfoView2.heightAnchor.constraint(equalTo: botInfoView1.heightAnchor),
            botInfoView2.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            botInfoView2.bottomAnchor.constraint(equalTo: botInfoView1.topAnchor),
            
            botInfoView3.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.9),
            botInfoView3.heightAnchor.constraint(equalTo: botInfoView1.heightAnchor),
            botInfoView3.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            botInfoView3.bottomAnchor.constraint(equalTo: botInfoView2.topAnchor),
            
            botInfoView4.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.9),
            botInfoView4.heightAnchor.constraint(equalTo: botInfoView1.heightAnchor),
            botInfoView4.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            botInfoView4.bottomAnchor.constraint(equalTo: botInfoView3.topAnchor),
        ])
        
        self.addToTabView(tabView: botInfoView4, icon: UIImage(systemName: "cloud.drizzle.fill")!, param: "Cloudiness", value: String(weatherResponse.clouds.all)+"%")
        self.addToTabView(tabView: botInfoView3, icon: UIImage(systemName: "drop.fill")!, param: "Humidity", value: String(weatherResponse.main.humidity)+"mm")
        self.addToTabView(tabView: botInfoView2, icon: UIImage(systemName: "wind")!, param: "Wind Speed", value: String(weatherResponse.wind.speed)+"M/S")
        let direction = windDirection(for: Double(weatherResponse.wind.deg))
        self.addToTabView(tabView: botInfoView1, icon: UIImage(systemName: "safari")!, param: "Wind Direction", value: direction)
        
        
        let namehash = abs(cityResponse.name.utf8.reduce(0) { $0 + Int($1) }) % 4
        
        var topColor: CGColor = UIColor.red.cgColor
        var botColor: CGColor = UIColor.blue.cgColor
        if namehash == 0{
            topColor = getLighterColor(baseColor: UIColor.red.cgColor)
            botColor = getLighterColor(baseColor: topColor)
        } else if namehash == 1 {
            topColor = getLighterColor(baseColor: UIColor.blue.cgColor)
            botColor = getLighterColor(baseColor: topColor)
        } else if namehash == 2 {
            topColor = getLighterColor(baseColor: UIColor(cgColor: CGColor(red: 0.0, green: 0.392, blue: 0.0, alpha: 1.0)).cgColor)
            botColor = getLighterColor(baseColor: topColor)
        } else if namehash == 3 {
            topColor = getLighterColor(baseColor: UIColor.orange.cgColor)
            botColor = getLighterColor(baseColor: topColor)
        }
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            topColor,
            botColor
        ]
        gradientLayer.frame = self.bounds
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.cornerRadius = 50
        self.layer.insertSublayer(gradientLayer, at: 0)
        
        self.layer.cornerRadius = 50
        
        self.layer.shadowColor = topColor
        self.layer.shadowOpacity = 0.8
        self.layer.shadowRadius = 20
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.masksToBounds = false
        
    }
}

extension UICollectionView {
    var centerIndexPath: IndexPath? {
        let centerPoint = CGPoint(x: contentOffset.x + bounds.width / 2, y: bounds.height / 2)
        return indexPathForItem(at: centerPoint)
    }
}

func weatherIcon(for condition: String) -> UIImage? {
    var iconName: String
    
    switch condition.lowercased() {
    case "clear":
        iconName = "sun.max.fill"
    case "clouds":
        iconName = "cloud.fill"
    case "rain":
        iconName = "cloud.rain.fill"
    case "snow":
        iconName = "cloud.snow.fill"
    case "thunderstorm":
        iconName = "cloud.bolt.rain.fill"
    case "drizzle":
        iconName = "cloud.drizzle.fill"
    case "fog":
        iconName = "cloud.fog.fill"
    default:
        iconName = "questionmark.circle.fill"
    }
    
    return UIImage(systemName: iconName)
}

func getLighterColor(baseColor: CGColor) -> CGColor{
    guard let components = baseColor.components else {return baseColor}
    
    let red = min(components[0] + (1-components[0])*0.2, 1.0)
    let green = min(components[1] + (1-components[1])*0.2, 1.0)
    let blue = min(components[2] + (1-components[2])*0.2, 1.0)
    return CGColor(red: red, green: green, blue: blue, alpha: 1.0)
}

func windDirection(for degrees: Double) -> String {
    switch degrees {
    case 0..<22.5, 337.5..<360:
        return "N"   // North
    case 22.5..<67.5:
        return "NE"  // North-East
    case 67.5..<112.5:
        return "E"   // East
    case 112.5..<157.5:
        return "SE"  // South-East
    case 157.5..<202.5:
        return "S"   // South
    case 202.5..<247.5:
        return "SW"  // South-West
    case 247.5..<292.5:
        return "W"   // West
    case 292.5..<337.5:
        return "NW"  // North-West
    default:
        return "Unknown"
    }
}
