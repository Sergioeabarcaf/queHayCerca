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
        return nil;
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        //Muestra por consola el mensaje de error en el ARSKViewDelegate
        print("Error ARDKViewDelegate: \(error.localizedDescription)")
    }
    
    //Pertenecientes a ARSessionObserver
    func sessionWasInterrupted(_ session: ARSession) {
        // Le avisa al delegado que se ha detenido el procesamiento de Frames
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Le avisa al delegado que se ha reiniciado el procesamiento de Frame
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //Administra los errores del CoreLocation
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //Pregunta si la autorizacion del usuario es permitida
        print("status es: \(status)")
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
    
    func updateSites(){
        return
    }
    
}
