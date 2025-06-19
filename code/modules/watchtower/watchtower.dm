#define WATCHTOWER_STAGE_WELDED 1
#define WATCHTOWER_STAGE_COLUMNS 2
#define WATCHTOWER_STAGE_HEIGHTNED_WELDER 2.5
#define WATCHTOWER_STAGE_HEIGHTNED_WRENCH 3
#define WATCHTOWER_STAGE_FLOOR 4
#define WATCHTOWER_STAGE_BARRICADED 5
#define WATCHTOWER_STAGE_ROOF_SUPPORT 6
#define WATCHTOWER_STAGE_COMPLETE 7

/obj/structure/watchtower
	name = "watchtower"
	desc = "A watchtower used to view the area around and protect it."
	icon = 'icons/obj/structures/watchtower.dmi'
	icon_state = "stage1"

	density = FALSE
	bound_width = 64
	bound_height = 96
	health = 1000
	layer = ABOVE_TURF_LAYER
	var/max_health = 1000

	var/stage = 1
	var/image/roof_image

/obj/structure/watchtower/Initialize()
	var/list/turf/blocked_turfs = CORNER_BLOCK(get_turf(src), 2, 1) + CORNER_BLOCK_OFFSET(get_turf(src), 2, 1, 0, 2)

	var/atom/west_blocker = new /obj/structure/blocker/watchtower(locate(x, y+1, z))
	var/atom/east_blocker = new /obj/structure/blocker/watchtower(locate(x+1, y+1, z))
	west_blocker.dir = WEST
	east_blocker.dir = EAST

	for(var/turf/current_turf in blocked_turfs)
		new /obj/structure/blocker/watchtower/full_tile(current_turf)

	update_icon()

	return ..()

/obj/structure/watchtower/Destroy()
	playsound(src, 'sound/effects/metal_crash.ogg', 50, 1)
	var/list/turf/top_turfs = CORNER_BLOCK_OFFSET(get_turf(src), 2, 1, 0, 1)

	for(var/turf/current_turf in top_turfs)
		for(var/mob/falling_mob in current_turf.contents)
			falling_mob.ex_act(100, 0)
			on_leave(falling_mob)

	new /obj/structure/girder(get_turf(src))
	new /obj/structure/girder/broken(locate(x+1, y, z))
	new /obj/structure/girder/broken(locate(x, y+1, z))
	new /obj/item/stack/sheet/metal(locate(x+1, y+1, z), 10)
	new /obj/item/stack/rods(locate(x+1, y+1, z), 20)

	return ..()

/obj/structure/watchtower/update_icon()
	. = ..()
	icon_state = "stage[stage]"

	overlays.Cut()

	if(stage >= WATCHTOWER_STAGE_BARRICADED)
		overlays += image(icon=icon, icon_state="railings", layer=ABOVE_MOB_LAYER, pixel_y=25)

	if (stage == WATCHTOWER_STAGE_COMPLETE)
		roof_image = image(icon=icon, icon_state="roof", layer=ABOVE_MOB_LAYER, pixel_y=51)
		roof_image.plane = ROOF_PLANE
		roof_image.appearance_flags = KEEP_APART
		overlays += roof_image

/obj/structure/watchtower/get_examine_text(mob/user)
	. = ..()
	switch(stage)
		if(WATCHTOWER_STAGE_WELDED)
			. += SPAN_NOTICE("Add 60 metal [SPAN_HELPFUL("rods")] to construct the connection rods.")
			return
		if(WATCHTOWER_STAGE_COLUMNS)
			. += SPAN_NOTICE("Use a [SPAN_HELPFUL("welder")] to weld the connection rods to the frame.")
			return
		if(WATCHTOWER_STAGE_HEIGHTNED_WELDER)
			. += SPAN_NOTICE("Use a [SPAN_HELPFUL("wrench")] to elevate the frame.")
			return
		if(WATCHTOWER_STAGE_HEIGHTNED_WRENCH)
			. += SPAN_NOTICE("Use a [SPAN_HELPFUL("screwdriver")] and 50 [SPAN_HELPFUL("metal")] sheets to construct the platform.")
			return
		if(WATCHTOWER_STAGE_FLOOR)
			. += SPAN_NOTICE("Use a [SPAN_HELPFUL("crowbar")] and 25 [SPAN_HELPFUL("plasteel")] sheets to construct [src] railings.")
			return
		if(WATCHTOWER_STAGE_BARRICADED)
			. += SPAN_NOTICE("Use a [SPAN_HELPFUL("wrench")] and 60 metal [SPAN_HELPFUL("rods")] to construct [src] support rods.")
			return
		if(WATCHTOWER_STAGE_ROOF_SUPPORT)
			. += SPAN_NOTICE("Use a [SPAN_HELPFUL("blowtorch")] and 25 [SPAN_HELPFUL("plasteel")] sheets to construct the roof.")
			return
		if(WATCHTOWER_STAGE_COMPLETE)
			. += SPAN_NOTICE("Use a [SPAN_HELPFUL("blowtorch")] and [SPAN_HELPFUL("metal")] sheets to repair.")
			return

/obj/structure/watchtower/attackby(obj/item/item, mob/user)
	if(user.action_busy)
		return

	if(istool(item) && !skillcheck(user, SKILL_CONSTRUCTION, SKILL_CONSTRUCTION_ENGI))
		to_chat(user, SPAN_WARNING("You are not trained to configure [src]..."))
		return TRUE

	switch(stage)
		if(WATCHTOWER_STAGE_WELDED)
			if(!istype(item, /obj/item/stack/rods))
				return

			var/obj/item/stack/rods/rods = item

			to_chat(user, SPAN_NOTICE("You start adding connection rods to [src]."))
			playsound(loc, 'sound/items/Screwdriver.ogg', 25, 1)

			if(!do_after(user, 4 SECONDS * user.get_skill_duration_multiplier(SKILL_CONSTRUCTION), INTERRUPT_NO_NEEDHAND|BEHAVIOR_IMMOBILE, BUSY_ICON_FRIENDLY, src))
				return

			if(rods.use(60))
				to_chat(user, SPAN_NOTICE("You add connection rods to [src]."))
				stage = WATCHTOWER_STAGE_COLUMNS
				update_icon()
			else
				to_chat(user, SPAN_NOTICE("You failed to construct the connection rods. You need more rods."))

			return
		if(WATCHTOWER_STAGE_COLUMNS)
			if(!iswelder(item))
				return

			if(!HAS_TRAIT(item, TRAIT_TOOL_BLOWTORCH))
				to_chat(user, SPAN_WARNING("You need a stronger blowtorch!"))
				return

			to_chat(user, SPAN_NOTICE("You start welding the connection rods to the frame."))
			playsound(loc, 'sound/items/Welder.ogg', 25, 1)

			if(!do_after(user, 4 SECONDS * user.get_skill_duration_multiplier(SKILL_CONSTRUCTION), INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
				return

			to_chat(user, SPAN_NOTICE("You weld the connection rods to the frame."))
			stage = WATCHTOWER_STAGE_HEIGHTNED_WELDER

			return
		if(WATCHTOWER_STAGE_HEIGHTNED_WELDER)
			if(!HAS_TRAIT(item, TRAIT_TOOL_WRENCH))
				return

			to_chat(user, SPAN_NOTICE("You start elevating the frame and screwing it up top."))
			playsound(loc, 'sound/items/Ratchet.ogg', 25, 1)

			if(!do_after(user, 4 SECONDS * user.get_skill_duration_multiplier(SKILL_CONSTRUCTION), INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
				return

			to_chat(user, SPAN_NOTICE("You elevate the the frame and screw it up top."))
			stage = WATCHTOWER_STAGE_HEIGHTNED_WRENCH
			update_icon()

			return
		if(WATCHTOWER_STAGE_HEIGHTNED_WRENCH)
			if(!HAS_TRAIT(item, TRAIT_TOOL_SCREWDRIVER))
				return

			var/obj/item/stack/sheet/metal/metal = user.get_inactive_hand()
			if(!istype(metal))
				to_chat(user, SPAN_BOLDWARNING("You need metal sheets in your offhand to continue construction of [src]."))
				return FALSE

			to_chat(user, SPAN_NOTICE("You start constructing [src] platform."))
			playsound(loc, 'sound/items/Screwdriver.ogg', 25, 1)

			if(!do_after(user, 4 SECONDS * user.get_skill_duration_multiplier(SKILL_CONSTRUCTION), INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
				return

			if(metal.use(50))
				to_chat(user, SPAN_NOTICE("You construct [src] platform."))
				stage = WATCHTOWER_STAGE_FLOOR
				update_icon()
			else
				to_chat(user, SPAN_NOTICE("You failed to construct [src] platform, you need more metal sheets in your offhand."))

			return
		if(WATCHTOWER_STAGE_FLOOR)
			if(!HAS_TRAIT(item, TRAIT_TOOL_CROWBAR))
				return

			var/obj/item/stack/sheet/plasteel/plasteel = user.get_inactive_hand()
			if(!istype(plasteel))
				to_chat(user, SPAN_BOLDWARNING("You need plasteel sheets in your offhand to continue construction of [src]."))
				return FALSE

			to_chat(user, SPAN_NOTICE("You start constructing [src] railing."))
			playsound(loc, 'sound/items/Crowbar.ogg', 25, 1)

			if(!do_after(user, 4 SECONDS * user.get_skill_duration_multiplier(SKILL_CONSTRUCTION), INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
				return

			if(plasteel.use(25))
				to_chat(user, SPAN_NOTICE("You construct [src] railing."))
				stage = WATCHTOWER_STAGE_BARRICADED
				update_icon()
			else
				to_chat(user, SPAN_NOTICE("You failed to construct [src] railing, you need more plasteel sheets in your offhand."))

			return
		if(WATCHTOWER_STAGE_BARRICADED)
			if (!HAS_TRAIT(item, TRAIT_TOOL_WRENCH))
				return

			var/obj/item/stack/rods/rods = user.get_inactive_hand()
			if(!istype(rods))
				to_chat(user, SPAN_BOLDWARNING("You need metal rods in your offhand to continue construction of [src]."))
				return FALSE

			to_chat(user, SPAN_NOTICE("You start constructing [src] support rods."))
			playsound(loc, 'sound/items/Ratchet.ogg', 25, 1)

			if(!do_after(user, 4 SECONDS * user.get_skill_duration_multiplier(SKILL_CONSTRUCTION), INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
				return

			if(rods.use(60))
				to_chat(user, SPAN_NOTICE("You construct [src] support rods."))
				stage = WATCHTOWER_STAGE_ROOF_SUPPORT
				update_icon()
			else
				to_chat(user, SPAN_NOTICE("You failed to construct [src] support rods, you need more metal rods in your offhand."))

			return
		if(WATCHTOWER_STAGE_ROOF_SUPPORT)
			if (!iswelder(item))
				return

			if(!HAS_TRAIT(item, TRAIT_TOOL_BLOWTORCH))
				to_chat(user, SPAN_WARNING("You need a stronger blowtorch!"))
				return

			var/obj/item/stack/sheet/plasteel/plasteel = user.get_inactive_hand()
			if(!istype(plasteel))
				to_chat(user, SPAN_BOLDWARNING("You need plasteel sheets in your offhand to continue construction of [src]."))
				return FALSE

			to_chat(user, SPAN_NOTICE("You start completing [src]."))
			playsound(loc, 'sound/items/Welder.ogg', 25, 1)

			if(!do_after(user, 4 SECONDS * user.get_skill_duration_multiplier(SKILL_CONSTRUCTION), INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
				return

			if(plasteel.use(25))
				to_chat(user, SPAN_NOTICE("You complete [src]."))
				stage = WATCHTOWER_STAGE_COMPLETE
				update_icon()
			else
				to_chat(user, SPAN_NOTICE("You failed to complete [src], you need more plasteel sheets in your offhand."))

			return
		if(WATCHTOWER_STAGE_COMPLETE)
			if (!iswelder(item))
				return

			if(!HAS_TRAIT(item, TRAIT_TOOL_BLOWTORCH))
				to_chat(user, SPAN_WARNING("You need a stronger blowtorch!"))
				return

			var/obj/item/stack/sheet/metal/metal = user.get_inactive_hand()
			if(!istype(metal))
				to_chat(user, SPAN_BOLDWARNING("You need metal sheets in your offhand to patch [src]."))
				return

			if(health >= max_health)
				to_chat(user, SPAN_NOTICE("[src] is in good condition."))
				return

			to_chat(user, SPAN_NOTICE("You start patching [src] with the metal sheets."))
			playsound(loc, 'sound/items/Welder.ogg', 25, 1)

			if(!do_after(user, 4 SECONDS * user.get_skill_duration_multiplier(SKILL_CONSTRUCTION), INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
				return

			if(metal.use(5))
				to_chat(user, SPAN_NOTICE("You patch [src] with the metal sheets."))
				update_health(-50)
			else
				to_chat(user, SPAN_NOTICE("You failed to patch [src], you need more metal sheets in your offhand."))

	. = ..()

	var/dam = health / max_health

	if(dam <= 0.3)
		. += SPAN_WARNING("It looks heavily damaged.")
	else if(dam <= 0.6)
		. += SPAN_WARNING("It looks moderately damaged.")
	else if (dam < 1)
		. += SPAN_DANGER("It looks slightly damaged.")


/obj/structure/watchtower/attack_hand(mob/user)
	if (stage < WATCHTOWER_STAGE_COMPLETE)
		return

	if(get_turf(user) == locate(x, y-1, z))
		var/people_on_watchtower = 0

		for(var/turf/current_turf in CORNER_BLOCK_OFFSET(src, 2, 1, 0, 1))
			for(var/mob/mob in current_turf.contents)
				if(mob.stat != DEAD)
					people_on_watchtower++

		if(people_on_watchtower >= 2)
			to_chat(user, SPAN_NOTICE("[src] is too crowded!"))
			return

		if(!do_after(user, 3 SECONDS, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
			return


		var/turf/actual_turf = locate(x, y+1, z)
		if(people_on_watchtower < 1 && user.pulling)
			user.pulling.forceMove(actual_turf)
			on_enter(user.pulling)

		user.forceMove(actual_turf)
		on_enter(user)


	else if(get_turf(user) == locate(x, y+1, z))
		if(!do_after(user, 3 SECONDS, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
			return

		var/turf/actual_turf = locate(x, y-1, z)
		if(user.pulling)
			on_leave(user.pulling)
			user.pulling.forceMove(actual_turf)

		user.forceMove(actual_turf)
		on_leave(user)

/obj/structure/watchtower/proc/on_enter(mob/user)
	ADD_TRAIT(user, TRAIT_ON_WATCHTOWER, "watchtower")
	if(user.client)
		user.client.change_view(user.client.view + 2)
	var/atom/movable/screen/plane_master/roof/roof_plane = user.hud_used?.plane_masters["[ROOF_PLANE]"]
	roof_plane?.invisibility = INVISIBILITY_MAXIMUM
	add_trait_to_all_guns(user)
	RegisterSignal(user, COMSIG_ITEM_PICKUP, PROC_REF(item_picked_up))
	RegisterSignal(user, COMSIG_LIVING_ZOOM_OUT, PROC_REF(on_unzoom))

	if(isxeno(user))
		RegisterSignal(user, COMSIG_XENO_ENTER_TUNNEL, PROC_REF(on_tunnel))

/obj/structure/watchtower/proc/on_unzoom(mob/user)
	SIGNAL_HANDLER
	if(user.client)
		user.client.change_view(user.client.view + 2)

/obj/structure/watchtower/proc/on_tunnel()
	SIGNAL_HANDLER
	return COMPONENT_CANCEL_TUNNEL

/obj/structure/watchtower/proc/on_leave(mob/user)
	REMOVE_TRAIT(user, TRAIT_ON_WATCHTOWER, "watchtower")
	if(user.client)
		user.client.change_view(max(user.client.view - 2, 7))
	var/atom/movable/screen/plane_master/roof/roof_plane = user.hud_used?.plane_masters["[ROOF_PLANE]"]
	roof_plane?.invisibility = 0
	UnregisterSignal(user, COMSIG_ITEM_PICKUP)
	UnregisterSignal(user, COMSIG_LIVING_ZOOM_OUT)

	if(isxeno(user))
		UnregisterSignal(user, COMSIG_XENO_ENTER_TUNNEL)

/obj/structure/watchtower/proc/add_trait_to_all_guns(mob/user)
	for(var/obj/item/weapon/gun/gun in user)
		gun.add_bullet_traits(list(BULLET_TRAIT_ENTRY_ID("watchtower_arc", /datum/element/bullet_trait_direct_only/watchtower)))

	for(var/obj/item/storage/storage in user)
		for(var/obj/item/weapon/gun/gun in storage.contents)
			gun.add_bullet_traits(list(BULLET_TRAIT_ENTRY_ID("watchtower_arc", /datum/element/bullet_trait_direct_only/watchtower)))

/obj/structure/watchtower/proc/item_picked_up(obj/item/picked_up_item, mob/living/carbon/human/user)
	SIGNAL_HANDLER
	if(!istype(picked_up_item, /obj/item/weapon/gun))
		return

	var/obj/item/weapon/gun/gun = picked_up_item
	gun.add_bullet_traits(list(BULLET_TRAIT_ENTRY_ID("watchtower_arc", /datum/element/bullet_trait_direct_only/watchtower)))

/obj/structure/watchtower/attack_alien(mob/living/carbon/xenomorph/xeno)
	if(get_turf(xeno) == locate(x, y-1, z) && xeno.a_intent != INTENT_HARM && xeno.mob_size < MOB_SIZE_BIG && stage >= WATCHTOWER_STAGE_COMPLETE)
		if(!do_after(xeno, 3 SECONDS, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_HOSTILE))
			return

		var/turf/actual_turf = locate(x, y+1, z)
		xeno.forceMove(actual_turf)
		on_enter(xeno)
	else if(get_turf(xeno) == locate(x, y+1, z) && xeno.a_intent != INTENT_HARM && xeno.mob_size < MOB_SIZE_BIG && stage >= WATCHTOWER_STAGE_COMPLETE)
		if(!do_after(xeno, 3 SECONDS, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_HOSTILE))
			return

		var/turf/actual_turf = locate(x, y-1, z)
		xeno.forceMove(actual_turf)
		on_leave(xeno)
	else
		xeno.animation_attack_on(src)
		playsound(src, "alien_claw_metal", 25, TRUE)
		update_health(rand(xeno.melee_damage_lower, xeno.melee_damage_upper))
		return XENO_ATTACK_ACTION

// For Mappers
/obj/structure/watchtower/stage1
	stage = WATCHTOWER_STAGE_WELDED
	icon_state = "stage1"
/obj/structure/watchtower/stage2
	stage = WATCHTOWER_STAGE_COLUMNS
	icon_state = "stage2"
/obj/structure/watchtower/stage3
	stage = WATCHTOWER_STAGE_HEIGHTNED_WRENCH
	icon_state = "stage3"
/obj/structure/watchtower/stage4
	stage = WATCHTOWER_STAGE_FLOOR
	icon_state = "stage4"
/obj/structure/watchtower/stage5
	stage = WATCHTOWER_STAGE_BARRICADED
	icon_state = "stage5"
/obj/structure/watchtower/stage6
	stage = WATCHTOWER_STAGE_ROOF_SUPPORT
	icon_state = "stage6"
/obj/structure/watchtower/complete
	stage = WATCHTOWER_STAGE_COMPLETE
	icon_state = "stage7"
