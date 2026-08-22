extends Node

const ICON_PATH = "res://Textures/Sprites/Upgrades/"
const WEAPON_PATH = "res://Textures/Sprites/Weapons/"
const UPGRADES = {
	"arrow1": {
		"icon": WEAPON_PATH + "arrow.png",
		"displayname": "Arrow",
		"details": "A spear of ice is thrown at a random enemy",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"arrow2": {
		"icon": WEAPON_PATH + "arrow.png",
		"displayname": "Arrow",
		"details": "An addition Arrow is thrown",
		"level": "Level: 2",
		"prerequisite": ["arrow1"],
		"type": "weapon"
	},
	"arrow3": {
		"icon": WEAPON_PATH + "arrow.png",
		"displayname": "Arrow",
		"details": "Arrows now pass through another enemy and do + 3 damage",
		"level": "Level: 3",
		"prerequisite": ["arrow2"],
		"type": "weapon"
	},
	"arrow4": {
		"icon": WEAPON_PATH + "arrow.png",
		"displayname": "Arrow",
		"details": "An additional 2 Arrows are thrown",
		"level": "Level: 4",
		"prerequisite": ["arrow3"],
		"type": "weapon"
	},
	"whip1": {
		"icon": WEAPON_PATH + "whip.png",
		"displayname": "whip",
		"details": "A horizontal whip, slashing thrue enemies",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"whip2": {
		"icon": WEAPON_PATH + "whip.png",
		"displayname": "whip",
		"details": "Whip gets 50% stronger",
		"level": "Level: 2",
		"prerequisite": ["whip1"],
		"type": "weapon"
	},
	"whip3": {
		"icon": WEAPON_PATH + "whip.png",
		"displayname": "whip",
		"details": "Whip gets stronger",
		"level": "Level: 3",
		"prerequisite": ["whip2"],
		"type": "weapon"
	},
	"whip4": {
		"icon": WEAPON_PATH + "whip.png",
		"displayname": "whip",
		"details": "Knockback is incresed by 25%",
		"level": "Level: 4",
		"prerequisite": ["whip3"],
		"type": "weapon"
	},
	"falcon1": {
		"icon": WEAPON_PATH + "falcon_3_new_attack.png",
		"displayname": "falcon",
		"details": "A magical falcon will follow you attacking enemies in a straight line",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"falcon2": {
		"icon": WEAPON_PATH + "falcon_3_new_attack.png",
		"displayname": "falcon",
		"details": "The falcon will now attack an additional enemy per attack",
		"level": "Level: 2",
		"prerequisite": ["falcon1"],
		"type": "weapon"
	},
	"falcon3": {
		"icon": WEAPON_PATH + "falcon_3_new_attack.png",
		"displayname": "falcon",
		"details": "The falcon will attack another additional enemy per attack",
		"level": "Level: 3",
		"prerequisite": ["falcon2"],
		"type": "weapon"
	},
	"falcon4": {
		"icon": WEAPON_PATH + "falcon_3_new_attack.png",
		"displayname": "falcon",
		"details": "The falcon now does + 5 damage per attack and causes 20% additional knockback",
		"level": "Level: 4",
		"prerequisite": ["falcon3"],
		"type": "weapon"
	},
	"tornado1": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "Tornado",
		"details": "A tornado is created and random heads somewhere in the players direction",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"tornado2": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "Tornado",
		"details": "An additional Tornado is created",
		"level": "Level: 2",
		"prerequisite": ["tornado1"],
		"type": "weapon"
	},
	"tornado3": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "Tornado",
		"details": "The Tornado cooldown is reduced by 0.5 seconds",
		"level": "Level: 3",
		"prerequisite": ["tornado2"],
		"type": "weapon"
	},
	"tornado4": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "Tornado",
		"details": "An additional tornado is created and the knockback is increased by 25%",
		"level": "Level: 4",
		"prerequisite": ["tornado3"],
		"type": "weapon"
	},
	"armor1": {
		"icon": ICON_PATH + "armor.png",
		"displayname": "Armor",
		"details": "Reduces Damage By 1 point",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"armor2": {
		"icon": ICON_PATH + "armor.png",
		"displayname": "Armor",
		"details": "Reduces Damage By an additional 1 point",
		"level": "Level: 2",
		"prerequisite": ["armor1"],
		"type": "upgrade"
	},
	"armor3": {
		"icon": ICON_PATH + "armor.png",
		"displayname": "Armor",
		"details": "Reduces Damage By an additional 1 point",
		"level": "Level: 3",
		"prerequisite": ["armor2"],
		"type": "upgrade"
	},
	"armor4": {
		"icon": ICON_PATH + "armor.png",
		"displayname": "Armor",
		"details": "Reduces Damage By an additional 1 point",
		"level": "Level: 4",
		"prerequisite": ["armor3"],
		"type": "upgrade"
	},
	"speed1": {
		"icon": ICON_PATH + "Speed.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased by 50% of base speed",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"speed2": {
		"icon": ICON_PATH + "Speed.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased by an additional 50% of base speed",
		"level": "Level: 2",
		"prerequisite": ["speed1"],
		"type": "upgrade"
	},
	"speed3": {
		"icon": ICON_PATH + "Speed.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased by an additional 50% of base speed",
		"level": "Level: 3",
		"prerequisite": ["speed2"],
		"type": "upgrade"
	},
	"speed4": {
		"icon": ICON_PATH + "Speed.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased an additional 50% of base speed",
		"level": "Level: 4",
		"prerequisite": ["speed3"],
		"type": "upgrade"
	},
	"tome1": {
		"icon": ICON_PATH + "Area.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"tome2": {
		"icon": ICON_PATH + "Area.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 2",
		"prerequisite": ["tome1"],
		"type": "upgrade"
	},
	"tome3": {
		"icon": ICON_PATH + "Area.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 3",
		"prerequisite": ["tome2"],
		"type": "upgrade"
	},
	"tome4": {
		"icon": ICON_PATH + "Area.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 4",
		"prerequisite": ["tome3"],
		"type": "upgrade"
	},
	"scroll1": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"scroll2": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 2",
		"prerequisite": ["scroll1"],
		"type": "upgrade"
	},
	"scroll3": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 3",
		"prerequisite": ["scroll2"],
		"type": "upgrade"
	},
	"scroll4": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 4",
		"prerequisite": ["scroll3"],
		"type": "upgrade"
	},
	"ring1": {
		"icon": ICON_PATH + "Ring.png",
		"displayname": "Ring",
		"details": "Your spells now spawn 1 more additional attack",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"ring2": {
		"icon": ICON_PATH + "Ring.png",
		"displayname": "Ring",
		"details": "Your spells now spawn an additional attack",
		"level": "Level: 2",
		"prerequisite": ["ring1"],
		"type": "upgrade"
	},
	"food": {
		"icon": ICON_PATH + "food.png",
		"displayname": "Food",
		"details": "Heals you for 20 health",
		"level": "N/A",
		"prerequisite": [],
		"type": "item"
	}
}
