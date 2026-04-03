# ImgZen Tests

This directory contains unit tests for the ImgZen application, organized to mirror the main application structure.

## Test Organization

### Domain/
Tests for domain models and business logic.

#### Domain/
Tests for domain model types.
- `ImageMetadataTests.swift` - Tests for image metadata structure
- `InputItemTests.swift` - Tests for input item model and source handling
- `OutputItemTests.swift` - Tests for output item model
- `ContextActionTests.swift` - Tests for context action model
- `ImageResolutionTests.swift` - Tests for image resolution enum

#### Domain/ImageConversion/
Tests for image conversion functionality.
- `ImageConversionErrorTests.swift` - Tests for conversion error types
- `ImageConverterTests.swift` - Tests for image format conversion logic
- `ImageFormatTests.swift` - Tests for image format enums and properties

#### Domain/Services/
Tests for domain service classes.
- `ImageConversionServiceTests.swift` - Tests for image conversion orchestration
- `ImageServiceTests.swift` - Tests for image data and metadata retrieval
- `InputServiceTests.swift` - Tests for input item management

### UI/
Tests for UI and presentation layer logic.

#### UI/Components/
Tests for reusable UI components and utilities.
- `AsyncResourceLoaderTests.swift` - Tests for async resource loading functionality

#### UI/Presentation/
Tests for presentation layer logic.
- `ImageItemPresenterTests.swift` - Tests for image metadata presentation formatting

## Running Tests

Tests can be run using:
- Xcode: `Cmd+U` or Product → Test
- Command line: `xcodebuild test -scheme ImgZen`

## Test Framework

All tests use Swift Testing framework with `@Test` attributes and `#expect` assertions.

