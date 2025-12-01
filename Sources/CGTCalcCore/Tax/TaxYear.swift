//
//  TaxYear.swift
//  cgtcalc
//
//  Created by Matt Galloway on 08/06/2020.
//

import Foundation

public struct TaxYear: Sendable {
  public let year: Int

  public var string: String { "\(self.year - 1)/\(self.year)" }

  public init(yearEnding year: Int) {
    self.year = year
  }

  public init(containingDate: Date) {
    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents([.year, .month, .day], from: containingDate)
    var year = components.year!
    if components.month! > 4 {
      year += 1
    }
    if components.month! == 4, components.day! > 5 {
      year += 1
    }
    self.init(yearEnding: year)
  }
}

extension TaxYear: CustomStringConvertible {
  public var description: String {
    return self.string
  }
}

extension TaxYear: Comparable {
  public static func < (lhs: TaxYear, rhs: TaxYear) -> Bool {
    return lhs.year < rhs.year
  }
}

extension TaxYear: Equatable {
  public static func == (lhs: TaxYear, rhs: TaxYear) -> Bool {
    return lhs.year == rhs.year
  }
}

extension TaxYear: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.year)
  }
}

extension TaxYear {
  struct Rates {
    let exemption: Decimal
    let basicRate: Decimal
    let higherRate: Decimal
  }

  static let rates: [TaxYear: Rates] = [
    TaxYear(yearEnding: 2014): Rates(exemption: 10900, basicRate: 18, higherRate: 28),
    TaxYear(yearEnding: 2015): Rates(exemption: 11000, basicRate: 18, higherRate: 28),
    TaxYear(yearEnding: 2016): Rates(exemption: 11100, basicRate: 18, higherRate: 28),
    TaxYear(yearEnding: 2017): Rates(exemption: 11100, basicRate: 10, higherRate: 20),
    TaxYear(yearEnding: 2018): Rates(exemption: 11300, basicRate: 10, higherRate: 20),
    TaxYear(yearEnding: 2019): Rates(exemption: 11700, basicRate: 10, higherRate: 20),
    TaxYear(yearEnding: 2020): Rates(exemption: 12000, basicRate: 10, higherRate: 20),
    TaxYear(yearEnding: 2021): Rates(exemption: 12300, basicRate: 10, higherRate: 20),
    TaxYear(yearEnding: 2022): Rates(exemption: 12300, basicRate: 10, higherRate: 20),
    TaxYear(yearEnding: 2023): Rates(exemption: 12300, basicRate: 10, higherRate: 20),
    TaxYear(yearEnding: 2024): Rates(exemption: 6000, basicRate: 10, higherRate: 20),
    TaxYear(yearEnding: 2025): Rates(exemption: 3000, basicRate: 10, higherRate: 20),
    TaxYear(yearEnding: 2026): Rates(exemption: 3000, basicRate: 18, higherRate: 24)
  ]

  static let postProcessors: [TaxYear: TaxYearPostProcessor] = [
    TaxYear(yearEnding: 2025): TaxYearPostProcessor20242025()
  ]
}
