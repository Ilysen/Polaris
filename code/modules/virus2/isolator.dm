/obj/machinery/disease2/isolator/
	name = "pathogenic isolator"
	desc = "Used to isolate and identify diseases, allowing for comparison with a remote database."
	density = 1
	anchored = 1
	icon = 'icons/obj/virology.dmi'
	icon_state = "isolator"
	var/isolating = 0
	var/datum/disease2/disease/virus2 = null
	var/obj/item/reagent_containers/syringe/sample = null

/obj/machinery/disease2/isolator/update_icon()
	if (stat & (BROKEN|NOPOWER))
		icon_state = "isolator"
		return

	if (isolating)
		icon_state = "isolator_processing"
	else if (sample)
		icon_state = "isolator_in"
	else
		icon_state = "isolator"

/obj/machinery/disease2/isolator/attackby(var/obj/O as obj, var/mob/user)
	if(default_unfasten_wrench(user, O, 20))
		return

	else if(!istype(O,/obj/item/reagent_containers/syringe)) return
	var/obj/item/reagent_containers/syringe/S = O

	if(sample)
		to_chat(user, "\The [src] is already loaded.")
		return

	sample = S
	user.drop_item()
	S.loc = src

	user.visible_message("[user] adds \a [O] to \the [src]!", "You add \a [O] to \the [src]!")
	SStgui.update_uis(src)
	update_icon()

	src.attack_hand(user)

/obj/machinery/disease2/isolator/attack_hand(mob/user as mob)
	if(stat & (NOPOWER|BROKEN))
		return
	tgui_interact(user)

/obj/machinery/disease2/isolator/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PathogenicIsolator", name)
		ui.open()


/obj/machinery/disease2/isolator/tgui_data(mob/user)
	var/list/data = list()
	data["syringe_inserted"] = !!sample
	data["isolating"] = isolating
	data["pathogen_pool"] = null
	data["can_print"] = !isolating

	var/list/pathogen_pool = list()
	if(sample)
		for(var/datum/reagent/blood/B in sample.reagents.reagent_list)
			var/list/virus = B.data["virus2"]
			for (var/ID in virus)
				var/datum/disease2/disease/V = virus[ID]
				var/datum/data/record/R = null
				if (ID in virusDB)
					R = virusDB[ID]

				var/mob/living/carbon/human/D = B.data["donor"]
				pathogen_pool.Add(list(list(\
					"name" = "[istype(D) ? "[D.get_species()] " : ""][B.name]", \
					"dna" = B.data["blood_DNA"], \
					"unique_id" = V.uniqueID, \
					"reference" = "\ref[V]", \
					"is_in_database" = !!R, \
					"record" = "\ref[R]")))
	data["pathogen_pool"] = pathogen_pool

	var/list/db = list()
	for(var/ID in virusDB)
		var/datum/data/record/r = virusDB[ID]
		db.Add(list(list("name" = r.fields["name"], "record" = "\ref[r]")))
	data["database"] = db
	data["modal"] = tgui_modal_data(src)
	return data

/obj/machinery/disease2/isolator/process()
	if (isolating > 0)
		isolating -= 1
		if (isolating == 0)
			if (virus2)
				var/obj/item/virusdish/d = new /obj/item/virusdish(src.loc)
				d.virus2 = virus2.getcopy()
				virus2 = null
				ping("\The [src] pings, \"Viral strain isolated.\"")

			SStgui.update_uis(src)
			update_icon()

/obj/machinery/disease2/isolator/tgui_act(action, list/params)
	if(..())
		return TRUE

	var/mob/user = usr
	add_fingerprint(user)
	
	. = TRUE
	switch(tgui_modal_act(src, action, params))
		if(TGUI_MODAL_ANSWER)
			return

	switch(action)
		if("view_entry")
			var/datum/data/record/v = locate(params["vir"])
			if(!istype(v))
				return FALSE
			tgui_modal_message(src, "virus", "", null, v.fields["tgui_description"])
			return TRUE

		if("print")
			print(user, params)
			return TRUE

		if("isolate")
			var/datum/disease2/disease/V = locate(params["isolate"])
			if (V)
				virus2 = V
				isolating = 20
				update_icon()
			return TRUE

		if("eject")
			if(!sample)
				return FALSE
			sample.forceMove(loc)
			sample = null
			update_icon()
			return TRUE

/obj/machinery/disease2/isolator/proc/print(mob/user, list/params)
	var/obj/item/paper/P = new /obj/item/paper(loc)

	switch(params["type"])
		if("patient_diagnosis")
			if (!sample) return
			P.name = "paper - Patient Diagnostic Report"
			P.info = {"
				[virology_letterhead("Patient Diagnostic Report")]
				<center><small><font color='red'><b>CONFIDENTIAL MEDICAL REPORT</b></font></small></center><br>
				<large><u>Sample:</u></large> [sample.name]<br>
"}

			if (user)
				P.info += "<u>Generated By:</u> [user.name]<br>"

			P.info += "<hr>"

			for(var/datum/reagent/blood/B in sample.reagents.reagent_list)
				var/mob/living/carbon/human/D = B.data["donor"]
				P.info += "<large><u>[D.get_species()] [B.name]:</u></large><br>[B.data["blood_DNA"]]<br>"

				var/list/virus = B.data["virus2"]
				P.info += "<u>Pathogens:</u> <br>"
				if (virus.len > 0)
					for (var/ID in virus)
						var/datum/disease2/disease/V = virus[ID]
						P.info += "[V.name()]<br>"
				else
					P.info += "None<br>"

			P.info += {"
			<hr>
			<u>Additional Notes:</u>&nbsp;
"}

		if("virus_list")
			P.name = "paper - Virus List"
			P.info = {"
				[virology_letterhead("Virus List")]
"}

			var/i = 0
			for (var/ID in virusDB)
				i++
				var/datum/data/record/r = virusDB[ID]
				P.info += "[i]. " + r.fields["name"]
				P.info += "<br>"

			P.info += {"
			<hr>
			<u>Additional Notes:</u>&nbsp;
"}

		if("virus_record")
			var/datum/data/record/v = locate(params["vir"])
			if(!istype(v))
				return FALSE
			P.name = "paper - Viral Profile"
			P.info = {"
				[virology_letterhead("Viral Profile")]
				[v.fields["description"]]
				<hr>
				<u>Additional Notes:</u>&nbsp;
"}

	state("The nearby computer prints out a report.")
