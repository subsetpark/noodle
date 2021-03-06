import sequtils, bigints, math, strutils, tables, docopt, algorithm
import noodlepkg/[factor, primes]

const
  helpText = """
  Noodle - Goedel numbers on your computer.

  Usage:
    noodle <exp>
    noodle -d <num>

  Given an expression in PM, noodle will display its Noodle
  Number. Given a Noodle Number, noodle will display the
  expression it refers to.

  The vocabulary of PM:
    ~ V -> E = 0 s ( ) , + *
  """
type
  SignKind = enum
    skSyntax, skVariable
  Sign = object
    case kind: SignKind
    of skSyntax:
      syntaxSign: SyntaxSign
    of skVariable:
      variable: string
  SyntaxSign = enum
    sNot = (1, "~")
    sOr = "V"
    sIfThen = "->"
    sThereIs = "E"
    sEquals = "="
    sZero = "0"
    sSuccessor = "s"
    sParens = "("
    sCloseParens = ")"
    sComma = ","
    sPlus = "+"
    sTimes = "*"
  Variable = char
  Formula* = seq[Sign]
  NoodleNumber* = BigInt

  Bindings = object
    bindings: Table[string, BigInt]
    reverseBindings: Table[BigInt, string]
    index: int
    variableChar: char

proc `$`*(sign: Sign): string =
  case sign.kind
  of skSyntax: $sign.syntaxSign
  of skVariable: sign.variable

proc `$`*(formula: Formula): string =
  "'" & formula.join(" ") & "'"

var variableBindings = Bindings(
  bindings: initTable[string, BigInt](),
  reverseBindings: initTable[BigInt, string](),
  index: 5, # variables start at 13
  variableChar: 'a'
)
proc bindVariable(variable: string) =
  if variable notin variableBindings.bindings:
    let newPrime = getPrime(variableBindings.index)
    variableBindings.bindings[variable] = newPrime
    variableBindings.reverseBindings[newPrime] = variable
    inc variableBindings.index

proc resetBindings*() =
  variableBindings.bindings.clear()
  variableBindings.reverseBindings.clear()
  variableBindings.index = 5

converter parse*(s: string): Formula =
  let tokens = s.split(" ")
  result = newSeq[Sign](tokens.len)
  for i, element in tokens:
    try:
      let syntaxSign = parseEnum[SyntaxSign](element)
      result[i] = Sign(kind: skSyntax, syntaxSign: syntaxSign)
    except ValueError:
      bindVariable(element)
      result[i] = Sign(kind: skVariable, variable: element)

converter toExponent(sign: Sign): BigInt =
  case sign.kind
  of skSyntax:
    sign.syntaxSign.int.initBigInt
  of skVariable:
    variableBindings.bindings[sign.variable].initBigInt

type
  Power = object
    base*, exponent*: BigInt
  Factors* = seq[Power]

proc `$`*(p: Power): string = "$#^$#" % [$p.base, $p.exponent]
proc `$`*(factors: Factors): string = "( " & factors.join(" × ") & " )"

converter toComponents*(f: Formula): Factors =
  result = newSeq[Power](f.len)

  for i, sign in f:
    let
      base = getPrime(i)
      exponent = sign.initBigInt
    result[i] = Power(
      base: base,
      exponent: exponent
    )

proc resolve*(p: Power): BigInt = pow(p.base, p.exponent)

converter product*(components: Factors): NoodleNumber =
  var v = 1.initBigInt
  for component in components:
    v *= component.resolve
  result = v.NoodleNumber

converter toNoodleNumber*(s: string): NoodleNumber = s.Formula.Factors.NoodleNumber
converter toNoodleNumber*(i: int): NoodleNumber = i.initBigInt.NoodleNumber

type NonSequentialPrimeError = object of ValueError

converter toFactors(n: BigInt): Factors =
  let
    factors = n.factors
    highFactor = max(factors)
    highFactorIdx = findPrime(highFactor)

  var counterSeq = newSeqWith(highFactorIdx + 1, 0.initBigInt)

  for f in factors:
    let counterIdx = findPrime(f)
    counterSeq[counterIdx] += 1
  var isZero = false
  for i, count in counterSeq:
    if isZero and count > 0:
      var populatedPrimes = newSeq[BigInt]()
      for j, count in counterSeq:
        if count > 0:
          populatedPrimes.add(getPrime(j))
      let msg = "Factors are not the sequential primes: $#. This is not a Noodle number." %
        $populatedPrimes
      raise newException(NonSequentialPrimeError, msg)
    elif count == 0:
      isZero = true
  result = newSeq[Power](counterSeq.filterIt(it > 0).len)
  for i, count in counterSeq:
    let
      prime = getPrime(i)
      newPower = Power(
        base: prime,
        exponent: count
      )
    result[i] = (newPower)

converter toSign(power: Power): Sign =
  if power.exponent in 1.BigInt..12.BigInt:
    result.kind = skSyntax
    # Gross.
    result.syntaxSign = power.exponent.`$`.parseInt.SyntaxSign
  else:
    result.kind = skVariable
    if power.exponent notin variableBindings.reverseBindings:
      while $variableBindings.variableChar in variableBindings.bindings:
        variableBindings.variableChar = (
          variableBindings.variableChar.int +
          1
        ).chr
      let newVar = $variableBindings.variableChar
      bindVariable(newVar)
    result.variable = variableBindings.reverseBindings[power.exponent]

converter toFormula(factors: Factors): Formula =
  result = factors.mapIt(it.Sign)

converter toFormula(n: BigInt): Formula =
  n.Factors.Formula

when isMainModule:
  let
    args = docopt(helpText, version = "Noodle 0.2")
    decode = args["-d"]
  if decode:
    let num = args["<num>"].`$`.initBigInt
    try:
      echo num.Formula
    except NonSequentialPrimeError as e:
      echo e.msg
  else:
    let exp = $args["<exp>"]
    echo exp.NoodleNumber
