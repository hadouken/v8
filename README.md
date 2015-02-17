# Overview

This repository contains the build script to download, build and publish
the V8 JavaScript engine for Hadouken on Windows.

V8 is built with MSVC-12 (Visual Studio 2013).

## Building

```
PS> .\build.ps1
```

This will clone the latest V8 master branch and related tools, then build it in
both debug and release versions for Win32.

The output (including a NuGet package) is put in the `bin` folder.

# License

This project is provided as-is under the MIT license. For more information, see
`LICENSE`.

 * For V8, see https://developers.google.com/v8/terms.
