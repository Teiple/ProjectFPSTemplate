class_name AnimationConfig

const config : Dictionary = {
		# Events to trigger transition of animations inside player's view model animation tree
		"events" : {
			# local_animation_transition_subscribers is used for transitions within a specific weapon animation set
			# global_animation_transition_target is used for transitions between multiple weapons. Specifically when switching from one weapon to another
			"equip": {
				"local_animation_transition_subscribers": [],
				"global_animation_transition_target": "equip",
			},
			"fire": {
				"local_animation_transition_subscribers": [
					"idle/fire", "fire/fire", "equip/fire"
				],
				"global_animation_transition_target": "fire",
			},
			"reload": {
				"local_animation_transition_subscribers": [
					"idle/reload", "fire/reload"
				],
				"global_animation_transition_target": "",
			},
			# Note: This doesn't mean that transition from any state to idle is immediate
			# But rather if this event is ever used, it is aimed to get a instant result
			# Usecase: Loading a save
			"idle": {
				"local_animation_transition_subscribers": [
					"(any_state_immediate)/idle"
				],
				"global_animation_transition_target": "idle",
			}
		},
		# Configuration for building animation statemachines for player's view model and weapons 
		"state_machine" : {
			"saving_directory": {
				"player": "res://src/resources/player",
				"weapon": "res://src/resources/weapon",
			},
			"saving_name": {
				"player": "player_$(weapon_id)_state_machine.tres",
				"weapon": "$(weapon_id)_state_machine.tres",
			},
			# There should be only one at_end transition for each animation
			"animations": {
				"equip": {
					"pos": Vector2(-200, 0),
					"transitions": [
						{ "to": "unequip", "mode": "immediate" },
						{ "to": "idle", "mode": "at_end" },
						{ "to": "fire", "mode": "immediate" },
						{ "to": "reload", "mode": "immediate" },
					],
					"autostart" : false,
				},
				"unequip": {
					"pos": Vector2(0, 100),
					"transitions": [
						{ "to": "equip", "mode": "immediate" },
						{ "to": "idle", "mode": "immediate" },
						{ "to": "fire", "mode": "immediate" },
						{ "to": "reload", "mode": "immediate" },
					],
					"autostart" : false,
				},
				"idle": {
					"pos": Vector2(-100, 0),
					"transitions": [
						{ "to": "equip", "mode": "immediate" },
						{ "to": "unequip", "mode": "immediate" },
						{ "to": "fire", "mode": "immediate" },
						{ "to": "reload", "mode": "immediate" },
					],
					"autostart" : false,
				},
				"fire": {
					"pos": Vector2(100, 0),
					"transitions": [
						{ "to": "equip", "mode": "immediate" },
						{ "to": "idle", "mode": "at_end" },
						{ "to": "unequip", "mode": "immediate" },
						{ "to": "reload", "mode": "immediate" },
						{ "to": "fire", "mode": "immediate"},
					],
					"autostart" : false,
				},
				"reload": {
					"pos": Vector2(0, -100),
					"transitions": [
						{ "to": "idle", "mode": "at_end" },
						{ "to": "equip", "mode": "immediate" },
						{ "to": "unequip", "mode": "immediate" },
						{ "to": "fire", "mode": "immediate" },
					],
					"autostart" : false,
				}
			}
		},
		# Replace player view model's AnimationPlayer with a custom one with timed callbacks
		"animation_player": {
			"saving_directory": "res://src/resources/player",
			"saving_name": "view_model_override_animation_player.scn"
		},
		# Most weapons won't have an animation for every view model's animation,
		# some animations won't require them to change at all (eg. idle, equip, unequip, etc.)
		# This config specifies which animations their state machines should fall back to
		# Use "_" for default fallback
		"animation_fallbacks": {
			"pistol": {
				"equip": "default",
				"unequip": "default",
				"idle": "default",
			},
			"smg": {
				"equip": "default",
				"unequip": "default",
				"idle": "default",
				"fire": "default",
				"reload": "default",
			},
		}
	}
