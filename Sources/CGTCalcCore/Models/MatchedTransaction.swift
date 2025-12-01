//
//  MatchedTransaction.swift
//  cgtcalc
//
//  Created by Matt Galloway on 01/11/2025.
//

import Foundation

public final class MatchedTransaction: Sendable {
  public let transaction: Transaction
  public let underlyingPrice: Decimal
  public let amount: Decimal
  public let expenses: Decimal
  public let offset: Decimal

  public var price: Decimal {
    self.underlyingPrice + (self.offset / self.amount)
  }

  public var value: Decimal {
    (self.underlyingPrice * self.amount) + self.offset
  }

  public var asset: String {
    self.transaction.asset
  }

  public var date: Date {
    self.transaction.date
  }

  init(transaction: Transaction, underlyingPrice: Decimal, amount: Decimal, expenses: Decimal, offset: Decimal) {
    self.transaction = transaction
    self.underlyingPrice = underlyingPrice
    self.amount = amount
    self.expenses = expenses
    self.offset = offset
  }
}

extension MatchedTransaction: CustomStringConvertible {
  public var description: String {
    return "<\(String(describing: type(of: self))): transaction=\(self.transaction), amount=\(self.amount), underlyingPrice=\(self.underlyingPrice), price=\(self.price), expenses=\(self.expenses), offset=\(self.offset)>"
  }
}
