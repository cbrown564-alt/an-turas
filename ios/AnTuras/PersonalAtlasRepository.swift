import CryptoKit
import Foundation

/// One remotely fetchable, independently correctable personal-atlas subject.
/// The signing key is pinned by the app; it never comes from this manifest.
struct PersonalAtlasArtifact: Codable, Hashable {
    let subjectId: String
    let version: String
    let path: String
    let sha256: String
    let signature: String
    let contentDate: String
}

struct PersonalAtlasReleaseManifest: Codable, Hashable {
    let releaseId: String
    let version: String
    let contentDate: String
    let publicKeyId: String
    let artifacts: [PersonalAtlasArtifact]

    func artifact(for subjectId: String) -> PersonalAtlasArtifact? {
        artifacts.first { $0.subjectId == subjectId }
    }
}

enum PersonalAtlasRepositoryError: Error, LocalizedError {
    case missingArtifact(String)
    case invalidURL(String)
    case invalidDigest
    case invalidSignature
    case invalidPublicKey
    case invalidResponse
    case malformedSubject

    var errorDescription: String? {
        switch self {
        case .missingArtifact:
            return "This subject is not included in the current reviewed release."
        case .invalidURL:
            return "The reviewed detail pack has an invalid address."
        case .invalidDigest, .invalidSignature, .invalidPublicKey:
            return "The reviewed detail pack could not be authenticated."
        case .invalidResponse:
            return "The reviewed detail pack is unavailable right now."
        case .malformedSubject:
            return "The reviewed detail pack could not be read."
        }
    }
}

enum PersonalAtlasPackVerifier {
    static func digestHex(for data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func verify(
        _ data: Data,
        artifact: PersonalAtlasArtifact,
        publicKey: Data
    ) throws {
        guard digestHex(for: data) == artifact.sha256.lowercased() else {
            throw PersonalAtlasRepositoryError.invalidDigest
        }
        guard let signature = Data(base64Encoded: artifact.signature) else {
            throw PersonalAtlasRepositoryError.invalidSignature
        }
        let key: Curve25519.Signing.PublicKey
        do {
            key = try Curve25519.Signing.PublicKey(rawRepresentation: publicKey)
        } catch {
            throw PersonalAtlasRepositoryError.invalidPublicKey
        }
        guard key.isValidSignature(signature, for: data) else {
            throw PersonalAtlasRepositoryError.invalidSignature
        }
    }
}

actor PersonalAtlasDetailCache {
    private let directory: URL
    private let fileManager: FileManager

    init(directory: URL? = nil, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        if let directory {
            self.directory = directory
        } else {
            let support = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            self.directory = support.appendingPathComponent("PersonalAtlas", isDirectory: true)
        }
        try fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    func authenticatedData(
        for artifact: PersonalAtlasArtifact,
        publicKey: Data
    ) throws -> Data? {
        let url = cacheURL(for: artifact)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        do {
            try PersonalAtlasPackVerifier.verify(data, artifact: artifact, publicKey: publicKey)
            return data
        } catch {
            try? fileManager.removeItem(at: url)
            throw error
        }
    }

    func storeAuthenticated(
        _ data: Data,
        for artifact: PersonalAtlasArtifact,
        publicKey: Data
    ) throws {
        try PersonalAtlasPackVerifier.verify(data, artifact: artifact, publicKey: publicKey)
        try data.write(to: cacheURL(for: artifact), options: [.atomic])
    }

    func remove(subjectId: String) throws {
        let prefix = safeComponent(subjectId) + "-"
        for url in try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) where url.lastPathComponent.hasPrefix(prefix) {
            try fileManager.removeItem(at: url)
        }
    }

    private func cacheURL(for artifact: PersonalAtlasArtifact) -> URL {
        directory.appendingPathComponent(
            "\(safeComponent(artifact.subjectId))-\(safeComponent(artifact.version)).json"
        )
    }

    private func safeComponent(_ value: String) -> String {
        value.map { character in
            character.isLetter || character.isNumber || character == "." || character == "-"
                ? character
                : "_"
        }
        .reduce(into: "") { $0.append($1) }
    }
}

actor PersonalAtlasRepository {
    typealias Fetcher = @Sendable (URL) async throws -> (Data, URLResponse)

    private let baseURL: URL
    private let manifest: PersonalAtlasReleaseManifest
    private let pinnedPublicKey: Data
    private let cache: PersonalAtlasDetailCache
    private let fetcher: Fetcher

    init(
        baseURL: URL,
        manifest: PersonalAtlasReleaseManifest,
        pinnedPublicKey: Data,
        cache: PersonalAtlasDetailCache,
        fetcher: @escaping Fetcher = { url in
            try await URLSession.shared.data(from: url)
        }
    ) {
        self.baseURL = baseURL
        self.manifest = manifest
        self.pinnedPublicKey = pinnedPublicKey
        self.cache = cache
        self.fetcher = fetcher
    }

    /// Returns a cached authenticated subject first. Network failure therefore never
    /// erases a previously opened or saved result.
    func subject(id: String) async throws -> OriginSubject {
        guard let artifact = manifest.artifact(for: id) else {
            throw PersonalAtlasRepositoryError.missingArtifact(id)
        }
        if let data = try await cache.authenticatedData(
            for: artifact,
            publicKey: pinnedPublicKey
        ) {
            return try decodeSubject(data, expectedId: id)
        }

        guard let url = URL(string: artifact.path, relativeTo: baseURL)?.absoluteURL else {
            throw PersonalAtlasRepositoryError.invalidURL(artifact.path)
        }
        let (data, response) = try await fetcher(url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw PersonalAtlasRepositoryError.invalidResponse
        }
        try await cache.storeAuthenticated(data, for: artifact, publicKey: pinnedPublicKey)
        return try decodeSubject(data, expectedId: id)
    }

    private func decodeSubject(_ data: Data, expectedId: String) throws -> OriginSubject {
        guard let subject = try? JSONDecoder().decode(OriginSubject.self, from: data),
              subject.id == expectedId else {
            throw PersonalAtlasRepositoryError.malformedSubject
        }
        return subject
    }
}
