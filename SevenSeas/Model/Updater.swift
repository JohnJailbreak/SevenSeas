//
//  Updater.swift
//  SevenSeas
//
//  Checks GitHub for a newer SevenSeas and hands it to TrollStore. This is Octopus's updater (Updater.swift), which
//  is Speaka's and Caz's, which follow Dopamine's (DOUIManager, DOUpdateViewController, DODownloadViewController).
//  Dopamine: Copyright (c) 2023-2024 Lars Fröder (opa334), MIT License (see NOTICE.md).
//
//  Octopus downloads the .tipa itself and installs it through its own root helper. SevenSeas has no helper, so
//  `install()` hands the release's link to TrollStore, which downloads and installs it. That is the only difference;
//  when a privileged helper exists, `install()` is the one place to change.
//

import Combine
import Foundation
import UIKit

/// One GitHub release of SevenSeas: its title (the version), its notes (the changelog) and the app it carries.
struct AppRelease: Identifiable, Equatable {
    let id: Int
    let name: String
    let body: String
    let version: [Int]
    let tipaURL: URL?
}

final class Updater: ObservableObject {
    /// Settings > Check for Updates, and the line under it.
    enum ManualCheck: Equatable {
        case idle
        case checking
        case upToDate(String)   // the version that's installed
        case failed(String)     // why: you're offline, GitHub's limit, ...
    }

    /// What a check ends in: an update to show, nothing newer, or why it couldn't.
    enum CheckResult: Equatable {
        case available
        case upToDate
        case failed(String)
    }

    static let apiURL = URL(string: "https://api.github.com/repos/JohnJailbreak/SevenSeas/releases")!
    static let releasesPage = URL(string: "https://github.com/JohnJailbreak/SevenSeas/releases")!

    /// Releases newer than this app, newest first: the changelog.
    @Published private(set) var updates: [AppRelease] = []
    /// The newest release whose app is newer than this one, if any.
    @Published private(set) var available: AppRelease? = nil
    @Published private(set) var manual: ManualCheck = .idle
    /// When SevenSeas last got an answer from GitHub.
    @Published private(set) var lastChecked: Date? = UpdatePrefs.lastCheck
    /// Set while TrollStore is being opened, so the Update button can't be tapped twice.
    @Published private(set) var handingOff = false

    private var checking = false
    private var checked = false
    private var waiting: [(CheckResult) -> Void] = []
    private var lastFetch: Date? = nil
    /// Settings > Update notifications, while SevenSeas is open: the check again every 2 minutes.
    private var watchTimer: Timer?

    var isAvailable: Bool { return available != nil }

    func watch(_ on: Bool) {
        watchTimer?.invalidate()
        watchTimer = nil
        guard on else { return }
        watchTimer = Timer.scheduledTimer(withTimeInterval: UpdateNotifications.interval, repeats: true) { [weak self] _ in
            self?.check(again: true)
        }
    }

    // MARK: - Checking

    /// Fetches the releases once per launch, or `again`. Drafts and pre-releases are ignored, as in Caz and Dopamine.
    /// Every caller of a check in flight gets its answer.
    func check(again: Bool = false, completion: ((CheckResult) -> Void)? = nil) {
        if let completion { waiting.append(completion) }
        guard !checking else { return }
        guard again || !checked else {
            finishCheck(isAvailable ? .available : .upToDate)
            return
        }
        checking = true
        Self.fetchReleases { [weak self] outcome in
            DispatchQueue.main.async {
                guard let self else { return }
                self.checking = false
                self.lastFetch = Date()
                switch outcome {
                case .failure(let failure):
                    self.finishCheck(.failed(failure.reason))   // offline or rate limited: the next check tries again
                case .success(let releases):
                    self.checked = true
                    self.lastChecked = UpdatePrefs.lastCheck
                    self.choose(from: releases, app: Self.versionParts(AppInfo.version))
                    self.finishCheck(self.isAvailable ? .available : .upToDate)
                }
            }
        }
    }

    /// When SevenSeas comes to the front: a fresh check, so the Update Available a notification promised is there at
    /// once, unless one answered in the last 20 s (switching apps back and forth).
    func checkOnActivation() {
        refreshLastChecked()
        if let lastFetch, Date().timeIntervalSince(lastFetch) < 20 { return }
        check(again: true)
    }

    /// Settings > Check for Updates: always a fresh check; its outcome is the line under the button.
    func checkNow(completion: ((CheckResult) -> Void)? = nil) {
        guard manual != .checking else {
            if let completion { waiting.append(completion) }
            return
        }
        manual = .checking
        check(again: true) { [weak self] result in
            guard let self else { return }
            switch result {
            case .available: self.manual = .idle
            case .upToDate: self.manual = .upToDate(AppInfo.version)
            case .failed(let reason): self.manual = .failed(reason)
            }
            completion?(result)
        }
    }

    func refreshLastChecked() {
        let when = UpdatePrefs.lastCheck
        if when != lastChecked { lastChecked = when }
    }

    private func finishCheck(_ result: CheckResult) {
        let callers = waiting
        waiting = []
        callers.forEach { $0(result) }
    }

    func choose(from releases: [AppRelease], app: [Int]) {
        let chosen = Self.select(from: releases, app: app)
        if chosen.available != available { available = chosen.available }
        if chosen.updates != updates { updates = chosen.updates }
    }

    /// The newest release that carries the app, if it's newer than `app`, and every release newer than `app`, newest
    /// first, for the changelog.
    static func select(from releases: [AppRelease], app: [Int]) -> (available: AppRelease?, updates: [AppRelease]) {
        let newest = releases.sorted { compare($0.version, $1.version) > 0 }
        var available: AppRelease? = nil
        if let release = newest.first(where: { $0.tipaURL != nil }), compare(release.version, app) > 0 {
            available = release
        }
        return (available, newest.filter { compare($0.version, app) > 0 })
    }

    // MARK: - The release list, from GitHub

    /// Every check goes through here: the app's, its background one and Settings > Check for Updates. It asks with the
    /// last answer's ETag: an unchanged list comes back as 304, which doesn't count against GitHub's 60 unauthenticated
    /// requests an hour, and the answer kept in memory is used. A failure says why, for the line under Check for Updates.
    private static let api: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()
    private static let answerLock = NSLock()
    private static var lastAnswer: (etag: String, body: Data)? = nil

    static func fetchReleases(completion: @escaping (Result<[AppRelease], FetchFailure>) -> Void) {
        var request = URLRequest(url: apiURL, timeoutInterval: 20)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        answerLock.lock(); let previous = lastAnswer; answerLock.unlock()
        if let previous { request.setValue(previous.etag, forHTTPHeaderField: "If-None-Match") }
        api.dataTask(with: request) { data, response, error in
            if let error = error as? URLError {
                completion(.failure(FetchFailure(Self.describe(error))))
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(FetchFailure(error?.localizedDescription ?? "GitHub didn't answer")))
                return
            }
            var body = data
            switch http.statusCode {
            case 200:
                if let data, let etag = http.value(forHTTPHeaderField: "ETag") {
                    Self.answerLock.lock(); Self.lastAnswer = (etag, data); Self.answerLock.unlock()
                }
            case 304 where previous != nil:
                body = previous?.body
            default:
                completion(.failure(FetchFailure(Self.describe(http))))
                return
            }
            guard let body, let releases = Self.parse(body) else {
                completion(.failure(FetchFailure("GitHub's answer couldn't be read")))
                return
            }
            UpdatePrefs.lastCheck = Date()
            completion(.success(releases))
        }.resume()
    }

    struct FetchFailure: Error {
        let reason: String
        init(_ reason: String) { self.reason = reason }
    }

    static func describe(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            return "you're offline"
        case .timedOut:
            return "GitHub didn't answer"
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return "GitHub couldn't be reached"
        default:
            return error.localizedDescription
        }
    }

    static func describe(_ response: HTTPURLResponse) -> String {
        if response.statusCode == 403 || response.statusCode == 429,
           response.value(forHTTPHeaderField: "X-RateLimit-Remaining") == "0" {
            if let reset = response.value(forHTTPHeaderField: "X-RateLimit-Reset").flatMap(Double.init) {
                let time = DateFormatter.localizedString(from: Date(timeIntervalSince1970: reset), dateStyle: .none,
                                                         timeStyle: .short)
                return "GitHub's hourly limit is used up until \(time)"
            }
            return "GitHub's hourly limit is used up"
        }
        return "GitHub answered \(response.statusCode)"
    }

    private struct APIRelease: Decodable {
        struct Asset: Decodable {
            let name: String
            let browserDownloadUrl: String
        }
        let id: Int
        let tagName: String
        let name: String?
        let body: String?
        let draft: Bool
        let prerelease: Bool
        let assets: [Asset]
    }

    static func parse(_ data: Data) -> [AppRelease]? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let list = try? decoder.decode([APIRelease].self, from: data) else { return nil }
        return list.compactMap { release -> AppRelease? in
            if release.draft || release.prerelease { return nil }
            let version = versionParts(release.tagName)
            if version.isEmpty { return nil }
            let title = release.name.flatMap { $0.isEmpty ? nil : $0 } ?? release.tagName
            return AppRelease(id: release.id, name: title, body: release.body ?? "", version: version,
                              tipaURL: link(in: release.assets, ending: ".tipa") ?? link(in: release.assets, ending: ".ipa"))
        }
    }

    private static func link(in assets: [APIRelease.Asset], ending suffix: String) -> URL? {
        guard let asset = assets.first(where: { $0.name.lowercased().hasSuffix(suffix) }) else { return nil }
        return URL(string: asset.browserDownloadUrl)
    }

    /// "v1.0.7" -> [1, 0, 7]
    static func versionParts(_ text: String) -> [Int] {
        return text.split(whereSeparator: { !$0.isASCII || !$0.isNumber }).compactMap { Int($0) }
    }

    static func compare(_ a: [Int], _ b: [Int]) -> Int {
        for index in 0..<max(a.count, b.count) {
            let x = index < a.count ? a[index] : 0
            let y = index < b.count ? b[index] : 0
            if x != y { return x < y ? -1 : 1 }
        }
        return 0
    }

    // MARK: - Installing

    /// TrollStore installs from a link with `apple-magnifier://install?url=`, the same hand-off Caz, Speaka, Octopus
    /// and Dopamine use: TrollStore downloads the .tipa and installs it, and SevenSeas closes when it does. Without
    /// TrollStore, the releases page opens instead.
    ///
    /// This is where a privileged helper would go: download the asset, then have the helper run TrollStore's installer
    /// on the local file (Octopus's `install-update`).
    func install() {
        guard !handingOff, let url = available?.tipaURL else {
            UIApplication.shared.open(Self.releasesPage)
            return
        }
        guard let link = URL(string: "apple-magnifier://install?url=" + url.absoluteString) else {
            UIApplication.shared.open(Self.releasesPage)
            return
        }
        handingOff = true
        UIApplication.shared.open(link, options: [:]) { [weak self] opened in
            DispatchQueue.main.async {
                self?.handingOff = false
                if !opened { UIApplication.shared.open(Updater.releasesPage) }
            }
        }
    }
}

/// What the updater remembers between launches.
enum UpdatePrefs {
    private static let notifiedKey = "sevenseas.update.notifiedVersion"
    private static let lastCheckKey = "sevenseas.update.lastCheck"
    private static let enabledKey = "sevenseas.update.notifications"

    /// Settings > Update notifications. Off until iOS has allowed notifications.
    static var notificationsEnabled: Bool {
        get { return UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    /// The release already announced, so it is announced once however it was found.
    static var notifiedVersion: String? {
        get { return UserDefaults.standard.string(forKey: notifiedKey) }
        set { UserDefaults.standard.set(newValue, forKey: notifiedKey) }
    }

    static var lastCheck: Date? {
        get { return UserDefaults.standard.object(forKey: lastCheckKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastCheckKey) }
    }
}
