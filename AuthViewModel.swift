// File: AuthViewModel.swift

import Foundation
import FirebaseAuth
import Combine

class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User? // You might want to create a User model for more details
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.userSession = Auth.auth().currentUser
        
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userSession = user
            // fetch user profile from Firestore
        }
    }
    
    func signIn(withEmail email: String, password: String) async -> Bool {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            print("DEBUG: User signed in: \(result.user.uid)")
            return true
        } catch {
            print("DEBUG: Failed to sign in with error: \(error.localizedDescription)")
            return false
        }
    }
    
    func signUp(withEmail email: String, password: String) async -> Bool {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            print("DEBUG: User signed up and logged in: \(result.user.uid)")
            // Here you could create a new user document in Firestore
            return true
        } catch {
            print("DEBUG: Failed to sign up with error: \(error.localizedDescription)")
            return false
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            print("DEBUG: User signed out.")
        } catch {
            print("DEBUG: Failed to sign out with error: \(error.localizedDescription)")
        }
    }
}

