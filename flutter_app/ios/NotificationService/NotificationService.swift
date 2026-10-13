import UserNotifications

/// Les images des notifications push sur iOS.
///
/// Le serveur envoie `mutable-content: 1` et l'adresse de l'image dans
/// `fcm_options.image` ; Android l'affiche seul, iOS passe d'abord la
/// notification à cette extension. On télécharge l'image et on l'attache :
/// vignette dans la notification, en grand sur un appui long.
///
/// C'est ce que fait `Messaging.serviceExtension().populateNotificationContent`
/// de Firebase, écrit ici en quelques lignes pour que l'extension n'embarque
/// ni Firebase ni aucun framework — elle reste un binaire seul, sans pod.
///
/// Rien ne doit faire perdre la notification : sans image, image illisible,
/// réseau lent ou temps écoulé, elle part telle qu'elle est arrivée.
final class NotificationService: UNNotificationServiceExtension {
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    private var download: URLSessionDownloadTask?
    // Le téléchargement et l'expiration peuvent finir en même temps :
    // la notification ne doit être rendue qu'une fois.
    private let lock = NSLock()

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler

        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            deliver(request.content)
            return
        }
        bestAttemptContent = content

        guard let url = Self.imageURL(in: content.userInfo) else {
            deliver(content)
            return
        }

        download = URLSession.shared.downloadTask(with: url) { [weak self] location, response, error in
            guard let self else { return }
            if error == nil,
               let location,
               (response as? HTTPURLResponse)?.statusCode == 200,
               let attachment = Self.attachment(from: location, response: response, url: url) {
                content.attachments = [attachment]
            }
            self.deliver(content)
        }
        download?.resume()
    }

    /// iOS laisse environ 30 secondes : passé ce délai, sans l'image.
    override func serviceExtensionTimeWillExpire() {
        download?.cancel()
        if let content = bestAttemptContent {
            deliver(content)
        }
    }

    private func deliver(_ content: UNNotificationContent) {
        lock.lock()
        let handler = contentHandler
        contentHandler = nil
        lock.unlock()
        handler?(content)
    }

    /// `fcm_options.image`, en https seulement.
    static func imageURL(in userInfo: [AnyHashable: Any]) -> URL? {
        guard let options = userInfo["fcm_options"] as? [String: Any],
              let raw = options["image"] as? String,
              let url = URL(string: raw),
              url.scheme?.lowercased() == "https" else {
            return nil
        }
        return url
    }

    /// Le fichier téléchargé, renommé avec la bonne extension : iOS en déduit
    /// le type, et refuse un fichier qu'il ne reconnaît pas.
    static func attachment(from location: URL, response: URLResponse?, url: URL) -> UNNotificationAttachment? {
        let ext: String
        switch response?.mimeType?.lowercased() {
        case "image/png": ext = "png"
        case "image/gif": ext = "gif"
        case "image/jpeg", "image/jpg": ext = "jpg"
        default:
            let fromPath = url.pathExtension.lowercased()
            ext = ["png", "gif", "jpg", "jpeg"].contains(fromPath) ? fromPath : "jpg"
        }

        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
        do {
            try FileManager.default.moveItem(at: location, to: file)
            return try UNNotificationAttachment(identifier: "image", url: file, options: nil)
        } catch {
            return nil
        }
    }
}
