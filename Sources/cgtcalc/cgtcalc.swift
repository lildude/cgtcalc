//
//  cgtcalc.swift
//  cgtcalc
//
//  Created by Matt Galloway on 06/06/2020.
//  Modified by Colin Seymour on 28/03/2023.
//

import ArgumentParser
import CGTCalcCore
import Foundation

@main
struct CGTCalc: AsyncParsableCommand {
  static let VERSION = "0.1.0"

  @Argument(help: "The input data filename")
  var filename: String

  @Flag(name: .shortAndLong, help: "Enable verbose logging")
  var verbose = false

  @Option(name: .shortAndLong, help: "Output file")
  var outputFile: String?

  @Flag(name: [.customShort("t"), .long], help: "Generate separate file for last complete tax year")
  var taxYear = false

  static let configuration = CommandConfiguration(commandName: "cgtcalc", version: Self.VERSION)

  func run() async throws {
    let logLevel: BasicLogger.Level
    if self.verbose {
      logLevel = .Debug
    } else {
      logLevel = .Info
    }
    let logger = BasicLogger(level: logLevel)

    do {
      let data = try String(contentsOfFile: filename, encoding: .utf8)
      let parser: Parser
      if filename.hasSuffix(".csv") {
        logger.info("Detected CSV input")
        parser = CSVParser()
      } else {
        logger.info("Detected default input")
        parser = DefaultParser()
      }
      let input = try parser.calculatorInput(fromData: data)

      let calculator = try Calculator(input: input, logger: logger)
      let result = try await calculator.process()

      let presenter: Presenter
      // If the filename ends in .md, assume markdown
      let outputFile = self.outputFile ?? "-"
      if outputFile.hasSuffix(".md") {
        logger.info("Detected markdown output")
        presenter = MarkdownPresenter(result: result)
      } else {
        logger.info("Detected default text output")
        presenter = TextPresenter(result: result)
      }

      let output = try presenter.process()

      if let outputFile = self.outputFile, outputFile != "-" {
        let outputFileUrl = URL(fileURLWithPath: outputFile)
        switch output {
        case .data(let data):
          try data.write(to: outputFileUrl)
        case .string(let string):
          try string.write(to: outputFileUrl, atomically: true, encoding: .utf8)
        }
      } else {
        switch output {
        case .data:
          print("Cannot output to console for this presenter. Choose a file to write to instead.")
        case .string(let string):
          print(string)
        }
      }

      // Generate separate file for last full tax year if requested
      if self.taxYear {
        try await self.generateTaxYearFile(
          result: result,
          presenter: presenter,
          outputFile: self.outputFile,
          logger: logger
        )
      }
    } catch {
      logger.error("Failed: \(error)")
    }
  }

  private func generateTaxYearFile(
    result: CalculatorResult,
    presenter: Presenter,
    outputFile: String?,
    logger: BasicLogger
  ) async throws {
    // Find the last full tax year (must have ended before today)
    let today = Date()
    let currentTaxYear = TaxYear(containingDate: today)

    guard let lastFullTaxYear = result.taxYearSummaries
      .map({ $0.taxYear })
      .filter({ $0.year < currentTaxYear.year })
      .sorted(by: { $0 > $1 })
      .first else {
      logger.error("No complete tax year found to generate separate file")
      return
    }

    logger.info("Generating separate file for tax year \(lastFullTaxYear.string)")

    // Determine output directory and file extension
    let outputDirectory: URL
    let fileExtension: String

    if let outputFile = outputFile, outputFile != "-" {
      let outputURL = URL(fileURLWithPath: outputFile)
      outputDirectory = outputURL.deletingLastPathComponent()
      fileExtension = outputURL.pathExtension
    } else {
      outputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      fileExtension = "txt"
    }

    // Generate filename based on tax year
    let taxYearStart = lastFullTaxYear.year - 1
    let taxYearEnd = lastFullTaxYear.year
    let baseFilename = String(format: "TY-%04d-%02d", taxYearStart, taxYearEnd % 100)
    let filename = fileExtension.isEmpty ? baseFilename : "\(baseFilename).\(fileExtension)"
    let taxYearFileURL = outputDirectory.appendingPathComponent(filename)

    logger.info("Tax year file will be written to \(taxYearFileURL.path)")

    // Generate output for the specific tax year
    let taxYearOutput = try presenter.processForTaxYear(lastFullTaxYear)

    // Write to file
    switch taxYearOutput {
    case .data(let data):
      try data.write(to: taxYearFileURL)
    case .string(let string):
      try string.write(to: taxYearFileURL, atomically: true, encoding: .utf8)
    }

    logger.info("Tax year file written to \(taxYearFileURL.path)")
  }
}
