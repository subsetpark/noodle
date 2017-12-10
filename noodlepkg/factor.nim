import random, math, emmy, bigints, strutils
import primes

randomize()

type Num = int | BigInt

proc abs(n: BigInt): BigInt =
  result = n
  if n < 0:
    result *= -1

proc gcd(x, y: BigInt): BigInt =
  var (x,y) = (x,y)
  while y != 0:
    x = x mod y
    swap x, y
  abs x

proc randOneTo(n: int): int =
  result = random(n) + 1

proc brent*[T: Num](n: T): T =
  when T is BigInt:
    if n <= maxPrime and primes.checkKnownPrimes(n):
      return n

  if n mod 2 == 0:
    when T is int:
      return 2
    else:
      return 2.initBigInt

  when T is int:
    var
      y = randOneTo(n - 1)
      c = randOneTo(n - 1)
      m = randOneTo(n - 1)
      g, r, q = 1
      lowerBound, x, k, ys = 0
  else:
    # The biggest hack in the system. Instead of finding a
    # random number between 1 and n - 1, chop off the range at
    # the extent of `int` so we can use `random`.
    let
      upperBound = min(int.high.initBigInt, n)
      converted = upperBound.`$`.parseInt
    var
      y = randOneTo(converted).initBigInt
      c = randOneTo(converted).initBigInt
      m = randOneTo(converted).initBigInt
      g, r, q = 1.initBigInt
      lowerBound, x, k, ys = 0.initBigInt
  while g == 1:
    x = y
    for i in lowerBound..r:
      y = ((y * y) mod n + c) mod n
    when T is int:
      k = 0
    else:
      k = 0.initBigInt
    while k < r and g == 1:
      ys = y
      for i in lowerBound..min(m, r - k):
        y = ((y * y) mod n + c) mod n
        q = q * (x - y).abs mod n
      g = gcd(q, n)
      k += m
    r *= 2
  if g == n:
    while true:
      ys = ((ys * ys) mod n + c) mod n
      g = gcd((x - ys).abs, n)
      if g > 1:
        break

  result = g

proc product[T: Num](factors: seq[T]): T =
  when T is int:
    result = 1
  else:
    result = 1.initBigInt
  for factor in factors:
    result *= factor

proc isPrime(n: BigInt): bool =
  if n <= 1:
    result = false
  elif n <= maxPrime:
    result = checkKnownPrimes(n)
  else:
    result = brent(n) == n

proc factors*[T: Num](X: T): seq[T] =
  result = newSeq[T]()

  var x = X
  while result.product != X:
    let newFactor = brent(x)
    if newFactor.isPrime:
      result.add(newFactor)
    else:
      let subFactors = newFactor.factors
      result &= subFactors
    x = x div newFactor

when isMainModule:
  randomize()
  echo 12, 12.factors
  echo 24, 24.factors
  echo 13, 13.factors
  echo $14.initBigInt, $14.initBigInt.factors
  let x = "86454241232213244940572171129190212913163914455885369651984583708290030003086155865969700000000".initBigInt
  echo x.factors
  echo "243000000".initBigInt.factors
  let y = "5360325091417636408929324124026616273125961139637047656420202769496479504673257011276160038152183519255743750000000000000".initBigInt
  echo y.factors
