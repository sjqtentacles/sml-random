(* Tests for sml-random. SplitMix64 reference vectors for seed 0 are
   0xe220a8397b1dcdaf, 0x6e789e6aa1b965f4, 0x06c45d188009454f. *)

structure RandomTests =
struct
  open Harness

  fun hx w = String.map Char.toLower (Word64.fmt StringCvt.HEX w)

  fun run () =
    let
      val () = section "SplitMix64 reference vectors (seed 0)"
      val g0 = Random.fromSeed 0w0
      val (w1, g1) = Random.nextWord g0
      val (w2, g2) = Random.nextWord g1
      val (w3, _)  = Random.nextWord g2
      val () = checkString "first"  ("e220a8397b1dcdaf", hx w1)
      val () = checkString "second" ("6e789e6aa1b965f4", hx w2)
      val () = checkString "third"  ("6c45d188009454f", hx w3)

      val () = section "Determinism / reproducibility"
      val (a1, _) = Random.nextWord (Random.fromSeed 0w12345)
      val (a2, _) = Random.nextWord (Random.fromSeed 0w12345)
      val () = checkBool "same seed same first word" (true, a1 = a2)
      val (b1, _) = Random.nextWord (Random.fromSeed 0w99999)
      val () = checkBool "different seed differs" (true, a1 <> b1)

      val () = section "nextInt bounds + bias-free range"
      val () =
        let
          fun gather 0 _ acc = acc
            | gather k g acc =
                let val (i, g') = Random.nextInt g 6
                in gather (k - 1) g' (i :: acc) end
          val xs = gather 2000 (Random.fromSeed 0w7) []
          val allInRange = List.all (fn i => i >= 0 andalso i < 6) xs
          val sawLow = List.exists (fn i => i = 0) xs
          val sawHigh = List.exists (fn i => i = 5) xs
        in
          checkBool "all in [0,6)" (true, allInRange);
          checkBool "saw 0" (true, sawLow);
          checkBool "saw 5" (true, sawHigh)
        end
      val () = checkRaises "nextInt 0 raises" (fn () => Random.nextInt (Random.fromSeed 0w1) 0)

      val () = checkBool "nextInt bound 1 is always 0"
                 (true, #1 (Random.nextInt (Random.fromSeed 0w42) 1) = 0)

      val () = section "nextReal in [0,1)"
      val () =
        let
          fun gather 0 _ acc = acc
            | gather k g acc =
                let val (r, g') = Random.nextReal g in gather (k-1) g' (r :: acc) end
          val rs = gather 1000 (Random.fromSeed 0w3) []
        in
          checkBool "all in [0,1)" (true, List.all (fn r => r >= 0.0 andalso r < 1.0) rs)
        end

      val () = section "tokens"
      val (tok, _) = Random.hexToken (Random.fromSeed 0w1) 16
      val () = checkInt "hexToken length" (16, String.size tok)
      val () = checkBool "hexToken is all hex chars"
                 (true, List.all (fn c => Char.isHexDigit c) (String.explode tok))
      val (tok2, _) = Random.hexToken (Random.fromSeed 0w1) 16
      val () = checkString "hexToken reproducible" (tok, tok2)
      val (alpha, _) = Random.token (Random.fromSeed 0w2) "AB" 32
      val () = checkBool "token uses only alphabet"
                 (true, List.all (fn c => c = #"A" orelse c = #"B") (String.explode alpha))
      val () = checkRaises "token empty alphabet raises"
                 (fn () => Random.token (Random.fromSeed 0w1) "" 4)

      val () = section "bytes"
      val (bs, _) = Random.bytes (Random.fromSeed 0w5) 64
      val () = checkInt "bytes length" (64, String.size bs)

      val () = section "split produces independent streams"
      val (gl, gr) = Random.split (Random.fromSeed 0w777)
      val (lw, _) = Random.nextWord gl
      val (rw, _) = Random.nextWord gr
      val () = checkBool "split halves differ" (true, lw <> rw)
      (* split is itself deterministic *)
      val (gl2, gr2) = Random.split (Random.fromSeed 0w777)
      val () = checkBool "split reproducible"
                 (true, #1 (Random.nextWord gl2) = lw andalso #1 (Random.nextWord gr2) = rw)
    in
      ()
    end
end
