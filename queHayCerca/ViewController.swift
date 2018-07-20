//
//  ViewController.swift
//  queHayCerca
//
//  Created by Sergio Abarca Flores on 12-07-18.
//  Copyright © 2018 sergioeabarcaf. All rights reserved.
//

import UIKit
import SpriteKit
import ARKit
import CoreLocation
import GameplayKit

class ViewController: UIViewController, ARSKViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var sceneView: ARSKView!
    
    let locationManager = CLLocationManager()
    var userLocation = CLLocation()
    
    var sitesJSON : JSON!
    var sites = [UUID : String]()
    
    var userHeading = 0.0
    var headingStep = 0
    
    //ViewDidLoad prepara las configuraciones necesarias antes de que sea cargada la app
    override func viewDidLoad() {
        super.viewDidLoad()
        
    //Configurar LocationManager
        locationManager.delegate = self
        //kCLLocaitonAccurancyBest Configura para pedir la posicion exacta del telefono, pero aumenta el consumo de bateria.
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //Se almacenan los permisos que entrego el usuario.
        locationManager.requestWhenInUseAuthorization()
        
    //Configurar la escena
        sceneView.delegate = self
        
        // Mostrar por pantalla los siguientes parametros
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        sceneView.showsQuadCount = true
        sceneView.showsDrawCount = true
        sceneView.showsPhysics = true
        sceneView.showsFields = true
        
        
        // Cargar la escena
        if let scene = SKScene(fileNamed: "Scene") {
            sceneView.presentScene(scene)
        }
    }
    
    //viewWillAppear es llamado luego que se carga en memoria la APP, con eso se preparan los objetos que seran mostrados en la vista
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configura la ARKit
        let configuration = ARWorldTrackingConfiguration()

        //Corre la configuracion del ARkit en la escena
        sceneView.session.run(configuration)
    }
    
    //ViewWillDisappear es llamado cuando la vista desaparecera de la pantalla
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Pausa los procesos de la session.
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSKViewDelegate
    
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        //Pide a ARSKViewDelagate un nodo de SpriteKit con el ancla creada
        
        //Crear etiqueta con nombre del ancla
        let labelNode = SKLabelNode(text: sites[anchor.identifier])
        //central la etiqueta en horizontal y vertical
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        
        //Crear nuevo tamaño mayor al label
        let newSize = labelNode.frame.size.applying(CGAffineTransform(scaleX: 1.1, y: 1.5))
        //Crear fondo
        let backgroundNode = SKShapeNode(rectOf: newSize, cornerRadius: 10)
        //Color de fondo
        let randomColor = UIColor(hue: CGFloat(GKRandomSource.sharedRandom().nextUniform()), saturation: 0.5, brightness: 0.4, alpha: 0.8)
        //Rellenar color random en background
        backgroundNode.fillColor = randomColor
        //definir color de contenido
        backgroundNode.strokeColor = randomColor.withAlphaComponent(1.0)
        //Agrandar borde del background
        backgroundNode.lineWidth = 2
        
        //agregar labelnode como hijo de background
        backgroundNode.addChild(labelNode)
        
        return backgroundNode;
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        //Muestra por consola el mensaje de error en el ARSKViewDelegate
        print("Error ARDKViewDelegate: \(error.localizedDescription)")
    }
    
    //Pertenecientes a ARSessionObserver
    func sessionWasInterrupted(_ session: ARSession) {
        // Le avisa al delegado que se ha detenido el procesamiento de Frames
        print("El delegado sabe que se ha detenido el procesamiento de frame")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Le avisa al delegado que se ha reiniciado el procesamiento de Frame
        print("El delegado sabe que se ha reiniciado el procesamiento de frame")
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //Administra los errores del CoreLocation
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //Pregunta si la autorizacion del usuario es permitida
        if status == .authorizedWhenInUse{
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //Le avisa al delegado cuando hay una nueva posicion
        guard let location = locations.last else {return}
        userLocation = location
        print("La locacion es: \(userLocation)")
        DispatchQueue.global().async {
            self.updateSites()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        //Ejecutar bloque de manera asincrona
        DispatchQueue.main.async {
            //Se descartan los 2 primeros intentos del newHeading
            self.headingStep += 1
            if self.headingStep < 3 {return}
            
            //Con el tercer intento, se guarda en userHeading el norte magnetico, luego se detiene la actualizacion del heading y se llama a createSites
            self.userHeading = newHeading.magneticHeading
            self.locationManager.stopUpdatingHeading()
            print("Vista device: \(self.userHeading) , Intento: \(self.headingStep)")
            self.createSites()
        }
    }
    
    func updateSites(){
        
        //Obtener la lista de sitios desde la api de wikipedia
        let urlStr = "https://en.wikipedia.org/w/api.php?ggscoord=\(userLocation.coordinate.latitude)%7C\(userLocation.coordinate.longitude)&action=query&prop=coordinates%7Cpageimages%7Cpageterms&colimit=50&piprop=thumbnail&pithumbsize=500&pilimit=50&wbptterms=description&generator=geosearch&ggsradius=10000&ggslimit=50&format=json"
        
        guard let url = URL(string: urlStr) else {return}
        
        //Si se crea el date sin errores, se almacenan los siteJSON y se llama el metodo de LocationManager startUpdatingHeading
        if let date = try? Data(contentsOf: url){
            sitesJSON = JSON(date)
            locationManager.startUpdatingHeading()
        }
    }
    
    func createSites(){
        for site in sitesJSON["query"]["pages"].dictionaryValue.values {
            //Obtener la vista de la scena
            guard let sceneView = self.view as? ARSKView else {return}
            
            //Ubicar lat y lon del site
            let lat = site["coordinates"][0]["lat"].doubleValue
            let lon = site["coordinates"][0]["lon"].doubleValue
            //almacenar en una clase CLLocation la lat y lon en grados
            let location = CLLocation(latitude: lat, longitude: lon)
            //print(location)
            
            //Calcular la distancia del usuario hacia el lugar
            let distance = Float(userLocation.distance(from: location))
            print("distance: \(distance)")
            if distance <= 1000{
                //Calcular el azimut del usuario
                let azimut = direction(from: userLocation, to: location)
                //print("azimut: \(azimut)")
                //Calcular angulo entre azimut y usuario
                let angle = azimut - userHeading
                //print("angle: \(angle)")
                let angleRad = GLKMathDegreesToRadians(Float(angle))
                //print("angleRad: \(angleRad)")
                
                //Crear matriz de rotacion horizontal
                let horizontalRotation = float4x4(SCNMatrix4MakeRotation(Float(angleRad), 1, 0, 0))
                //print("horizontalRotation: \(horizontalRotation)")
                //Crear matriz de rotacion vertical
                let verticalRotation = float4x4(SCNMatrix4MakeRotation(-0.3 + (distance/500), 0, 1, 0))
                //print("verticalRotation: \(verticalRotation)")
                //Multiplicar matrices
                let rotation = simd_mul(horizontalRotation, verticalRotation)
                //print("rotation: \(rotation)")
                
                //Obtener matriz de la camara
                guard let currentFrame = sceneView.session.currentFrame else {return}
                //Multiplicar matriz de la camara con la rotation
                let rotationCamera = simd_mul(currentFrame.camera.transform, rotation)
                //Crear matriz identidad y moverla para posicionar el objeto en profundidad
                var translacion = matrix_identity_float4x4
                let dist = -(0.5 + (distance / 1000))
                print(dist)
                translacion.columns.3.z = dist
                //print("translacion: \(translacion)")
                
                //posicion donde se coloca el ancla
                let transform = simd_mul(rotationCamera, translacion)
                //Crear ancla
                let anchor = ARAnchor(transform: transform)
                //agregar el ancla a la session
                sceneView.session.add(anchor: anchor)
                
                //Agregar el ancla al diccionario site
                sites[anchor.identifier] = site["title"].string ?? "Lugar desconocido"
            }
        }
    }
    
    //MARK: Funciones matematicas para calcular distancia con los sites
    
    //Funcion para obtener la distancia en la tierra
    func direction(from p1:CLLocation, to p2:CLLocation) -> Double {
        //atag2( sen(dif longitudes) * cos(lon2)
        //  cos(lat1) * sen(lat2) - sen(lat1) * cos(lat2) * cos(dif longitudes)
        let difLon = p2.coordinate.longitude - p1.coordinate.longitude
        let y = sin(difLon) * cos(p2.coordinate.longitude)
        let x = cos(p1.coordinate.latitude) * sin(p2.coordinate.latitude) - sin(p1.coordinate.latitude) * cos(p2.coordinate.latitude) * cos(difLon)
        let atan_rad = atan2(y, x)
        
        return Double(GLKMathRadiansToDegrees(Float(atan_rad)))
    }
    
}
