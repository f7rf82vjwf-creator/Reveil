import SwiftUI
import UIKit
import AVFoundation
import Photos
import CoreLocation
import UserNotifications
import Network

// MARK: - Security Dashboard

struct SecurityDashboardView: View {

    @StateObject private var model = SecurityDashboardModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                overview

                protectionStatus

                permissionSection

                checksSection

                if !model.issues.isEmpty {
                    issuesSection
                }
            }
            .padding()
        }
        .navigationTitle("보안 진단")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    model.scan()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(model.isScanning)
            }
        }
        .onAppear {
            model.start()
        }
        .onDisappear {
            model.stop()
        }
    }

    // MARK: Overview

    private var overview: some View {
        VStack(spacing: 14) {

            HStack(spacing: 14) {

                ZStack {
                    Circle()
                        .fill(model.overall.color.opacity(0.15))
                        .frame(width: 62, height: 62)

                    if model.isScanning {
                        ProgressView()
                    } else {
                        Image(systemName: model.overall.icon)
                            .font(.system(size: 27, weight: .bold))
                            .foregroundColor(model.overall.color)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("종합 보안 상태")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(model.overall.title)
                        .font(.title3.bold())

                    Text(model.overall.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            HStack {
                statistic(
                    value: model.safeCount,
                    title: "정상",
                    color: .green
                )

                Spacer()

                statistic(
                    value: model.warningCount,
                    title: "주의",
                    color: .orange
                )

                Spacer()

                statistic(
                    value: model.dangerCount,
                    title: "위험",
                    color: .red
                )
            }

            if let date = model.lastScan {
                Text(
                    "마지막 검사: " +
                    date.formatted(
                        date: .omitted,
                        time: .standard
                    )
                )
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func statistic(
        value: Int,
        title: String,
        color: Color
    ) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: Protection

    private var protectionStatus: some View {
        VStack(alignment: .leading, spacing: 12) {

            Label("권한 보호", systemImage: "shield.lefthalf.filled")
                .font(.headline)

            Text(
                "Reveil은 iOS가 제공하는 권한 상태와 실행 환경의 보안 지표를 검사합니다."
            )
            .font(.caption)
            .foregroundColor(.secondary)

            protectionRow(
                title: "탈옥 환경",
                status: model.jailbreakStatus
            )

            protectionRow(
                title: "Debugger",
                status: model.debuggerStatus
            )

            protectionRow(
                title: "Runtime 환경",
                status: model.runtimeStatus
            )

            protectionRow(
                title: "네트워크 Proxy",
                status: model.proxyStatus
            )
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func protectionRow(
        title: String,
        status: SecurityStatus
    ) -> some View {
        HStack {
            Text(title)

            Spacer()

            Image(systemName: status.icon)
                .foregroundColor(status.color)

            Text(status.title)
                .font(.caption.bold())
                .foregroundColor(status.color)
        }
    }

    // MARK: Permissions

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Label(
                    "Reveil 권한",
                    systemImage: "lock.shield"
                )
                .font(.headline)

                Spacer()

                Button("설정") {
                    openAppSettings()
                }
                .font(.caption.bold())
            }

            Text(
                "아래 권한은 Reveil 앱 자체에 대한 iOS 권한입니다. " +
                "다른 앱의 권한은 일반 앱에서 직접 변경하거나 조회할 수 없습니다."
            )
            .font(.caption)
            .foregroundColor(.secondary)

            ForEach(model.permissions) { permission in
                permissionRow(permission)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func permissionRow(
        _ permission: PermissionItem
    ) -> some View {
        HStack(spacing: 12) {

            Image(systemName: permission.icon)
                .frame(width: 28)
                .foregroundColor(permission.status.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(permission.title)
                    .font(.subheadline)

                Text(permission.status.title)
                    .font(.caption)
                    .foregroundColor(permission.status.color)
            }

            Spacer()

            Image(systemName: permission.status.icon)
                .foregroundColor(permission.status.color)
        }
        .padding(.vertical, 4)
    }

    // MARK: Checks

    private var checksSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            Label(
                "보안 검사",
                systemImage: "checkmark.shield"
            )
            .font(.headline)

            ForEach(model.checks) { check in
                checkRow(check)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func checkRow(
        _ check: SecurityCheck
    ) -> some View {
        HStack(spacing: 12) {

            Image(systemName: check.icon)
                .foregroundColor(check.status.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(check.title)
                    .font(.subheadline.bold())

                Text(check.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            Spacer()

            Image(systemName: check.status.icon)
                .foregroundColor(check.status.color)
        }
        .padding(.vertical, 4)
    }

    // MARK: Issues

    private var issuesSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            Label(
                "감지된 문제",
                systemImage: "exclamationmark.shield.fill"
            )
            .font(.headline)

            ForEach(model.issues) { issue in
                VStack(alignment: .leading, spacing: 7) {

                    HStack {
                        Image(systemName: issue.status.icon)
                            .foregroundColor(issue.status.color)

                        Text(issue.title)
                            .font(.subheadline.bold())

                        Spacer()
                    }

                    Text(issue.message)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("권장 조치: \(issue.recommendation)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    issue.status.color.opacity(0.08)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 10)
                )
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Settings

    private func openAppSettings() {
        guard let url = URL(
            string: UIApplication.openSettingsURLString
        ) else {
            return
        }

        UIApplication.shared.open(url)
    }
}


// MARK: - Model

@MainActor
final class SecurityDashboardModel: ObservableObject {

    @Published private(set) var checks: [SecurityCheck] = []
    @Published private(set) var issues: [SecurityIssue] = []
    @Published private(set) var permissions: [PermissionItem] = []

    @Published private(set) var isScanning = false
    @Published private(set) var lastScan: Date?

    private var timer: Timer?

    var safeCount: Int {
        checks.filter { $0.status == .safe }.count
    }

    var warningCount: Int {
        checks.filter { $0.status == .warning }.count
    }

    var dangerCount: Int {
        checks.filter { $0.status == .danger }.count
    }

    var overall: SecurityOverall {
        if dangerCount > 0 {
            return .danger
        }

        if warningCount > 0 {
            return .warning
        }

        if checks.isEmpty {
            return .unknown
        }

        return .safe
    }

    var jailbreakStatus: SecurityStatus {
        statusFor(
            title: "탈옥",
            danger: checks.first {
                $0.title == "탈옥 상태"
            }?.status
        )
    }

    var debuggerStatus: SecurityStatus {
        statusFor(
            title: "Debugger",
            danger: checks.first {
                $0.title == "Debugger"
            }?.status
        )
    }

    var runtimeStatus: SecurityStatus {
        statusFor(
            title: "Runtime",
            danger: checks.first {
                $0.title == "리버스 엔지니어링"
            }?.status
        )
    }

    var proxyStatus: SecurityStatus {
        statusFor(
            title: "HTTP Proxy",
            danger: checks.first {
                $0.title == "HTTP Proxy"
            }?.status
        )
    }

    func start() {
        scan()

        timer?.invalidate()

        timer = Timer.scheduledTimer(
            withTimeInterval: 10,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.scan()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func scan() {

        guard !isScanning else {
            return
        }

        isScanning = true

        Task.detached(priority: .userInitiated) {

            let result = SecurityScanner.scan()

            await MainActor.run {
                self.checks = result.checks
                self.issues = result.issues
                self.permissions = PermissionScanner.scan()
                self.lastScan = Date()
                self.isScanning = false
            }
        }
    }

    private func statusFor(
        title: String,
        danger: SecurityCheckStatus?
    ) -> SecurityStatus {

        guard let danger else {
            return .unknown
        }

        switch danger {
        case .safe:
            return .safe
        case .warning:
            return .warning
        case .danger:
            return .danger
        case .unknown:
            return .unknown
        }
    }
}


// MARK: - Security Scanner

enum SecurityScanner {

    static func scan() -> SecurityScanResult {

        var checks: [SecurityCheck] = []
        var issues: [SecurityIssue] = []

        // Jailbreak

        let jailbreak =
            IOSSecuritySuite.amIJailbrokenWithFailMessage()

        if jailbreak.jailbroken {

            checks.append(
                SecurityCheck(
                    title: "탈옥 상태",
                    icon: "iphone.gen3.badge.exclamationmark",
                    status: .danger,
                    message: jailbreak.failMessage.isEmpty
                        ? "탈옥 의심 지표가 감지되었습니다."
                        : jailbreak.failMessage
                )
            )

            issues.append(
                SecurityIssue(
                    title: "탈옥 환경 의심",
                    status: .danger,
                    message: jailbreak.failMessage,
                    recommendation:
                        "기기의 탈옥 및 시스템 변조 여부를 확인하세요."
                )
            )

        } else {

            checks.append(
                SecurityCheck(
                    title: "탈옥 상태",
                    icon: "iphone.gen3",
                    status: .safe,
                    message:
                        "현재 검사에서 주요 탈옥 지표가 감지되지 않았습니다."
                )
            )
        }

        // Debugger

        let debugger =
            IOSSecuritySuite.amIDebugged()

        checks.append(
            SecurityCheck(
                title: "Debugger",
                icon: "ladybug",
                status: debugger ? .danger : .safe,
                message: debugger
                    ? "디버깅 환경이 감지되었습니다."
                    : "디버거가 감지되지 않았습니다."
            )
        )

        if debugger {
            issues.append(
                SecurityIssue(
                    title: "Debugger 감지",
                    status: .danger,
                    message:
                        "앱 프로세스가 디버깅되고 있을 가능성이 있습니다.",
                    recommendation:
                        "릴리스 환경이라면 실행 환경을 확인하세요."
                )
            )
        }

        // Emulator

        let emulator =
            IOSSecuritySuite.amIRunInEmulator()

        checks.append(
            SecurityCheck(
                title: "실행 환경",
                icon: "iphone",
                status: emulator ? .warning : .safe,
                message: emulator
                    ? "에뮬레이터 환경입니다."
                    : "실제 iOS 기기 환경입니다."
            )
        )

        // Reverse engineering

        let reverse =
            IOSSecuritySuite.amIReverseEngineeredWithFailedChecks()

        checks.append(
            SecurityCheck(
                title: "리버스 엔지니어링",
                icon: "wrench.and.screwdriver",
                status: reverse.reverseEngineered
                    ? .danger
                    : .safe,
                message: reverse.reverseEngineered
                    ? "\(reverse.failedChecks.count)개의 관련 지표가 감지되었습니다."
                    : "관련 지표가 감지되지 않았습니다."
            )
        )

        if reverse.reverseEngineered {
            issues.append(
                SecurityIssue(
                    title: "리버스 엔지니어링 지표",
                    status: .danger,
                    message:
                        "\(reverse.failedChecks.count)개의 관련 검사에서 문제가 발견되었습니다.",
                    recommendation:
                        "분석 도구나 변조된 실행 환경 여부를 확인하세요."
                )
            )
        }

        // Proxy

        let proxy =
            IOSSecuritySuite.amIProxied()

        checks.append(
            SecurityCheck(
                title: "HTTP Proxy",
                icon: "network",
                status: proxy ? .warning : .safe,
                message: proxy
                    ? "HTTP Proxy 설정이 감지되었습니다."
                    : "HTTP Proxy가 감지되지 않았습니다."
            )
        )

        if proxy {
            issues.append(
                SecurityIssue(
                    title: "HTTP Proxy 감지",
                    status: .warning,
                    message:
                        "시스템 HTTP Proxy 설정이 감지되었습니다.",
                    recommendation:
                        "의도한 테스트 설정이 아니라면 네트워크 설정을 확인하세요."
                )
            )
        }

        return SecurityScanResult(
            checks: checks,
            issues: issues
        )
    }
}


// MARK: - Permissions

enum PermissionScanner {

    static func scan() -> [PermissionItem] {

        var result: [PermissionItem] = []

        // Camera

        let camera =
            AVCaptureDevice.authorizationStatus(
                for: .video
            )

        result.append(
            PermissionItem(
                title: "카메라",
                icon: "camera",
                status: cameraStatus(camera)
            )
        )

        // Microphone

        let microphone =
            AVCaptureDevice.authorizationStatus(
                for: .audio
            )

        result.append(
            PermissionItem(
                title: "마이크",
                icon: "mic",
                status: microphoneStatus(microphone)
            )
        )

        // Photos

        let photos =
            PHPhotoLibrary.authorizationStatus(
                for: .readWrite
            )

        result.append(
            PermissionItem(
                title: "사진",
                icon: "photo",
                status: photoStatus(photos)
            )
        )

        // Notifications

        let semaphore = DispatchSemaphore(value: 0)

        var notificationStatus =
            PermissionState.unknown

        UNUserNotificationCenter.current()
            .getNotificationSettings { settings in

                notificationStatus =
                    notificationPermissionStatus(
                        settings.authorizationStatus
                    )

                semaphore.signal()
            }

        semaphore.wait()

        result.append(
            PermissionItem(
                title: "알림",
                icon: "bell",
                status: notificationStatus
            )
        )

        return result
    }

    private static func cameraStatus(
        _ status: AVAuthorizationStatus
    ) -> PermissionState {

        switch status {
        case .authorized:
            return .allowed
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notRequested
        @unknown default:
            return .unknown
        }
    }

    private static func microphoneStatus(
        _ status: AVAuthorizationStatus
    ) -> PermissionState {

        cameraStatus(status)
    }

    private static func photoStatus(
        _ status: PHAuthorizationStatus
    ) -> PermissionState {

        switch status {
        case .authorized:
            return .allowed
        case .limited:
            return .limited
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notRequested
        @unknown default:
            return .unknown
        }
    }

    private static func notificationPermissionStatus(
        _ status: UNAuthorizationStatus
    ) -> PermissionState {

        switch status {
        case .authorized, .provisional, .ephemeral:
            return .allowed
        case .denied:
            return .denied
        case .notDetermined:
            return .notRequested
        @unknown default:
            return .unknown
        }
    }
}


// MARK: - Models

struct SecurityScanResult {
    let checks: [SecurityCheck]
    let issues: [SecurityIssue]
}

struct SecurityCheck: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let status: SecurityCheckStatus
    let message: String
}

struct SecurityIssue: Identifiable {
    let id = UUID()
    let title: String
    let status: SecurityCheckStatus
    let message: String
    let recommendation: String
}

struct PermissionItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let status: PermissionState
}


// MARK: - Status

enum SecurityCheckStatus {
    case safe
    case warning
    case danger
    case unknown

    var title: String {
        switch self {
        case .safe:
            return "정상"
        case .warning:
            return "주의"
        case .danger:
            return "위험"
        case .unknown:
            return "확인 필요"
        }
    }

    var icon: String {
        switch self {
        case .safe:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .danger:
            return "xmark.octagon.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .safe:
            return .green
        case .warning:
            return .orange
        case .danger:
            return .red
        case .unknown:
            return .gray
        }
    }
}

enum PermissionState {
    case allowed
    case denied
    case restricted
    case limited
    case notRequested
    case unknown

    var title: String {
        switch self {
        case .allowed:
            return "허용"
        case .denied:
            return "거부"
        case .restricted:
            return "제한됨"
        case .limited:
            return "제한적 허용"
        case .notRequested:
            return "요청하지 않음"
        case .unknown:
            return "확인 필요"
        }
    }

    var icon: String {
        switch self {
        case .allowed, .limited:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .restricted:
            return "lock.fill"
        case .notRequested:
            return "minus.circle"
        case .unknown:
            return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .allowed:
            return .green
        case .limited:
            return .orange
        case .denied:
            return .red
        case .restricted:
            return .orange
        case .notRequested:
            return .gray
        case .unknown:
            return .gray
        }
    }
}

enum SecurityStatus {
    case safe
    case warning
    case danger
    case unknown

    var title: String {
        switch self {
        case .safe:
            return "정상"
        case .warning:
            return "주의"
        case .danger:
            return "위험"
        case .unknown:
            return "확인 필요"
        }
    }

    var icon: String {
        switch self {
        case .safe:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .danger:
            return "xmark.octagon.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .safe:
            return .green
        case .warning:
            return .orange
        case .danger:
            return .red
        case .unknown:
            return .gray
        }
    }
}

enum SecurityOverall {
    case safe
    case warning
    case danger
    case unknown

    var title: String {
        switch self {
        case .safe:
            return "보안 상태 정상"
        case .warning:
            return "보안 주의 필요"
        case .danger:
            return "보안 위험 감지"
        case .unknown:
            return "검사 중"
        }
    }

    var description: String {
        switch self {
        case .safe:
            return "주요 보안 문제가 발견되지 않았습니다."
        case .warning:
            return "일부 환경을 확인하는 것이 좋습니다."
        case .danger:
            return "중요한 보안 지표가 감지되었습니다."
        case .unknown:
            return "보안 검사를 실행하고 있습니다."
        }
    }

    var icon: String {
        switch self {
        case .safe:
            return "checkmark.shield.fill"
        case .warning:
            return "exclamationmark.shield.fill"
        case .danger:
            return "xmark.shield.fill"
        case .unknown:
            return "shield.lefthalf.filled"
        }
    }

    var color: Color {
        switch self {
        case .safe:
            return .green
        case .warning:
            return .orange
        case .danger:
            return .red
        case .unknown:
            return .gray
        }
    }
}