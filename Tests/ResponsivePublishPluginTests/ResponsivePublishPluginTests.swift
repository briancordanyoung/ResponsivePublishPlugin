//
//  ResponsivePublishPluginTests.swift
//  ResponsivePublishPlugin
//
//  Created by Cordt Zermin on 14.03.21.
//

import XCTest
import Publish
import Plot
import Files

@testable import ResponsivePublishPlugin

// MARK: - TestWebsite

private struct TestWebsite: Website {
    enum SectionID: String, WebsiteSectionID {
        case test
    }
    
    struct ItemMetadata: WebsiteItemMetadata { }
    
    var url = URL(string: "https://cordt.zermin.de")!
    var name = "test"
    var description = ""
    var language: Language = .english
    var imagePath: Path? = nil
}

final class ResponsivePublishPluginTests: XCTestCase {
    
    // MARK: - Properties
    
    private static var testDirPath: Path {
        let sourceFileURL = URL(fileURLWithPath: #file)
        return Path(sourceFileURL.deletingLastPathComponent().path)
    }
    
    private var outputFolder: Folder? {
        try? Folder(path: Self.testDirPath.appendingComponent("Output").absoluteString)
    }
    
    private var expectedFolder: Folder? {
        try? Folder(path: Self.testDirPath.appendingComponent("Expected").absoluteString)
    }
    
    private var resourcesFolderPath: Path {
        Path("Resources")
    }
    
    private func rewrites(using maxDimensions: [Int]) -> [ImageRewrite] {
        maxDimensions.flatMap {
            ResponsivePublishPlugin.rewrites(
                from: resourcesFolderPath.appendingComponent("img"),
                to: Path("img-optimized"),
                for: ImageConfiguration(
                    url: URL(fileURLWithPath: #file).appendingPathComponent("img/background.jpg"),
                    targetExtension: .webp,
                    targetSizes: [sizeClassFrom(upper: $0)]
                )!
            )
        }
    }
    
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        
        env = .mock()
        try? outputFolder?.delete()
    }
    
    override func tearDown() {
        super.tearDown()
        
        try? outputFolder?.delete()
        try? Folder(path: Self.testDirPath.appendingComponent(".publish").absoluteString).delete()
    }
    
    
    // MARK: - Tests
    
    func testCssIsRewritten() throws {
        try TestWebsite().publish(
            at: Self.testDirPath,
            using: [
                .copyResources(),
                .installPlugin(
                    .generateOptimizedImages(
                        from: resourcesFolderPath.appendingComponent("img"),
                        at: Path("img-optimized"),
                        rewriting: Path("css/styles.css")
                    )
                )
            ]
        )
        
        let output = try? outputFolder?
            .file(at: "css/styles.css")
            .readAsString()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { !" \n\t\r".contains($0) }
        
        let expected = try? expectedFolder?
            .file(named: "styles-expected.css")
            .readAsString()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { !" \n\t\r".contains($0) }
        
        XCTAssertEqual(output, expected)
    }
    
    func testCssIsntTouchedWhenThereAreNoSpecificRewrites() throws {
        try TestWebsite().publish(
            at: Self.testDirPath,
            using: [
                .copyResources(),
                .installPlugin(
                    .generateOptimizedImages(
                        from: resourcesFolderPath.appendingComponent("img"),
                        at: Path("img-optimized"),
                        rewriting: Path("css/styles-no-rewrite.css")
                    )
                )
            ]
        )
        
        let output = try? outputFolder?
            .file(at: "css/styles-no-rewrite.css")
            .readAsString()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { !" \n\t\r".contains($0) }
        
        let expected = try? expectedFolder?
            .file(named: "styles-expected-no-rewrite.css")
            .readAsString()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { !" \n\t\r".contains($0) }
        
        XCTAssertEqual(output, expected)
    }
    
    func testRewritesProduceCorrectPathes() {
        // Different sizes produce different target file names
        var expectation: [ImageRewrite] = [
            .init(
                source: .init(path: Path("Resources/img"), fileName: "background", extension: .jpg),
                target: .init(path: Path("img-optimized"), fileName: "background-normal", extension: .webp),
                targetSizeClass: .normal
            )
        ]
        XCTAssertEqual(self.rewrites(using: [1200]), expectation)
        print(self.rewrites(using: [1200]))
        expectation = [
            .init(
                source: .init(path: Path("Resources/img"), fileName: "background", extension: .jpg),
                target: .init(path: Path("img-optimized"), fileName: "background-extra-small", extension: .webp),
                targetSizeClass: .extraSmall
            )
        ]
        XCTAssertEqual(self.rewrites(using: [600]), expectation)
        
        expectation = [
            .init(
                source: .init(path: Path("Resources/img/"), fileName: "background", extension: .jpg),
                target: .init(path: Path("/img-optimized"), fileName: "background-normal", extension: .webp),
                targetSizeClass: .normal
            )
        ]
        XCTAssertEqual(self.rewrites(using: [1200]), expectation)
    }
    
    func testCamelCaseIsChangedToKebap() {
        XCTAssertEqual(
            ResponsivePublishPlugin.SizeClass.extraSmall.fileSuffix,
            "extra-small"
        )
    }
    
    func testImageTagsAreRewritten() throws {
        try TestWebsite().publish(
            at: Self.testDirPath,
            using: [
                .copyResources(),
                .installPlugin(
                    .generateOptimizedImages(
                        from: resourcesFolderPath.appendingComponent("img"),
                        at: Path("img-optimized"),
                        rewriting: Path("css/styles.css")
                    )
                )
            ]
        )
        
        let output = try? outputFolder?
            .file(at: "index.html")
            .readAsString()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { !" \n\t\r".contains($0) }
        
        let expected = try? expectedFolder?
            .file(named: "index-expected.html")
            .readAsString()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { !" \n\t\r".contains($0) }
        
        XCTAssertEqual(output, expected)
    }
    
    func testImagesForSizeClassesAreCreated() throws {
        try TestWebsite().publish(
            at: Self.testDirPath,
            using: [
                .copyResources(),
                .installPlugin(
                    .generateOptimizedImages(
                        from: resourcesFolderPath.appendingComponent("img"),
                        at: Path("img-optimized"),
                        rewriting: Path("css/styles.css")
                    )
                )
            ]
        )
        
        let output = try? outputFolder?
            .subfolder(at: "img-optimized")
            .files
            .names()
            .sorted()
        
        XCTAssertEqual(output?.count, 4)
        XCTAssertEqual(output, ["background-extra-small.webp", "background-large.webp", "background-normal.webp", "background-small.webp"])
    }
}
