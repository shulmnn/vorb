import Foundation

struct MultipartFormData {
    let boundary: String
    private(set) var data = Data()

    init(boundary: String = "Vorb-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    mutating func addField(named name: String, value: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        append("\(value)\r\n")
    }

    mutating func addFile(named name: String, filename: String, mimeType: String, contents: Data) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        data.append(contents)
        append("\r\n")
    }

    mutating func finalize() {
        append("--\(boundary)--\r\n")
    }

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    private mutating func append(_ string: String) {
        data.append(Data(string.utf8))
    }
}
