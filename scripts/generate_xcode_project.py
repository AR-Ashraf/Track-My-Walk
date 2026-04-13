#!/usr/bin/env python3
"""
Generate Boilerplate.xcodeproj for this repo (sources under Boilerplate/ + BoilerplateTests/).
Run from repo root: python3 scripts/generate_xcode_project.py
"""
from __future__ import annotations

import hashlib
import sys
from pathlib import Path


def xcode_id(*parts: str) -> str:
    h = hashlib.sha256("::".join(parts).encode()).hexdigest()[:24]
    return h.upper()


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    boilerplate = root / "Boilerplate"
    tests = root / "BoilerplateTests"
    if not boilerplate.is_dir():
        print("Missing Boilerplate/ directory", file=sys.stderr)
        return 1

    swift_main = sorted(boilerplate.rglob("*.swift"))
    swift_tests = sorted(tests.rglob("*.swift")) if tests.is_dir() else []

    proj_dir = root / "Boilerplate.xcodeproj"
    proj_dir.mkdir(parents=True, exist_ok=True)

    project_id = xcode_id("project", "root")
    main_group_id = xcode_id("group", "main")
    products_group_id = xcode_id("group", "products")
    bp_group_id = xcode_id("group", "boilerplate")
    bt_group_id = xcode_id("group", "boilerplatetests")
    app_target_id = xcode_id("target", "app")
    test_target_id = xcode_id("target", "tests")
    app_product_id = xcode_id("product", "app")
    test_product_id = xcode_id("product", "tests")
    app_sources_phase = xcode_id("phase", "appsources")
    test_sources_phase = xcode_id("phase", "testsources")
    app_frameworks_phase = xcode_id("phase", "appfw")
    test_frameworks_phase = xcode_id("phase", "testfw")
    app_resources_phase = xcode_id("phase", "appres")
    project_config_list = xcode_id("cfglist", "project")
    app_config_list = xcode_id("cfglist", "app")
    test_config_list = xcode_id("cfglist", "test")
    dbg_project = xcode_id("xcfg", "projdbg")
    rel_project = xcode_id("xcfg", "projrel")
    dbg_app = xcode_id("xcfg", "appdbg")
    rel_app = xcode_id("xcfg", "apprel")
    dbg_test = xcode_id("xcfg", "testdbg")
    rel_test = xcode_id("xcfg", "testrel")
    proxy_id = xcode_id("proxy", "test")
    dep_id = xcode_id("dep", "test")

    app_refs: list[tuple[str, str, str]] = []  # rid, bid, rel path
    for p in swift_main:
        rel = p.relative_to(boilerplate).as_posix()
        app_refs.append((xcode_id("fileref", rel), xcode_id("build", rel), rel))

    test_refs: list[tuple[str, str, str]] = []
    for p in swift_tests:
        rel = p.relative_to(tests).as_posix()
        test_refs.append((xcode_id("tfileref", rel), xcode_id("tbuild", rel), rel))

    lines: list[str] = []
    ap = lines.append
    ap("// !$*UTF8*$!")
    ap("{")
    ap("\tarchiveVersion = 1;")
    ap("\tclasses = {};")
    ap("\tobjectVersion = 56;")
    ap("\tobjects = {")

    ap("\t\t/* Begin PBXBuildFile section */")
    for rid, bid, rel in app_refs:
        name = Path(rel).name
        ap(f"\t\t{bid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {rid} /* {name} */; }};")
    for rid, bid, rel in test_refs:
        name = Path(rel).name
        ap(f"\t\t{bid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {rid} /* {name} */; }};")
    ap("\t\t/* End PBXBuildFile section */")
    ap("")

    ap("\t\t/* Begin PBXFileReference section */")
    for rid, bid, rel in app_refs:
        name = Path(rel).name
        ap(f"\t\t{rid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{rel}\"; sourceTree = \"<group>\"; }};")
    for rid, bid, rel in test_refs:
        name = Path(rel).name
        ap(f"\t\t{rid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{rel}\"; sourceTree = \"<group>\"; }};")
    ap(f"\t\t{app_product_id} /* Boilerplate.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Boilerplate.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    ap(f"\t\t{test_product_id} /* BoilerplateTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = BoilerplateTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")
    ap("\t\t/* End PBXFileReference section */")
    ap("")

    ap("\t\t/* Begin PBXFrameworksBuildPhase section */")
    ap(f"\t\t{app_frameworks_phase} /* Frameworks */ = {{")
    ap("\t\t\tisa = PBXFrameworksBuildPhase;")
    ap("\t\t\tbuildActionMask = 2147483647;")
    ap("\t\t\tfiles = ();")
    ap("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    ap("\t\t};")
    ap(f"\t\t{test_frameworks_phase} /* Frameworks */ = {{")
    ap("\t\t\tisa = PBXFrameworksBuildPhase;")
    ap("\t\t\tbuildActionMask = 2147483647;")
    ap("\t\t\tfiles = ();")
    ap("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    ap("\t\t};")
    ap("\t\t/* End PBXFrameworksBuildPhase section */")
    ap("")

    ap("\t\t/* Begin PBXGroup section */")
    ap(f"\t\t{bp_group_id} /* Boilerplate */ = {{")
    ap("\t\t\tisa = PBXGroup;")
    ap("\t\t\tchildren = (")
    for rid, _, rel in app_refs:
        ap(f"\t\t\t\t{rid} /* {Path(rel).name} */,")
    ap("\t\t\t);")
    ap("\t\t\tpath = Boilerplate;")
    ap("\t\t\tsourceTree = \"<group>\";")
    ap("\t\t};")

    ap(f"\t\t{bt_group_id} /* BoilerplateTests */ = {{")
    ap("\t\t\tisa = PBXGroup;")
    ap("\t\t\tchildren = (")
    for rid, _, rel in test_refs:
        ap(f"\t\t\t\t{rid} /* {Path(rel).name} */,")
    ap("\t\t\t);")
    ap("\t\t\tpath = BoilerplateTests;")
    ap("\t\t\tsourceTree = \"<group>\";")
    ap("\t\t};")

    ap(f"\t\t{products_group_id} /* Products */ = {{")
    ap("\t\t\tisa = PBXGroup;")
    ap("\t\t\tchildren = (")
    ap(f"\t\t\t\t{app_product_id} /* Boilerplate.app */,")
    ap(f"\t\t\t\t{test_product_id} /* BoilerplateTests.xctest */,")
    ap("\t\t\t);")
    ap("\t\t\tname = Products;")
    ap("\t\t\tsourceTree = \"<group>\";")
    ap("\t\t};")

    ap(f"\t\t{main_group_id} = {{")
    ap("\t\t\tisa = PBXGroup;")
    ap("\t\t\tchildren = (")
    ap(f"\t\t\t\t{bp_group_id} /* Boilerplate */,")
    ap(f"\t\t\t\t{bt_group_id} /* BoilerplateTests */,")
    ap(f"\t\t\t\t{products_group_id} /* Products */,")
    ap("\t\t\t);")
    ap("\t\t\tsourceTree = \"<group>\";")
    ap("\t\t};")
    ap("\t\t/* End PBXGroup section */")
    ap("")

    ap("\t\t/* Begin PBXNativeTarget section */")
    ap(f"\t\t{app_target_id} /* Boilerplate */ = {{")
    ap("\t\t\tisa = PBXNativeTarget;")
    ap(f"\t\t\tbuildConfigurationList = {app_config_list} /* Build configuration list for PBXNativeTarget \"Boilerplate\" */;")
    ap("\t\t\tbuildPhases = (")
    ap(f"\t\t\t\t{app_sources_phase} /* Sources */,")
    ap(f"\t\t\t\t{app_frameworks_phase} /* Frameworks */,")
    ap(f"\t\t\t\t{app_resources_phase} /* Resources */,")
    ap("\t\t\t);")
    ap("\t\t\tbuildRules = ();")
    ap("\t\t\tdependencies = ();")
    ap("\t\t\tname = Boilerplate;")
    ap("\t\t\tproductName = Boilerplate;")
    ap(f"\t\t\tproductReference = {app_product_id} /* Boilerplate.app */;")
    ap("\t\t\tproductType = \"com.apple.product-type.application\";")
    ap("\t\t};")

    ap(f"\t\t{test_target_id} /* BoilerplateTests */ = {{")
    ap("\t\t\tisa = PBXNativeTarget;")
    ap(f"\t\t\tbuildConfigurationList = {test_config_list} /* Build configuration list for PBXNativeTarget \"BoilerplateTests\" */;")
    ap("\t\t\tbuildPhases = (")
    ap(f"\t\t\t\t{test_sources_phase} /* Sources */,")
    ap(f"\t\t\t\t{test_frameworks_phase} /* Frameworks */,")
    ap("\t\t\t);")
    ap("\t\t\tbuildRules = ();")
    ap("\t\t\tdependencies = (")
    ap(f"\t\t\t\t{dep_id} /* PBXTargetDependency */,")
    ap("\t\t\t);")
    ap("\t\t\tname = BoilerplateTests;")
    ap("\t\t\tproductName = BoilerplateTests;")
    ap(f"\t\t\tproductReference = {test_product_id} /* BoilerplateTests.xctest */;")
    ap("\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";")
    ap("\t\t};")
    ap("\t\t/* End PBXNativeTarget section */")
    ap("")

    ap("\t\t/* Begin PBXProject section */")
    ap(f"\t\t{project_id} /* Project object */ = {{")
    ap("\t\t\tisa = PBXProject;")
    ap("\t\t\tattributes = {")
    ap("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    ap("\t\t\t\tLastSwiftUpdateCheck = 1500;")
    ap("\t\t\t\tLastUpgradeCheck = 1500;")
    ap("\t\t\t\tTargetAttributes = {")
    ap(f"\t\t\t\t\t{app_target_id} = {{")
    ap("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    ap("\t\t\t\t\t};")
    ap(f"\t\t\t\t\t{test_target_id} = {{")
    ap("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    ap(f"\t\t\t\t\t\ttestTargetID = {app_target_id};")
    ap("\t\t\t\t\t};")
    ap("\t\t\t\t};")
    ap("\t\t\t};")
    ap(f"\t\t\tbuildConfigurationList = {project_config_list} /* Build configuration list for PBXProject \"Boilerplate\" */;")
    ap("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    ap("\t\t\tdevelopmentRegion = en;")
    ap("\t\t\thasScannedForEncodings = 0;")
    ap("\t\t\tknownRegions = (en, Base);")
    ap(f"\t\t\tmainGroup = {main_group_id};")
    ap(f"\t\t\tproductRefGroup = {products_group_id} /* Products */;")
    ap("\t\t\tprojectDirPath = \"\";")
    ap("\t\t\tprojectRoot = \"\";")
    ap("\t\t\ttargets = (")
    ap(f"\t\t\t\t{app_target_id} /* Boilerplate */,")
    ap(f"\t\t\t\t{test_target_id} /* BoilerplateTests */,")
    ap("\t\t\t);")
    ap("\t\t};")
    ap("\t\t/* End PBXProject section */")
    ap("")

    ap("\t\t/* Begin PBXResourcesBuildPhase section */")
    ap(f"\t\t{app_resources_phase} /* Resources */ = {{")
    ap("\t\t\tisa = PBXResourcesBuildPhase;")
    ap("\t\t\tbuildActionMask = 2147483647;")
    ap("\t\t\tfiles = ();")
    ap("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    ap("\t\t};")
    ap("\t\t/* End PBXResourcesBuildPhase section */")
    ap("")

    ap("\t\t/* Begin PBXSourcesBuildPhase section */")
    ap(f"\t\t{app_sources_phase} /* Sources */ = {{")
    ap("\t\t\tisa = PBXSourcesBuildPhase;")
    ap("\t\t\tbuildActionMask = 2147483647;")
    ap("\t\t\tfiles = (")
    for _, bid, rel in app_refs:
        ap(f"\t\t\t\t{bid} /* {Path(rel).name} in Sources */,")
    ap("\t\t\t);")
    ap("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    ap("\t\t};")

    ap(f"\t\t{test_sources_phase} /* Sources */ = {{")
    ap("\t\t\tisa = PBXSourcesBuildPhase;")
    ap("\t\t\tbuildActionMask = 2147483647;")
    ap("\t\t\tfiles = (")
    for _, bid, rel in test_refs:
        ap(f"\t\t\t\t{bid} /* {Path(rel).name} in Sources */,")
    ap("\t\t\t);")
    ap("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    ap("\t\t};")
    ap("\t\t/* End PBXSourcesBuildPhase section */")
    ap("")

    ap("\t\t/* Begin PBXContainerItemProxy section */")
    ap(f"\t\t{proxy_id} /* PBXContainerItemProxy */ = {{")
    ap("\t\t\tisa = PBXContainerItemProxy;")
    ap(f"\t\t\tcontainerPortal = {project_id} /* Project object */;")
    ap("\t\t\tproxyType = 1;")
    ap(f"\t\t\tremoteGlobalIDString = {app_target_id};")
    ap("\t\t\tremoteInfo = Boilerplate;")
    ap("\t\t};")
    ap("\t\t/* End PBXContainerItemProxy section */")
    ap("")

    ap("\t\t/* Begin PBXTargetDependency section */")
    ap(f"\t\t{dep_id} /* PBXTargetDependency */ = {{")
    ap("\t\t\tisa = PBXTargetDependency;")
    ap(f"\t\t\ttarget = {app_target_id} /* Boilerplate */;")
    ap(f"\t\t\ttargetProxy = {proxy_id} /* PBXContainerItemProxy */;")
    ap("\t\t};")
    ap("\t\t/* End PBXTargetDependency section */")
    ap("")

    ap("\t\t/* Begin XCBuildConfiguration section */")
    for name, cid in [
        ("Debug", dbg_project),
        ("Release", rel_project),
    ]:
        ap(f"\t\t{cid} /* {name} */ = {{")
        ap("\t\t\tisa = XCBuildConfiguration;")
        ap("\t\t\tbuildSettings = {")
        if name == "Debug":
            ap("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
            ap("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
            ap("\t\t\t\tCOPY_PHASE_STRIP = NO;")
            ap("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
            ap("\t\t\t\tENABLE_TESTABILITY = YES;")
            ap("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
            ap("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
            ap("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
            ap("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
            ap("\t\t\t\tSDKROOT = iphoneos;")
            ap("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
            ap("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
        else:
            ap("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
            ap("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
            ap("\t\t\t\tCOPY_PHASE_STRIP = NO;")
            ap("\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";")
            ap("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
            ap("\t\t\t\tSDKROOT = iphoneos;")
            ap("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
        ap("\t\t\t};")
        ap(f"\t\t\tname = {name};")
        ap("\t\t};")

    app_settings = [
        "\t\t\t\tCODE_SIGN_STYLE = Automatic;",
        "\t\t\t\tCURRENT_PROJECT_VERSION = 1;",
        '\t\t\t\tDEVELOPMENT_TEAM = "";',
        "\t\t\t\tENABLE_PREVIEWS = YES;",
        "\t\t\t\tGENERATE_INFOPLIST_FILE = YES;",
        '\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "Track My Walk";',
        '\t\t\t\tINFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription = "Track My Walk can continue recording your walk when the screen is off if you allow always-on location.";',
        '\t\t\t\tINFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "Track My Walk uses your location to draw your route and measure distance while you walk.";',
        "\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;",
        "\t\t\t\tINFOPLIST_KEY_UIBackgroundModes = location;",
        "\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;",
        '\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");',
        "\t\t\t\tMARKETING_VERSION = 1.0;",
        "\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.trackmywalk.app;",
        '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";',
        '\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";',
        "\t\t\t\tSUPPORTS_MACCATALYST = NO;",
        "\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;",
        "\t\t\t\tSWIFT_VERSION = 5.0;",
        "\t\t\t\tTARGETED_DEVICE_FAMILY = 1;",
    ]

    for name, cid in [("Debug", dbg_app), ("Release", rel_app)]:
        ap(f"\t\t{cid} /* {name} */ = {{")
        ap("\t\t\tisa = XCBuildConfiguration;")
        ap("\t\t\tbuildSettings = {")
        for s in app_settings:
            ap(s)
        ap("\t\t\t};")
        ap(f"\t\t\tname = {name};")
        ap("\t\t};")

    test_settings = [
        '\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";',
        "\t\t\t\tCODE_SIGN_STYLE = Automatic;",
        "\t\t\t\tCURRENT_PROJECT_VERSION = 1;",
        '\t\t\t\tDEVELOPMENT_TEAM = "";',
        "\t\t\t\tGENERATE_INFOPLIST_FILE = YES;",
        "\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;",
        "\t\t\t\tMARKETING_VERSION = 1.0;",
        "\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.trackmywalk.app.tests;",
        '\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";',
        "\t\t\t\tSDKROOT = iphoneos;",
        "\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;",
        "\t\t\t\tSWIFT_VERSION = 5.0;",
        "\t\t\t\tTARGETED_DEVICE_FAMILY = 1;",
        '\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Boilerplate.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Boilerplate";',
    ]

    for name, cid in [("Debug", dbg_test), ("Release", rel_test)]:
        ap(f"\t\t{cid} /* {name} */ = {{")
        ap("\t\t\tisa = XCBuildConfiguration;")
        ap("\t\t\tbuildSettings = {")
        for s in test_settings:
            ap(s)
        ap("\t\t\t};")
        ap(f"\t\t\tname = {name};")
        ap("\t\t};")

    ap("\t\t/* End XCBuildConfiguration section */")
    ap("")

    ap("\t\t/* Begin XCConfigurationList section */")
    ap(f"\t\t{project_config_list} /* Build configuration list for PBXProject \"Boilerplate\" */ = {{")
    ap("\t\t\tisa = XCConfigurationList;")
    ap("\t\t\tbuildConfigurations = (")
    ap(f"\t\t\t\t{dbg_project} /* Debug */,")
    ap(f"\t\t\t\t{rel_project} /* Release */,")
    ap("\t\t\t);")
    ap("\t\t\tdefaultConfigurationIsVisible = 0;")
    ap("\t\t\tdefaultConfigurationName = Release;")
    ap("\t\t};")

    ap(f"\t\t{app_config_list} /* Build configuration list for PBXNativeTarget \"Boilerplate\" */ = {{")
    ap("\t\t\tisa = XCConfigurationList;")
    ap("\t\t\tbuildConfigurations = (")
    ap(f"\t\t\t\t{dbg_app} /* Debug */,")
    ap(f"\t\t\t\t{rel_app} /* Release */,")
    ap("\t\t\t);")
    ap("\t\t\tdefaultConfigurationIsVisible = 0;")
    ap("\t\t\tdefaultConfigurationName = Release;")
    ap("\t\t};")

    ap(f"\t\t{test_config_list} /* Build configuration list for PBXNativeTarget \"BoilerplateTests\" */ = {{")
    ap("\t\t\tisa = XCConfigurationList;")
    ap("\t\t\tbuildConfigurations = (")
    ap(f"\t\t\t\t{dbg_test} /* Debug */,")
    ap(f"\t\t\t\t{rel_test} /* Release */,")
    ap("\t\t\t);")
    ap("\t\t\tdefaultConfigurationIsVisible = 0;")
    ap("\t\t\tdefaultConfigurationName = Release;")
    ap("\t\t};")
    ap("\t\t/* End XCConfigurationList section */")

    ap("\t};")
    ap(f"\trootObject = {project_id} /* Project object */;")
    ap("}")

    out = proj_dir / "project.pbxproj"
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {out} ({len(swift_main)} app + {len(swift_tests)} test Swift files)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
