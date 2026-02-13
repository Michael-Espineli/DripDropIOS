protocol LaborContractRepository {
    func fetchContracts(for userId: String) async throws -> [LaborContract]
    func save(_ contract: LaborContract) async throws
}

final class FirestoreLaborContractRepository: LaborContractRepository {
    private let db: Firestore

    init(db: Firestore = FirebaseManager.shared.db) {
        self.db = db
    }

    func fetchContracts(for userId: String) async throws -> [LaborContract] {
        let snapshot = try await db.collection("laborContracts")
            .whereField("receiverId", isEqualTo: userId)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try doc.data(as: LaborContract.self)
        }
    }

    func save(_ contract: LaborContract) async throws {
        // Ensure your document ID strategies are consistent across envs
        try db.collection("laborContracts").document(contract.id).setData(from: contract)
    }
}