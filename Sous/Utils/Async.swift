import Foundation
// https://stackoverflow.com/questions/75019438/swift-have-a-timeout-for-async-await-function

public func withTimeout<T>(_ duration: TimeInterval, work: @escaping () async throws -> T) async throws -> T {
    let workTask = Task {
          let taskResult = try await work()
          try Task.checkCancellation()
          return taskResult
      }

      let timeoutTask = Task {
          try await Task.sleep(seconds: duration)
          workTask.cancel()
      }

    do {
        let result = try await workTask.value
        timeoutTask.cancel()
        return result
    } catch {
        if (error as? CancellationError) != nil {
            throw TimeoutErrors.timeoutElapsed
        } else {
            throw error
        }
    }
}

public enum TimeoutErrors: Error {
    case timeoutElapsed
}

public extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

public extension DispatchQueue {
    func performAsyncThrowing<Result>(_ block: @escaping () throws -> Result) async throws -> Result {
        try await withCheckedThrowingContinuation { cont in
            self.async {
                do {
                    let result = try block()
                    cont.resume(returning: result)
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    func performAsync<Result>(_ block: @escaping () -> Result) async -> Result {
        await withCheckedContinuation { cont in
            self.async {
                let result = block()
                cont.resume(returning: result)
            }
        }
    }
}
