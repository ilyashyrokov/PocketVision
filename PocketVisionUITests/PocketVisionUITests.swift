import XCTest

final class PocketVisionUITests: XCTestCase {
    @MainActor
    func testCameraCollectionAndModelTabsRender() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Pocket Vision"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "1 000 категорий ImageNet")).firstMatch.exists)
        app.tabBars.buttons["Коллекция"].tap()
        XCTAssertTrue(app.staticTexts["Здесь будут ваши находки"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Модель"].tap()
        XCTAssertTrue(app.staticTexts["Оценка исходных весов"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["67,7%"].exists)

        app.tabBars.buttons["Камера"].tap()
        XCTAssertTrue(app.buttons["Выбрать фото"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCameraPickerCanBeOpenedAndDismissed() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Сделать фото"].waitForExistence(timeout: 10))
        app.buttons["Сделать фото"].tap()

        XCTAssertTrue(app.buttons["Сфотографировать"].waitForExistence(timeout: 5))
        app.buttons["Закрыть"].tap()
        XCTAssertTrue(app.buttons["Сделать фото"].waitForExistence(timeout: 5))
    }
}
