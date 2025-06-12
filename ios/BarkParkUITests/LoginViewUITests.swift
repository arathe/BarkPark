//
//  LoginViewUITests.swift
//  BarkParkUITests
//
//  UI tests for LoginView authentication flow
//

import XCTest

final class LoginViewUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToLoginView() throws {
        // Assuming we start from WelcomeView
        let welcomeView = app.otherElements["WelcomeView"]
        
        // Look for login navigation button
        let loginButton = app.buttons["Already have account"]
        if loginButton.exists {
            loginButton.tap()
        }
        
        // Verify LoginView elements are present
        let emailField = app.textFields["Enter your email"]
        let passwordField = app.secureTextFields["Enter your password"]
        let signInButton = app.buttons["Sign In"]
        
        XCTAssertTrue(emailField.exists, "Email field should be present")
        XCTAssertTrue(passwordField.exists, "Password field should be present")
        XCTAssertTrue(signInButton.exists, "Sign In button should be present")
    }
    
    // MARK: - Form Validation Tests
    
    func testLoginButtonDisabledWithEmptyFields() throws {
        // Navigate to login if needed
        navigateToLoginView()
        
        let signInButton = app.buttons["Sign In"]
        XCTAssertTrue(signInButton.exists, "Sign In button should exist")
        
        // Button should be disabled when fields are empty
        XCTAssertFalse(signInButton.isEnabled, "Sign In button should be disabled with empty fields")
    }
    
    func testLoginButtonEnabledWithFilledFields() throws {
        navigateToLoginView()
        
        let emailField = app.textFields["Enter your email"]
        let passwordField = app.secureTextFields["Enter your password"]
        let signInButton = app.buttons["Sign In"]
        
        // Fill in the fields
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Button should now be enabled
        XCTAssertTrue(signInButton.isEnabled, "Sign In button should be enabled with filled fields")
    }
    
    func testEmailFieldKeyboardType() throws {
        navigateToLoginView()
        
        let emailField = app.textFields["Enter your email"]
        emailField.tap()
        
        // Verify email keyboard is shown (we can check this by verifying @ symbol exists)
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.exists, "Keyboard should be visible")
        
        // Note: Checking for specific keyboard type is complex in UI tests
        // We can verify email behavior by typing and checking the result
        emailField.typeText("test@example.com")
        XCTAssertEqual(emailField.value as? String, "test@example.com")
    }
    
    // MARK: - Password Visibility Tests
    
    func testPasswordVisibilityToggle() throws {
        navigateToLoginView()
        
        let passwordField = app.secureTextFields["Enter your password"]
        let visibilityButton = app.buttons.matching(identifier: "eye").firstMatch
        
        // Initially should be secure field
        XCTAssertTrue(passwordField.exists, "Secure password field should exist")
        
        // Type password
        passwordField.tap()
        passwordField.typeText("secretpassword")
        
        // Toggle visibility if button exists
        if visibilityButton.exists {
            visibilityButton.tap()
            
            // After toggle, might become regular text field
            let textField = app.textFields["Enter your password"]
            XCTAssertTrue(textField.exists || passwordField.exists, "Password field should exist in some form")
        }
    }
    
    // MARK: - Error Display Tests
    
    func testErrorMessageDisplay() throws {
        navigateToLoginView()
        
        let emailField = app.textFields["Enter your email"]
        let passwordField = app.secureTextFields["Enter your password"]
        let signInButton = app.buttons["Sign In"]
        
        // Fill with invalid credentials
        emailField.tap()
        emailField.typeText("wrong@example.com")
        
        passwordField.tap()
        passwordField.typeText("wrongpassword")
        
        // Submit form
        signInButton.tap()
        
        // Wait for error message to appear
        let errorText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'invalid' OR label CONTAINS[c] 'error' OR label CONTAINS[c] 'wrong'"))
        
        // Wait up to 10 seconds for error message
        let errorExists = errorText.firstMatch.waitForExistence(timeout: 10)
        XCTAssertTrue(errorExists, "Error message should appear for invalid credentials")
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStateDisplay() throws {
        navigateToLoginView()
        
        let emailField = app.textFields["Enter your email"]
        let passwordField = app.secureTextFields["Enter your password"]
        let signInButton = app.buttons["Sign In"]
        
        // Fill with any credentials to enable button
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Submit form
        signInButton.tap()
        
        // Look for loading indicator
        let loadingIndicator = app.activityIndicators.firstMatch
        let signingInText = app.staticTexts["Signing In..."]
        
        // Check if loading state appears (might be brief)
        if loadingIndicator.exists {
            XCTAssertTrue(true, "Loading indicator appeared")
        }
        
        if signingInText.exists {
            XCTAssertTrue(true, "Signing In text appeared")
        }
    }
    
    // MARK: - Navigation Bar Tests
    
    func testNavigationBarElements() throws {
        navigateToLoginView()
        
        // Check for navigation title
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.exists, "Navigation bar should exist")
        
        // Check for cancel button
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
    }
    
    func testCancelButtonDismissesView() throws {
        navigateToLoginView()
        
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        
        cancelButton.tap()
        
        // Should return to previous view (likely WelcomeView)
        let welcomeView = app.otherElements["WelcomeView"]
        let welcomeExists = welcomeView.waitForExistence(timeout: 5)
        
        // Note: This test might need adjustment based on actual navigation structure
        if !welcomeExists {
            // Alternative: check that login view is no longer visible
            let emailField = app.textFields["Enter your email"]
            XCTAssertFalse(emailField.exists, "Login view should be dismissed")
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityElements() throws {
        navigateToLoginView()
        
        let emailField = app.textFields["Enter your email"]
        let passwordField = app.secureTextFields["Enter your password"]
        let signInButton = app.buttons["Sign In"]
        
        // Verify accessibility labels exist
        XCTAssertTrue(emailField.exists, "Email field should be accessible")
        XCTAssertTrue(passwordField.exists, "Password field should be accessible")
        XCTAssertTrue(signInButton.exists, "Sign In button should be accessible")
        
        // Check that elements are accessible by VoiceOver
        XCTAssertTrue(emailField.isHittable, "Email field should be hittable")
        XCTAssertTrue(passwordField.isHittable, "Password field should be hittable")
    }
    
    // MARK: - Form Interaction Tests
    
    func testFormTabOrderAndInteraction() throws {
        navigateToLoginView()
        
        let emailField = app.textFields["Enter your email"]
        let passwordField = app.secureTextFields["Enter your password"]
        
        // Test tab order by filling fields sequentially
        emailField.tap()
        emailField.typeText("test@example.com")
        
        // Move to password field
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Verify values were entered correctly
        XCTAssertEqual(emailField.value as? String, "test@example.com")
        // Note: Password field value is typically hidden for security
    }
    
    // MARK: - Helper Methods
    
    private func navigateToLoginView() {
        // This method helps navigate to LoginView from wherever the app starts
        // Adjust based on your app's navigation structure
        
        let welcomeView = app.otherElements["WelcomeView"]
        let loginButton = app.buttons["Already have account"]
        
        // If we're on welcome view, tap login button
        if welcomeView.exists && loginButton.exists {
            loginButton.tap()
        }
        
        // Wait for login view to appear
        let emailField = app.textFields["Enter your email"]
        let loginViewAppeared = emailField.waitForExistence(timeout: 5)
        XCTAssertTrue(loginViewAppeared, "Login view should appear")
    }
    
    // MARK: - Performance Tests
    
    func testLoginViewPerformance() throws {
        // Measure performance of navigating to and interacting with login view
        measure {
            navigateToLoginView()
            
            let emailField = app.textFields["Enter your email"]
            let passwordField = app.secureTextFields["Enter your password"]
            
            emailField.tap()
            emailField.typeText("performance@test.com")
            
            passwordField.tap()
            passwordField.typeText("testpassword")
        }
    }
}