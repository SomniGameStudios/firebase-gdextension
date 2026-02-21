@preconcurrency import SwiftGodotRuntime
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
#if canImport(UIKit)
import UIKit
#endif

@Godot
class FirebaseAuthPlugin: RefCounted, @unchecked Sendable {
    // iOS-internal signals (not in GodotFirebaseAndroid API — used by wrapper internally)
    @Signal var firebase_initialized: SimpleSignal
    @Signal("message") var firebase_error: SignalWithArguments<String>

    // Public signals — match GodotFirebaseAndroid Auth API exactly
    @Signal("current_user_data") var auth_success: SignalWithArguments<GDictionary>
    @Signal("error_message") var auth_failure: SignalWithArguments<String>
    @Signal("success") var sign_out_success: SignalWithArguments<Bool>
    @Signal("current_user_data") var link_with_google_success: SignalWithArguments<GDictionary>
    @Signal("error_message") var link_with_google_failure: SignalWithArguments<String>

    private var isInitialized = false

    // MARK: - Initialization (iOS-specific, called by wrapper internally)

    @Callable
    func initialize() {
        guard !isInitialized else { return }
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            firebase_error.emit("GoogleService-Info.plist not found in app bundle. Add it to the Xcode project target.")
            return
        }
        FirebaseApp.configure(options: options)
        isInitialized = true
        firebase_initialized.emit()
    }

    // MARK: - Anonymous Auth

    @Callable
    func sign_in_anonymously() {
        guard isInitialized else {
            auth_failure.emit("Firebase not initialized")
            return
        }
        // If a user is already signed in, return their data instead of creating a new session
        if let existingUser = Auth.auth().currentUser {
            Task { @MainActor in
                self.auth_success.emit(self.userToDict(existingUser))
            }
            return
        }
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.auth_failure.emit(error.localizedDescription)
                    return
                }
                guard let user = result?.user else { return }
                self.auth_success.emit(self.userToDict(user))
            }
        }
    }

    // MARK: - Google Sign-In

    @Callable
    func sign_in_with_google() {
        guard isInitialized else {
            auth_failure.emit("Firebase not initialized")
            return
        }
        performGoogleSignIn { [weak self] credential, error in
            guard let self else { return }
            if let error {
                Task { @MainActor in self.auth_failure.emit(error) }
                return
            }
            guard let credential else { return }
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                guard let self else { return }
                Task { @MainActor in
                    if let error {
                        self.auth_failure.emit(error.localizedDescription)
                        return
                    }
                    guard let user = result?.user else { return }
                    self.auth_success.emit(self.userToDict(user))
                }
            }
        }
    }

    @Callable
    func link_anonymous_with_google() {
        guard isInitialized else {
            link_with_google_failure.emit("Firebase not initialized")
            return
        }
        guard let currentUser = Auth.auth().currentUser else {
            link_with_google_failure.emit("No user signed in")
            return
        }
        guard currentUser.isAnonymous else {
            link_with_google_failure.emit("Current user is not anonymous. Use sign_in_with_google() instead")
            return
        }
        performGoogleSignIn { [weak self] credential, error in
            guard let self else { return }
            if let error {
                Task { @MainActor in self.link_with_google_failure.emit(error) }
                return
            }
            guard let credential else { return }
            currentUser.link(with: credential) { [weak self] result, error in
                guard let self else { return }
                Task { @MainActor in
                    if let error {
                        let nsError = error as NSError
                        // Already linked with this provider — treat as success
                        if nsError.code == AuthErrorCode.providerAlreadyLinked.rawValue {
                            self.link_with_google_success.emit(self.userToDict(currentUser))
                            return
                        }
                        self.link_with_google_failure.emit(error.localizedDescription)
                        return
                    }
                    guard let user = result?.user else { return }
                    self.link_with_google_success.emit(self.userToDict(user))
                }
            }
        }
    }

    // MARK: - Sign Out

    @Callable
    func sign_out() {
        do {
            GIDSignIn.sharedInstance.signOut()
            try Auth.auth().signOut()
            sign_out_success.emit(true)
        } catch {
            auth_failure.emit(error.localizedDescription)
        }
    }

    // MARK: - User State

    @Callable func is_signed_in() -> Bool { Auth.auth().currentUser != nil }

    @Callable
    func get_current_user_data() -> GDictionary {
        guard let user = Auth.auth().currentUser else { return GDictionary() }
        return userToDict(user)
    }

    // MARK: - Private Helpers

    private func performGoogleSignIn(completion: @escaping (AuthCredential?, String?) -> Void) {
        #if os(iOS)
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(nil, "Missing Firebase clientID")
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        DispatchQueue.main.async {
            guard let rootVC = self.topMostViewController() else {
                completion(nil, "Could not find root view controller")
                return
            }
            GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
                if let error {
                    completion(nil, error.localizedDescription)
                    return
                }
                guard let user = result?.user, let idToken = user.idToken else {
                    completion(nil, "Google Sign-In failed: missing token")
                    return
                }
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken.tokenString,
                    accessToken: user.accessToken.tokenString
                )
                completion(credential, nil)
            }
        }
        #else
        completion(nil, "Google Sign-In is only available on iOS")
        #endif
    }

    #if os(iOS)
    @MainActor
    private func topMostViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }
        return findTopViewController(from: root)
    }

    private func findTopViewController(from vc: UIViewController) -> UIViewController {
        if let nav = vc as? UINavigationController {
            return findTopViewController(from: nav.visibleViewController ?? nav)
        }
        if let tab = vc as? UITabBarController {
            return findTopViewController(from: tab.selectedViewController ?? tab)
        }
        if let presented = vc.presentedViewController {
            return findTopViewController(from: presented)
        }
        return vc
    }
    #endif

    private func userToDict(_ user: FirebaseAuth.User) -> GDictionary {
        var dict = GDictionary()
        dict[Variant("uid")] = Variant(user.uid)
        dict[Variant("email")] = Variant(user.email ?? "")
        dict[Variant("displayName")] = Variant(user.displayName ?? "")
        dict[Variant("photoURL")] = Variant(user.photoURL?.absoluteString ?? "")
        dict[Variant("isAnonymous")] = Variant(user.isAnonymous)
        return dict
    }
}
