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
make clean
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
