import Contacts
import UIKit

class ContactsService {
    static let shared = ContactsService()
    private init() {}

    func requestAccess() async -> Bool {
        let store = CNContactStore()
        return (try? await store.requestAccess(for: .contacts)) ?? false
    }

    func saveContact(_ parsed: ParsedContact) throws {
        let contact = CNMutableContact()
        contact.givenName  = parsed.firstName
        contact.familyName = parsed.lastName
        contact.jobTitle   = parsed.jobTitle
        contact.organizationName = parsed.company

        // Emails
        contact.emailAddresses = parsed.emails.enumerated().map { i, email in
            CNLabeledValue(label: i == 0 ? CNLabelWork : CNLabelOther,
                           value: email as NSString)
        }

        // Phones
        contact.phoneNumbers = parsed.phones.map {
            CNLabeledValue(label: CNLabelWork, value: CNPhoneNumber(stringValue: $0))
        }

        // Website + LinkedIn
        var urls: [CNLabeledValue<NSString>] = []
        if !parsed.website.isEmpty {
            urls.append(CNLabeledValue(label: CNLabelWork, value: parsed.website as NSString))
        }
        if !parsed.linkedinUrl.isEmpty {
            urls.append(CNLabeledValue(label: "LinkedIn", value: parsed.linkedinUrl as NSString))
        }
        contact.urlAddresses = urls

        // Address (simple single-line for now)
        if !parsed.address.isEmpty {
            let postal = CNMutablePostalAddress()
            postal.street = parsed.address
            contact.postalAddresses = [CNLabeledValue(label: CNLabelWork, value: postal)]
        }

        // Notes
        if !parsed.notes.isEmpty {
            contact.note = parsed.notes
        }

        // Photo
        if let photo = parsed.photo, let data = photo.jpegData(compressionQuality: 0.8) {
            contact.imageData = data
        }

        let store = CNContactStore()
        let req = CNSaveRequest()
        req.add(contact, toContainerWithIdentifier: nil)
        try store.execute(req)
    }
}
