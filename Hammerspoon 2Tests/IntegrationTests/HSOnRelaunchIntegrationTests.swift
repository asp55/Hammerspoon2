//
//  HSOnRelaunchIntegrationTests.swift
//  Hammerspoon 2Tests
//

import Testing
import JavaScriptCore
@testable import Hammerspoon_2

/// Tests for `hs.onRelaunch`. The reopen event itself comes from AppKit, so these call
/// `ModuleRoot.callOnRelaunch()` directly, as `AppDelegate.applicationShouldHandleReopen` does.
@Suite("hs.onRelaunch tests")
struct HSOnRelaunchTests {
    @Test("onRelaunch is null until it's set")
    func testDefaultsToNull() {
        let harness = JSTestHarness()
        let root = harness.loadModuleRoot()
        #expect(harness.evalValue("hs.onRelaunch")?.isNull == true)
        #expect(root.callOnRelaunch() == false)
    }

    @Test("A function assigned to onRelaunch is called on relaunch")
    func testCallbackIsCalled() {
        let harness = JSTestHarness()
        let root = harness.loadModuleRoot()
        var calls = 0
        harness.registerCallback("onRelaunch") { calls += 1 }
        harness.eval("hs.onRelaunch = function() { __test_callback('onRelaunch') }")
        #expect(!harness.hasException)
        #expect(harness.evalTypeOf("hs.onRelaunch") == "function")

        #expect(root.callOnRelaunch() == true)
        #expect(calls == 1)
    }

    @Test("Assigning null removes the callback")
    func testAssigningNullRemovesCallback() {
        let harness = JSTestHarness()
        let root = harness.loadModuleRoot()
        var calls = 0
        harness.registerCallback("onRelaunch") { calls += 1 }
        harness.eval("hs.onRelaunch = function() { __test_callback('onRelaunch') }")
        harness.eval("hs.onRelaunch = null")
        #expect(!harness.hasException)

        #expect(harness.evalValue("hs.onRelaunch")?.isNull == true)
        #expect(root.callOnRelaunch() == false)
        #expect(calls == 0)
    }

    @Test("Assigning something that isn't a function leaves no callback")
    func testAssigningNonFunctionLeavesNoCallback() {
        let harness = JSTestHarness()
        let root = harness.loadModuleRoot()
        harness.eval("hs.onRelaunch = 'not a function'")
        #expect(!harness.hasException)

        #expect(harness.evalValue("hs.onRelaunch")?.isNull == true)
        #expect(root.callOnRelaunch() == false)
    }

    @Test("A callback that throws still counts as handled")
    func testThrowingCallbackCountsAsHandled() {
        let harness = JSTestHarness()
        let root = harness.loadModuleRoot()
        harness.eval("hs.onRelaunch = function() { throw new Error('boom') }")

        #expect(root.callOnRelaunch() == true)
    }

    @Test("A callback nothing else references survives garbage collection")
    func testUnreferencedCallbackSurvivesGC() {
        let harness = JSTestHarness()
        let root = harness.loadModuleRoot()
        var calls = 0
        harness.registerCallback("onRelaunch") { calls += 1 }
        // `void` + autoreleasepool, so eval's completion value doesn't keep the function alive
        autoreleasepool { _ = harness.eval("void (hs.onRelaunch = function() { __test_callback('onRelaunch') })") }
        harness.collectGarbage()

        #expect(root.callOnRelaunch() == true)
        #expect(calls == 1)
    }

    @Test("Shutdown removes the callback")
    func testShutdownRemovesCallback() {
        let harness = JSTestHarness()
        let root = harness.loadModuleRoot()
        var calls = 0
        harness.registerCallback("onRelaunch") { calls += 1 }
        harness.eval("hs.onRelaunch = function() { __test_callback('onRelaunch') }")

        root.shutdown()
        #expect(root.callOnRelaunch() == false)
        #expect(calls == 0)
    }
}
