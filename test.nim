import unittest
import noodle

suite "noodle tests":

  setUp:
    resetBindings()

  test "book example":
    let
      parsed = "0 = 0".Formula
      factors = parsed.Factors
      expectedBases = [2, 3, 5]
      expectedExponents = [6, 5, 6]
      expectedResolutions = [64, 243, 15_625]

    for i, factor in factors:
      check factor.base == expectedBases[i]
    for i, factor in factors:
      check factor.exponent == expectedExponents[i]
    for i, factor in factors:
      check factor.resolve == expectedResolutions[i]

    check("0 = 0".NoodleNumber == 243_000_000.NoodleNumber)

  test "variables":
    let
      parsed = "y".Formula
      factors = parsed.Factors
      factor = factors[0]

    check factor.base == 2
    check factor.exponent == 13

resetBindings()

proc decomposeFormula(s: string) =
  let
    f =s.Formula
    cs = f.Factors
    gNumber = cs.NoodleNumber

  echo ""
  echo "Formula :: ", f
  echo "Decomposition:"
  echo cs
  echo "..."
  echo gNumber
  echo "--------------------"

decomposeFormula "~ 0 = 0"
decomposeFormula "( E x ) ( x = s 0 )"
