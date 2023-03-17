/datum/tgui_module/agentcard
	name = "Agent Card"
	tgui_id = "AgentCard"

/datum/tgui_module/agentcard/tgui_data(mob/user, datum/tgui/ui, datum/tgui_state/state)
	var/list/data = ..()

	var/obj/item/card/id/syndicate/S = tgui_host()
	if (!istype(S))
		return list()

	var/list/entries = list()
	entries += list(list("name" = "Age", 				"value" = S.age))
	entries += list(list("name" = "Assignment",			"value" = S.assignment))
	entries += list(list("name" = "Blood Type",			"value" = S.blood_type))
	entries += list(list("name" = "DNA Hash", 			"value" = S.dna_hash))
	entries += list(list("name" = "Fingerprint Hash",	"value" = S.fingerprint_hash))
	entries += list(list("name" = "Name", 				"value" = S.registered_name))
	entries += list(list("name" = "Sex", 				"value" = S.sex))
	data["entries"] = entries

	data["electronic_warfare"] = S.electronic_warfare

	return data

/datum/tgui_module/agentcard/tgui_status(mob/user, datum/tgui_state/state)
	var/obj/item/card/id/syndicate/S = tgui_host()
	if (!istype(S) || user != S.registered_user)
		return STATUS_CLOSE
	return ..()

/datum/tgui_module/agentcard/tgui_act(action, list/params, datum/tgui/ui, datum/tgui_state/state)
	if (..())
		return TRUE

	var/obj/item/card/id/syndicate/S = tgui_host()
	var/new_val = params["new_value"]
	switch (action)
		if ("electronic_warfare")
			S.electronic_warfare = !S.electronic_warfare
			to_chat(usr, SPAN_NOTICE("Electronic warfare [S.electronic_warfare ? "enabled" : "disabled"]."))
			return TRUE
		if ("age")
			var/num_age = text2num(new_val)
			if (num_age)
				S.age = num_age < 0 ? initial(S.age) : num_age
				to_chat(usr, SPAN_NOTICE("Age has been set to '[S.age]'."))
				return TRUE
		if ("appearance")
			var/datum/card_state/choice = input(usr, "Select the appearance for this card.", "Agent Card Appearance") as null|anything in id_card_states()
			if (choice && tgui_status(usr, state) == STATUS_INTERACTIVE)
				S.icon_state = choice.icon_state
				S.item_state = choice.item_state
				S.sprite_stack = choice.sprite_stack
				S.update_icon()
				to_chat(usr, SPAN_NOTICE("Appearance updated."))
				return TRUE
		if ("assignment")
			if (istext(new_val))
				S.assignment = new_val
				to_chat(usr, SPAN_NOTICE("Occupation changed to '[S.assignment]'."))
				S.update_name()
				return TRUE
		if ("bloodtype")
			if (istext(new_val))
				S.blood_type = new_val
				to_chat(usr, SPAN_NOTICE("Blood type changed to '[S.blood_type]'."))
				return TRUE
		if ("dnahash")
			if (istext(new_val))
				S.dna_hash = new_val
				to_chat(usr, SPAN_NOTICE("DNA hash changed to '[S.dna_hash]'."))
				return TRUE
		if ("fingerprinthash")
			if (istext(new_val))
				S.fingerprint_hash = new_val
				to_chat(usr, SPAN_NOTICE("Fingerprint hash changed to '[S.fingerprint_hash]'."))
				return TRUE
		if ("name")
			if (istext(new_val))
				S.registered_name = new_val
				S.update_name()
				to_chat(usr, SPAN_NOTICE("Registered name changed to '[S.name]'."))
				return TRUE
		if ("photo")
			S.set_id_photo(usr)
			to_chat(usr, SPAN_NOTICE("Photo updated."))
			return TRUE
		if ("sex")
			if (istext(new_val))
				S.sex = new_val
				to_chat(usr, SPAN_NOTICE("Sex changed to '[S.sex]'."))
				return TRUE
		if ("factory_reset")
			if (alert(usr, "This will factory reset the card, including access and owner. Continue?", "Factory Reset", "Yes", "No") == "Yes" && tgui_status(usr, state) == STATUS_INTERACTIVE)
				S.age = initial(S.age)
				S.access = syndicate_access.Copy()
				S.assignment = initial(S.assignment)
				S.blood_type = initial(S.blood_type)
				S.dna_hash = initial(S.dna_hash)
				S.electronic_warfare = initial(S.electronic_warfare)
				S.fingerprint_hash = initial(S.fingerprint_hash)
				S.icon_state = initial(S.icon_state)
				S.item_state = initial(S.item_state)
				S.sprite_stack = S.initial_sprite_stack
				S.front = null
				S.name = initial(S.name)
				S.registered_name = initial(S.registered_name)
				S.unset_registered_user()
				S.sex = initial(S.sex)
				S.update_icon()
				to_chat(usr, SPAN_NOTICE("All information has been deleted from \the [src]."))
				return TRUE
