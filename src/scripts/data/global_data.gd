class_name GlobalData

enum PoolCategory {
	HITSCAN_BULLET_TRAIL,
	BULLET_PROJECTILE,
	DEFAULT_BULLET_HOLE_DECAL,
	DEFAULT_IMPACT_EFFECT,
}

enum AttackType {
	BULLET,
	MELEE,
	EXPLOSION,
}

enum BallisticModel {
	HITSCAN,
	PROJECTILE,
}

enum ConfigId {
	DEFAULT,
	ANIMATION_CONFIG,
}

enum MenuId {
	NONE,
	PAUSE_MENU,
}

enum MenuPauseOption {
	PRESERVE_CURRENT_STATE,
	PAUSE,
	UNPAUSE,
}


class Group:
	const SAVEABLE := "saveable"


enum SaveSectionId {
	DEFAULT,
	PLAYER,
	POOL,
}


const SAVE_SECTION_MAP := {
	SaveSectionId.DEFAULT : "",
	SaveSectionId.PLAYER : "player",
	SaveSectionId.POOL : "pool",
}
