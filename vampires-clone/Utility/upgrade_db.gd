extends Node

const ICON_PATH = "res://Textures/Sprites/Upgrades/"
const WEAPON_PATH = "res://Textures/Sprites/Weapons/"
const UPGRADES = {
	"arrow1": {
		"icon": WEAPON_PATH + "Arrow.png",
		"displayname": "Arrow",
		"details": "An enchanted arrow piercing a random enemy",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
		"arrow2": {
		"icon": WEAPON_PATH + "Arrow.png",
		"displayname": "Arrow",
		"details": "An additional arrow is fired",
		"level": "Level: 2",
		"prerequisite": ["arrow1"],
		"type": "weapon"
	},
		"A Thing": {
		"icon": ICON_PATH + "Up1.png",
		"displayname": "A thing",
		"details": "Heals for 20 HP",
		"level": "N/A",
		"prerequisite": [],
		"type": "item"
	},
}
