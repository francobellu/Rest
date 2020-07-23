import XCTest

import MyModuleTests

var tests = [XCTestCaseEntry]()
tests += MyModuleTests.allTests()
XCTMain(tests)
