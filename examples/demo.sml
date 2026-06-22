(* demo.sml - a deterministic, splittable SplitMix64 generator. Every generator
   is created from a FIXED seed, and the state is immutable, so the streams are
   reproducible across runs and (all arithmetic being masked Word64) across
   compilers. Output is raw words in hex, integer draws, and string tokens --
   no reals are printed. *)

structure R = Random

fun hx w = StringCvt.padLeft #"0" 16 (String.map Char.toLower (Word64.fmt StringCvt.HEX w))

fun takeWords 0 _ acc = List.rev acc
  | takeWords k g acc =
      let val (w, g') = R.nextWord g in takeWords (k - 1) g' (w :: acc) end

val ws = takeWords 3 (R.fromSeed 0w0) []
val () = print ("first 3 words (seed 0): " ^ String.concatWith " " (List.map hx ws) ^ "\n")

fun rolls 0 _ acc = List.rev acc
  | rolls k g acc =
      let val (i, g') = R.nextInt g 6 in rolls (k - 1) g' (i :: acc) end
val dice = rolls 10 (R.fromSeed 0w7) []
val () = print ("10 nextInt 6 (seed 7):  "
                ^ String.concatWith " " (List.map Int.toString dice) ^ "\n")

val (tok, _) = R.hexToken (R.fromInt 42) 16
val () = print ("hexToken 16 (seed 42):  " ^ tok ^ "\n")

val (alnum, _) = R.token (R.fromInt 123) "abcdefghijklmnopqrstuvwxyz" 12
val () = print ("token 12 (seed 123):    " ^ alnum ^ "\n")

(* Split into two independent streams; show the first word of each. *)
val (gl, gr) = R.split (R.fromSeed 0w999)
val (lw, _) = R.nextWord gl
val (rw, _) = R.nextWord gr
val () = print ("split (seed 999):       left=" ^ hx lw ^ " right=" ^ hx rw ^ "\n")
