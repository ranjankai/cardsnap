import Foundation
import UIKit

struct ParsedContact: Codable, Identifiable {
    var id = UUID()
    var firstName: String = ""
    var lastName: String = ""
    var jobTitle: String = ""
    var company: String = ""
    var emails: [String] = []
    var phones: [String] = []
    var website: String = ""
    var address: String = ""
    var linkedinUrl: String = ""
    var notes: String = ""

    // Not encoded/decoded – handled separately
    var photo: UIImage? = nil

    enum CodingKeys: String, CodingKey {
        case firstName, lastName, jobTitle, company, emails, phones, website, address, linkedinUrl
    }

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }
}
