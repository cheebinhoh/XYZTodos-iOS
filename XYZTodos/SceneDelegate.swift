//
//  SceneDelegate.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/27/20.
//
//  Copyright © 2020 - 2021 Chee Bin Hoh. All rights reserved.
//

import UIKit
import WidgetKit
import CloudKit
import BackgroundTasks

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func handleAppUrl(_ scene: UIScene,
                      openURLContexts urlContexts:Set<UIOpenURLContext>) {
        
        let urllink = urlContexts.first {
       
            return $0.url.scheme == appScheme
        }
        
        if let url = urllink?.url {
        
            switch url.host {
            
                case httpUrlWidgetHost:
                    var sequenceNr: Int?
                    var group: String?
                    
                    let parameterList = url.query?.split(separator: "&")
                    
                    for parameter in parameterList! {
                        
                        let parameterNameValue = parameter.split(separator: "=")
                        
                        for (index, name) in parameterNameValue.enumerated() {
                            
                            switch name {
                                case "sequenceNr":
                                    guard index + 1 < parameterNameValue.count else {
                                        
                                        fatalError("Exception: missing parameter value for SequenceNr")
                                    }
                                
                                    guard let value = Int(parameterNameValue[index + 1]) else {
                                        
                                        fatalError("Exception: parameter value for SequenceNr must be number")
                                    }
                                    
                                    sequenceNr = value
                                    
                                case "group":
                                    guard index + 1 < parameterNameValue.count else {
                                        
                                        fatalError("Exception: missing parameter value for SequenceNr")
                                    }
                                
                                    group = String(parameterNameValue[index + 1])
                                    
                                default:
                                    break
                            }
                        }
                    }
                    
                    if let group = group,
                        let sequenceNr = sequenceNr {
                        
                        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                            
                            fatalError("Exception: AppDelegate is expected")
                        }

                        appDelegate.addExpandedGroupInTodosView(group: group)
                        appDelegate.setHighlightGroupSequenceNrInTodosView(group: group,
                                                                           sequenceNr: sequenceNr)
                    }
                    
                default:
                    break
            } // switch url.host 
        } // if let url = urllink?.url
    }
    
    // App opened from background
    func scene(_ scene: UIScene,
               openURLContexts urlContexts: Set<UIOpenURLContext>) {
        
        if !urlContexts.isEmpty {

            handleAppUrl(scene, openURLContexts: urlContexts)
        }
    }
    
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        guard let _ = (scene as? UIWindowScene) else { return }
        
        if let _ = connectionOptions.shortcutItem {
                // Save it off for later when we become active.
            
            executeAddTodo()
        } else if !connectionOptions.urlContexts.isEmpty {
            
            handleAppUrl(scene, openURLContexts: connectionOptions.urlContexts)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        
        registerDeregisterNotification()
        UIApplication.shared.applicationIconBadgeNumber = 0
         
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
             
            fatalError("Exception: AppDelegate is expected")
        }

        appDelegate.switchToTodosView()
        
        if appDelegate.expandedTodoGroups.isEmpty {
        
            appDelegate.addExpandedGroupInTodosView(group: todayDoW.rawValue)
        }
        
        appDelegate.reloadTodosDataInTodosView()
        appDelegate.syncTodosWithiCloud()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            
            fatalError("Exception: AppDelegate is expected")
        }
        
        appDelegate.saveExpandedGroupsInTodosView()
        registerDeregisterNotification()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        
        executeAddTodo()
    }
}

