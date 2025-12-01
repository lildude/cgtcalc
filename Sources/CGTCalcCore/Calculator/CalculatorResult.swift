//
//  CalculatorResult.swift
//  cgtcalc
//
//  Created by Matt Galloway on 08/06/2020.
//

import Foundation

public struct CalculatorResult: Sendable {
  let input: CalculatorInput
  public let taxYearSummaries: [TaxYearSummary]
  public let holdings: [Holding]

  public struct DisposalResult: Sendable {
    public let disposal: Transaction
    public let gain: Decimal
    public let disposalMatches: [DisposalMatch]
  }

  public struct TaxYearSummary: Sendable {
    public let taxYear: TaxYear
    public let overallGains: Decimal
    public let proceeds: Decimal
    public let allowableCosts: Decimal
    public let exemption: Decimal
    public let carryForwardLoss: Decimal
    public let taxableGains: Decimal
    public let basicRateTax: Decimal
    public let higherRateTax: Decimal
    public let gainsCount: Int
    public let totalGains: Decimal
    public let lossesCount: Int
    public let totalLosses: Decimal
    public let disposalResults: [DisposalResult]
  }

  public struct Holding: Sendable {
    public let asset: String
    public let amount: Decimal
    public let costBasis: Decimal
  }

  init(input: CalculatorInput, disposalMatches: [DisposalMatch], holdings: [Holding]) throws {
    self.input = input
    self.holdings = holdings

    var carryForwardLoss = Decimal.zero
    self.taxYearSummaries = try disposalMatches
      .reduce(into: [TaxYear: [DisposalMatch]]()) { result, disposalMatch in
        var disposalMatches = result[disposalMatch.taxYear, default: []]
        disposalMatches.append(disposalMatch)
        result[disposalMatch.taxYear] = disposalMatches
      }
      .sorted { $0.key < $1.key }
      .map { taxYear, disposalMatches in
        var disposalMatchesByDisposal: [Transaction: [DisposalMatch]] = [:]
        var gainByDisposal: [Transaction: Decimal] = [:]

        var totalProceeds = Decimal.zero
        var totalAllowableCosts = Decimal.zero

        for disposalMatch in disposalMatches {
          let disposal = disposalMatch.disposal.transaction
          var matches = disposalMatchesByDisposal[disposal, default: []]
          matches.append(disposalMatch)
          disposalMatchesByDisposal[disposal] = matches
          gainByDisposal[disposal, default: Decimal.zero] += disposalMatch.gain
          totalProceeds += disposalMatch.disposal.value
          totalAllowableCosts += disposalMatch.allowableCosts
        }

        var totalOverallGains = Decimal.zero
        var totalGains = Decimal.zero
        var gainsCount = 0
        var totalLosses = Decimal.zero
        var lossesCount = 0
        let disposalResults =
          disposalMatchesByDisposal.map { disposal, disposalMatches -> DisposalResult in
            let roundedGain = TaxMethods.roundedGain(gainByDisposal[disposal]!)
            if roundedGain.isSignMinus {
              totalLosses -= roundedGain
              lossesCount += 1
            } else {
              totalGains += roundedGain
              gainsCount += 1
            }
            totalOverallGains += roundedGain
            return DisposalResult(disposal: disposal, gain: roundedGain, disposalMatches: disposalMatches)
          }
          .sorted {
            if $0.disposal.date == $1.disposal.date {
              return $0.disposal.asset < $1.disposal.asset
            }
            return $0.disposal.date < $1.disposal.date
          }

        guard let taxYearRates = TaxYear.rates[taxYear] else {
          throw CalculatorError.InternalError("Missing tax year rates for \(taxYear)")
        }

        let taxableGains: Decimal
        let gainAboveExemption = max(totalOverallGains - taxYearRates.exemption, Decimal.zero)
        if !gainAboveExemption.isZero {
          let lossUsed = min(gainAboveExemption, carryForwardLoss)
          taxableGains = gainAboveExemption - lossUsed
          carryForwardLoss -= lossUsed
        } else {
          taxableGains = Decimal.zero
          if totalOverallGains.isSignMinus {
            carryForwardLoss -= totalOverallGains
          }
        }
        let basicRateTax = TaxMethods.roundedGain(taxableGains * taxYearRates.basicRate * 0.01)
        let higherRateTax = TaxMethods.roundedGain(taxableGains * taxYearRates.higherRate * 0.01)

        return TaxYearSummary(
          taxYear: taxYear,
          overallGains: totalOverallGains,
          proceeds: TaxMethods.roundedGain(totalProceeds),
          allowableCosts: TaxMethods.roundedGain(totalAllowableCosts),
          exemption: taxYearRates.exemption,
          carryForwardLoss: carryForwardLoss,
          taxableGains: taxableGains,
          basicRateTax: basicRateTax,
          higherRateTax: higherRateTax,
          gainsCount: gainsCount,
          totalGains: totalGains,
          lossesCount: lossesCount,
          totalLosses: totalLosses,
          disposalResults: disposalResults)
      }
  }
}
