import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/michaelespineli/Desktop/DripDrop/DripDrop/Resources/Utilities.swift", line: 1)
//
//  Utilities.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/15/23.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import MapKit
//import GoogleSignIn
//import GoogleAPIClientForREST_Calendar
import Darwin
extension Array where Element: Equatable {
    mutating func removeDuplicates() {
        var result = [Element]()
        for value in self {
            if !result.contains(value) {
                result.append(value)
            }
        }
        self = result
    }
}
func isValidEmail(_ email: String) -> Bool {
    let emailRegEx = __designTimeString("#23905_0", fallback: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
    
    let emailPred = NSPredicate(format:__designTimeString("#23905_1", fallback: "SELF MATCHES %@"), emailRegEx)
    return emailPred.evaluate(with: email)
}
func changeStringToPhoneNumber(phoneNumber:String)->String{
    
    let num:Int = Int(phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? __designTimeInteger("#23905_2", fallback: 0000000000)
    let returnString:String = __designTimeString("#23905_3", fallback: "sms:") + String(num)
    return returnString
}

extension Query {
    func getDocuments<T>(as type: T.Type) async throws -> [T] where T : Decodable {
        try await getDocumentsWithSnapshot(as: type).serviceStops
    }
    
    func getDocumentsWithSnapshot<T>(as type: T.Type) async throws -> (serviceStops: [T] , lastDocument:DocumentSnapshot?) where T : Decodable {
        let snapshot = try await self.getDocuments()
        
        let serviceStops = try snapshot.documents.map({ document in
            try document.data(as: T.self)
        })
        return ( serviceStops,snapshot.documents.last)
    }
    
    func getCustomerDocuments<T>(as type: T.Type) async throws -> [T] where T : Decodable {
        try await getCustomerDocumentsWithSnapshot(as: type).customers
    }
    
    func getCustomerDocumentsWithSnapshot<T>(as type: T.Type) async throws -> (customers: [T] , lastDocument:DocumentSnapshot?) where T : Decodable {
        let snapshot = try await self.getDocuments()
        
        let customers = try snapshot.documents.map({ document in
            try document.data(as: T.self)
        })
        return ( customers,snapshot.documents.last)
    }
}

func daysBetween(start: Date, end: Date) -> Int {
    return Calendar.current.dateComponents([.day], from: start, to: end).day!
}
func minBetween(start: Date, end: Date) -> Int {
    return Calendar.current.dateComponents([.minute], from: start, to: end).minute!
}
func timeBetweenAsSeconds(start: Date, end: Date) -> Int {
    return Calendar.current.dateComponents([.second], from: start, to: end).second!
}
func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
    return (seconds / __designTimeInteger("#23905_4", fallback: 3600), (seconds % __designTimeInteger("#23905_5", fallback: 3600)) / __designTimeInteger("#23905_6", fallback: 60), (seconds % __designTimeInteger("#23905_7", fallback: 3600)) % __designTimeInteger("#23905_8", fallback: 60))
}
func minToHoursMinuets(_ minuets: Int) -> (hours:Int, min:Int) {
    return (hours:(minuets / __designTimeInteger("#23905_9", fallback: 60)), min:((minuets % __designTimeInteger("#23905_10", fallback: 3600)) % __designTimeInteger("#23905_11", fallback: 60)))
}
extension String  {
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}
func displaySecondsAsTime(seconds:Int) -> String {
    return __designTimeString("#23905_12", fallback: "")
}

func makeDate(year: Int, month: Int, day: Int, hr: Int, min: Int, sec: Int) -> Date {
    let calendar = Calendar(identifier: .gregorian)
    // calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let components = DateComponents(year: year, month: month, day: day, hour: hr, minute: min, second: sec)
    return calendar.date(from: components)!
}
func fullDateAndTime(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_13", fallback: "MM/dd/yyyy' 'HH:mm")//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return __designTimeString("#23905_14", fallback: "no service Date")
    }
    
}
func shortDateAndTime(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_15", fallback: "MM/dd/yy' 'HH:mm")//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return __designTimeString("#23905_16", fallback: "no service Date")
    }
    
}
func displayMonthAndYear(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_17", fallback: "MMMM, yyyy")//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return __designTimeString("#23905_18", fallback: "no service Date")
    }
    
}
func displayPreviousMonthAndCurrentYear(date:Date)->String{
    let calendar = Calendar.current
    let previousMonth = calendar.date(byAdding: .month, value: __designTimeInteger("#23905_19", fallback: -1), to: date)!
    
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_20", fallback: "MMMM, yyyy")//this your string date format
    return String(dateFormatter.string(from:previousMonth))
    
}
func displayCurrentMonthAndPreviousYear(date:Date)->String{
    let calendar = Calendar.current
    //    let components = calendar.dateComponents([.year, .month, .day], from: date)
    let previousYear = calendar.date(byAdding: .year, value: __designTimeInteger("#23905_21", fallback: -1), to: date)!
    
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_22", fallback: "MMMM, yyyy")//this your string date format
    return String(dateFormatter.string(from:previousYear))
}
func numberOfDaysBetween(_ from: Date,_ to: Date) -> Int {
    let calendar = Calendar.current
    let numberOfDays = calendar.dateComponents([.day], from: from, to: to)
    
    return numberOfDays.day!
}
func numberOfWeeksBetween(_ from: Date,_ to: Date) -> Double {
    let calendar = Calendar.current
    let numberOfDays = calendar.dateComponents([.day], from: from, to: to)
    let weeks = numberOfDays.day!/__designTimeInteger("#23905_23", fallback: 7)
    return floor(Double(weeks))
}
func displayMinAsMinAndHour(min:Int) ->String {
    let formatter = DateComponentsFormatter()
    
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .pad
    formatter.allowedUnits = [.hour, .minute]
    let time:TimeInterval = TimeInterval(min*__designTimeInteger("#23905_24", fallback: 60))
    
    return formatter.string(from: time)!
}
func displayNumberAsMinAndHourAndSecond(seconds:Int) ->String {
    let formatter = DateComponentsFormatter()
    
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .pad
    formatter.allowedUnits = [.hour, .minute,.second]
    let time:TimeInterval = TimeInterval(seconds)
    
    return formatter.string(from: time)!
}
func displayNumberAsMinAndHour(seconds:Int) ->String {
    let formatter = DateComponentsFormatter()
    
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .pad
    formatter.allowedUnits = [.hour, .minute]
    let time:TimeInterval = TimeInterval(seconds)
    
    return formatter.string(from: time)!
}
func displayAsLengthInMiles(distance:Int) ->String {
    let distance1 = Measurement(value: Double(distance), unit: UnitLength.miles)
    
    
    return distance1.formatted(.measurement(width: .abbreviated, usage: .road))
}

func numberOfYearsBetween(_ from: Date,_ to: Date) -> Double {
    let calendar = Calendar.current
    let numberOfDays = calendar.dateComponents([.day], from: from, to: to)
    let days = Double(numberOfDays.day!)
    let years = days/__designTimeInteger("#23905_25", fallback: 365)
    return Double(years)
}
extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from) // <1>
        let toDate = startOfDay(for: to) // <2>
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate) // <3>
        
        return numberOfDays.day!
    }
}
func fullDateAndDay(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_26", fallback: "EEEE, MMM d, yyyy")//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return __designTimeString("#23905_27", fallback: "no service Date")
    }
    
}
func dateAndTime(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_28", fallback: "MMM d, h:mm a")//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return __designTimeString("#23905_29", fallback: "no service Date")
    }
    
}
func time(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_30", fallback: "h:mm a")//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return __designTimeString("#23905_31", fallback: "no service Date")
    }
    
}
func fullDate(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_32", fallback: "MM/dd/yyyy")//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return __designTimeString("#23905_33", fallback: "no service Date")
    }
    
}
func dateDayDisplay(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_34", fallback: "dd")//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return __designTimeString("#23905_35", fallback: "no service Date")
    }
    
}
func weekDay(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_36", fallback: "EEEE")//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
    } else {
        return __designTimeString("#23905_37", fallback: "no service Date")
    }
    
}
func shortWeekDay(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_38", fallback: "E")//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return __designTimeString("#23905_39", fallback: "no service Date")
    }
    
}
func shortDate(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_40", fallback: "MM/dd/yy")//this your string date format
    if date != nil{
        let newDate = date?.zeroSeconds
        
        return String(dateFormatter.string(from:newDate!))
        
    } else {
        return __designTimeString("#23905_41", fallback: "no service Date")
    }
    
}
func dayMonth(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_42", fallback: "MM/dd")//this your string date format
    if date != nil{
        let newDate = date?.zeroSeconds
        
        return String(dateFormatter.string(from:newDate!))
        
    } else {
        return __designTimeString("#23905_43", fallback: "no service Date")
    }
    
}
func roundTimeToNearest15(date:Date?)->String{
    let calendar = Calendar(identifier: .gregorian)
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = __designTimeString("#23905_44", fallback: "HH:mm")//this your string date format
    if date != nil{
        let year = calendar.component(.year, from: date!)
        let month = calendar.component(.month, from: date!)
        let day = calendar.component(.day, from: date!)
        let hour = calendar.component(.hour, from: date!)
        let minutes = Double(calendar.component(.minute, from: date!))
        let minAsDecimal = minutes/__designTimeInteger("#23905_45", fallback: 30) // maybe change this to 15 as my calendar gets more accurate
        print(__designTimeString("#23905_46", fallback: "look here"))
        
        print(minAsDecimal)
        let roundedMinutes = Int(round(minAsDecimal * __designTimeInteger("#23905_47", fallback: 10)) / __designTimeInteger("#23905_48", fallback: 10))
        print(roundedMinutes)
        let finalMinutes = roundedMinutes * __designTimeInteger("#23905_49", fallback: 30) // maybe change this to 15 as my calendar gets more accurate
        print(finalMinutes)
        
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: finalMinutes, second: __designTimeInteger("#23905_50", fallback: 0))
        let returnDate =  calendar.date(from: components)!
        
        return String(dateFormatter.string(from:returnDate))
        
    } else {
        return __designTimeString("#23905_51", fallback: "no service Date")
    }
    
}
struct JSON {
    static let encoder = JSONEncoder()
}
extension Encodable {
    subscript(key: String) -> Any? {
        return dictionary[key]
    }
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSON.encoder.encode(self))) as? [String: Any] ?? [:]
    }
}
extension Date {
    
    func startOfDay() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func endOfDay() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: __designTimeInteger("#23905_52", fallback: 0), day: __designTimeInteger("#23905_53", fallback: +1)), to: self.startOfDay())!
    }
    
    func startOfWeek() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func endOfWeek() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: __designTimeInteger("#23905_54", fallback: 0), day: __designTimeInteger("#23905_55", fallback: 7)), to: self.startOfWeek())!
    }
    func startOfMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func endOfMonth() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: __designTimeInteger("#23905_56", fallback: 1), day: __designTimeInteger("#23905_57", fallback: -1)), to: self.startOfMonth())!
    }

    func previousMonth() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: __designTimeInteger("#23905_58", fallback: -1), day: __designTimeInteger("#23905_59", fallback: 0)), to: self.startOfMonth())!
    }
    func previousYear() -> Date {
        return Calendar.current.date(byAdding: DateComponents(year: __designTimeInteger("#23905_60", fallback: -1), month: __designTimeInteger("#23905_61", fallback: 0)), to: self.startOfMonth())!
    }
    var zeroSeconds: Date? {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return calendar.date(from: dateComponents)
    }
    public func distance(to other: Date) -> TimeInterval {
        return other.timeIntervalSinceReferenceDate - self.timeIntervalSinceReferenceDate
    }
    
    public func advanced(by n: TimeInterval) -> Date {
        return self + n
    }
    
}

protocol CSVLoadable {
    init?(raw:[String])
}
func findRelativeDate(day:String,dateSelected:Date) ->(day:String,date:Date) {
    var dayNumber = __designTimeInteger("#23905_62", fallback: 0)
    let displayDay = dateSelected
    let currentDay = shortWeekDay(date: displayDay)
    var displayDayNumber = __designTimeInteger("#23905_63", fallback: 0)
    
    switch currentDay{
    case "Sun":
        displayDayNumber = __designTimeInteger("#23905_64", fallback: 0)
    case "Mon":
        displayDayNumber = __designTimeInteger("#23905_65", fallback: 1)
    case "Tue":
        displayDayNumber = __designTimeInteger("#23905_66", fallback: 2)
    case "Wed":
        displayDayNumber = __designTimeInteger("#23905_67", fallback: 3)
    case "Thur":
        displayDayNumber = __designTimeInteger("#23905_68", fallback: 4)
    case "Fri":
        displayDayNumber = __designTimeInteger("#23905_69", fallback: 5)
    case "Sat":
        displayDayNumber = __designTimeInteger("#23905_70", fallback: 6)
    default:
        displayDayNumber = __designTimeInteger("#23905_71", fallback: 0)
    }
    
    switch day{
    case "Sun":
        dayNumber = __designTimeInteger("#23905_72", fallback: 0)
    case "Mon":
        dayNumber = __designTimeInteger("#23905_73", fallback: 1)
    case "Tue":
        dayNumber = __designTimeInteger("#23905_74", fallback: 2)
    case "Wed":
        dayNumber = __designTimeInteger("#23905_75", fallback: 3)
    case "Thur":
        dayNumber = __designTimeInteger("#23905_76", fallback: 4)
    case "Fri":
        dayNumber = __designTimeInteger("#23905_77", fallback: 5)
    case "Sat":
        dayNumber = __designTimeInteger("#23905_78", fallback: 6)
    default:
        dayNumber = __designTimeInteger("#23905_79", fallback: 0)
    }
    
    let result = dayNumber - displayDayNumber
    let resultDate = Calendar.current.date(byAdding: .day, value: result, to: dateSelected)!
    return (day:dateDayDisplay(date: resultDate),date:resultDate)
    
}

extension String {
    func numberOfOccurrencesOf(string: String) -> Int {
        return self.components(separatedBy:string).count - __designTimeInteger("#23905_80", fallback: 1)
    }
}
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//Color Variables
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
extension Color {
    //    public static var lightBlue: Color {return Color("lightBlue")}
    
    public static var promt: Color {return Color(__designTimeString("#23905_81", fallback: "textFieldPrompt"))}
    
    //    public static var poolRed: Color {return Color("poolRed")}
    //    public static var poolGreen: Color {return Color("poolGreen")}
    //    public static var poolBlue: Color {return Color("poolBlue")}
    //    public static var poolWhite: Color {return Color("poolWhite")}
    //    public static var poolYellow: Color {return Color("poolYellow")}
    
    public static var headerColor: Color {return Color(__designTimeString("#23905_82", fallback: "headerColor"))}
    
    //    public static var realYellow: Color {return Color("RealYellow")}
    public static var basicFontText: Color {return Color(__designTimeString("#23905_83", fallback: "fontColor"))}
    public static var reverseFontText: Color {return Color(__designTimeString("#23905_84", fallback: "Other"))}
    
    public static var simpleBG: Color {return Color(__designTimeString("#23905_85", fallback: "simpleBG"))}
    public static var listColor: Color {return Color(__designTimeString("#23905_86", fallback: "listColor"))}

//    public static var defaultBackground: Color {return Color("defaultBackground")}

    //    public static var bronze: Color {return Color("Bronze")}
    //    public static var darkGray: Color {return Color("DarkGray")}
    //
    //    public static var silver: Color {return Color("Silver")}
    //    public static var gold: Color {return Color("Gold")}
    public static var BNW: Color {return Color(__designTimeString("#23905_87", fallback: "BNW"))}
    
    static subscript(name: String) -> Color {
        switch name {
        case "black":
            return Color.black
        case "blue":
            return Color.blue
        case "brown":
            return Color.brown
        case "cyan":
            return Color.cyan
        case "green":
            return Color.poolGreen
        case "indigo":
            return Color.indigo
        case "mint":
            return Color.mint
        case "orange":
            return Color.orange
        case "pink":
            return Color.pink
        case "purple":
            return Color.purple
        case "red":
            return Color.red
        case "teal":
            return Color.teal
        case "white":
            return Color.white
        case "yellow":
            return Color.yellow
        default:
            return Color.accentColor
        }
    }
}
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//Google Functions
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func suggestionChems(_ DosageDictionary:[String:String],_ chem:String,_ gallons:Double)->String{
    //        let gallons:Double = Double(gallonsString) ?? 0.0
    
    let currentString = __designTimeString("#23905_88", fallback: "1")
    let desiredString = __designTimeString("#23905_89", fallback: "1")
    //    let calcType = ""
    let current:Double = Double(currentString) ?? __designTimeFloat("#23905_90", fallback: 0.0)
    let desired:Double = Double(desiredString) ?? __designTimeFloat("#23905_91", fallback: 0.0)
    
    let chlorine:Double = __designTimeFloat("#23905_92", fallback: 0.0825)
    let acid:Double = __designTimeInteger("#23905_93", fallback: 10)//ounces at 15% change to 5 if acid is 30% //0.30
    
    var change:Double = __designTimeInteger("#23905_94", fallback: 0)
    var workingNumber:Double = __designTimeInteger("#23905_95", fallback: 0)
    var amountToAdd:Double = __designTimeInteger("#23905_96", fallback: 0)
    var gallonsToAdd:Double = __designTimeInteger("#23905_97", fallback: 0)
    
    switch chem {
    case "Liquid Chlorine":
        let currentString = DosageDictionary[__designTimeString("#23905_98", fallback: "Free Chlorine")] ?? __designTimeString("#23905_99", fallback: "0.0")
        let currentChlorine:Double = Double(currentString) ?? __designTimeFloat("#23905_100", fallback: 0.0)
        let desiredChlorine:Double = __designTimeFloat("#23905_101", fallback: 5.0)
        
        workingNumber = __designTimeFloat("#23905_102", fallback: 2.3) / chlorine //produces 1 ppm change for 10,000
        change = desiredChlorine - currentChlorine
        amountToAdd  = workingNumber * (gallons/__designTimeInteger("#23905_103", fallback: 10000)) * (change/__designTimeInteger("#23905_104", fallback: 1))
        gallonsToAdd = amountToAdd/__designTimeInteger("#23905_105", fallback: 128)
        if gallonsToAdd > __designTimeInteger("#23905_106", fallback: 0) {
            let formatted = String(format:  __designTimeString("#23905_107", fallback: "%.2f"), gallonsToAdd)
            return __designTimeString("#23905_108", fallback: "Gallons ") + String(formatted)
        }else{
            return __designTimeString("#23905_109", fallback: "Chlorine too High")
        }
    case "Chlorine Tabs":
        workingNumber = __designTimeFloat("#23905_110", fallback: 2.3) / chlorine //produces 1 ppm change for 10,000
        change = desired - current
        amountToAdd  = workingNumber * (gallons/__designTimeInteger("#23905_111", fallback: 10000)) * (change/__designTimeInteger("#23905_112", fallback: 1))
        gallonsToAdd = amountToAdd/__designTimeInteger("#23905_113", fallback: 128)
        let formatted = String(format:  __designTimeString("#23905_114", fallback: "%.2f"), gallonsToAdd)
        return __designTimeString("#23905_115", fallback: "Gallons ") + String(formatted)
    case "Muriatic Acid":
        let currentString = DosageDictionary[__designTimeString("#23905_116", fallback: "pH")] ?? __designTimeString("#23905_117", fallback: "0.0")
        let currentAcid:Double = Double(currentString) ?? __designTimeFloat("#23905_118", fallback: 0.0)
        let desiredAcid:Double = __designTimeFloat("#23905_119", fallback: 7.4)
        change = desiredAcid - currentAcid
        
        if change > __designTimeInteger("#23905_120", fallback: 0) {
            return __designTimeString("#23905_121", fallback: "0")
            
        }else {
            let acidChange = change * __designTimeInteger("#23905_122", fallback: -1)//turns positive
            let acidFactor = acidChange/__designTimeFloat("#23905_123", fallback: 0.1)//how many times
            amountToAdd  = (gallons/__designTimeInteger("#23905_124", fallback: 10000)) * (acidFactor*acid)
            gallonsToAdd = amountToAdd/__designTimeInteger("#23905_125", fallback: 128)
            
            let formatted = String(format:  __designTimeString("#23905_126", fallback: "%.2f"), gallonsToAdd)
            return __designTimeString("#23905_127", fallback: "Gallons  ") + String(formatted)
            
        }
        
    case "Soda Ash":
        
        let currentString = DosageDictionary[__designTimeString("#23905_128", fallback: "pH")] ?? __designTimeString("#23905_129", fallback: "0.0")
        let currentAcid:Double = Double(currentString) ?? __designTimeFloat("#23905_130", fallback: 0.0)
        let desiredAcid:Double = __designTimeFloat("#23905_131", fallback: 7.4)
        change = desiredAcid - currentAcid
        
        if change > __designTimeInteger("#23905_132", fallback: 0) {
            //to use sodaash
            let lbsSodaAsh = change/__designTimeFloat("#23905_133", fallback: 0.1)
            
            amountToAdd  = (gallons/__designTimeInteger("#23905_134", fallback: 10000)) * (lbsSodaAsh*__designTimeFloat("#23905_135", fallback: 5.3))
            let lbs = amountToAdd/__designTimeInteger("#23905_136", fallback: 16)
            let formatted = String(format:  __designTimeString("#23905_137", fallback: "%.2f"), lbs)
            
            return __designTimeString("#23905_138", fallback: "Lbs  ") + String(formatted)
        }else {
            return __designTimeString("#23905_139", fallback: "0")
            
        }
    default:
        let dosage = __designTimeInteger("#23905_140", fallback: 1)
        return String(dosage)
    }
    
    
    
}

func recommendationChems(gallons:Double,dosageTemplate:SavedDosageTemplate,readingList:[Reading],hasAlgea:Bool)-> String{
    //    print("Calculating Recommendations...")
    //    print("gallons >> \(gallons)")
    //    print("Dosage >> \(String(describing: dosageTemplate.name))")
    //    print("hasAlgea >> \(hasAlgea)")
    let dosageType = dosageTemplate.chemType
    var currentString:String = __designTimeString("#23905_141", fallback: "")
    
    //    let desiredString:String = "1"
    //    let calcType = ""
    //    let current:Double = Double(currentString) ?? 0.0
    //    let desired:Double = Double(desiredString) ?? 0.0
    
    let chlorine:Double = __designTimeFloat("#23905_142", fallback: 0.0825)
    let acid:Double = __designTimeInteger("#23905_143", fallback: 10)//ounces at 15% change to 5 if acid is 30% //0.30
    var change:Double = __designTimeInteger("#23905_144", fallback: 0)
    var workingNumber:Double = __designTimeInteger("#23905_145", fallback: 0)
    var amountToAdd:Double = __designTimeInteger("#23905_146", fallback: 0)
    var gallonsToAdd:Double = __designTimeInteger("#23905_147", fallback: 0)
    switch dosageType {
    case "Sodium Bromide":
        if hasAlgea {
            return __designTimeString("#23905_148", fallback: "Oz: 1")
        } else {
            return __designTimeString("#23905_149", fallback: "Oz: 0")
        }
    case "Tabs":
        //        print("Calculating Chlorine Reccomendation")
        if let foo = readingList.first(where: {$0.dosageType == __designTimeString("#23905_150", fallback: "Free Chlorine")}) {
            //            print(" - \(foo)")
            currentString = foo.amount ?? __designTimeString("#23905_151", fallback: "0")
        } else {
            currentString = __designTimeString("#23905_152", fallback: "0")
        }
        //        print(currentString)
        let currentChlorine:Double = Double(currentString) ?? __designTimeFloat("#23905_153", fallback: 0.0)
        let desiredChlorine:Double = __designTimeFloat("#23905_154", fallback: 5.0)
        
        workingNumber = __designTimeFloat("#23905_155", fallback: 2.3) / chlorine //produces 1 ppm change for 10,000
        change = desiredChlorine - currentChlorine
        amountToAdd  = workingNumber * (gallons/__designTimeInteger("#23905_156", fallback: 10000)) * (change/__designTimeInteger("#23905_157", fallback: 1))
        gallonsToAdd = amountToAdd/__designTimeInteger("#23905_158", fallback: 128)
        if gallonsToAdd > __designTimeInteger("#23905_159", fallback: 0) {
            //            let formatted = String(format:  "%.2f", gallonsToAdd)
            let tabs = gallons/__designTimeInteger("#23905_160", fallback: 8000)
            return __designTimeString("#23905_161", fallback: "Tabs: ") + String(format:__designTimeString("#23905_162", fallback: "%.2f"),tabs)
            //            return "Gallons " + String(formatted)
        }else{
            let tabs = gallons/__designTimeInteger("#23905_163", fallback: 16000)
            return __designTimeString("#23905_164", fallback: "Tabs: ") + String(format:__designTimeString("#23905_165", fallback: "%.2f"),tabs)
            //            return "Chlorine too High"
        }
        
    case "Liquid Chlorine":
        //        print("Calculating Chlorine Reccomendation")
        if let foo = readingList.first(where: {$0.dosageType == __designTimeString("#23905_166", fallback: "Free Chlorine")}) {
            print(" - \(foo)")
            currentString = foo.amount ?? __designTimeString("#23905_167", fallback: "0")
        } else {
            currentString = __designTimeString("#23905_168", fallback: "0")
        }
        //        print(currentString)
        let currentChlorine:Double = Double(currentString) ?? __designTimeFloat("#23905_169", fallback: 0.0)
        let desiredChlorine:Double = __designTimeFloat("#23905_170", fallback: 5.0)
        
        workingNumber = __designTimeFloat("#23905_171", fallback: 2.3) / chlorine //produces 1 ppm change for 10,000
        change = desiredChlorine - currentChlorine
        amountToAdd  = workingNumber * (gallons/__designTimeInteger("#23905_172", fallback: 10000)) * (change/__designTimeInteger("#23905_173", fallback: 1))
        gallonsToAdd = amountToAdd/__designTimeInteger("#23905_174", fallback: 128)
        if hasAlgea {
            gallonsToAdd = gallonsToAdd + __designTimeInteger("#23905_175", fallback: 1)
        }
        if gallonsToAdd > __designTimeInteger("#23905_176", fallback: 0) {
            let formatted = String(format:  __designTimeString("#23905_177", fallback: "%.2f"), gallonsToAdd)
            //            print("Liquid Chlorine  - Gallons : \(String(formatted))")
            
            return __designTimeString("#23905_178", fallback: "Gallons: ") + String(formatted)
        }else{
            //            print("Chlorine too High")
            return __designTimeString("#23905_179", fallback: "Chlorine too High")
        }
        //    case "Chlorine Tabs":
        //        workingNumber = 2.3 / chlorine //produces 1 ppm change for 10,000
        //        change = desired - current
        //        amountToAdd  = workingNumber * (gallons/10000) * (change/1)
        //        gallonsToAdd = amountToAdd/128
        //        let formatted = String(format:  "%.2f", gallonsToAdd)
        //        return "Gallons " + String(formatted)
    case "Muriatic Acid":
        //        print("Calculating pH Reccomendation - Muriatic Acid")
        
        if let foo = readingList.first(where: {$0.dosageType == __designTimeString("#23905_180", fallback: "pH")}) {
            print(" - \(foo)")
            currentString = foo.amount ?? __designTimeString("#23905_181", fallback: "0")
        } else {
            currentString = __designTimeString("#23905_182", fallback: "0")
        }
        let currentAcid:Double = Double(currentString) ?? __designTimeFloat("#23905_183", fallback: 0.0)
        let desiredAcid:Double = __designTimeFloat("#23905_184", fallback: 7.3)
        change = desiredAcid - currentAcid
        
        if change > __designTimeInteger("#23905_185", fallback: 0) {
            //            print("Muriatic Acid  - Gallons : 0")
            
            return __designTimeString("#23905_186", fallback: "Do not Add")
            
        }else {
            let acidChange = change * __designTimeInteger("#23905_187", fallback: -1)//turns positive
            let acidFactor = acidChange/__designTimeFloat("#23905_188", fallback: 0.1)//how many times
            amountToAdd  = (gallons/__designTimeInteger("#23905_189", fallback: 10000)) * (acidFactor*acid)
            gallonsToAdd = amountToAdd/__designTimeInteger("#23905_190", fallback: 128)
            
            let formatted = String(format:  __designTimeString("#23905_191", fallback: "%.2f"), gallonsToAdd)
            //            print("Muriatic Acid  - Gallons : \(String(formatted))")
            
            return __designTimeString("#23905_192", fallback: "Gallons: ") + String(formatted)
            
        }
        
    case "Soda Ash":
        //        print("Calculating pH Reccomendation - Soda Ash")
        
        if let foo = readingList.first(where: {$0.dosageType == __designTimeString("#23905_193", fallback: "pH")}) {
            //            print(" - \(foo)")
            currentString = foo.amount ?? __designTimeString("#23905_194", fallback: "0")
        } else {
            currentString = __designTimeString("#23905_195", fallback: "0")
        }
        
        let currentAcid:Double = Double(currentString) ?? __designTimeFloat("#23905_196", fallback: 0.0)
        let desiredAcid:Double = __designTimeFloat("#23905_197", fallback: 7.4)
        change = desiredAcid - currentAcid
        
        if change > __designTimeInteger("#23905_198", fallback: 0) {
            //to use sod ash
            let lbsSodaAsh = change/__designTimeFloat("#23905_199", fallback: 0.1)
            
            amountToAdd  = (gallons/__designTimeInteger("#23905_200", fallback: 10000)) * (lbsSodaAsh*__designTimeFloat("#23905_201", fallback: 5.3))
            let lbs = amountToAdd/__designTimeInteger("#23905_202", fallback: 16)
            let formatted = String(format:  __designTimeString("#23905_203", fallback: "%.2f"), lbs)
            //            print("Soda Ash  - Oz : \(String(formatted))")
            return __designTimeString("#23905_204", fallback: "Oz: ") + String(formatted)
        }else {
            //            print("Soda Ash  - Oz: 0")
            
            return __designTimeString("#23905_205", fallback: "0")
            
        }
    default:
        let dosage = __designTimeInteger("#23905_206", fallback: 0)
        return String(dosage)
    }
    
    
}

func getUnitLength(measurment:String)->UnitLength{
    var returnUnit:UnitLength = UnitLength.meters
    switch measurment{
    case "Meter":
        returnUnit = UnitLength.meters
    case "Feet":
        returnUnit = UnitLength.feet
    case "Inch":
        returnUnit = UnitLength.inches
    case "Centimeter":
        returnUnit = UnitLength.centimeters
    default:
        returnUnit = UnitLength.centimeters
    }
    
    return returnUnit
}
func getUnitMass(measurment:String)->UnitMass{
    var returnUnit:UnitMass = UnitMass.ounces
    switch measurment{
    case "Pounds":
        returnUnit = UnitMass.pounds
    case "Ounce":
        returnUnit = UnitMass.ounces
    default:
        returnUnit = UnitMass.ounces
    }
    return returnUnit
}
func getUnitVolume(measurment:String)->UnitVolume{
    var returnUnit:UnitVolume = UnitVolume.fluidOunces
    switch measurment{
    case "Gallons":
        returnUnit = UnitVolume.gallons
    case "Fluid Ounces":
        returnUnit = UnitVolume.fluidOunces
    case "Cubic Feet":
        returnUnit = UnitVolume.cubicFeet
    case "Cup":
        returnUnit = UnitVolume.cups
    default:
        returnUnit = UnitVolume.fluidOunces
    }
    return returnUnit
}
func getCoordinate(from address: String) async throws -> CLLocationCoordinate2D {
    let geocoder = CLGeocoder()
    
    guard let location = try await geocoder.geocodeAddressString(address)
        .compactMap( { $0.location } )
        .first(where: { $0.horizontalAccuracy >= __designTimeInteger("#23905_207", fallback: 0) } )
    else {
        throw CLError(.geocodeFoundNoResult)
    }
    
    return location.coordinate
}
func convertAddressToCordinates1(address:Address) async throws ->CLLocationCoordinate2D {
    let fulladdress = address.streetAddress + __designTimeString("#23905_208", fallback: " ") + address.city + __designTimeString("#23905_209", fallback: " ") + address.state + __designTimeString("#23905_210", fallback: " ") + address.zip
    var addressCoordinates = CLLocationCoordinate2D(latitude: __designTimeFloat("#23905_211", fallback: 1.00), longitude: __designTimeFloat("#23905_212", fallback: 1.00))
    let geoCoder = CLGeocoder()
    print("Converting Address >> \(fulladdress) to Coordinates")
    geoCoder.geocodeAddressString(fulladdress) {
        placemarks, error in
        let placemark = placemarks?.first
        
        addressCoordinates.latitude = placemark?.location?.coordinate.latitude ?? __designTimeInteger("#23905_213", fallback: 32)
        addressCoordinates.longitude = placemark?.location?.coordinate.longitude ?? __designTimeInteger("#23905_214", fallback: -117)
        print("Address Coordinates >> \(addressCoordinates)")
    }
    usleep(__designTimeInteger("#23905_215", fallback: 1201000))
    return addressCoordinates
}
func convertAddressToCordinates2(address: Address, completion: @escaping (Double, Double) -> Void){
    let fulladdress = address.streetAddress + __designTimeString("#23905_216", fallback: " ") + address.city + __designTimeString("#23905_217", fallback: " ") + address.state + __designTimeString("#23905_218", fallback: " ") + address.zip
    let geoCoder = CLGeocoder()
    geoCoder.geocodeAddressString(fulladdress) {
        placemarks, error in
        let placemark = placemarks?.first
        if let lat:Double = placemark?.location?.coordinate.latitude , let lon:Double = placemark?.location?.coordinate.longitude {
            completion(lat, lon)
        }
    }
}
func getNumInList(list:[ServiceStop],id:String)-> Int{
    var stopList:[String] = []
    for stop in list {
        stopList.append(stop.id)
        print(__designTimeString("#23905_219", fallback: "stop.id"))
        
        print(stop.id)
    }
    if let index = stopList.firstIndex(of: id) {
        print("Index of \(id) is \(index)")
        return index + __designTimeInteger("#23905_220", fallback: 1)
    } else {
        print("\(stopList) is not in the list")
        return __designTimeInteger("#23905_221", fallback: 1)
        
    }
}
#if os(iOS)
func dismissKeyboard() {
    UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.endEditing(__designTimeBoolean("#23905_222", fallback: true)) // 4
}
#endif
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

//func convertStringToEnumFavorite(favList:[String])->[Category]{
//    var categoryList:[Category] = []
//    for fav in favList {
//        let anEnum = Category(rawValue: fav)!
//        categoryList.append(anEnum)
//    }
//    return categoryList
//}
#if os(iOS)
extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    static var isMac: Bool {
        UIDevice.current.userInterfaceIdiom == .mac
    }
}
#endif

struct Line:Shape{
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: __designTimeInteger("#23905_223", fallback: 0), y: __designTimeInteger("#23905_224", fallback: 0)))
        path.addLine(to: CGPoint(x: rect.width, y: __designTimeInteger("#23905_225", fallback: 0)))
        return path
    }
}
func isDate(_ date: Date, inDayContaining referenceDate: Date) -> Bool {
    let calendar = Calendar.current
    
    // Extract components from both dates
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    let referenceComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)
    
    // Compare date components to check if they are in the same day
    return dateComponents == referenceComponents
}
func startOfWeek(for date: Date) -> Date {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    print(calendar.date(from: components)!)
    return calendar.date(from: components)!
}
func getNextServiceDate(lastServiceDate:Date?,every:String?,frequency:String?) -> Date? {
    let calendar = Calendar.current
    
    var date = Date()
    guard let everyString = every else {
        return nil
    }
    guard let lastServiceDateValidated = lastServiceDate else {
        return nil
    }
    if let repeatingEvery = Int(everyString) {
        switch frequency {
        case "Day":
            print(__designTimeString("#23905_226", fallback: "Day"))
            date = calendar.date(byAdding: .day, value: repeatingEvery, to: lastServiceDateValidated)!
            
        case "Week":
            print(__designTimeString("#23905_227", fallback: "Week"))
            
            let week = repeatingEvery * __designTimeInteger("#23905_228", fallback: 7)
            date = calendar.date(byAdding: .day, value: week, to: lastServiceDateValidated)!
            
        case "Month":
            print(__designTimeString("#23905_229", fallback: "Month"))
            
            date = calendar.date(byAdding: .month, value: repeatingEvery, to: lastServiceDateValidated)!
            
        case "Year":
            print(__designTimeString("#23905_230", fallback: "Year"))
            
            date = calendar.date(byAdding: .year, value: repeatingEvery, to: lastServiceDateValidated)!
            
        default:
            print(__designTimeString("#23905_231", fallback: "None"))
            return nil
        }
    } else {
        print(__designTimeString("#23905_232", fallback: "Error Converting Number"))
        return nil
    }
    return date
}

enum Alphebet: String, Hashable, CaseIterable, Identifiable {
    case A
    case B
    case C
    case D
    case E
    case F
    case G
    case H
    case I
    case J
    case K
    case L
    case M
    case N
    case O
    case P
    case Q
    case R
    case S
    case T
    case U
    case V
    case W
    case X
    case Y
    case Z
    
    var id: String {
        return self.rawValue
    }
    func upperCase() -> String {
        switch self {
        case .A:
            return __designTimeString("#23905_233", fallback: "A")
        case .B:
            return __designTimeString("#23905_234", fallback: "B")
        case .C:
            return __designTimeString("#23905_235", fallback: "C")
        case .D:
            return __designTimeString("#23905_236", fallback: "D")
        case .E:
            return __designTimeString("#23905_237", fallback: "E")
        case .F:
            return __designTimeString("#23905_238", fallback: "F")
        case .G:
            return __designTimeString("#23905_239", fallback: "G")
        case .H:
            return __designTimeString("#23905_240", fallback: "H")
        case .I:
            return __designTimeString("#23905_241", fallback: "I")
        case .J:
            return __designTimeString("#23905_242", fallback: "J")
        case .K:
            return __designTimeString("#23905_243", fallback: "K")
        case .L:
            return __designTimeString("#23905_244", fallback: "L")
        case .M:
            return __designTimeString("#23905_245", fallback: "M")
        case .N:
            return __designTimeString("#23905_246", fallback: "N")
        case .O:
            return __designTimeString("#23905_247", fallback: "O")
        case .P:
            return __designTimeString("#23905_248", fallback: "P")
        case .Q:
            return __designTimeString("#23905_249", fallback: "Q")
        case .R:
            return __designTimeString("#23905_250", fallback: "R")
        case .S:
            return __designTimeString("#23905_251", fallback: "S")
        case .T:
            return __designTimeString("#23905_252", fallback: "T")
        case .U:
            return __designTimeString("#23905_253", fallback: "U")
        case .V:
            return __designTimeString("#23905_254", fallback: "V")
        case .W:
            return __designTimeString("#23905_255", fallback: "W")
        case .X:
            return __designTimeString("#23905_256", fallback: "X")
        case .Y:
            return __designTimeString("#23905_257", fallback: "Y")
        case .Z:
            return __designTimeString("#23905_258", fallback: "Z")
        }
    }
    func lowerCase() -> String {
        switch self {
        case .A:
            return __designTimeString("#23905_259", fallback: "a")
        case .B:
            return __designTimeString("#23905_260", fallback: "b")
        case .C:
            return __designTimeString("#23905_261", fallback: "c")
        case .D:
            return __designTimeString("#23905_262", fallback: "d")
        case .E:
            return __designTimeString("#23905_263", fallback: "e")
        case .F:
            return __designTimeString("#23905_264", fallback: "f")
        case .G:
            return __designTimeString("#23905_265", fallback: "g")
        case .H:
            return __designTimeString("#23905_266", fallback: "h")
        case .I:
            return __designTimeString("#23905_267", fallback: "i")
        case .J:
            return __designTimeString("#23905_268", fallback: "j")
        case .K:
            return __designTimeString("#23905_269", fallback: "k")
        case .L:
            return __designTimeString("#23905_270", fallback: "l")
        case .M:
            return __designTimeString("#23905_271", fallback: "m")
        case .N:
            return __designTimeString("#23905_272", fallback: "n")
        case .O:
            return __designTimeString("#23905_273", fallback: "o")
        case .P:
            return __designTimeString("#23905_274", fallback: "p")
        case .Q:
            return __designTimeString("#23905_275", fallback: "q")
        case .R:
            return __designTimeString("#23905_276", fallback: "r")
        case .S:
            return __designTimeString("#23905_277", fallback: "s")
        case .T:
            return __designTimeString("#23905_278", fallback: "t")
        case .U:
            return __designTimeString("#23905_279", fallback: "u")
        case .V:
            return __designTimeString("#23905_280", fallback: "v")
        case .W:
            return __designTimeString("#23905_281", fallback: "w")
        case .X:
            return __designTimeString("#23905_282", fallback: "x")
        case .Y:
            return __designTimeString("#23905_283", fallback: "y")
        case .Z:
            return __designTimeString("#23905_284", fallback: "z")
        }
    }
    
}

func calculateLevel(exp:Int)->(level:Int,percentage:Double,expToNextlevel:Double){
    var level:Int = __designTimeInteger("#23905_285", fallback: 1)
    var percentage:Double = __designTimeFloat("#23905_286", fallback: 0.0)
    var expToNextlevel:Double = __designTimeInteger("#23905_287", fallback: 0)
    //This will Help Calculate Exp
    if exp <= __designTimeInteger("#23905_288", fallback: 500) {
        //Level 1
        level = __designTimeInteger("#23905_289", fallback: 1)
        let expInLevel:Double = Double(exp)
        expToNextlevel = expInLevel
        
        percentage = Double(exp / __designTimeInteger("#23905_290", fallback: 500))
    } else if exp > __designTimeInteger("#23905_291", fallback: 500) && exp <= 1_000 {
        //Level 2
        level = __designTimeInteger("#23905_292", fallback: 2)
        let expInLevel:Double = Double(exp) - __designTimeInteger("#23905_293", fallback: 500)
        expToNextlevel = expInLevel
        
        percentage = Double(expInLevel / __designTimeInteger("#23905_294", fallback: 500))
    } else if exp > 1_000 && exp <= 2_000 {
        //Level 3
        level = __designTimeInteger("#23905_295", fallback: 3)
        let expInLevel:Double = Double(exp)  - 1_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 1_000)
        
    } else if exp > 2_000 && exp <= 4_000 {
        //Level 4
        level = __designTimeInteger("#23905_296", fallback: 4)
        let expInLevel:Double = Double(exp)  - 2_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 2_000)
        
    } else if exp > 4_000 && exp <= 8_000 {
        //Level 5
        level = __designTimeInteger("#23905_297", fallback: 5)
        let expInLevel:Double = Double(exp)  - 4_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 4_000)
        
    } else if exp > 8_000 && exp <= 16_000 {
        //Level 6
        level = __designTimeInteger("#23905_298", fallback: 6)
        let expInLevel:Double = Double(exp)  - 8_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 8_000)
        
    } else if exp > 16_000 && exp <= 32_000 {
        //Level 7
        level = __designTimeInteger("#23905_299", fallback: 7)
        let expInLevel:Double = Double(exp)  - 16_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 16_000)
        
    } else if exp > 32_000 && exp <= 64_000 {
        //Level 8
        level = __designTimeInteger("#23905_300", fallback: 8)
        let expInLevel:Double = Double(exp)  - 32_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 32_000)
        
    } else if exp > 64_000 && exp <= 128_000 {
        //Level 9
        level = __designTimeInteger("#23905_301", fallback: 9)
        let expInLevel:Double = Double(exp)  - 64_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 64_000)
        
    } else if exp > 128_000 && exp <= 256_000 {
        //Level 10
        level = __designTimeInteger("#23905_302", fallback: 10)
        let expInLevel:Double = Double(exp)  - 128_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 128_000)
        
    } else if exp > 256_000 && exp <= 512_000 {
        //Level 11
        level = __designTimeInteger("#23905_303", fallback: 11)
        let expInLevel:Double = Double(exp)  - 256_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 256_000)
        
    } else if exp > 512_000 && exp <= 1_024_000 {
        //Level 12
        level = __designTimeInteger("#23905_304", fallback: 12)
        let expInLevel:Double = Double(exp)  - 512_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 512_000)
        
    } else if exp > 1_024_000 && exp <= 2_048_000 {
        //Level 13
        level = __designTimeInteger("#23905_305", fallback: 13)
        let expInLevel:Double = Double(exp)  - 1_024_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 1_024_000)
        
    } else if exp > 2_048_000 && exp <= 4_096_000 {
        //Level 14
        level = __designTimeInteger("#23905_306", fallback: 14)
        let expInLevel:Double = Double(exp)  - 2_048_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 2_048_000)
        
    } else if exp > 4_096_000 && exp <= 8_192_000 {
        //Level 15
        level = __designTimeInteger("#23905_307", fallback: 15)
        let expInLevel:Double = Double(exp)  - 4_096_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 4_096_000)
        
    } else if exp > 8_192_000 && exp <= 16_384_00 {
        //Level 16
        level = __designTimeInteger("#23905_308", fallback: 16)
        let expInLevel:Double = Double(exp)  - 8_192_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 8_192_000)
        
    } else if exp > 16_384_00 && exp <= 32_768_00 {
        //Level 17
        level = __designTimeInteger("#23905_309", fallback: 17)
        let expInLevel:Double = Double(exp)  - 16_384_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 16_384_00)
        
    } else if exp > 32_768_00 && exp <= 65_536_00 {
        //Level 18
        level = __designTimeInteger("#23905_310", fallback: 18)
        let expInLevel:Double = Double(exp)  - 32_768_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 32_768_00)
        
    } else if exp > 65_536_00 && exp <= 131_072_00 {
        //Level 19
        level = __designTimeInteger("#23905_311", fallback: 19)
        let expInLevel:Double = Double(exp)  - 65_536_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 65_536_00)
        
    } else if exp > 131_072_00 && exp <= 262_144_00 {
        //Level 21
        level = __designTimeInteger("#23905_312", fallback: 21)
        let expInLevel:Double = Double(exp)  - 131_072_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 131_072_00)
        
    } else if exp > 262_144_00 && exp <= 524_288_00 {
        //Level 22
        level = __designTimeInteger("#23905_313", fallback: 22)
        let expInLevel:Double = Double(exp)  - 262_144_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 262_144_00)
        
    } else if exp > 524_288_00 && exp <= 1_048_576_00 {
        //Level 23
        level = __designTimeInteger("#23905_314", fallback: 23)
        let expInLevel:Double = Double(exp)  - 524_288_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 524_288_00)
        
    } else if exp > 1_048_576_00 && exp <= 2_097_152_00 {
        //Level 24
        level = __designTimeInteger("#23905_315", fallback: 24)
        let expInLevel:Double = Double(exp)  - 1_048_576_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 1_048_576_00)
        
    } else if exp > 2_097_152_00 && exp <= 4_194_304_00 {
        //Level 25
        level = __designTimeInteger("#23905_316", fallback: 25)
        let expInLevel:Double = Double(exp)  - 2_097_152_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 2_097_152_00)
        
    } else if exp > 4_194_304_00 {
        //Level 26
        level = __designTimeInteger("#23905_317", fallback: 26)
        let expInLevel:Double = Double(exp)  - 4_194_304_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 4_194_304_00)
        
    }
    return (level:level,percentage:percentage,expToNextlevel:expToNextlevel)
}

import SwiftUI

@available(iOS 14, *)
/// Adds a transparent View and read it's frame.
///
/// Adds a GeometryReader with infinity frame.
public struct FrameReader: View {
    
    let coordinateSpace: CoordinateSpace
    let onChange: (_ frame: CGRect) -> Void
    
    public init(coordinateSpace: CoordinateSpace, onChange: @escaping (_ frame: CGRect) -> Void) {
        self.coordinateSpace = coordinateSpace
        self.onChange = onChange
    }
    
    public var body: some View {
        GeometryReader { geo in
            Text(__designTimeString("#23905_318", fallback: ""))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear(perform: {
                    onChange(geo.frame(in: coordinateSpace))
                })
                .onChange(of: geo.frame(in: coordinateSpace), perform: onChange)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

@available(iOS 14, *)
public extension View {
    
    /// Get the frame of the View
    ///
    /// Adds a GeometryReader to the background of a View.
    func readingFrame(coordinateSpace: CoordinateSpace = .global, onChange: @escaping (_ frame: CGRect) -> ()) -> some View {
        background(FrameReader(coordinateSpace: coordinateSpace, onChange: onChange))
    }
}

@available(iOS 14, *)
struct FrameReader_Previews: PreviewProvider {
    
    struct PreviewView: View {
        
        @State private var yOffset: CGFloat = 0
        
        var body: some View {
            ScrollView(.vertical) {
                VStack {
                    Text(__designTimeString("#23905_319", fallback: ""))
                        .frame(maxWidth: .infinity)
                        .frame(height: __designTimeInteger("#23905_320", fallback: 200))
                        .cornerRadius(__designTimeInteger("#23905_321", fallback: 10))
                        .background(Color.green)
                        .padding()
                        .readingFrame { frame in
                            yOffset = frame.minY
                        }
                    
                    ForEach(__designTimeInteger("#23905_322", fallback: 0)..<__designTimeInteger("#23905_323", fallback: 30)) { x in
                        Text(__designTimeString("#23905_324", fallback: ""))
                            .frame(maxWidth: .infinity)
                            .frame(height: __designTimeInteger("#23905_325", fallback: 200))
                            .cornerRadius(__designTimeInteger("#23905_326", fallback: 10))
                            .background(Color.green)
                            .padding()
                    }
                }
            }
            .coordinateSpace(name: __designTimeString("#23905_327", fallback: "test"))
            .overlay(Text("Offset: \(yOffset)"))
        }
    }
    
    static var previews: some View {
        PreviewView()
    }
}


struct DragGestureViewModifier: ViewModifier {
    
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1
    
    let axes: Axis.Set
    let minimumDistance: CGFloat
    let resets: Bool
    let animation: Animation
    let rotationMultiplier: CGFloat
    let scaleMultiplier: CGFloat
    let onChanged: ((_ dragOffset: CGSize) -> ())?
    let onEnded: ((_ dragOffset: CGSize) -> ())?
    
    init(
        _ axes: Axis.Set = [.horizontal, .vertical],
        minimumDistance: CGFloat = 0,
        resets: Bool,
        animation: Animation,
        rotationMultiplier: CGFloat = 0,
        scaleMultiplier: CGFloat = 0,
        onChanged: ((_ dragOffset: CGSize) -> ())?,
        onEnded: ((_ dragOffset: CGSize) -> ())?) {
            self.axes = axes
            self.minimumDistance = minimumDistance
            self.resets = resets
            self.animation = animation
            self.rotationMultiplier = rotationMultiplier
            self.scaleMultiplier = scaleMultiplier
            self.onChanged = onChanged
            self.onEnded = onEnded
        }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .rotationEffect(Angle(degrees: rotation), anchor: .center)
            .offset(getOffset(offset: lastOffset))
            .offset(getOffset(offset: offset))
            .simultaneousGesture(
                DragGesture(minimumDistance: minimumDistance, coordinateSpace: .global)
                    .onChanged({ value in
                        onChanged?(value.translation)
                        
                        withAnimation(animation) {
                            offset = value.translation
                            
                            rotation = getRotation(translation: value.translation)
                            scale = getScale(translation: value.translation)
                        }
                    })
                    .onEnded({ value in
                        if !resets {
                            onEnded?(lastOffset)
                        } else {
                            onEnded?(value.translation)
                        }
                        
                        withAnimation(animation) {
                            offset = .zero
                            rotation = __designTimeInteger("#23905_328", fallback: 0)
                            scale = __designTimeInteger("#23905_329", fallback: 1)
                            
                            if !resets {
                                lastOffset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height)
                            } else {
                                onChanged?(offset)
                            }
                        }
                    })
            )
    }
    
    
    private func getOffset(offset: CGSize) -> CGSize {
        switch axes {
        case .vertical:
            return CGSize(width: __designTimeInteger("#23905_330", fallback: 0), height: offset.height)
        case .horizontal:
            return CGSize(width: offset.width, height: __designTimeInteger("#23905_331", fallback: 0))
        default:
            return offset
        }
    }
    
    private func getRotation(translation: CGSize) -> CGFloat {
        let max = UIScreen.main.bounds.width / __designTimeInteger("#23905_332", fallback: 2)
        let percentage = translation.width * rotationMultiplier / max
        let maxRotation: CGFloat = __designTimeInteger("#23905_333", fallback: 10)
        return percentage * maxRotation
    }
    
    private func getScale(translation: CGSize) -> CGFloat {
        let max = UIScreen.main.bounds.width / __designTimeInteger("#23905_334", fallback: 2)
        
        var offsetAmount: CGFloat = __designTimeInteger("#23905_335", fallback: 0)
        switch axes {
        case .vertical:
            offsetAmount = abs(translation.height + lastOffset.height)
        case .horizontal:
            offsetAmount = abs(translation.width + lastOffset.width)
        default:
            offsetAmount = (abs(translation.width + lastOffset.width) + abs(translation.height + lastOffset.height)) / __designTimeInteger("#23905_336", fallback: 2)
        }
        
        let percentage = offsetAmount * scaleMultiplier / max
        let minScale: CGFloat = __designTimeFloat("#23905_337", fallback: 0.8)
        let range = __designTimeInteger("#23905_338", fallback: 1) - minScale
        return __designTimeInteger("#23905_339", fallback: 1) - (range * percentage)
    }
    
}

public extension View {
    
    /// Add a DragGesture to a View.
    ///
    /// DragGesture is added as a simultaneousGesture, to not interfere with other gestures Developer may add.
    ///
    /// - Parameters:
    ///   - axes: Determines the drag axes. Default allows for both horizontal and vertical movement.
    ///   - resets: If the View should reset to starting state onEnded.
    ///   - animation: The drag animation.
    ///   - rotationMultiplier: Used to rotate the View while dragging. Only applies to horizontal movement.
    ///   - scaleMultiplier: Used to scale the View while dragging.
    ///   - onEnded: The modifier will handle the View's offset onEnded. This escaping closure is for Developer convenience.
    ///
    func withDragGesture(
        _ axes: Axis.Set = [.horizontal, .vertical],
        minimumDistance: CGFloat = 0,
        resets: Bool = true,
        animation: Animation = .spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.0),
        rotationMultiplier: CGFloat = 0,
        scaleMultiplier: CGFloat = 0,
        onChanged: ((_ dragOffset: CGSize) -> ())? = nil,
        onEnded: ((_ dragOffset: CGSize) -> ())? = nil) -> some View {
            modifier(DragGestureViewModifier(axes, minimumDistance: minimumDistance, resets: resets, animation: animation, rotationMultiplier: rotationMultiplier, scaleMultiplier: scaleMultiplier, onChanged: onChanged, onEnded: onEnded))
        }
    
}

struct DragGestureViewModifier_Previews: PreviewProvider {
    
    static var previews: some View {
        RoundedRectangle(cornerRadius: __designTimeInteger("#23905_340", fallback: 10))
            .frame(width: __designTimeInteger("#23905_341", fallback: 300), height: __designTimeInteger("#23905_342", fallback: 200))
            .withDragGesture(
                [.vertical, .horizontal],
                resets: __designTimeBoolean("#23905_343", fallback: true),
                animation: .easeIn,
                rotationMultiplier: __designTimeFloat("#23905_344", fallback: 1.1),
                scaleMultiplier: __designTimeFloat("#23905_345", fallback: 1.1),
                onChanged: { dragOffset in
                    let tx = dragOffset.height
                    let ty = dragOffset.width
                },
                onEnded: { dragOffset in
                    let tx = dragOffset.height
                    let ty = dragOffset.width
                }
            )
    }
}

func longestWord(str: String) -> String {
    let wordArray = str.components(separatedBy: .whitespacesAndNewlines)
    var longWord = __designTimeString("#23905_346", fallback: "")
    
    for w in wordArray {
        if w.count > longWord.count {
            longWord = w
        }
    }
    
    return longWord
}
