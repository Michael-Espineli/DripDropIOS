//
//  WorkOffer+Counts.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//

import Foundation

extension WorkOffer {
    var isWorkOfferRecord: Bool {
        let trimmedId = id.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBoardPostId = boardPostId.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedId.hasPrefix("comp_work_offer") ||
            trimmedBoardPostId.hasPrefix("comp_work_offer") ||
            trimmedBoardPostId.hasPrefix("comp_work_board") {
            return true
        }

        if postedToBoard ||
            boardIds?.isEmpty == false ||
            boardNames?.isEmpty == false ||
            boardName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return true
        }

        if !offeredToUserId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !offeredToUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !acceptedByUserId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !acceptedByUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }

        if !jobTaskIds.isEmpty ||
            !serviceStopTaskIds.isEmpty ||
            offeredAmountCents > 0 ||
            estimatedLaborCents > 0 ||
            estimatedPayTotalCents != nil ||
            estimatedPayLines?.isEmpty == false {
            return true
        }

        return false
    }
}

extension Array where Element == WorkOffer {
    var workOfferRecords: [WorkOffer] {
        filter(\.isWorkOfferRecord)
    }

    var openDirectOfferCount: Int {
        workOfferRecords.filter {
            $0.offerType == .directUser &&
            (
                $0.status == .sent ||
                $0.status == .viewed ||
                $0.status == .posted
            )
        }
        .count
    }

    var openBoardOfferCount: Int {
        workOfferRecords.filter {
            $0.offerType == .internalBoard &&
            (
                $0.status == .posted ||
                $0.status == .viewed
            )
        }
        .count
    }

    var acceptedReadyToScheduleCount: Int {
        workOfferRecords.filter {
            $0.status == .accepted &&
            $0.serviceStopId.isEmpty
        }
        .count
    }

    var scheduledOfferCount: Int {
        workOfferRecords.filter {
            $0.status == .scheduled ||
            $0.status == .inProgress ||
            $0.status == .completed ||
            !$0.serviceStopId.isEmpty
        }
        .count
    }

    var openOfferCount: Int {
        workOfferRecords.filter { $0.status.isOpen }.count
    }
}
