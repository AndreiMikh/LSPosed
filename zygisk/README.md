# Vector Zygisk Module & Framework Loader

## Overview

This Sub-Project Constitutes the Injection Engine of the Vector Framework, It Acts as the Bridge Between the Android Zygote Process and the High-Level XPosed API

The Project is a Hybrid System Consisting of Two Distinct Layers:
1.  **Native Layer (C++)**: A Zygisk Module that Hooks Process Creation, Filters Targets, and Bootstraps the Environment
2.  **Loader Layer (Kotlin)**: The Initial Java-World Payload that Initializes the XPosed Bridge, Establishes High-Level IPC, and Manages the "Parasitic" Execution Environment for the Manager

Its Primary Responsibility is to Inject the Vector LSPosed Framework into the Target Process's Memory at the earliest possible stage of its lifecycle, Ensuring a Robust and Stealthy Environment

---

## Part 1: The Native Zygisk Layer

The Native Layer (`LIBZYGISK.SO`) is the entry point. It hooks into the Zygote process creation lifecycle via the Zygisk API (e.g., `preAppSpecialize`, `postAppSpecialize`). It is architected to have minimal internal logic, delegating heavy lifting (like ART hooking and ELF parsing) to the core [native](../native) library.

### Core Responsibilities
*   **Target Filtering**: Implements Logic to Skip Isolated Processes, Application Zygotes, and Non-Target System Components to Minimize Footprint
*   **IPC Communication**: Establishes a Secure Binder IPC Connection with the Daemon Manager Service via a "RENDEZVOUS" System Service to Fetch the Framework DEX and Configuration Data (e.g., Obfuscation Maps)
*   **DEX Loading**: Uses `InMemoryDexClassLoader` to Load the Framework's Byte Code Directly from Memory, Avoiding Disk I/O Signatures
*   **JNI Interception**: Installs a Low-Level JNI Hook on `CallBooleanMethodV`, This Intercepts `Binder.ExecTransact` Calls, Allowing the Framework to Patch Into the System's IPC Flow Without Registering Standard Android Services

### Key Components (C++)
*   **`VectorModule` (`module.cpp`)**: The Central Orchestrator Implementing `Zygisk::ModuleBase`, It Manages the Injection State Machine and Inherits From `Vector::Native::Context` to Gain Core Injection Capabilities
*   **`IPCBridge` (`IPC BRIDGE CPP`)**: A Singleton Handling Raw Binder Transactions, It Manages the Two-Step Connection Protocol (Rendezvous -> Dedicated Binder) and Contains the JNI Table Override Logic

---

## Part 2: The Kotlin Framework Loader

Once the Native Layer Successfully Loads the DEX, Control is Handed Off to the Kotlin Layer via JNI, This Layer Handles High-Level Android Framework Manipulation, Xposed Initialization, and Identity Spoofing

### Core Responsibilities
*   **Bootstrapping**: `Main.ForkCommon` Acts as the Java Entry Point, It differentiates Between the `System Server` and Standard Applications
*   **Parasitic Injection**: Implements the Logic to Run the Full LSPosed Manager Application Inside a Host Poocess (Currently `Com.Android.Shell`). This allows the Manager to Run with Elevated Privileges Without Being Installed as a System App
*   **Manual Bridge Service**: Provides the Java-Side Handling for the Intercepted Binder Transactions

### Key Components (Kotlin)
*   **`Main`**: The Singleton Entry Point, It Initializes the XPosed Bridge (`Startup`) and Decides Whether to Load the Standard XPosed Environment or the Parasitic Manager
*   **`BridgeService`**: The Peer to the C++ `IPCBridge`, It Decodes Custom `LSP` Transactions, Manages the Distribution of the system service Binder, and Handles Communication Between the Injected Framework and the Root Daemon
*   **`ParasiticManagerHooker`**: The Complex Logic for Identity Transplantation
    *   **App Swap**: Swaps the Host's `ApplicationInfo` with the Manager's Info During `HandleBindApplication`
    *   **State Persistence**: Since the Android System is Unaware the Host Process is Running Manager Activities, This Component Manually Captures and Restores `Bundle` States to Prevent Data Loss During Life Cycle Events
    *   **Resource Spoofing**: Hooks `WebView` and `ContentProvider` Installation to Satisfy Package Name Validations

---

## Injection & Execution Flow

The Full Life Cycle of a Vector LSPosed-Instrumented process Follows this Sequence:

1.  **Zygote Fork**: Zygisk Triggers the `PreAppSpecialize` Callback in C++
2.  **Native Decision**: `VectorModule` Checks the UID/Process Name, If Valid, it Initializes the `IPCBridge`
3.  **DEX Fetch**: The C++ Layer Connects to the Root Daemon, Fetches the Framework DEX File Descriptor and the Obfuscation Map
4.  **Memory Loading**: `PostAppSpecialize` Triggers the Creation of an `InMemoryDexClassLoader`
5.  **JNI Hand-off**: The Native Module Calls the Static Kotlin Method `Org.LSPosed.LSPD.Core.Main.ForkCommon`.
6.  **Identity Check (Kotlin)**:
    *   **If Manager Package**: `ParasiticManagerHooker.Start()` is Called, The Process is "Hi-Jacked" to run the Manager UI
    *   **If Standard App**: `Startup.BootStrapXposed()` is Called, Third-Party Modules are Loaded
7.  **Live Interception**: Throughout the Process Life, the C++ JNI hook Redirects Specific `Binder.ExecTransact` Calls to `BridgeService.ExecTransact` in Kotlin

---

## Maintenance & Technical Notes

### The IPC Protocol
The communication Between the Native Loader and the Kotlin Framework Relies on Specific Conventions:
*   **Transaction Code**: The Custom Code `VEC` (Bitwise Constructed) Must Remain Synchronized Between `IPC BRIDGE CPP` (Native) and `BridgeService.kt` (Kotlin)
*   **The "Out-Parameter" List**: In `ParasiticManagerHooker.start()`, you will See an Empty List `MutableListOf<IBinder>()`,
It is Used as an "Out-Parameter" for the Binder Call, Allowing the Root Daemon to Push the Manager Service Binder Back to the Loader

### System Server Hooks
The `ParasiticManagerSystemHooker` Runs *only* in the `SYSTEM SERVER`, It Uses `XPosedHooker` to intercept `ActivityTaskSupervisor.resolveActivity`. It Detects Intents Tagged with `LAUNCH MANAGER` and Forcefully Redirects them to the Parasitic Process (e.g., `Shell`), Modifying the `ActivityInfo` on the Fly to Ensure the Manager Launches Correctly
