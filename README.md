# sml-random

[![CI](https://github.com/sjqtentacles/sml-random/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-random/actions/workflows/ci.yml)

A small, deterministic, splittable pseudo-random generator for Standard ML,
based on [SplitMix64](https://dl.acm.org/doi/10.1145/2714064.2660195).

`sml-random` gives the web stack reproducible randomness for session IDs,
CSRF nonces, jitter, and sampling -- seeded, immutable, and identical across
runs and compilers. The state is a value (no mutation), so generators can be
copied, replayed, and `split` into independent streams.

> **Not cryptographically secure.** For unguessable secrets, seed it from a
> real entropy source at the impure edge, or use HMAC-based tokens from
> `sml-crypto`.

Pure Standard ML over the Basis library -- no dependencies. Verified on
**MLton** and **Poly/ML** against the SplitMix64 reference vectors.

## API

```sml
structure Random : sig
  type t
  val fromSeed : Word64.word -> t
  val fromInt  : int -> t
  val nextWord : t -> Word64.word * t
  val nextInt  : t -> int -> int * t      (* [0, bound), unbiased *)
  val nextReal : t -> real * t            (* [0.0, 1.0) *)
  val nextByte : t -> char * t
  val bytes    : t -> int -> string * t
  val token    : t -> string -> int -> string * t   (* from an alphabet *)
  val hexToken : t -> int -> string * t
  val split    : t -> t * t
end
```

Every operation returns the produced value *and* the advanced generator, so
threading state is explicit and replay is trivial.

### Example

```sml
val g = Random.fromSeed 0w12345
val (sessionId, g) = Random.hexToken g 32
val (dieRoll, g) = Random.nextInt g 6        (* 0..5 *)
val (left, right) = Random.split g           (* two independent streams *)
```

## Build & test

Requires [MLton](http://mlton.org/) and/or [Poly/ML](https://polyml.org/).

```sh
make test        # MLton
make test-poly   # Poly/ML
make all-tests   # both
make example     # build + run the demo
make clean
```

## Demo

[`examples/demo.sml`](examples/demo.sml) creates generators from fixed seeds
and prints raw words in hex, integer draws, string tokens, and the first word
of each half of a `split`. Because the state is immutable and all arithmetic is
masked `Word64`, the output is identical on every run and on both compilers
(the seed-0 words match the SplitMix64 reference vectors). Run it with:

```
$ make example
first 3 words (seed 0): e220a8397b1dcdaf 6e789e6aa1b965f4 06c45d188009454f
10 nextInt 6 (seed 7):  3 0 0 3 4 3 4 0 5 5
hexToken 16 (seed 42):  532426d45efe67c2
token 12 (seed 123):    pwyvqcyvbrda
split (seed 999):       left=f374ee4c47c6faa8 right=482d8cc409c06222
```

## Installing with smlpkg

```sh
smlpkg add github.com/sjqtentacles/sml-random
smlpkg sync
```

Reference `lib/github.com/sjqtentacles/sml-random/sml-random.mlb` from your
own `.mlb`, or feed `sources.mlb` to `tools/polybuild` (Poly/ML).

## Tests

19 deterministic checks: the SplitMix64 reference output for seed 0
(`0xe220a8397b1dcdaf`, ...), seed reproducibility, unbiased `nextInt` range
coverage, `nextReal` range, token/byte generation, and that `split` yields
independent yet reproducible streams. Run `make all-tests`.

## License

MIT. See [LICENSE](LICENSE).
