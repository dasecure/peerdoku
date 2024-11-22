import GameKit

@MainActor
class GameCenterManager: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterManager()
    
    var isAuthenticated = false
    private var authenticationViewController: UIViewController?
    
    // Leaderboard IDs
    private enum LeaderboardID: String {
        case easyMode = "com.peerdoku.leaderboard.easy"
        case mediumMode = "com.peerdoku.leaderboard.medium"
        case hardMode = "com.peerdoku.leaderboard.hard"
        case expertMode = "com.peerdoku.leaderboard.expert"
        
        static func forDifficulty(_ difficulty: SudokuDifficulty) -> String {
            switch difficulty {
            case .easy: return easyMode.rawValue
            case .medium: return mediumMode.rawValue
            case .hard: return hardMode.rawValue
            case .expert: return expertMode.rawValue
            }
        }
    }
    
    func authenticatePlayer() {
        let localPlayer = GKLocalPlayer.local
        
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            if let error = error {
                print("Game Center authentication error: \(error.localizedDescription)")
                return
            }
            
            if let viewController = viewController {
                self?.authenticationViewController = viewController
                Task { @MainActor in
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(viewController, animated: true)
                    }
                }
            } else if localPlayer.isAuthenticated {
                self?.isAuthenticated = true
                print("Player authenticated in Game Center")
            } else {
                print("Game Center authentication failed")
                self?.isAuthenticated = false
            }
        }
    }
    
    func submitScore(_ score: Int, difficulty: SudokuDifficulty) {
        guard isAuthenticated else {
            print("Cannot submit score: Player not authenticated")
            return
        }
        
        let leaderboardID = LeaderboardID.forDifficulty(difficulty)
        
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboardID]
                )
                print("Score submitted successfully")
            } catch {
                print("Error submitting score: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in
            gameCenterViewController.dismiss(animated: true)
        }
    }
    
    func showLeaderboard() {
        guard isAuthenticated else {
            print("Cannot show leaderboard: Player not authenticated")
            return
        }
        
        Task { @MainActor in
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                let viewController = GKGameCenterViewController(state: .leaderboards)
                viewController.gameCenterDelegate = self
                rootViewController.present(viewController, animated: true)
            }
        }
    }
    
    // Calculate score based on difficulty, time, and mistakes
    func calculateScore(difficulty: SudokuDifficulty, time: TimeInterval, mistakes: Int) -> Int {
        let baseScore: Int
        switch difficulty {
        case .easy:   baseScore = 1000
        case .medium: baseScore = 2000
        case .hard:   baseScore = 3000
        case .expert: baseScore = 4000
        }
        
        // Deduct points for time (more points for faster completion)
        let timeDeduction = Int(time) * 2
        
        // Deduct points for mistakes
        let mistakeDeduction = mistakes * 200
        
        // Calculate final score
        let finalScore = max(0, baseScore - timeDeduction - mistakeDeduction)
        
        return finalScore
    }
} 