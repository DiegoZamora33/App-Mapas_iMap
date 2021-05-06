//
//  ViewController.swift
//  iMap
//
//  Created by Diego Zamora on 03/05/21.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    //MARK: - Variables y Outlets
    @IBOutlet weak var miMapa: MKMapView!
    @IBOutlet weak var boxSearch: UISearchBar!
    
    var miUbicacion: CLLocation?
    
    
    //MARK: - Managers
    var coreLocation = CLLocationManager()
    
    
    
    //MARK: - DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// MKMapViewDelegate
        miMapa.delegate = self
        
        /// Search Bar Delegate
        boxSearch.delegate = self
        
        /// CoreLocation Delegate
        coreLocation.delegate = self
        
        /// Permiso de Ubicacion
        coreLocation.requestWhenInUseAuthorization()
        coreLocation.requestLocation()
        
        /// La mejor presicion porfis
        coreLocation.desiredAccuracy = kCLLocationAccuracyBest
        
        /// Iniciar la actualizacino de Localizacion
        coreLocation.startUpdatingLocation()
    }
    
    
    //MARK: - Get GPS Button
    @IBAction func getGPS(_ sender: UIButton) {
        print("Lat: \(miUbicacion?.coordinate.latitude ?? 0) - Long: \(miUbicacion?.coordinate.longitude ?? 0)")
        
        let spanMapa = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        
        let region = MKCoordinateRegion(center: miUbicacion!.coordinate, span: spanMapa)
        
        miMapa.setRegion(region, animated: true)
        miMapa.showsUserLocation = true
        
    }

}


//MARK: - Extension CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate{
    
    /// Did Update Locations
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let ubicacion = locations.first {
            self.miUbicacion = ubicacion
        }
        
    }
    
    
    /// Did Fail with Error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener coordenadas \(error.localizedDescription)")
    }
}


//MARK: - Extension para UISearchBar
extension ViewController: UISearchBarDelegate
{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        boxSearch.resignFirstResponder()
        
        let geocoder = CLGeocoder()
        
        if let direccion = boxSearch.text {
            geocoder.geocodeAddressString(direccion) { (places: [CLPlacemark]?, error: Error?) in
                
                /// Crear el Destino
                guard let destinoRuta = places?.first?.location else {
                    return
                }
                
                if error == nil
                {
                    /// Buscar en el MAPA
                    let lugar = places?.first
                    let anotacion = MKPointAnnotation()
                    
                    anotacion.coordinate = (lugar?.location?.coordinate)!
                    
                    anotacion.title = direccion
                    
                    let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    
                    let region = MKCoordinateRegion(center: anotacion.coordinate, span: span)
                    
                    self.miMapa.setRegion(region, animated: true)
                    self.miMapa.addAnnotation(anotacion)
                    self.miMapa.selectAnnotation(anotacion, animated: true)
                    
                    /// Mandar llamar a Trazar Ruta
                    self.trazarRuta(destino: destinoRuta.coordinate)
                }
                else
                {
                    print("Error al Buscar... '\(String(describing: error?.localizedDescription))'")
                }
            }
        }
    }
}


//MARK: - Extension MKMapViewDelegate
extension ViewController: MKMapViewDelegate {
    
    /// Funcion para trazar Ruta
    func trazarRuta(destino: CLLocationCoordinate2D) {
        guard let origen = coreLocation.location?.coordinate else { return }
        
        /// Crear PlaceMarks
        let origenPlaceMark = MKPlacemark(coordinate: origen)
        let destinoPlaceMark = MKPlacemark(coordinate: destino)
        
        /// Crear ITEMs
        let origenItem = MKMapItem(placemark: origenPlaceMark)
        let destinoItem = MKMapItem(placemark: destinoPlaceMark)
        
        /// Solicitud de Ruta
        let solicitudDestino = MKDirections.Request()
        solicitudDestino.source = origenItem
        solicitudDestino.destination = destinoItem
        
        /// Medio de Transporte
        solicitudDestino.transportType = .automobile
        solicitudDestino.requestsAlternateRoutes = true
        
        /// Calcular la Ruta
        let address = MKDirections(request: solicitudDestino)
        address.calculate { (respuesta: MKDirections.Response?, error: Error?) in
            
            /// Variable Segura
            guard let respuestaSegura = respuesta else {
                if let error = error {
                    print("Sucedió un Error: \(error.localizedDescription)")
                }
                return
            }
            
            /// Si todo sale bien
            let ruta = respuestaSegura.routes[0]
            
            /// Agregar Anotation Punto Medio
            let routeAnnotation = MKPointAnnotation()
            
            let middlePoint = ruta.polyline.points()[ruta.polyline.pointCount].coordinate
            
            
            routeAnnotation.coordinate = middlePoint
            routeAnnotation.title = "Distancia"
            routeAnnotation.subtitle = "\(ruta.distance) m"
            
            
            self.miMapa.addAnnotation(routeAnnotation)

            
            /// Agregar al Mapa una Superposicion
            self.miMapa.addOverlay(ruta.polyline)
            self.miMapa.setVisibleMapRect(ruta.polyline.boundingMapRect, animated: true)
            
        }
    }
    
    
    /// Funcion para Agregar la SuperPosicion al Mapa
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderizado = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        
        renderizado.strokeColor = .systemBlue
        
        
        return renderizado
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation.title == "YO"
        {
            return nil
        }
        else
        {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            
            view.
                view.animatesDrop = true
                view.canShowCallout = true
                return view;
        }
    }
}
