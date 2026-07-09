//
//  NotificationService.swift
//  NotificationService
//
//  Created by Houleng.LY on 8/7/26.
//

import UserNotifications

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    var downloadTask: URLSessionDownloadTask?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent,
              let audioUrlString = request.content.userInfo["audioUrl"] as? String,
              let audioUrl = URL(string: audioUrlString) else {
            contentHandler(request.content)
            return
        }
        
        print("Start downloading ... : \(audioUrlString)")
        
        downloadTask = URLSession.shared.downloadTask(with: audioUrl) { [weak self] (tempLocation, response, error) in
            guard let self = self else { return }

            defer {
                contentHandler(bestAttemptContent)
            }

            guard let tempLocation = tempLocation, error == nil else {
                print("Download failed: \(error?.localizedDescription ?? "unknown")")
                return
            }

            do {
                let fileManager = FileManager.default

                guard let groupURL = fileManager.containerURL(
                    forSecurityApplicationGroupIdentifier: "group.com.chipmongbank.bankingapp.uat"
                ) else {
                    print("App Group container not found. Check your entitlements.")
                    return
                }

                let soundsURL = groupURL.appendingPathComponent("Library/Sounds", isDirectory: true)

                if !fileManager.fileExists(atPath: soundsURL.path) {
                    try fileManager.createDirectory(at: soundsURL,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
                }

                let fileName = "incoming_alert.wav"
                let destinationURL = soundsURL.appendingPathComponent(fileName)

                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }

                try fileManager.moveItem(at: tempLocation, to: destinationURL)

                bestAttemptContent.sound = UNNotificationSound(
                    named: UNNotificationSoundName(rawValue: fileName)
                )
                bestAttemptContent.title = bestAttemptContent.title
                print("Sound saved to: \(destinationURL.path)")

            } catch {
                print("File error: \(error.localizedDescription)")
            }
        }

        downloadTask?.resume()
    }

    override func serviceExtensionTimeWillExpire() {
        downloadTask?.cancel()
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
