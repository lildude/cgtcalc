//
//  Parser.swift
//  CGTCalcCore
//
//  Created by Colin Seymour on 28/03/2023.
//

import Foundation

public enum ParserError: Error {
  case IncorrectNumberOfFields(String)
  case InvalidKind(String)
  case InvalidDate(String)
  case InvalidAmount(String)
  case InvalidPrice(String)
  case InvalidExpenses(String)
  case InvalidValue(String)
}

public class CalculatorInput {
  public let transactions: [Transaction]
  public let assetEvents: [AssetEvent]

  public init(transactions: [Transaction], assetEvents: [AssetEvent]) {
    self.transactions = transactions
    self.assetEvents = assetEvents
  }
}

public protocol Parser {
  func calculatorInput(fromData data: String) throws -> CalculatorInput
}

