//
//  DashboardView.swift
//  Reveil
//
//  Created by Lessica on 2023/10/2.
//

import SwiftUI

#if canImport(UserNotifications)
import UserNotifications
#endif

struct DashboardView: View, GlobalTimerObserver {

    let id = UUID()
    let globalName: String = String(describing: Dashboard.self)

    @ObservedObject private var viewModel = Dashboard.shared
    @ObservedObject private var securityModel = Security.shared

    private static var isUserNotificationAuthorizationRequested = false
    private static var isUserNotificationAuthorizationRequestGranted = false

    // MARK: - Badge

    @available(iOS 16.0, *)
    private func updateBadgeCount() {
        #if canImport(UserNotifications)

        if !Self.isUserNotificationAuthorizationRequested {

            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.badge]) { succeed, _ in

                    if succeed {
                        let securityModelPresented =
                            PinStorage.shared.isPinned(forKey: .Security)

                        UNUserNotificationCenter.current().setBadgeCount(
                            securityModelPresented
                            ? Security.shared.numberOfInsecureChecks
                            : 0
                        )
                    }

                    Self.isUserNotificationAuthorizationRequestGranted = succeed
                    Self.isUserNotificationAuthorizationRequested = true
                }

        } else if Self.isUserNotificationAuthorizationRequestGranted {

            let securityModelPresented =
                PinStorage.shared.isPinned(forKey: .Security)

            UNUserNotificationCenter.current().setBadgeCount(
                securityModelPresented
                ? Security.shared.numberOfInsecureChecks
                : 0
            )
        }

        #endif
    }

    // MARK: - Body

    var body: some View {

        ScrollView(.vertical) {

            VStack(spacing: 20) {

                // =====================================================
                // 보안 진단 카드
                // =====================================================

                NavigationLink {
                    SecurityDashboardView()
                } label: {

                    HStack(spacing: 14) {

                        ZStack {

                            Circle()
                                .fill(Color.red.opacity(0.12))
                                .frame(
                                    width: 50,
                                    height: 50
                                )

                            Image(systemName: "shield.checkered")
                                .font(
                                    .system(
                                        size: 23,
                                        weight: .semibold
                                    )
                                )
                                .foregroundColor(.red)
                        }

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {

                            Text("보안 진단")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text(
                                "기기 보안 · 권한 · 탈옥 · 무결성 상태 확인"
                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        }

                        Spacer()

                        Image(
                            systemName: "chevron.right"
                        )
                        .font(
                            .system(
                                size: 14,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(.secondary)
                    }
                    .padding(15)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(
                            cornerRadius: 14
                        )
                        .fill(
                            Color(
                                PlatformColor
                                    .secondarySystemBackgroundAlias
                            )
                        )
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: 14
                        )
                        .stroke(
                            Color(
                                PlatformColor
                                    .separatorAlias
                            ),
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)

                // =====================================================
                // 기존 Security Check
                // =====================================================

                if PinStorage.shared.isPinned(forKey: .Security) {

                    Section {
                        CheckmarkWidget()
                    }
                }

                // =====================================================
                // 기존 Dashboard Widgets
                // =====================================================

                ForEach(
                    viewModel.entries,
                    id: \.key
                ) { entry in

                    Section {

                        widgetBuilder(entry)
                            .padding(.all, 12)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 4
                                )
                                .foregroundColor(
                                    Color(
                                        PlatformColor
                                            .secondarySystemBackgroundAlias
                                    )
                                )
                                .opacity(0.25)
                            )
                            .overlay {

                                RoundedRectangle(
                                    cornerRadius: 4
                                )
                                .stroke(
                                    Color(
                                        PlatformColor
                                            .separatorAlias
                                    ),
                                    lineWidth: 1
                                )
                            }
                            .overlay {

                                navigationLinkBuilder(entry)
                            }

                    }
                    .padding(
                        entry === viewModel.entries.last
                        ? .bottom
                        : [],
                        8
                    )
                    .listSectionSeparator(
                        hidden: true
                    )
                }
            }
            .padding()
        }

        // MARK: - Lifecycle

        .onAppear {

            if #available(iOS 16.0, *) {
                updateBadgeCount()
            }

            GlobalTimer.shared.addObserver(self)
        }

        .onDisappear {

            GlobalTimer.shared.removeObserver(self)
        }

        .onReceive(
            securityModel.$isLoading
        ) { isLoading in

            if #available(iOS 16.0, *) {

                if !isLoading {
                    updateBadgeCount()
                }

            } else {
                // Fallback on earlier versions
            }
        }
    }

    // MARK: - Widget Builder

    @ViewBuilder
    private func widgetBuilder(
        _ entry: any Entry
    ) -> some View {

        if let basicEntry = entry as? BasicEntry {

            fieldWidgetBuilder(basicEntry)

        } else if let usageEntry =
                    entry as? UsageEntry<Double> {

            usageWidgetBuilder(usageEntry)

        } else if let activityEntry =
                    entry as? ActivityEntry {

            activityWidgetBuilder(activityEntry)

        } else if let trafficEntryIO =
                    entry as? TrafficEntryIO {

            trafficWidgetBuilder(trafficEntryIO)
        }
    }

    // MARK: - Field

    @ViewBuilder
    private func fieldWidgetBuilder(
        _ entry: BasicEntry
    ) -> some View {

        FieldWidget(entry: entry)
    }

    // MARK: - Activity

    @ViewBuilder
    private func activityWidgetBuilder(
        _ entry: ActivityEntry
    ) -> some View {

        ActivityWidget(entry: entry)
    }

    // MARK: - Usage

    @ViewBuilder
    private func usageWidgetBuilder(
        _ entry: UsageEntry<Double>
    ) -> some View {

        UsageWidget(entry: entry)
    }

    // MARK: - Traffic

    @ViewBuilder
    private func trafficWidgetBuilder(
        _ entry: TrafficEntryIO
    ) -> some View {

        TrafficWidget(
            label: entry.name,
            style: .compat,
            receivedEntry: entry.download,
            sentEntry: entry.upload
        )
    }

    // MARK: - Navigation

    @ViewBuilder
    private func navigationLinkBuilder(
        _ entry: any Entry
    ) -> some View {

        NavigationLink(
            destination: {

                viewModel
                    .anyListView(key: entry.key)
                    .environmentObject(
                        HighlightedEntryKey(
                            object: entry.key
                        )
                    )
            },
            label: {
                Color.clear
            }
        )
        .contentShape(Rectangle())
    }

    // MARK: - Global Timer

    func eventOccurred(
        globalTimer timer: GlobalTimer
    ) {

        viewModel.updateEntries()
    }
}

// MARK: - Previews

struct DashboardView_Previews: PreviewProvider {

    static var previews: some View {

        DashboardView()
    }
}