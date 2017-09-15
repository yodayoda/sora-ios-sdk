import Foundation
import Sora

final class TestCase {
    
    var id: String
    var title: String
    var configuration: Configuration
    var viewController: TestCaseViewController?
    var testSuite: TestSuite?
    
    init(id: String, title: String, configuration: Configuration) {
        self.id = id
        self.title = title
        self.configuration = configuration
    }
    
}

final class TestSuite {

    var testCases: [TestCase]

    init(testCases: [TestCase]) {
        self.testCases = testCases
    }
    
    convenience init?(contentsOf url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let suite = try decoder.decode(TestSuite.self, from: data)
            self.init(testCases: suite.testCases)
        } catch let e {
            print("failed to load test suite (\(e.localizedDescription))")
            do {
                print("remove file")
                try FileManager.default.removeItem(at: url)
            } catch let e {
                print("failed to remove file (\(e.localizedDescription))")
            }
            return nil
        }
    }
    
    func add(testCase: TestCase) {
        testCases.append(testCase)
        testCase.testSuite = self
    }
    
    func remove(testCase: TestCase) {
        testCases = testCases.filter { e in
            return e.id != testCase.id
        }
    }

    func remove(testCaseAt: Int) {
        testCases.remove(at: testCaseAt)
    }
    
    func insert(testCase: TestCase, at: Int) {
        testCases.insert(testCase, at: at)
    }
    
    func write(to url: URL) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self)
            try data.write(to: url)
        } catch let e {
            print("failed to save test suite (\(e.localizedDescription))")
        }
    }
    
}

extension TestCase: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case configuration
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let configuration = try container.decode(Configuration.self, forKey: .configuration)
        self.init(id: id, title: title, configuration: configuration)
    }
    
    public func encode(to encoder: Encoder) throws {
        var encoder = encoder.container(keyedBy: CodingKeys.self)
        try encoder.encode(id, forKey: .id)
        try encoder.encode(title, forKey: .title)
        try encoder.encode(configuration, forKey: .configuration)
    }
    
}

extension TestSuite: Codable {
    
    enum CodingKeys: String, CodingKey {
        case testCases
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let testCases = try container.decode([TestCase].self, forKey: .testCases)
        self.init(testCases: testCases)
    }
    
    public func encode(to encoder: Encoder) throws {
        var encoder = encoder.container(keyedBy: CodingKeys.self)
        try encoder.encode(testCases, forKey: .testCases)
    }
    
}
