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
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    
    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
}
func changeStringToPhoneNumber(phoneNumber:String)->String{
    
    let num:Int = Int(phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0000000000
    let returnString:String = "sms:" + String(num)
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
    return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}
func minToHoursMinuets(_ minuets: Int) -> (hours:Int, min:Int) {
    return (hours:(minuets / 60), min:((minuets % 3600) % 60))
}
extension String  {
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}
func displaySecondsAsTime(seconds:Int) -> String {
    return ""
}

func makeDate(year: Int, month: Int, day: Int, hr: Int, min: Int, sec: Int) -> Date {
    let calendar = Calendar(identifier: .gregorian)
    // calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let components = DateComponents(year: year, month: month, day: day, hour: hr, minute: min, second: sec)
    return calendar.date(from: components)!
}
func fullDateAndTime(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd/yyyy' 'HH:mm"//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return "no service Date"
    }
    
}
func shortDateAndTime(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd/yy' 'HH:mm"//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return "no service Date"
    }
    
}
func displayMonthAndYear(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM, yyyy"//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return "no service Date"
    }
    
}
func displayPreviousMonthAndCurrentYear(date:Date)->String{
    let calendar = Calendar.current
    let previousMonth = calendar.date(byAdding: .month, value: -1, to: date)!
    
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM, yyyy"//this your string date format
    return String(dateFormatter.string(from:previousMonth))
    
}
func displayCurrentMonthAndPreviousYear(date:Date)->String{
    let calendar = Calendar.current
    //    let components = calendar.dateComponents([.year, .month, .day], from: date)
    let previousYear = calendar.date(byAdding: .year, value: -1, to: date)!
    
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM, yyyy"//this your string date format
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
    let weeks = numberOfDays.day!/7
    return floor(Double(weeks))
}
func displayMinAsMinAndHour(min:Int) ->String {
    let formatter = DateComponentsFormatter()
    
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .pad
    formatter.allowedUnits = [.hour, .minute]
    let time:TimeInterval = TimeInterval(min*60)
    
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
    let years = days/365
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
    dateFormatter.dateFormat = "EEEE, MMM d, yyyy"//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return "no service Date"
    }
    
}
func dateAndTime(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d, h:mm a"//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return "no service Date"
    }
    
}
func time(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "h:mm a"//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return "no service Date"
    }
    
}
func fullDate(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd/yyyy"//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return "no service Date"
    }
    
}
func dateDayDisplay(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd"//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return "no service Date"
    }
    
}
func weekDay(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE"//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
    } else {
        return "no service Date"
    }
    
}
func shortWeekDay(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "E"//this your string date format
    if date != nil{
        return String(dateFormatter.string(from:date!))
        
    } else {
        return "no service Date"
    }
    
}
func shortDate(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd/yy"//this your string date format
    if date != nil{
        let newDate = date?.zeroSeconds
        
        return String(dateFormatter.string(from:newDate!))
        
    } else {
        return "no service Date"
    }
    
}
func dayMonth(date:Date?)->String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd"//this your string date format
    if date != nil{
        let newDate = date?.zeroSeconds
        
        return String(dateFormatter.string(from:newDate!))
        
    } else {
        return "no service Date"
    }
    
}
func roundTimeToNearest15(date:Date?)->String{
    let calendar = Calendar(identifier: .gregorian)
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm"//this your string date format
    if date != nil{
        let year = calendar.component(.year, from: date!)
        let month = calendar.component(.month, from: date!)
        let day = calendar.component(.day, from: date!)
        let hour = calendar.component(.hour, from: date!)
        let minutes = Double(calendar.component(.minute, from: date!))
        let minAsDecimal = minutes/30 // maybe change this to 15 as my calendar gets more accurate
        print("look here")
        
        print(minAsDecimal)
        let roundedMinutes = Int(round(minAsDecimal * 10) / 10)
        print(roundedMinutes)
        let finalMinutes = roundedMinutes * 30 // maybe change this to 15 as my calendar gets more accurate
        print(finalMinutes)
        
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: finalMinutes, second: 0)
        let returnDate =  calendar.date(from: components)!
        
        return String(dateFormatter.string(from:returnDate))
        
    } else {
        return "no service Date"
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
        return Calendar.current.date(byAdding: DateComponents(month: 0, day: +1), to: self.startOfDay())!
    }
    
    func startOfWeek() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func endOfWeek() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: 0, day: 7), to: self.startOfWeek())!
    }
    func startOfMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func endOfMonth() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: self.startOfMonth())!
    }

    func previousMonth() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: -1, day: 0), to: self.startOfMonth())!
    }
    func previousYear() -> Date {
        return Calendar.current.date(byAdding: DateComponents(year: -1, month: 0), to: self.startOfMonth())!
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
    var dayNumber = 0
    let displayDay = dateSelected
    let currentDay = shortWeekDay(date: displayDay)
    var displayDayNumber = 0
    
    switch currentDay{
    case "Sun":
        displayDayNumber = 0
    case "Mon":
        displayDayNumber = 1
    case "Tue":
        displayDayNumber = 2
    case "Wed":
        displayDayNumber = 3
    case "Thur":
        displayDayNumber = 4
    case "Fri":
        displayDayNumber = 5
    case "Sat":
        displayDayNumber = 6
    default:
        displayDayNumber = 0
    }
    
    switch day{
    case "Sun":
        dayNumber = 0
    case "Mon":
        dayNumber = 1
    case "Tue":
        dayNumber = 2
    case "Wed":
        dayNumber = 3
    case "Thur":
        dayNumber = 4
    case "Fri":
        dayNumber = 5
    case "Sat":
        dayNumber = 6
    default:
        dayNumber = 0
    }
    
    let result = dayNumber - displayDayNumber
    let resultDate = Calendar.current.date(byAdding: .day, value: result, to: dateSelected)!
    return (day:dateDayDisplay(date: resultDate),date:resultDate)
    
}

extension String {
    func numberOfOccurrencesOf(string: String) -> Int {
        return self.components(separatedBy:string).count - 1
    }
}
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//Color Variables
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
extension Color {
    //    public static var lightBlue: Color {return Color("lightBlue")}
    
    public static var promt: Color {return Color("textFieldPrompt")}
    
    //    public static var poolRed: Color {return Color("poolRed")}
    //    public static var poolGreen: Color {return Color("poolGreen")}
    //    public static var poolBlue: Color {return Color("poolBlue")}
    //    public static var poolWhite: Color {return Color("poolWhite")}
    //    public static var poolYellow: Color {return Color("poolYellow")}
    
    public static var headerColor: Color {return Color("headerColor")}
    
    //    public static var realYellow: Color {return Color("RealYellow")}
    public static var basicFontText: Color {return Color("fontColor")}
    public static var reverseFontText: Color {return Color("Other")}
    
    public static var simpleBG: Color {return Color("simpleBG")}
    public static var listColor: Color {return Color("listColor")}

//    public static var defaultBackground: Color {return Color("defaultBackground")}

    //    public static var bronze: Color {return Color("Bronze")}
    //    public static var darkGray: Color {return Color("DarkGray")}
    //
    //    public static var silver: Color {return Color("Silver")}
    //    public static var gold: Color {return Color("Gold")}
    public static var BNW: Color {return Color("BNW")}
    
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
    
    let currentString = "1"
    let desiredString = "1"
    //    let calcType = ""
    let current:Double = Double(currentString) ?? 0.0
    let desired:Double = Double(desiredString) ?? 0.0
    
    let chlorine:Double = 0.0825
    let acid:Double = 10//ounces at 15% change to 5 if acid is 30% //0.30
    
    var change:Double = 0
    var workingNumber:Double = 0
    var amountToAdd:Double = 0
    var gallonsToAdd:Double = 0
    
    switch chem {
    case "Liquid Chlorine":
        let currentString = DosageDictionary["Free Chlorine"] ?? "0.0"
        let currentChlorine:Double = Double(currentString) ?? 0.0
        let desiredChlorine:Double = 5.0
        
        workingNumber = 2.3 / chlorine //produces 1 ppm change for 10,000
        change = desiredChlorine - currentChlorine
        amountToAdd  = workingNumber * (gallons/10000) * (change/1)
        gallonsToAdd = amountToAdd/128
        if gallonsToAdd > 0 {
            let formatted = String(format:  "%.2f", gallonsToAdd)
            return "Gallons " + String(formatted)
        }else{
            return "Chlorine too High"
        }
    case "Chlorine Tabs":
        workingNumber = 2.3 / chlorine //produces 1 ppm change for 10,000
        change = desired - current
        amountToAdd  = workingNumber * (gallons/10000) * (change/1)
        gallonsToAdd = amountToAdd/128
        let formatted = String(format:  "%.2f", gallonsToAdd)
        return "Gallons " + String(formatted)
    case "Muriatic Acid":
        let currentString = DosageDictionary["pH"] ?? "0.0"
        let currentAcid:Double = Double(currentString) ?? 0.0
        let desiredAcid:Double = 7.4
        change = desiredAcid - currentAcid
        
        if change > 0 {
            return "0"
            
        }else {
            let acidChange = change * -1//turns positive
            let acidFactor = acidChange/0.1//how many times
            amountToAdd  = (gallons/10000) * (acidFactor*acid)
            gallonsToAdd = amountToAdd/128
            
            let formatted = String(format:  "%.2f", gallonsToAdd)
            return "Gallons  " + String(formatted)
            
        }
        
    case "Soda Ash":
        
        let currentString = DosageDictionary["pH"] ?? "0.0"
        let currentAcid:Double = Double(currentString) ?? 0.0
        let desiredAcid:Double = 7.4
        change = desiredAcid - currentAcid
        
        if change > 0 {
            //to use sodaash
            let lbsSodaAsh = change/0.1
            
            amountToAdd  = (gallons/10000) * (lbsSodaAsh*5.3)
            let lbs = amountToAdd/16
            let formatted = String(format:  "%.2f", lbs)
            
            return "Lbs  " + String(formatted)
        }else {
            return "0"
            
        }
    default:
        let dosage = 1
        return String(dosage)
    }
    
    
    
}

func recommendationChems(gallons:Double,dosageTemplate:SavedDosageTemplate,readingList:[Reading],hasAlgea:Bool)-> String{
    //    print("Calculating Recommendations...")
    //    print("gallons >> \(gallons)")
    //    print("Dosage >> \(String(describing: dosageTemplate.name))")
    //    print("hasAlgea >> \(hasAlgea)")
    let dosageType = dosageTemplate.chemType
    var currentString:String = ""
    
    //    let desiredString:String = "1"
    //    let calcType = ""
    //    let current:Double = Double(currentString) ?? 0.0
    //    let desired:Double = Double(desiredString) ?? 0.0
    
    let chlorine:Double = 0.0825
    let acid:Double = 10//ounces at 15% change to 5 if acid is 30% //0.30
    var change:Double = 0
    var workingNumber:Double = 0
    var amountToAdd:Double = 0
    var gallonsToAdd:Double = 0
    switch dosageType {
    case "Sodium Bromide":
        if hasAlgea {
            return "Oz: 1"
        } else {
            return "Oz: 0"
        }
    case "Tabs":
        //        print("Calculating Chlorine Reccomendation")
        if let foo = readingList.first(where: {$0.dosageType == "Free Chlorine"}) {
            //            print(" - \(foo)")
            currentString = foo.amount ?? "0"
        } else {
            currentString = "0"
        }
        //        print(currentString)
        let currentChlorine:Double = Double(currentString) ?? 0.0
        let desiredChlorine:Double = 5.0
        
        workingNumber = 2.3 / chlorine //produces 1 ppm change for 10,000
        change = desiredChlorine - currentChlorine
        amountToAdd  = workingNumber * (gallons/10000) * (change/1)
        gallonsToAdd = amountToAdd/128
        if gallonsToAdd > 0 {
            //            let formatted = String(format:  "%.2f", gallonsToAdd)
            let tabs = gallons/8000
            return "Tabs: " + String(format:"%.2f",tabs)
            //            return "Gallons " + String(formatted)
        }else{
            let tabs = gallons/16000
            return "Tabs: " + String(format:"%.2f",tabs)
            //            return "Chlorine too High"
        }
        
    case "Liquid Chlorine":
        //        print("Calculating Chlorine Reccomendation")
        if let foo = readingList.first(where: {$0.dosageType == "Free Chlorine"}) {
            print(" - \(foo)")
            currentString = foo.amount ?? "0"
        } else {
            currentString = "0"
        }
        //        print(currentString)
        let currentChlorine:Double = Double(currentString) ?? 0.0
        let desiredChlorine:Double = 5.0
        
        workingNumber = 2.3 / chlorine //produces 1 ppm change for 10,000
        change = desiredChlorine - currentChlorine
        amountToAdd  = workingNumber * (gallons/10000) * (change/1)
        gallonsToAdd = amountToAdd/128
        if hasAlgea {
            gallonsToAdd = gallonsToAdd + 1
        }
        if gallonsToAdd > 0 {
            let formatted = String(format:  "%.2f", gallonsToAdd)
            //            print("Liquid Chlorine  - Gallons : \(String(formatted))")
            
            return "Gallons: " + String(formatted)
        }else{
            //            print("Chlorine too High")
            return "Chlorine too High"
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
        
        if let foo = readingList.first(where: {$0.dosageType == "pH"}) {
            print(" - \(foo)")
            currentString = foo.amount ?? "0"
        } else {
            currentString = "0"
        }
        let currentAcid:Double = Double(currentString) ?? 0.0
        let desiredAcid:Double = 7.3
        change = desiredAcid - currentAcid
        
        if change > 0 {
            //            print("Muriatic Acid  - Gallons : 0")
            
            return "Do not Add"
            
        }else {
            let acidChange = change * -1//turns positive
            let acidFactor = acidChange/0.1//how many times
            amountToAdd  = (gallons/10000) * (acidFactor*acid)
            gallonsToAdd = amountToAdd/128
            
            let formatted = String(format:  "%.2f", gallonsToAdd)
            //            print("Muriatic Acid  - Gallons : \(String(formatted))")
            
            return "Gallons: " + String(formatted)
            
        }
        
    case "Soda Ash":
        //        print("Calculating pH Reccomendation - Soda Ash")
        
        if let foo = readingList.first(where: {$0.dosageType == "pH"}) {
            //            print(" - \(foo)")
            currentString = foo.amount ?? "0"
        } else {
            currentString = "0"
        }
        
        let currentAcid:Double = Double(currentString) ?? 0.0
        let desiredAcid:Double = 7.4
        change = desiredAcid - currentAcid
        
        if change > 0 {
            //to use sod ash
            let lbsSodaAsh = change/0.1
            
            amountToAdd  = (gallons/10000) * (lbsSodaAsh*5.3)
            let lbs = amountToAdd/16
            let formatted = String(format:  "%.2f", lbs)
            //            print("Soda Ash  - Oz : \(String(formatted))")
            return "Oz: " + String(formatted)
        }else {
            //            print("Soda Ash  - Oz: 0")
            
            return "0"
            
        }
    default:
        let dosage = 0
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
        .first(where: { $0.horizontalAccuracy >= 0 } )
    else {
        throw CLError(.geocodeFoundNoResult)
    }
    
    return location.coordinate
}
func convertAddressToCordinates1(address:Address) async throws ->CLLocationCoordinate2D {
    let fulladdress = address.streetAddress + " " + address.city + " " + address.state + " " + address.zip
    var addressCoordinates = CLLocationCoordinate2D(latitude: 1.00, longitude: 1.00)
    let geoCoder = CLGeocoder()
    print("Converting Address >> \(fulladdress) to Coordinates")
    geoCoder.geocodeAddressString(fulladdress) {
        placemarks, error in
        let placemark = placemarks?.first
        
        addressCoordinates.latitude = placemark?.location?.coordinate.latitude ?? 32
        addressCoordinates.longitude = placemark?.location?.coordinate.longitude ?? -117
        print("Address Coordinates >> \(addressCoordinates)")
    }
    usleep(1201000)
    return addressCoordinates
}
func convertAddressToCordinates2(address: Address, completion: @escaping (Double, Double) -> Void){
    let fulladdress = address.streetAddress + " " + address.city + " " + address.state + " " + address.zip
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
        print("stop.id")
        
        print(stop.id)
    }
    if let index = stopList.firstIndex(of: id) {
        print("Index of \(id) is \(index)")
        return index + 1
    } else {
        print("\(stopList) is not in the list")
        return 1
        
    }
}
#if os(iOS)
func dismissKeyboard() {
    UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.endEditing(true) // 4
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
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
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
            print("Day")
            date = calendar.date(byAdding: .day, value: repeatingEvery, to: lastServiceDateValidated)!
            
        case "Week":
            print("Week")
            
            let week = repeatingEvery * 7
            date = calendar.date(byAdding: .day, value: week, to: lastServiceDateValidated)!
            
        case "Month":
            print("Month")
            
            date = calendar.date(byAdding: .month, value: repeatingEvery, to: lastServiceDateValidated)!
            
        case "Year":
            print("Year")
            
            date = calendar.date(byAdding: .year, value: repeatingEvery, to: lastServiceDateValidated)!
            
        default:
            print("None")
            return nil
        }
    } else {
        print("Error Converting Number")
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
            return "A"
        case .B:
            return "B"
        case .C:
            return "C"
        case .D:
            return "D"
        case .E:
            return "E"
        case .F:
            return "F"
        case .G:
            return "G"
        case .H:
            return "H"
        case .I:
            return "I"
        case .J:
            return "J"
        case .K:
            return "K"
        case .L:
            return "L"
        case .M:
            return "M"
        case .N:
            return "N"
        case .O:
            return "O"
        case .P:
            return "P"
        case .Q:
            return "Q"
        case .R:
            return "R"
        case .S:
            return "S"
        case .T:
            return "T"
        case .U:
            return "U"
        case .V:
            return "V"
        case .W:
            return "W"
        case .X:
            return "X"
        case .Y:
            return "Y"
        case .Z:
            return "Z"
        }
    }
    func lowerCase() -> String {
        switch self {
        case .A:
            return "a"
        case .B:
            return "b"
        case .C:
            return "c"
        case .D:
            return "d"
        case .E:
            return "e"
        case .F:
            return "f"
        case .G:
            return "g"
        case .H:
            return "h"
        case .I:
            return "i"
        case .J:
            return "j"
        case .K:
            return "k"
        case .L:
            return "l"
        case .M:
            return "m"
        case .N:
            return "n"
        case .O:
            return "o"
        case .P:
            return "p"
        case .Q:
            return "q"
        case .R:
            return "r"
        case .S:
            return "s"
        case .T:
            return "t"
        case .U:
            return "u"
        case .V:
            return "v"
        case .W:
            return "w"
        case .X:
            return "x"
        case .Y:
            return "y"
        case .Z:
            return "z"
        }
    }
    
}

func calculateLevel(exp:Int)->(level:Int,percentage:Double,expToNextlevel:Double){
    var level:Int = 1
    var percentage:Double = 0.0
    var expToNextlevel:Double = 0
    //This will Help Calculate Exp
    if exp <= 500 {
        //Level 1
        level = 1
        let expInLevel:Double = Double(exp)
        expToNextlevel = expInLevel
        
        percentage = Double(exp / 500)
    } else if exp > 500 && exp <= 1_000 {
        //Level 2
        level = 2
        let expInLevel:Double = Double(exp) - 500
        expToNextlevel = expInLevel
        
        percentage = Double(expInLevel / 500)
    } else if exp > 1_000 && exp <= 2_000 {
        //Level 3
        level = 3
        let expInLevel:Double = Double(exp)  - 1_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 1_000)
        
    } else if exp > 2_000 && exp <= 4_000 {
        //Level 4
        level = 4
        let expInLevel:Double = Double(exp)  - 2_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 2_000)
        
    } else if exp > 4_000 && exp <= 8_000 {
        //Level 5
        level = 5
        let expInLevel:Double = Double(exp)  - 4_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 4_000)
        
    } else if exp > 8_000 && exp <= 16_000 {
        //Level 6
        level = 6
        let expInLevel:Double = Double(exp)  - 8_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 8_000)
        
    } else if exp > 16_000 && exp <= 32_000 {
        //Level 7
        level = 7
        let expInLevel:Double = Double(exp)  - 16_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 16_000)
        
    } else if exp > 32_000 && exp <= 64_000 {
        //Level 8
        level = 8
        let expInLevel:Double = Double(exp)  - 32_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 32_000)
        
    } else if exp > 64_000 && exp <= 128_000 {
        //Level 9
        level = 9
        let expInLevel:Double = Double(exp)  - 64_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 64_000)
        
    } else if exp > 128_000 && exp <= 256_000 {
        //Level 10
        level = 10
        let expInLevel:Double = Double(exp)  - 128_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 128_000)
        
    } else if exp > 256_000 && exp <= 512_000 {
        //Level 11
        level = 11
        let expInLevel:Double = Double(exp)  - 256_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 256_000)
        
    } else if exp > 512_000 && exp <= 1_024_000 {
        //Level 12
        level = 12
        let expInLevel:Double = Double(exp)  - 512_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 512_000)
        
    } else if exp > 1_024_000 && exp <= 2_048_000 {
        //Level 13
        level = 13
        let expInLevel:Double = Double(exp)  - 1_024_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 1_024_000)
        
    } else if exp > 2_048_000 && exp <= 4_096_000 {
        //Level 14
        level = 14
        let expInLevel:Double = Double(exp)  - 2_048_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 2_048_000)
        
    } else if exp > 4_096_000 && exp <= 8_192_000 {
        //Level 15
        level = 15
        let expInLevel:Double = Double(exp)  - 4_096_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 4_096_000)
        
    } else if exp > 8_192_000 && exp <= 16_384_00 {
        //Level 16
        level = 16
        let expInLevel:Double = Double(exp)  - 8_192_000
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 8_192_000)
        
    } else if exp > 16_384_00 && exp <= 32_768_00 {
        //Level 17
        level = 17
        let expInLevel:Double = Double(exp)  - 16_384_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 16_384_00)
        
    } else if exp > 32_768_00 && exp <= 65_536_00 {
        //Level 18
        level = 18
        let expInLevel:Double = Double(exp)  - 32_768_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 32_768_00)
        
    } else if exp > 65_536_00 && exp <= 131_072_00 {
        //Level 19
        level = 19
        let expInLevel:Double = Double(exp)  - 65_536_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 65_536_00)
        
    } else if exp > 131_072_00 && exp <= 262_144_00 {
        //Level 21
        level = 21
        let expInLevel:Double = Double(exp)  - 131_072_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 131_072_00)
        
    } else if exp > 262_144_00 && exp <= 524_288_00 {
        //Level 22
        level = 22
        let expInLevel:Double = Double(exp)  - 262_144_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 262_144_00)
        
    } else if exp > 524_288_00 && exp <= 1_048_576_00 {
        //Level 23
        level = 23
        let expInLevel:Double = Double(exp)  - 524_288_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 524_288_00)
        
    } else if exp > 1_048_576_00 && exp <= 2_097_152_00 {
        //Level 24
        level = 24
        let expInLevel:Double = Double(exp)  - 1_048_576_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 1_048_576_00)
        
    } else if exp > 2_097_152_00 && exp <= 4_194_304_00 {
        //Level 25
        level = 25
        let expInLevel:Double = Double(exp)  - 2_097_152_00
        expToNextlevel = expInLevel
        percentage = Double(expInLevel / 2_097_152_00)
        
    } else if exp > 4_194_304_00 {
        //Level 26
        level = 26
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
            Text("")
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
                    Text("")
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .cornerRadius(10)
                        .background(Color.green)
                        .padding()
                        .readingFrame { frame in
                            yOffset = frame.minY
                        }
                    
                    ForEach(0..<30) { x in
                        Text("")
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .cornerRadius(10)
                            .background(Color.green)
                            .padding()
                    }
                }
            }
            .coordinateSpace(name: "test")
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
                            rotation = 0
                            scale = 1
                            
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
            return CGSize(width: 0, height: offset.height)
        case .horizontal:
            return CGSize(width: offset.width, height: 0)
        default:
            return offset
        }
    }
    
    private func getRotation(translation: CGSize) -> CGFloat {
        let max = UIScreen.main.bounds.width / 2
        let percentage = translation.width * rotationMultiplier / max
        let maxRotation: CGFloat = 10
        return percentage * maxRotation
    }
    
    private func getScale(translation: CGSize) -> CGFloat {
        let max = UIScreen.main.bounds.width / 2
        
        var offsetAmount: CGFloat = 0
        switch axes {
        case .vertical:
            offsetAmount = abs(translation.height + lastOffset.height)
        case .horizontal:
            offsetAmount = abs(translation.width + lastOffset.width)
        default:
            offsetAmount = (abs(translation.width + lastOffset.width) + abs(translation.height + lastOffset.height)) / 2
        }
        
        let percentage = offsetAmount * scaleMultiplier / max
        let minScale: CGFloat = 0.8
        let range = 1 - minScale
        return 1 - (range * percentage)
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
        RoundedRectangle(cornerRadius: 10)
            .frame(width: 300, height: 200)
            .withDragGesture(
                [.vertical, .horizontal],
                resets: true,
                animation: .easeIn,
                rotationMultiplier: 1.1,
                scaleMultiplier: 1.1,
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
    var longWord = ""
    
    for w in wordArray {
        if w.count > longWord.count {
            longWord = w
        }
    }
    
    return longWord
}
