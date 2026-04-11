import Foundation

struct GitHubClient {
    let token: String

    init() {
        self.token = ProcessInfo.processInfo.environment["GITHUB_TOKEN"] ?? ""
    }

    func postComment(markdown: String, repo: String, prNumber: Int) async throws {
        let url = URL(string: "https://api.github.com/repos/\(repo)/issues/\(prNumber)/comments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")

        // Check for existing SwiftGuard comment to update
        let existingCommentId = try await findExistingComment(repo: repo, prNumber: prNumber)

        if let commentId = existingCommentId {
            // Update existing comment
            let updateURL = URL(string: "https://api.github.com/repos/\(repo)/issues/comments/\(commentId)")!
            var updateRequest = URLRequest(url: updateURL)
            updateRequest.httpMethod = "PATCH"
            updateRequest.setValue("application/json", forHTTPHeaderField: "content-type")
            updateRequest.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
            updateRequest.httpBody = try JSONSerialization.data(withJSONObject: ["body": markdown])
            let (_, response) = try await URLSession.shared.data(for: updateRequest)
            let httpResponse = response as! HTTPURLResponse
            guard httpResponse.statusCode == 200 else {
                throw GitHubError.requestFailed(httpResponse.statusCode)
            }
        } else {
            request.httpBody = try JSONSerialization.data(withJSONObject: ["body": markdown])
            let (_, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as! HTTPURLResponse
            guard httpResponse.statusCode == 201 else {
                throw GitHubError.requestFailed(httpResponse.statusCode)
            }
        }

        print("   ✅ PR comment posted")
    }

    func requestReviewers(reviewers: [String], repo: String, prNumber: Int) async throws {
        let url = URL(string: "https://api.github.com/repos/\(repo)/pulls/\(prNumber)/requested_reviewers")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")

        let cleanReviewers = reviewers.map { $0.replacingOccurrences(of: "@", with: "") }
        request.httpBody = try JSONSerialization.data(withJSONObject: ["reviewers": cleanReviewers])

        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        guard httpResponse.statusCode == 201 else {
            print("   ⚠️ Failed to assign reviewers (status \(httpResponse.statusCode))")
            return
        }
        print("   ✅ Reviewers assigned: \(cleanReviewers.joined(separator: ", "))")
    }

    func addLabels(labels: [String], repo: String, prNumber: Int) async throws {
        let url = URL(string: "https://api.github.com/repos/\(repo)/issues/\(prNumber)/labels")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["labels": labels])

        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        guard httpResponse.statusCode == 200 else {
            print("   ⚠️ Failed to add labels (status \(httpResponse.statusCode))")
            return
        }
        print("   ✅ Labels applied: \(labels.joined(separator: ", "))")
    }

    private func findExistingComment(repo: String, prNumber: Int) async throws -> Int? {
        let url = URL(string: "https://api.github.com/repos/\(repo)/issues/\(prNumber)/comments?per_page=100")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let comments = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []

        for comment in comments {
            if let body = comment["body"] as? String, body.contains("SwiftGuard Report") {
                return comment["id"] as? Int
            }
        }
        return nil
    }
}

enum GitHubError: Error, LocalizedError {
    case requestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let code):
            return "GitHub API request failed with status \(code)"
        }
    }
}
