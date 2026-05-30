//
//  WorkOffer+Counts.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//

import Foundation

extension Array where Element == WorkOffer {

    var openDirectOfferCount: Int {
        self.filter {
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
        self.filter {
            $0.offerType == .internalBoard &&
            (
                $0.status == .posted ||
                $0.status == .viewed
            )
        }
        .count
    }

    var acceptedReadyToScheduleCount: Int {
        self.filter {
            $0.status == .accepted &&
            $0.serviceStopId.isEmpty
        }
        .count
    }

    var scheduledOfferCount: Int {
        self.filter {
            $0.status == .scheduled ||
            $0.status == .inProgress ||
            $0.status == .completed ||
            !$0.serviceStopId.isEmpty
        }
        .count
    }

    var openOfferCount: Int {
        self.filter { $0.status.isOpen }.count
    }
}
