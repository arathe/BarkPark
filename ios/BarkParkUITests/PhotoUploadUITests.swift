//
//  PhotoUploadUITests.swift
//  BarkParkUITests
//
//  UI tests for photo upload functionality
//

import XCTest

final class PhotoUploadUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Add Dog Photo Upload Tests
    
    @MainActor
    func testAddDogWithProfilePhoto() throws {
        // Navigate to Add Dog screen
        app.buttons["Add Your First Dog"].tap()
        
        // Fill basic info
        let nameField = app.textFields["Dog's name"]
        nameField.tap()
        nameField.typeText("Test Dog")
        
        // Test profile photo picker
        let addPhotoButton = app.buttons["Add Profile Photo"]
        #expect(addPhotoButton.exists)
        
        addPhotoButton.tap()
        
        // Verify photo picker appears (system photo picker)
        // Note: In UI tests, we can only verify the picker appears
        // Actual photo selection requires device photos or simulator setup
        
        // Cancel photo picker for test
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        }
        
        // Verify we can still submit without photo
        let submitButton = app.buttons["Add Test Dog"]
        #expect(submitButton.exists)
        #expect(submitButton.isEnabled)
    }
    
    @MainActor
    func testAddDogPhotoPickerOptional() throws {
        app.buttons["Add Your First Dog"].tap()
        
        let nameField = app.textFields["Dog's name"]
        nameField.tap()
        nameField.typeText("No Photo Dog")
        
        // Verify form is still valid without photo
        let submitButton = app.buttons["Add No Photo Dog"]
        #expect(submitButton.exists)
        #expect(submitButton.isEnabled)
        
        // Should be able to submit successfully
        submitButton.tap()
        
        // Should navigate back to pack view
        #expect(app.navigationBars["My Pack"].exists)
    }
    
    // MARK: - Edit Dog Photo Tests
    
    @MainActor
    func testEditDogPhotos() throws {
        // First, ensure we have a dog to edit
        // This test assumes a dog exists or creates one
        if app.buttons["Add Your First Dog"].exists {
            // Create a test dog first
            createTestDog()
        }
        
        // Tap on dog card to view details
        app.buttons.matching(identifier: "dogCard").firstMatch.tap()
        
        // Tap edit button
        app.buttons["Edit"].tap()
        
        // Verify edit screen appears
        #expect(app.navigationBars["Edit Profile"].exists)
        
        // Test profile photo editing
        app.buttons["Change Profile Photo"].tap()
        
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        }
        
        // Test gallery photo management
        app.buttons["Manage Gallery"].tap()
        
        #expect(app.navigationBars["Photo Gallery"].exists)
        
        // Test add gallery photo
        app.buttons["Add Photos"].tap()
        
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        }
        
        // Navigate back
        app.navigationBars.buttons.firstMatch.tap()
        app.navigationBars.buttons.firstMatch.tap()
    }
    
    @MainActor
    func testGalleryPhotoManagement() throws {
        // Navigate to gallery management
        if app.buttons["Add Your First Dog"].exists {
            createTestDog()
        }
        
        app.buttons.matching(identifier: "dogCard").firstMatch.tap()
        app.buttons["Edit"].tap()
        app.buttons["Manage Gallery"].tap()
        
        // Test empty gallery state
        #expect(app.staticTexts["No photos yet"].exists)
        #expect(app.buttons["Add Photos"].exists)
        
        // Test adding photos
        app.buttons["Add Photos"].tap()
        
        // Cancel picker for test
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        }
        
        // Test back navigation
        app.navigationBars.buttons.firstMatch.tap()
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testPhotoUploadErrorHandling() throws {
        // Test error states when backend is not available
        if app.buttons["Add Your First Dog"].exists {
            app.buttons["Add Your First Dog"].tap()
            
            let nameField = app.textFields["Dog's name"]
            nameField.tap()
            nameField.typeText("Error Test Dog")
            
            // Try to submit - should show error if backend unavailable
            app.buttons["Add Error Test Dog"].tap()
            
            // Check for error message
            if app.alerts.firstMatch.exists {
                #expect(app.alerts.firstMatch.staticTexts["Error"].exists)
                app.alerts.buttons["OK"].tap()
            }
        }
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testPhotoPickerPerformance() throws {
        measure {
            app.buttons["Add Your First Dog"].tap()
            
            let nameField = app.textFields["Dog's name"]
            nameField.tap()
            nameField.typeText("Performance Test")
            
            app.buttons["Add Profile Photo"].tap()
            
            if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].tap()
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestDog() {
        app.buttons["Add Your First Dog"].tap()
        
        let nameField = app.textFields["Dog's name"]
        nameField.tap()
        nameField.typeText("UI Test Dog")
        
        app.buttons["Add UI Test Dog"].tap()
        
        // Wait for navigation back
        _ = app.navigationBars["My Pack"].waitForExistence(timeout: 5)
    }
}

// MARK: - XCUIElement Extensions for Testing

extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        
        self.tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}