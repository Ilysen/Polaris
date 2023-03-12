/obj/effect/newrune/teleport
	rune_name = "Teleport"
	rune_desc = "When invoked, teleports anything on top of itself to another Teleport rune sharing the same keyword."
	circle_words = list(CULT_WORD_TRAVEL, CULT_WORD_SELF, CULT_WORD_OTHER)
	invocation = "Sas'so c'arta forbici!"
	var/key_word

/obj/effect/newrune/teleport/examine(mob/user, infix, suffix)
	. = ..()
	if (iscultist(user))
		. += SPAN_DANGER("This rune has a key word of \"[key_word]\".")

/obj/effect/newrune/teleport/after_scribe(mob/living/author)
	var/word = input(author, "Choose a key word for this rune.", rune_name) as null|anything in cult.english_words
	if (QDELETED(src) || QDELETED(author))
		return
	if (!word)
		word = CULT_WORD_OTHER
		to_chat(author, SPAN_WARNING("No key word specified. Using \"[word]\" instead."))
	key_word = word
	circle_words[3] = word
	update_icon()

/obj/effect/newrune/teleport/can_invoke(mob/living/invoker)
	var/valid_runes = 0
	for (var/obj/effect/newrune/teleport/T in cult.all_runes - src)
		if (T.key_word == key_word)
			valid_runes++
	if (!valid_runes)
		to_chat(invoker, SPAN_WARNING("There are no other Teleport runes with a keyword of \"[key_word]\"."))
		return
	return TRUE

/obj/effect/newrune/teleport/invoke(list/invokers)
	var/list/runes
	for (var/obj/effect/newrune/teleport/T in cult.all_runes - src)
		if (T.key_word == key_word)
			LAZYADD(runes, T)
	if (!LAZYLEN(runes))
		return fizzle()
	var/obj/effect/newrune/teleport/T = pick(runes)
	var/turf/new_loc = get_turf(T)
	for (var/mob/living/L in get_turf(src))
		to_chat(L, SPAN_WARNING("You are dragged through space!"))
		L.forceMove(new_loc)
	for (var/obj/O in get_turf(src))
		if (!O.anchored)
			O.forceMove(new_loc)
	visible_message(SPAN_DANGER("\The [src] emit\s a burst of red light!"))
	T.visible_message(SPAN_DANGER("\The [src] emit\s a burst of red light!"))
