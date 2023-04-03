SUBSYSTEM_DEF(telecomms)
	name = "Telecomms"
	flags = SS_NO_INIT | SS_NO_FIRE
	var/static/list/devices
	var/static/list/hubs

/datum/controller/subsystem/telecomms/proc/transmit_packet(datum/packet/P)
	if (!P?.source)
		return
	var/turf/source_turf = get_turf(P.source)
	var/list/signal_spread = GetConnectedZlevels(source_turf)
	if (P.subspace)
		var/obj/machinery/telecomms/hub/chosen_hub
		for (var/obj/machinery/telecomms/hub/H in hubs)
			if (!H.on)
				continue
			var/list/hub_zlevels = GetConnectedZlevels(get_turf(H))
			for (var/Z in hub_zlevels)
				if (signal_spread.Find(Z))
					chosen_hub = H
					P.source = chosen_hub // Log the packet and its source, with the hub becoming the new source via routing
					break
		if (!chosen_hub)
			return
	var/effective_latency = P.get_latency()
	for (var/atom/A in devices)
		var/turf/T = get_turf(A)
		if (P.range && get_dist(get_turf(A), source_turf) < P.range)
			continue
		if (!P.cross_z)
			var/is_connected
			var/list/receiver_zlevels = GetConnectedZlevels(T)
			for (var/Z in signal_spread)
				if (receiver_zlevels.Find(Z))
					is_connected = TRUE
					break
			if (!is_connected)
				continue
		addtimer(CALLBACK(src, .proc/send_packet_to_atom, A, P), effective_latency)
	// We shouldn't need much time for this, but we give it a buffer for safety reasons
	QDEL_IN(P, max(1, effective_latency) * 2)

/datum/controller/subsystem/telecomms/proc/send_packet_to_atom(atom/A, datum/packet/P)
	if (!P?.source)
		return
	A.receive_packet(P)

/// Add a device to the telecommunications network, accounting for duplicates.
/datum/controller/subsystem/telecomms/proc/add_device(atom/A)
	LAZYDISTINCTADD(devices, A)

/// Remove a device from the telecommunications network.
/datum/controller/subsystem/telecomms/proc/remove_device(atom/A)
	LAZYREMOVE(devices, A)

/// Returns whether or not the telecomms network contains device `A` in its device list.
/datum/controller/subsystem/telecomms/proc/has_device(atom/A)
	return LAZYFIND(devices, A)


/**
 * Packets are disposable datums carrying a payload of data used to send arbitrary information between atoms.
 * They're most notably used for radio communications, but are also passed between certain things like atmos devices.
 * After a packet is fully processed by all recipients, it is deleted.
 */
/datum/packet
	/// The atom that this signal originates from.
	var/atom/source
	/// A list of the data contained in this signal.
	var/list/payload
	/// An optional string or number attached to this signal. Encrypted signals can't be received by devices that don't hack the same encryption in some way.
	var/encryption
	/// The frequency this signal is being sent with.
	var/frequency = 0
	/// Subspace signals must be routed through a telecomms hub, but are usually global.
	/// Non-subspace signals do not require a hub but are usually local instead.
	/// Generally speaking, headsets transmit subspace signals, while intercoms, handheld radios, etc do not.
	var/subspace
	/// How far this signal will travel before being unreceivable. By default, signals span all connected z-levels.
	var/range
	/// By default, signals can only be received by things on connected z-levels (with possible exceptions.) If this value is non-zero, it will transmit to the entire world instead.
	var/cross_z
	/// For the fiendish, packets can be given "latency" to simulate network lag, tracked in deciseconds.
	/// By default, all packets have no latency/are instant.
	var/latency
	/// Another way of handling packet latency. If two numbers are passed here, they represent the minimum and maximum possible extra latency for the packet.
	/// Any results from latency_range will be added onto `latency` as a static number.
	var/list/latency_range

/// Returns the effective latency of this packet, equal to `latency` plus `rand(latency_range[1], latency_range[2])`.
/datum/packet/proc/get_latency()
	var/random_latency = 0
	if (LAZYLEN(latency_range) >= 2)
		random_latency = rand(latency_range[1], latency_range[2])
	return max(0, latency) + max(0, random_latency)

/datum/packet/New(_source, _payload, _encryption, _frequency, _subspace, _range, _cross_z, _latency, _latency_range)
	if (!isnull(source))
		source = _source
	if (!isnull(payload))
		payload = _payload
	if (!isnull(encryption))
		encryption = _encryption
	if (!isnull(frequency))
		frequency = _frequency
	if (!isnull(subspace))
		subspace = _subspace
	if (!isnull(range))
		range = _range
	if (!isnull(cross_z))
		cross_z = _cross_z
	if (!isnull(latency))
		latency = _latency
	if (LAZYLEN(latency_range))
		latency_range = _latency_range
	return ..()



/obj/item/new_radio
	icon = 'icons/obj/radio.dmi'
	name = "station bounced radio"
	desc = "Used to talk to people when headsets don't function. Range is limited."
	suffix = "\[3\]"
	icon_state = "walkietalkie"
	item_state = "radio"
	slot_flags = SLOT_BELT
	w_class = ITEMSIZE_SMALL
	telecomms_receiver = TRUE

	var/enabled = TRUE
	var/sending = FALSE
	var/receiving = TRUE
	var/frequency = PUB_FREQ

/obj/item/new_radio/talk_into(mob/M, list/message_pieces, verb = "says")
	if (!enabled)
		return
	if (!M || !LAZYLEN(message_pieces))
		return
	if (istype(M))
		M.trigger_aiming(TARGET_CAN_RADIO)
	send_packet(src, list("message" = message_pieces.Join()), null, frequency, TRUE)

/obj/item/new_radio/receive_packet(datum/packet/P)
	if (P.frequency != frequency)
		return
	var/message = P.data["message"]
	if (message)
		visible_message(SPAN_NOTICE(message))
		playsound(loc, 'sound/effects/radio_common.ogg', 20, TRUE, TRUE, preference = /datum/client_preference/radio_sounds)
