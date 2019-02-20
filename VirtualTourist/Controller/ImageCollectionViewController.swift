//
//  ImageCollectionViewController.swift
//  VirtualTourist
//
//  Created by Ashish Nautiyal on 2/14/19.
//  Copyright © 2019 Ashish  Nautiyal. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ImageCollectionViewController: UIViewController {
    
    // MARK: Outlets
    @IBOutlet weak var noItemLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Properties
    var dataController : DataController!
    var backgroundContext : NSManagedObjectContext!
    var location: Location!
    var fetchedResultController : NSFetchedResultsController<Images>!
    var collection: UIBarButtonItem!
    
    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureToolbarItems()
        setUpFetchResultController()
        setMapRegion()
        addMapAnnotations()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setToolbarHidden(true, animated: false)
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultController = nil
    }
    
    // Settingup CoreData result for image collection
    //Entity: Images
    fileprivate func setUpFetchResultController() {
        backgroundContext = dataController.backgroundContext
        let fetchRequest: NSFetchRequest<Images> = Images.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAT", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let predicate = NSPredicate(format: "location == %@", location)
        fetchRequest.predicate = predicate
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        do{
            try  fetchedResultController.performFetch()
            if (fetchedResultController.sections![0].numberOfObjects == 0 ){
                setActivityIndicator(true)
                Client.getImages(latitude: location.latitude, longitude: location.longitude, Int(UInt32(location.page)) + 1, completion: handleResponse(response:error:))
            }
        }
        catch {
            fatalError("The fetch could not be performed : \(error.localizedDescription)")
        }
    }
    
    // handle the response of image collection flicker API request
    func handleResponse(response: LocationResponse?, error : Error?){
        setActivityIndicator(false)
        if let error = error {
            showFailure(message: error.localizedDescription)
            return
        }
        
        if let response = response {
            if response.photos.photo.count == 0 {
            showFailure(message: "No item found")
            return
        }
            let locationID =  location.objectID
            let backgroundContext : NSManagedObjectContext! = dataController.backgroundContext
            backgroundContext.perform {
                let locationNote = backgroundContext.object(with: locationID) as! Location
                locationNote.page = Int16(response.photos.page)
                for photo in response.photos.photo {
                    let img = Images(context: self.dataController.backgroundContext)
                    img.createdAT = Date()
                    img.url = photo.url
                    img.location = locationNote
                    try? backgroundContext.save()
                }
            }
        }
    }
    
    // Show the activity indicator during Image collection Request
    func  setActivityIndicator(_ showIndicator: Bool){
        if showIndicator {
            noItemLabel.isHidden = true
            activityIndicator.startAnimating()
        }
        else{
            activityIndicator.stopAnimating()
        }
        collection.isEnabled = !showIndicator
    }
    
    // Show error alert on the Image collection request failure
    func showFailure(message: String) {
        noItemLabel.isHidden = false
        let alertVC = UIAlertController(title: "Request Failed", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC,animated: true, completion: nil)
    }
    
    
    // Adding annotaion to map
    func addMapAnnotations(){
        let lat = CLLocationDegrees(location.latitude)
        let long = CLLocationDegrees(location.longitude )
        
        // The lat and long are used to create a CLLocationCoordinates2D instance.
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        // Here we create the annotation and set its coordiate, title, and subtitle properties
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        // Here we add the annotations to the map.
        self.mapView.addAnnotation(annotation)
        
    }
    
    
    
}

// -------------------------------------------------------------------------
// MARK: Toolbar
extension ImageCollectionViewController{
    /// Returns an array of toolbar items. Used to configure the view controller's
    /// `toolbarItems' property, and to configure an accessory view for the
    /// text view's keyboard that also displays these items.
    func makeToolbarItems() -> [UIBarButtonItem] {
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        collection = UIBarButtonItem(title: "New Collection", style: .plain, target: self, action: #selector(newCollectionTapped(sender:)))
        return [space,collection,space]
    }
    
    //MARK: Helper method
    // Delete old images collection and call API for new images collection
    @IBAction func newCollectionTapped(sender: Any) {
        for managedObject in self.fetchedResultController.sections![0].objects!
        {
            let managedObjectData = managedObject as! Images
            let id = managedObjectData.objectID
            backgroundContext.perform {
                let backgroundObject = self.backgroundContext.object(with: id) as! Images
                self.backgroundContext.delete(backgroundObject)
                try? self.backgroundContext.save()
            }
            
        }
        setActivityIndicator(true)
        Client.getImages(latitude: location.latitude, longitude: location.longitude, Int(UInt32(location.page)) + 1  , completion: handleResponse(response:error:))
    }
    
    /// Configure the current toolbar
    func configureToolbarItems() {
        toolbarItems = makeToolbarItems()
        navigationController?.setToolbarHidden(false, animated: false)
    }
}

// -------------------------------------------------------------------------
// MARK: Map Delegate
extension ImageCollectionViewController : MKMapViewDelegate {
    func setMapRegion(){
        let lat =  location.latitude
        let long = location.longitude
        let longitudeDelta: Double = 9
        let latitudeDelta: Double = 9
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: long), span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
        mapView.setRegion(region, animated: false)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
        
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}

// -------------------------------------------------------------------------
// MARK : UICollectionViewDelegate
extension ImageCollectionViewController : UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Configure cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCollectionCell", for: indexPath) as! CollectionViewCell
        let aPhoto = fetchedResultController.object(at: indexPath)
        cell.activityIndicator.startAnimating()
        cell.img?.image = UIImage(named: "placeHolder")
        
        // check if image is already saved in coredata use that
        if let data = aPhoto.image {
            let image = UIImage(data: data)
            cell.activityIndicator.stopAnimating()
            cell.img.image = image
        }
            //else download image save to database and use it
        else if let path = aPhoto.url { Client.downloadImage(imagePath: path) { data, error in
            cell.activityIndicator.stopAnimating()
            guard let data = data else { return }
            let image = UIImage(data: data)
            cell.img.image = image
            cell.setNeedsLayout()
            let photoID = aPhoto.objectID
            self.backgroundContext.perform {
                let backgroundPhoto = self.backgroundContext.object(with: photoID) as! Images
                backgroundPhoto.image = data
                try! self.backgroundContext.save()
            }
            }
        }
        return cell
    }
    
    
}

// -------------------------------------------------------------------------
// MARK: NSFetchedResultsControllerDelegate
extension ImageCollectionViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        fetchedResultController = controller as! NSFetchedResultsController<Images>
        switch type {
        case .insert:
            imageCollectionView.insertItems(at:[newIndexPath!])
        case .delete:
            imageCollectionView.deleteItems(at: [indexPath!])
            
        default:
            break
        }
    }
}
