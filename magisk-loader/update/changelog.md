🎉 **Release: Vector 1.0** 🎉

Welcome to Vector 1.0! As Part of our Ongoing Transition, the Project has Officially been Renamed from `LSPosed` to `Vector`, While our Major Internal Refactoring is Still Underway, we are Releasing 1.0 Now to Provide a Stable, Feature-Complete Environment for those Relying on Legacy Lib XPosed APIs

### 📚 Lib XPosed API 100 & 101
With the Recent Publication of Lib XPosed API 101, the Ecosystem is Moving Toward a New Standard with Significant Breaking Changes, Because API 100 was Never Officially Published, **Vector 1.0 Serves as the Definitive Implementation of the API 100 era**, Built from the Exact Xommit Prior to the API 101 Jump

### 🏗️ Architecture & API Updates
*   **Vector & Zygisk Overhaul:** Officially Renamed and Modularized the Project, Featuring a Completely Rewritten, Modern Zygisk Architecture
*   **API 100 Finalization:** Completed All Remaining Lib XPosed API 100 Features, including Comprehensive Support for Static Initializers, Constructor Hooking, and Centralized Logging


### ⚙️ Core Engine & System Enhancements
*   🔓 **Bypassed Bionic `LD PRELOAD` Restrictions:** Resolved Fatal Namespace Errors on Android 10 by Loading the `Dex2oat` Hook Library via a `MEMFD CREATE` TMPFS-Backed File Descriptor, Bypassing the Linker's Namespace Checks
*   🛡️ **Reflection Parity Overhaul:** Completely Rebuilt the `INVOKESPECIALMETHOD` Backend to Improve Performance, Enhance Robustness, and Mirror Standard Java Reflection Behavior
*   ⏱️ **Late Injection Standalone Launch:** Added Native Support for Manual Late Injection (Triggered by NeoZygisk), without Relying on Magisk's Early-Init Phase—Highly Useful for AOSP Debug Builds
