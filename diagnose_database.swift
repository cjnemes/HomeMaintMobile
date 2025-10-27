#!/usr/bin/env swift

// This script checks if the production database has the seeded data
// Run with: swift diagnose_database.swift

import Foundation

// Path to the app's database
let homeDir = FileManager.default.homeDirectoryForCurrentUser
let appSupportPath = homeDir.appendingPathComponent("Library/Developer/CoreSimulator/Devices")

print("🔍 Diagnostic Script for HomeMaint Database")
print("=" * 50)
print("\n📱 Checking simulator databases...")
print("\nTo find your app's database:")
print("1. Run the app in simulator")
print("2. Check console output for: '✅ Database initialized at: <path>'")
print("3. Use that path to inspect the database with:")
print("   sqlite3 <path>")
print("\n📝 Once in sqlite3, run these queries:")
print("   SELECT COUNT(*) FROM categories;  -- Should be 9")
print("   SELECT COUNT(*) FROM locations;   -- Should be 12")
print("   SELECT name FROM categories;")
print("   SELECT name FROM locations;")
print("\n" + "=" * 50)
