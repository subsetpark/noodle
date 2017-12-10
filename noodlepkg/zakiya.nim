#[
 This Nim source file will compile to an executable program to
 perform the Segmented Sieve of Zakiya (SSoZ) to find primes <= N.
 It is based on the P5 Strictly Prime (SP) Prime Generator.

 Prime Genrators have the form:  mod*k + ri; ri -> {1,r1..mod-1}
 The residues ri are integers coprime to mod, i.e. gcd(ri,mod) = 1
 For P5, mod = 2*3*5 = 30 and the number of residues are
 rescnt = (2-1)(3-1)(5-1) = 8, which are {1,7,11,13,17,19,23,29}.

 Adjust segment byte length parameter B (usually L1|l2 cache size)
 for optimum operational performance for cpu|system being used.

 Verified on Nim 0.17, using clang (smaller exec) or gcc

 $ nim c --cc:[clang|gcc] --d:release  ssozp5.nim

 Then run executable: $ ./ssozp5 <cr>, and enter value for N.
 As coded, input values cover the range: 7 -- 2^64-1

 Related code, papers, and tutorials, are downloadable here:

 http://www.4shared.com/folder/TcMrUvTB/_online.html

 Use of this code is free subject to acknowledgment of copyright.
 Copyright (c) 2017 Jabari Zakiya -- jzakiya at gmail dot com
 Version Date: 2017/08/23

 This code is provided under the terms of the
 GNU General Public License Version 3, GPLv3, or greater.
 License copy/terms are here:  http://www.gnu.org/licenses/
]#

import math                   # for sqrt function

# Global var used to count number of primes in 'seg' variable
# Each value is number of '0' bits (primes) for values 0..255
let pbits = [
 8,7,7,6,7,6,6,5,7,6,6,5,6,5,5,4,7,6,6,5,6,5,5,4,6,5,5,4,5,4,4,3
,7,6,6,5,6,5,5,4,6,5,5,4,5,4,4,3,6,5,5,4,5,4,4,3,5,4,4,3,4,3,3,2
,7,6,6,5,6,5,5,4,6,5,5,4,5,4,4,3,6,5,5,4,5,4,4,3,5,4,4,3,4,3,3,2
,6,5,5,4,5,4,4,3,5,4,4,3,4,3,3,2,5,4,4,3,4,3,3,2,4,3,3,2,3,2,2,1
,7,6,6,5,6,5,5,4,6,5,5,4,5,4,4,3,6,5,5,4,5,4,4,3,5,4,4,3,4,3,3,2
,6,5,5,4,5,4,4,3,5,4,4,3,4,3,3,2,5,4,4,3,4,3,3,2,4,3,3,2,3,2,2,1
,6,5,5,4,5,4,4,3,5,4,4,3,4,3,3,2,5,4,4,3,4,3,3,2,4,3,3,2,3,2,2,1
,5,4,4,3,4,3,3,2,4,3,3,2,3,2,2,1,4,3,3,2,3,2,2,1,3,2,2,1,2,1,1,0
]

# The global residue values for the P5 prime generator.
let residues = [1, 7, 11, 13, 17, 19, 23, 29, 31]

# Global parameters
const
  modp5 = 30           # mod value for P5 prime generator
  rescnt = 8           # number of residues for P5 prime generator
var
  pcnt = 0             # number of primes from r1..sqrt(N)
  primecnt = 0'u64     # number of primes <= N
  next: seq[uint64]    # table of regroups vals for primes multiples
  primes: seq[int]     # list of primes r1..sqrt(N)
  seg: seq[uint8]      # segment byte array to perform ssoz

# This routine is used to compute the list of primes r1..sqrt(input_num),
# stored in global var 'primes', and its count stored in global var 'pcnt'.
# Any algorithm (fast|small) can be used. Here the SoZ using P7 is used.
proc sozp7(val: int | int64) =      # Use P7 prime gen to finds upto val
  let md = 210                      # P7 mod value
  let rscnt = 48                    # P7 residue count and residues list
  let res = [1, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67
          , 71, 73, 79, 83, 89, 97,101,103,107,109,113,121,127,131,137,139
          ,143,149,151,157,163,167,169,173,179,181,187,191,193,197,199,209,211]

  var posn = newSeq[int](210)              # small array (hash) to convert
  for i in 0 .. <rscnt: posn[res[i]] = i-1 # (x mod md) to values -1,0,1,2..6

  let num = (val-1) or 1            # if val even then subtract 1
  var k = num div md                # compute its residue group val
  var modk = md * k                 # compute its base num
  var r = 1                         # starting with first residue
  while num >= modk+res[r]: r += 1  # find last pc position <= num
  let maxprms = k*rscnt + r - 1     # maximum number of prime candidates
  var prms = newSeq[bool](maxprms)  # array of prime candidates set False

  let sqrtN = int(sqrt float64(num))
  modk = 0; r = 0; k = 0

  # sieve to eliminate prime multiples from list of pcs r1..sqrtN
  for prm in prms:                  # from list of pc positions in prms
    r += 1; if r > rscnt: (r = 1; modk += md; k += 1)
    if prm: continue                # if pc not prime go to next location
    let res_r = res[r]              # if prime save residue of prime value
    let prime = modk + res_r        # numerate the prime value
    if  prime > sqrtN: break        # exit if > sqrtN
    let prmstep = prime * rscnt     # prime's stepsize to eliminate its mults
    for ri in res[1..rscnt]:        # eliminate prime's multiples from prms
      let prod = res_r * ri         # residues cross-product for this prime
      # compute resgroup val of 1st prime multiple for each restrack
      # starting there, mark all prime multiples on restrack upto end of prms
      var prm_mult = (k*(prime + ri) + prod div md)*rscnt + posn[prod mod md]
      while prm_mult < maxprms: prms[prm_mult] = true; prm_mult += prmstep

  # prms now contains the nonprime positions for the prime candidates r1..N
  # extract primes into global var 'primes' and count into global var 'pcnt'
  primes = @[7]                     # r1 prime for P5
  modk = 0; r=0
  for prm in prms:                  # numerate primes from processed pcs list
    r += 1; if r > rscnt: (r = 1; modk += md)
    if not prm: primes.add(modk + res[r])  # put prime in global 'primes' list
  pcnt = len(primes)                       # set global count of primes

# This routine initializes the [rescnt x pcnt] global var 'next'
# table with the resgroup values of the 1st prime multiples for
# each prime r1..sqrtN along the restracks for the 8 P5 residues
# (7, 11..29, 31). 'next' is used to eliminate prime multiples in
# 'seg' for each SSoZ segment, and is updated with new resgroup
# values for each prime for use with subsequent segment
# iterations.
proc next_init() =
  var pos = newSeq[int](modp5)                    # create small array (hash)
  for i in 0 .. <rescnt: pos[residues[i]] = i-1   # to convert an (x mod modp5)
  pos[1] = rescnt-1                               # val into restrack val 0..7

  # load 'next' with 1st prime multiples regroups vals along
  # each residue track
  for j, prime in primes:                         # for each prime r1..sqrt(N)
    let k = uint((prime-2)) div uint(modp5)       # find the resgroup it's in
    let r = uint((prime-2)) mod uint(modp5) + 2   # and its residue value
    for ri in residues[1 .. rescnt]:              # for each prime|residue pair
      let prod: int = int(r) * ri                 # compute res cross-product r*ri
      let row:  int = pos[prod mod modp5] * pcnt  # compute residue track address
      # compute|store resgroup val of 1st prime multiple for prime|ri residue pair
      next[row + j] = k*(uint(prime) + uint(ri)) + uint(prod-2) div uint(modp5)

# This routine performs the segment sieve for a segment of Kn
# resgroups|bytes.  Each 'seg' bit represents a residue track of
# Kn resgroups, which are processed sequentially. 'next' resgroup
# vals are used to mark prime multiples in 'seg' along each
# restrack, and is udpated for each prime for the next segment.
# Upon completion the number of primes ('0' bits) per 'seg' byte
# are added to global var 'primecnt'.
proc segsieve(Kn: int) =              # for Kn resgroups in segment
  for b in 0 .. <Kn: seg[b] = 0       # initialize seg bits to all prime '0'
  for r in 0 .. <rescnt:              # for each ith (of 8) residues for P5
    let biti = uint8(1 shl r)         # set the ith residue track bit mask
    let row  = r * pcnt               # set address to ith row in next[]
    for j, prime in primes:           # for each prime r1..sqrt(N)
      if next[row + j] < uint(Kn):    # if 1st mult resgroup index <= seg size
        var k = int(next[row + j])    # get its resgroup value
        while k < Kn:                 # for each primenth byte < segment size
          seg[k] = seg[k] or biti     # set resgroup's restrack bit to '1' (nonprime)
          k += int(prime)             # compute next prime multiple resgroup
        next[row + j] = uint(k - Kn)  # 1st resgroup in next eligible segment
      else: next[row + j] -= uint(Kn) # do if 1st mult resgroup index > seg size
                                      # count the primes in the segment
  for byt in seg[0..<Kn]:             # for the Kn resgroup bytes
    primecnt += uint(pbits[byt])      # count the '0' bits as primes


proc pi*(n: int, getPrime = false): uint64 =
  const B = 256 * 1024
  let KB = B
  seg = newSeq[uint8](B)

  let num = uint64((n-1) or 1)
  var
    k: uint64 = num div modp5
    modk = uint64(modp5) * k
    r = 1

  while num >= modk+uint64(residues[r]):
    r += 1

  let
    Kmax = uint64(num-2) div uint64(modp5) + 1
    sqrtN = int(sqrt float64(num))

  sozP7(sqrtN)
  next = newSeq[uint64](rescnt*pcnt)
  next_init()

  primecnt = 3
  var
    Kn: int = KB
    Ki = 0'u64

  while Ki < Kmax:
    if Kmax-Ki < uint64(KB):
      Kn = int(Kmax-Ki) # to set last segment size

    segsieve(Kn)
    Ki += uint64(KB)

  var
    lprime = 0'u64
    b = Kn-1

  modk = uint64(modp5) * (Kmax-1)
  r = rescnt-1
  while true:
    if (int(seg[b]) and (1 shl r)) == 0:
      lprime = modk + uint64(residues[r+1])
      if lprime <= num: break
      primecnt -= 1

    r -= 1
    if r < 0:
      (r = rescnt-1; modk -= modp5; b -= 1) # if necessary

  result = primecnt

when isMainModule:
  echo pi(1021081)
