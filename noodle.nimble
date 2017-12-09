# Package

version       = "0.1.0"
author        = "Zach Smith"
description   = "Godel Numbers"
license       = "MIT"

# Dependencies

requires "nim >= 0.17.3"
requires "emmy"
requires "docopt"

skipFiles = @["test.nim"]
bin = @["noodle"]
