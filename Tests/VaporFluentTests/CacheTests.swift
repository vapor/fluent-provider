import XCTest
@testable import VaporFluent

class CacheTests: XCTestCase {
    func testHappyPath() throws {
        // config specifying memory database
        var config = Config([:])
        try config.set("fluent.driver", "memory")
        try config.set("droplet.cache", "fluent")

        // create droplet with Fluent provider
        let drop = try Droplet(
            arguments: ["vapor", "serve", "--port=8832"],
            environment: .custom("debug"), 
            config: config
        )
        try drop.addProvider(VaporFluent.Provider.self)
        
        // add the entity for storing fluent caches
        drop.preparations += FluentCache.CacheEntity.self

        // run the droplet
        background {
            drop.run()
        }
        drop.console.wait(seconds: 1)

        // test cache
        XCTAssert(drop.cache is FluentCache)

        try drop.cache.set("foo", "bar")
        XCTAssertEqual(
            try drop.cache.get("foo")?.string,
            "bar"
        )

        do {
            try drop.cache.set("foo", try Node(node: ["hello": "world"]))
            XCTFail("Operation should have failed.")
        } catch SQLiteDriverError.unsupported(let message) {
            // setting objects is unsupported
            print(message)
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }


    static var allTests = [
        ("testHappyPath", testHappyPath),
    ]
}