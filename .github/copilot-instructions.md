# GitHub Copilot Instructions for cgtcalc

## Project Overview

`cgtcalc` is a command-line application written in Swift that calculates UK capital gains tax (CGT) based on transaction data. The project is designed to help users calculate their capital gains tax liability according to UK HMRC rules.

**Key Purpose**: Calculate CGT for share transactions occurring on or after 6th April 2008, following current UK tax rules including same-day matching, bed-and-breakfast rules, and Section 104 holdings.

## Architecture

The project is structured as a Swift Package with two main components:

### 1. CGTCalcCore Library
The core calculation engine containing:
- **Parser**: Converts input data (text or CSV) into structured transaction data
  - `DefaultParser`: Space-delimited format parser
  - `CSVParser`: Comma-separated values parser
- **Calculator**: Main calculation engine processing transactions and asset events
- **Presenter**: Formats calculation results for output
  - `TextPresenter`: Plain text output
  - `MarkdownPresenter`: Markdown formatted output
- **Tax Logic**: UK tax year handling and CGT rules implementation

### 2. cgtcalc Executable
A command-line interface that:
- Uses `ArgumentParser` for CLI argument handling
- Detects input format (CSV vs default) automatically
- Detects output format (Markdown vs text) based on file extension
- Provides verbose logging option for debugging

## Code Style & Conventions

### Swift Standards
- Use Swift 6.0 syntax and features
- Code must be `Sendable` compliant for concurrency safety
- Prefer `async/await` for asynchronous operations
- Use `final` classes where inheritance is not intended
- Mark classes as `Sendable` when thread-safe

### Naming Conventions
- Use descriptive names for classes, methods, and variables
- Enums use PascalCase for cases (e.g., `. SameDay`, `.BedAndBreakfast`)
- Protocol names describe capabilities (e.g., `Logger`, `Parser`, `Presenter`)

### Financial Calculations
- **ALWAYS** use `Decimal` type for monetary values and quantities
- Never use `Double` or `Float` for financial calculations
- Round gains to 2 decimal places using `rounded(to: 2)`
- Currency formatting: `£` symbol followed by amount (e.g., "£1234.56")

### Date Handling
- Use `DateFormatter` with locale `en_US_POSIX`
- Use UTC timezone (`TimeZone(secondsFromGMT: 0)`)
- Date format: `dd/MM/yyyy` (e. g., "28/11/2019")
- Tax years run from 6th April to 5th April

### Error Handling
- Use custom error types for domain-specific errors (e.g., `ParserError`, `CalculatorError`)
- Throw errors for invalid data rather than failing silently
- Provide descriptive error messages

## Key Domain Concepts

### Transaction Types
- **BUY**: Purchase of shares/assets
- **SELL**: Disposal of shares/assets
- Format: `KIND DATE ASSET AMOUNT PRICE EXPENSES`

### Asset Events
- **CAPRETURN**: Capital return (equalisation payment for funds)
- **DIVIDEND**: Dividend with retained income tax (accumulation funds)
- **SPLIT**: Stock split (increase in shares, decreases cost basis)
- **UNSPLIT**: Reverse stock split

### CGT Matching Rules (in order of precedence)
1. **Same Day**: Acquisitions and disposals on the same date
2. **Bed & Breakfast**: Acquisitions within 30 days after disposal
3. **Section 104**: Pool of all remaining shares with average cost basis

### Tax Years
- UK tax year: 6th April to 5th April
- Tax rates and exemptions stored in `TaxYear. rates` dictionary
- Current limitations: 2024/25 rate changes (post-29 Oct 2024) require manual calculation

## Testing Guidelines

### Test Structure
- Unit tests in `Tests/CGTCalcCoreTests/`
- Example-based tests compare input files to expected output files
- Test data in `Tests/CGTCalcCoreTests/TestData/`
- Private tests (not committed) can be placed in `PrivateExamples/`

### Test Patterns
- Use `XCTest` framework
- Test files follow naming: `*Tests.swift`
- Example tests use input/output file pairs for end-to-end validation
- Use `StubLogger` for testing (not `BasicLogger`)

## Important Constraints & Warnings

### What to Avoid
- ❌ Do NOT support transactions before 6th April 2008
- ❌ Do NOT use floating-point types for financial calculations
- ❌ Do NOT modify core tax calculation logic without understanding HMRC rules
- ❌ Do NOT remove disclaimer about not being financial advice

### Platform Considerations
- Code runs on both macOS (. v15+) and Linux
- Use conditional compilation for platform-specific code:
  ```swift
  #if os(Linux)
    import Glibc
  #else
    import Darwin
  #endif
  ```

## Extensions & Customization

Users can extend the library by:
1. **Custom Parsers**: Implement `Parser` protocol to support new input formats
2. **Custom Presenters**: Implement `Presenter` protocol for different output formats

Example pattern:
```swift
let parser = CustomParser() // or DefaultParser(), CSVParser()
let input = try parser.calculatorInput(fromData: data)
let calculator = try Calculator(input: input, logger: logger)
let result = try await calculator.process()
let presenter = CustomPresenter(result: result) // or TextPresenter(), MarkdownPresenter()
let output = try presenter.process()
```

## Logging

- Use `Logger` protocol for all logging
- Log levels: Debug, Info, Warn, Error
- Production code uses `BasicLogger`
- Tests use `StubLogger`
- Verbose mode (`-v` flag) enables Debug level logging

## Dependencies

- **swift-argument-parser**: CLI argument parsing (v1.6. 0+)
- No other external dependencies for core functionality

## Common Tasks

### Adding New Tax Year Rates
Update `TaxYear.rates` dictionary in `Sources/CGTCalcCore/Tax/TaxYear.swift`

### Adding New Asset Event Types
1. Add case to `AssetEvent.Kind` enum
2. Update parsers (`DefaultParser`, `CSVParser`)
3. Handle in `Section104Holding.process(assetEvent:)`
4. Add tests

### Modifying Output Format
Create new `Presenter` implementation or modify existing `TextPresenter`/`MarkdownPresenter`

## License

MIT License - See LICENSE file for details