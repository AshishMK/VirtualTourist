//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Ashish Nautiyal on 2/13/19.
//  Copyright © 2019 Ashish  Nautiyal. All rights reserved.
//

import UIKit
import MapKit
import CoreData
class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Properties
    var dataController : DataController!
    var fetchedResultController : NSFetchedResultsController<Location>!
    var saveObserverToken: Any?
    
    
    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        configureToolbarItems()
        navigationItem.rightBarButtonItem = editButtonItem
        setMapview()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchResultController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultController = nil
    }
    
    
    // Settingup CoreData result for Map Pin Annotaions
    //Entity: Location
    fileprivate func setUpFetchResultController() {
        let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        do{
            try  fetchedResultController.performFetch()
            addMapAnnotations()
        }
        catch {
            fatalError("The fetch could not be performed : \(error.localizedDescription)")
        }
        
    }
    
    //MARK: Helper Methods
    // Helper method for adding annotaions on the Map
    func addMapAnnotations(){
        // We will create an MKPointAnnotation for each location in "Location entity array". The
        // point annotations will be stored in this array, and then provided to the map view.
        var annotations = [MKPointAnnotation]()
        
        // The "Location entity " array is loaded with the sample data below. We are using the dictionaries
        // to create map annotations. This would be more stylish if the dictionaries were being
        // used to create custom structs. Perhaps StudentLocation structs.
        for location in fetchedResultController.sections![0].objects! {
            let locationSaved : Location = location as! Location
            // Notice that the float values are being used to create CLLocationDegree values.
            // This is a version of the Double type.
            let lat = CLLocationDegrees(locationSaved.latitude)
            let long = CLLocationDegrees(locationSaved.longitude )
            
            // The lat and long are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            // Here we create the annotation and set its coordiate, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            // Finally we place the annotation in an array of annotations.
            annotations.append(annotation)
        }
        // When the array is complete, we add the annotations to the map.
        self.mapView.addAnnotations(annotations)
    }
    
    // -------------------------------------------------------------------------
    // MARK: - Map view data source
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        // Configure Annotation view
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Initializing map with saved state and adding long touch and map tap delegate for adding annotation
        setMapPreferences()
    }
    
    // Set touch delegate for long touch and tap gesture
    func setMapview(){
        let longPressGestureRecognized = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(gestureReconizer:)))
        longPressGestureRecognized.minimumPressDuration = 0.5
        longPressGestureRecognized.delaysTouchesBegan = true
        longPressGestureRecognized.delegate = self
        self.mapView.addGestureRecognizer(longPressGestureRecognized)
        let tapGestureRecognized = UITapGestureRecognizer(target: self, action: #selector(self.handlePress(gestureReconizer:)))
        tapGestureRecognized.delegate = self
        self.mapView.addGestureRecognizer(tapGestureRecognized)
        checkIfFirstLaunch()
    }
    
    // check and set map state if it app is open for first time else set the last saved state of map
    func checkIfFirstLaunch() {
        if UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            let lat =  UserDefaults.standard.double( forKey: "latitude")
            let long = UserDefaults.standard.double( forKey: "longitude")
            let longitudeDelta = UserDefaults.standard.double( forKey: "longitudeDelta")
            let latitudeDelta = UserDefaults.standard.double( forKey: "latitudeDelta")
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: long), span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
            mapView.setRegion(region, animated: false)
        }
        else {
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
            setMapPreferences()
        }
    }
    
    // set preferemnces for Map state
    func setMapPreferences(){
        UserDefaults.standard.set(mapView.region.center.latitude, forKey: "latitude")
        UserDefaults.standard.set(mapView.region.center.longitude, forKey: "longitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: "latitudeDelta")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: "longitudeDelta")
        UserDefaults.standard.synchronize()
    }
    
    // MARK : Helper method for Touch gesture delegate
    // Handle long press gesture if long press happen on an Annotation perform segue else add new annotation on selected location
    @objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == UIGestureRecognizerState.began {
            let touchLocation = gestureReconizer.location(in: mapView)
            var addLocation : Bool = true
            let locationCoordinate = mapView.convert(touchLocation,toCoordinateFrom: mapView)
            if let subview = mapView.hitTest(touchLocation, with: nil) {
                if subview is MKPinAnnotationView {
                    addLocation = false
                    openSegueForAnnotation(locationCoordinate, (subview as! MKAnnotationView).annotation!)
                    
                }
            }
            if addLocation && !isEditing {
                addAnnotation(locationCoordinate.latitude, locationCoordinate.longitude)
            }
            return
        }
        
    }
    
    // Handle tap gesture
    @objc func handlePress(gestureReconizer: UITapGestureRecognizer) {
        let touchLocation = gestureReconizer.location(in: mapView)
        let locationCoordinate = mapView.convert(touchLocation,toCoordinateFrom: mapView)
        // if tapped location on map is an annotation than perform segue for selected annotation
        if let subview = mapView.hitTest(touchLocation, with: nil) {
            if subview is MKPinAnnotationView {
                openSegueForAnnotation(locationCoordinate, (subview as! MKAnnotationView).annotation!)
            }
        }
        return
    }
    
    
    // Add location on long gesture
    func addAnnotation(_ latitude: Double, _ longitude: Double){
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        let backgroundContext : NSManagedObjectContext! = dataController.backgroundContext
        backgroundContext.perform {
            let backgroundLocation = Location(context: self.dataController.backgroundContext)
            backgroundLocation.latitude = latitude
            backgroundLocation.longitude = longitude
            backgroundLocation.createdAt = Date()
            try? backgroundContext.save()
        }
    }
    
    // open View Controller segue for the selected annotation
    func openSegueForAnnotation(_ coord1:CLLocationCoordinate2D, _ annotation: MKAnnotation){
        let locationFromTouch = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        var distances = [CLLocationDistance]()
        
        for location in fetchedResultController.sections![0].objects! {
            let loc = location as! Location
            distances.append(locationFromTouch.distance(from: CLLocation(latitude:loc.latitude, longitude: loc.longitude)))
        }
        let closest = distances.min()//shortest distance
        let position = distances.index(of: closest!)//index of shortest distance
        let aLocation = fetchedResultController.object(at:  IndexPath(row: position!, section: 0))
        
        if isEditing {
            let id = aLocation.objectID
            let backgroundContext : NSManagedObjectContext! = dataController.backgroundContext
            mapView.removeAnnotation(annotation)
            backgroundContext.perform {
                let backgroundLocation = backgroundContext.object(with: id)
                backgroundContext.delete(backgroundLocation)
                try? backgroundContext.save()
            }
        }
        else {
            performSegue(withIdentifier: "showImageCollection", sender: aLocation)
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showImageCollection" {
            if let vc = segue.destination as? ImageCollectionViewController {
                vc.location = sender as! Location
                vc.dataController = dataController
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: Toolbar
    func configureToolbarItems() {
        toolbarItems = makeToolbarItems()
    }
    
    /// Returns an array of toolbar items. Used to configure the view controller's
    /// `toolbarItems' property, and to configure an accessory view for the
    /// text view's keyboard that also displays these items.
    func makeToolbarItems() -> [UIBarButtonItem] {
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let collection = UIBarButtonItem(title: "Tap Pins to Delete", style: .plain, target: self, action: nil )
        return [space,collection,space]
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        navigationController?.setToolbarHidden(!editing, animated: true)
    }
}

// -------------------------------------------------------------------------
// MARK: NSFetchedResultsControllerDelegate
extension MapViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        fetchedResultController = controller as! NSFetchedResultsController<Location>
    }
}






