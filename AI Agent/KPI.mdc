# Key Performance Indicators (KPIs)

## Functional KPIs
- **Sync Delta Accuracy**: 100% of serialized sync payloads must contain only modified fields since the last successful sync time.
  - *Target*: 100%
  - *Pass/Fail*: Fail if any unmodified field is sent in a sync payload.
- **Funnel Progression Tracking**: 100% of defined funnels must correctly capture steps in the correct order.
  - *Target*: 100%
  - *Pass/Fail*: Fail if steps completed out of order are logged as completed.

## Technical KPIs
- **Swift 6 Concurrency Compliance**: Zero compiler errors or warnings under Swift 6 strict concurrency checks.
  - *Target*: 0 warnings/errors.
  - *Pass/Fail*: Fail if any compiler warning is produced in release configuration.
- **Dependency Isolation**: No direct dependencies on third-party frameworks.
  - *Target*: 0 external frameworks.
  - *Pass/Fail*: Fail if any Cocoapods, SwiftPM, or Carthage packages are imported outside Apple core libraries.

## Performance KPIs
- **Analytics Auto-Instrumentation Overhead**: The time added to `viewDidAppear` by swizzled analytics trackers must be minimal.
  - *Target*: < 2.0ms.
  - *Pass/Fail*: Fail if instrumentation overhead exceeds 5.0ms on test devices (iPhone 13 or newer).
- **Delta Sync Payload Serialization Time**: Time to identify and serialize modified fields.
  - *Target*: < 50ms for a dataset of 100 records.
  - *Pass/Fail*: Fail if serialization takes > 150ms.

## Reliability KPIs
- **Background Sync Completion Rate**: The background task completes successfully without being terminated by the OS.
  - *Target*: > 98% of scheduled tasks.
  - *Pass/Fail*: Fail if background task failure rate due to execution timeouts exceeds 5%.
- **Event Buffer Persistence**: Analytics events are successfully saved to disk if the network is down.
  - *Target*: 100% persistent retention.
  - *Pass/Fail*: Fail if any event is lost during app crash while offline.

## Security KPIs
- **Consent Gate Security**: Zero events tracked or sent before consent is recorded.
  - *Target*: 0 events.
  - *Pass/Fail*: Fail if a network request is dispatched before consent is granted.
- **Credential Storage Safety**: Auth tokens utilized by background sync must reside in Keychain.
  - *Target*: 100% Keychain storage.
  - *Pass/Fail*: Fail if credentials are written to UserDefaults or logs.

## User Experience KPIs
- **App Crash Mitigation**: Swizzling or tracking must not cause app crashes.
  - *Target*: 0% crash rate in SDK-owned code paths.
  - *Pass/Fail*: Fail if any runtime crash is traced back to swizzling routines.

## Acceptance Criteria
- [ ] All tests in test suite pass.
- [ ] Swizzling executes safely across all supported iOS/macOS versions (iOS 15+, macOS 12+).
- [ ] Memory footprint does not grow continuously (no leaks under heavy sync loop).
