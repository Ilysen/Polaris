/client/proc/triple_ai()
	set category = "Fun"
	set name = "Create AI Triumvirate"

	if(ticker.current_state > GAME_STATE_PREGAME)
		to_chat(usr, "This option is currently only usable during pregame. This may change at a later date.")
		return

	var/datum/job/job = SSjob.get_job("AI")
	if(!job)
		to_chat(usr, "Unable to locate the AI job")
		return
	if(ticker.triai)
		ticker.triai = 0
		to_chat(usr, "Only one AI will be spawned at round start.")
		message_admins("<font color='blue'>[key_name_admin(usr)] has toggled off triple AIs at round start.</font>", 1)
	else
		ticker.triai = 1
		to_chat(usr, "There will be an AI Triumvirate at round start.")
		message_admins("<font color='blue'>[key_name_admin(usr)] has toggled on triple AIs at round start.</font>", 1)
	return
