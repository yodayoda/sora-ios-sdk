import Foundation
import Sora

protocol TestCaseControllable {

    weak var testCaseController: TestCaseController! { get set }
    
}

final class TestCaseController {
    
    weak var testCase: TestCase!
    var mediaChannel: MediaChannel?
    
    var viewController: TestCaseViewController?
    
    init(testCase: TestCase) {
        self.testCase = testCase
    }
    
    func disconnect(error: Error?) {
        mediaChannel?.disconnect(error: error)
        mediaChannel = nil
    }
    
}

final class TestCase {
    
    var testSuite: TestSuite?
    var id: String
    var title: String
    var configuration: Configuration
    
    var numberOfItemsInVideoViewSection: Int = 1
    var videoViewAspectRatio: AspectRatio = .standard

    init(id: String, title: String, configuration: Configuration) {
        self.id = id
        self.title = title
        self.configuration = configuration
    }
    
}

extension TestCase: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case configuration
        case numberOfItemsInVideoViewSection
        case videoViewAspectRatio
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let configuration = try container.decode(Configuration.self, forKey: .configuration)
        self.init(id: id, title: title, configuration: configuration)
        numberOfItemsInVideoViewSection = try container
            .decode(Int.self, forKey: .numberOfItemsInVideoViewSection)
        videoViewAspectRatio = try container
            .decode(AspectRatio.self, forKey: .videoViewAspectRatio)
    }
    
    public func encode(to encoder: Encoder) throws {
        var encoder = encoder.container(keyedBy: CodingKeys.self)
        try encoder.encode(id, forKey: .id)
        try encoder.encode(title, forKey: .title)
        try encoder.encode(configuration, forKey: .configuration)
        try encoder.encode(numberOfItemsInVideoViewSection,
                           forKey: .numberOfItemsInVideoViewSection)
        try encoder.encode(videoViewAspectRatio, forKey: .videoViewAspectRatio)
    }
    
}