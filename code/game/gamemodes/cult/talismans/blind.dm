/obj/item/paper/newtalisman/blind
	talisman_name = "Blind"
	talisman_desc = "Induces blindness in nonbelievers within two tiles."
	invocation = "Sti'kaliesin!"

/obj/item/paper/newtalisman/blind/invoke(mob/living/user)
	to_chat(user, SPAN_WARNING("The talisman in your hands turns to gray dust, blinding nearby nonbelievers."))
	var/list/affected = list()
	for (var/mob/living/L in viewers(2, src))
		if (iscultist(L) || findNullRod(L))
			continue
		affected.Add(L)
		L.eye_blurry = max(30, L.eye_blurry)
		L.Blind(10)
		to_chat(L, SPAN_DANGER("Your vision floods with burning red light!"))
	add_attack_logs(user, affected, "blindness talisman")
