//
//  OnibusViewController.swift
//  Transito Rio
//
//  Created by Rodrigo Amora on 29/11/23.
//

import UIKit
import MapKit
import CoreLocation

class OnibusViewController: BaseViewController {

    // MARK: - @IBOutlets
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var btnAllocationType: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var onibusMapView: MKMapView!
    
    // MARK: - Atributes
    private let locationManager = CLLocationManager()
    private var latitude: Double = 0.0
    private var longitude: Double = 0.0
    private var listaOnibus: [Onibus] = []
    private lazy var onibusViewModel: OnibusViewModel = OnibusViewModel(onibusDelegate: self)
    
    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configurarNavBar()
        self.configurarDelegates()
        self.atualizarLocalizacao()
    }
    
    // MARK: - Methods
    private func configurarDelegates() {
        self.onibusMapView.delegate = self
    }
    
    private func configurarNavBar() {
        let menuSobre = UIAction(title: String(localized: "menu_about"), image: UIImage(systemName: "info.circle")) { _ in
            print("AAAAAA")
        }
        
        self.btnAllocationType.image = UIImage(systemName: "text.justify")
        self.btnAllocationType.menu = UIMenu(title: "", children: [menuSobre])
        
        self.navBar.topItem?.title = String(localized: "app_name")
    }
    
    private func centralizarMapView() {
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        //let region = MKCoordinateRegion(center: coordinates, span: span)
        let region = MKCoordinateRegion( center: coordinates, latitudinalMeters: CLLocationDistance(exactly: 1500)!, longitudinalMeters: CLLocationDistance(exactly: 1500)!)
        
        self.onibusMapView.setRegion(region, animated: true)
        self.onibusMapView.showsUserLocation = true
    }
    
    private func buscarOnibus() {
        self.activityIndicatorView.configureActivityIndicatorView()
        self.onibusViewModel.buscarOnibus()
    }
    
    private func limparMapa() {
        if self.onibusMapView.annotations.count > 0 {
            self.onibusMapView.removeAnnotations(self.onibusMapView.annotations)
        }
    }
    
    private func atualizarLocalizacao() {
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()

        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            self.locationManager.startUpdatingLocation()
        }
    }
    
    private func populateMapView(listaOnibus: [Onibus]) {
        for onibus in self.listaOnibus {
            let latitude = Double(onibus.latitude.replacingOccurrences(of: ",", with: ".")) ?? 0.0
            let longitude = Double(onibus.longitude.replacingOccurrences(of: ",", with: ".")) ?? 0.0
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            annotation.title = "\(String(localized: "numero_carro")) \(onibus.ordem) - \(String(localized: "linha_carro")) \(onibus.linha)"
            
            self.onibusMapView.addAnnotation(annotation)
        }
    }
    
    private func agendarPoximaBusca() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            self.buscarOnibus()
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension OnibusViewController: CLLocationManagerDelegate {
    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {}
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        self.latitude = locValue.latitude
        self.longitude = locValue.longitude
        self.centralizarMapView()
        self.buscarOnibus()
    }
}

// MARK: - MKMapViewDelegate
extension OnibusViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
//        guard annotation is Salon else { return nil }

        let identifier = "Onibus"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            
            let btn = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = btn
        } else {
            annotationView?.annotation = annotation
        }

        return annotationView
    }
}

// MARK: - OnibusDelegate
extension OnibusViewController: OnibusDelegate {
    func populateMap(listaOnibus: [Onibus]) {
        self.activityIndicatorView.hideActivityIndicatorView()
        self.listaOnibus = listaOnibus
        self.limparMapa()
        self.populateMapView(listaOnibus: listaOnibus)
        self.agendarPoximaBusca()
    }
    
    func replaceAll(listaOnibus: [Onibus]) {}
    
    func showError() {
        self.activityIndicatorView.hideActivityIndicatorView()
        self.showAlert(title: "", message: String(localized: "sem_onibus"))
    }
}

