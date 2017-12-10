# Package

version       = "0.1.0"
author        = "Zach Smith"
description   = "Godel Numbers"
license       = "MIT"

# Dependencies

requires "nim >= 0.17.2"
requires "emmy"
requires "docopt"
requires "memo"

skipFiles = @["test.nim"]
bin = @["noodle"]
