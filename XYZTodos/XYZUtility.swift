//
//  XYZUtility.swift
//  XYZTodos
//
//  Created by Chee Bin Hoh on 10/29/20.
//

import Foundation

enum DayOfWeek: String, CaseIterable {

    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
    case Sunday
}

extension String {
    
    func localized() -> String {
        
        return NSLocalizedString(self, comment:"")
    }
}

// MARK: - formatting

func formattingDate(_ date: Date,
                    style: DateFormatter.Style) -> String {
    
    let dateFormatter = DateFormatter();
    
    dateFormatter.dateStyle = style
    
    return dateFormatter.string(from: date)
}

func formattingDateTime(_ date: Date) -> String {
    
    let dateFormatter = DateFormatter();
    
    // FIXME, we will need to think about localization
    dateFormatter.dateFormat = "MMM-dd, yyyy 'at' hh:mm a"
    
    return dateFormatter.string(from: date)
}

func formattingAndProcessDoubleValue(of input: String) -> String {
    
    var processedInput = ""
    var afterPoint = false
    var numberOfDigitsAfterPoint = 0
    let digitSet = CharacterSet.decimalDigits
    let numberOfFixedDecimalPoints = 2
    
    if ( input.isEmpty )
    {
        return "0.00"
    }
    
    let lastChar = input[input.index(before: input.endIndex)]
    
    if Locale.current.decimalSeparator ?? "" == "\(lastChar)" {
        
        processedInput = shiftingDecimalPoint(of: input)
        numberOfDigitsAfterPoint = numberOfFixedDecimalPoints
    } else {
        
        for c in input.unicodeScalars {
            
            if !digitSet.contains(c) {
                
                afterPoint = true
                continue
            } else {
                
                if afterPoint {
                    
                    numberOfDigitsAfterPoint = numberOfDigitsAfterPoint + 1
                }
                
                processedInput += "\(c)"
            }
        }
    }

    var doubleValue = Double(processedInput) ?? 0.0
    
    while numberOfDigitsAfterPoint != numberOfFixedDecimalPoints {
        
        doubleValue = doubleValue / 100
        
        if numberOfDigitsAfterPoint < numberOfFixedDecimalPoints {
            
            numberOfDigitsAfterPoint = numberOfDigitsAfterPoint + 1
        } else {
            
            numberOfDigitsAfterPoint = numberOfDigitsAfterPoint - 1
        }
    }
    
    return "\(doubleValue)"
}

func shiftingDecimalPoint(of input: String) -> String {
    
    var processedInput = ""
    var decimalPointFound = false
    let reversedInput = input.reversed()

    for c in String(reversedInput).unicodeScalars {
        
        if Locale.current.decimalSeparator ?? "" == "\(c)" {
            
            if ( decimalPointFound ) {
                
                continue
            } else {
                
                if processedInput.isEmpty {
                    
                    processedInput = processedInput + "00"
                }
            }
            
            decimalPointFound = true
        }

        processedInput = processedInput + "\(c)"
    }
    
    return String(processedInput.reversed())
}

func formattingDoubleValueAsDouble(of input: String) -> Double {
    
    return Double(formattingDoubleValue(of: input)) ?? 0.0
}

func formattingDoubleValue(of input: String) -> String {
    
    var processedInput = ""
    var startWithDecimalDigit = false
    var startWithNegativeSign = false
    let digitSet = CharacterSet.decimalDigits
    
    let inputToBeProcessed = input
    
    for c in inputToBeProcessed.unicodeScalars {
        
        if !startWithNegativeSign && c == "-" {
          
            startWithNegativeSign = true
        } else if startWithDecimalDigit {
            
            if digitSet.contains(c) || ( Locale.current.decimalSeparator ?? "" == "\(c)" ) {
                
                processedInput += "\(c)"
            }
        } else if !digitSet.contains(c) {
            
            continue
        } else {
            
            startWithDecimalDigit = true
            processedInput += "\(c)"
        }
    }
    
    return startWithNegativeSign ? "-\(processedInput)" : processedInput
}

func formattingCurrencyValue(of input: Double,
                             as code: String?) -> String {
    
    let value = "\(input)"
    
    return formattingCurrencyValue(of: value, as: code)
}

func formattingCurrencyValue(of input: String,
                             as code: String?) -> String {
    
    let processedInput = formattingDoubleValue(of: input)
    
    let formatter = NumberFormatter()

    let amountAsDouble = Double(processedInput) ?? 0.0
    let amountASNSNumber = NSNumber(value: amountAsDouble)
    
    formatter.numberStyle = .currency
    formatter.currencyCode = code
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2

    guard let formattedAmount = formatter.string(from: amountASNSNumber) else {
        
        return ""
    }
    
    return formattedAmount
}
