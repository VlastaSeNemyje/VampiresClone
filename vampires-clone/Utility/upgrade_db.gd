extends Node

const ICON_PATH = "res://Textures/Sprites/Upgrades/"
const WEAPON_PATH = "res://Textures/Sprites/Weapons/"
const UPGRADES = {
	"arrow1": {
		"icon": WEAPON_PATH + "arrow.png",
		"displayname": "Cursed Spit",
		"details": "Cursed Spit is thrown at a random enemy",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"arrow2": {
		"icon": WEAPON_PATH + "arrow.png",
		"displayname": "Cursed Spit",
		"details": "An additional Cursed Spit is thrown",
		"level": "Level: 2",
		"prerequisite": ["arrow1"],
		"type": "weapon"
	},
	"arrow3": {
		"icon": WEAPON_PATH + "arrow.png",
		"displayname": "Cursed Spit",
		"details": "Cursed Spit now passes through another enemy and does +3 damage",
		"level": "Level: 3",
		"prerequisite": ["arrow2"],
		"type": "weapon"
	},
	"arrow4": {
		"icon": WEAPON_PATH + "arrow.png",
		"displayname": "Cursed Spit",
		"details": "An additional 2 Cursed Spits are thrown",
		"level": "Level: 4",
		"prerequisite": ["arrow3"],
		"type": "weapon"
	},
	"whip1": {
		"icon": WEAPON_PATH + "whip.png",
		"displayname": "Claws",
		"details": "Claws slash horizontally through enemies",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"whip2": {
		"icon": WEAPON_PATH + "whip.png",
		"displayname": "Claws",
		"details": "Claws get 50% stronger",
		"level": "Level: 2",
		"prerequisite": ["whip1"],
		"type": "weapon"
	},
	"whip3": {
		"icon": WEAPON_PATH + "whip.png",
		"displayname": "Claws",
		"details": "Claws get stronger",
		"level": "Level: 3",
		"prerequisite": ["whip2"],
		"type": "weapon"
	},
	"whip4": {
		"icon": WEAPON_PATH + "whip.png",
		"displayname": "Claws",
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
	"kanec1": {
		"icon": WEAPON_PATH + "Kanec.png",
		"displayname": "Forest Spirit",
		"details": "Forest Spirits run across the screen from left and right, hurting every enemy in their way",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"kanec2": {
		"icon": WEAPON_PATH + "Kanec.png",
		"displayname": "Forest Spirit",
		"details": "Forest Spirits are 50% bigger and two run from each side",
		"level": "Level: 2",
		"prerequisite": ["kanec1"],
		"type": "weapon"
	},
	"kanec3": {
		"icon": WEAPON_PATH + "Kanec.png",
		"displayname": "Forest Spirit",
		"details": "Three Forest Spirits run from each side",
		"level": "Level: 3",
		"prerequisite": ["kanec2"],
		"type": "weapon"
	},
	"kanec4": {
		"icon": WEAPON_PATH + "Kanec.png",
		"displayname": "Forest Spirit",
		"details": "A giant Forest Spirit joins in from a random side, dealing double damage",
		"level": "Level: 4",
		"prerequisite": ["kanec3"],
		"type": "weapon"
	},
	"incense1": {
		"icon": WEAPON_PATH + "Potion.png",
		"displayname": "Charming Incense",
		"details": "Drops an incense bomb near you that explodes after a short delay - lure enemies into the blast",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"incense2": {
		"icon": WEAPON_PATH + "Potion.png",
		"displayname": "Charming Incense",
		"details": "Drops two bombs and the explosion damage is increased by 25%",
		"level": "Level: 2",
		"prerequisite": ["incense1"],
		"type": "weapon"
	},
	"incense3": {
		"icon": WEAPON_PATH + "Potion.png",
		"displayname": "Charming Incense",
		"details": "Drops three bombs, the explosion area is 15% bigger and the cooldown is shorter",
		"level": "Level: 3",
		"prerequisite": ["incense2"],
		"type": "weapon"
	},
	"incense4": {
		"icon": WEAPON_PATH + "Potion.png",
		"displayname": "Charming Incense",
		"details": "The explosion leaves a lingering cloud that keeps hurting enemies and the cooldown is shorter",
		"level": "Level: 4",
		"prerequisite": ["incense3"],
		"type": "weapon"
	},
	"plague1": {
		"icon": WEAPON_PATH + "Plague.png",
		"displayname": "Plague",
		"details": "A plague projectile jumps from enemy to enemy, hurting each one it touches",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"plague2": {
		"icon": WEAPON_PATH + "Plague.png",
		"displayname": "Plague",
		"details": "Two plague projectiles are shot and damage is increased by 20%",
		"level": "Level: 2",
		"prerequisite": ["plague1"],
		"type": "weapon"
	},
	"plague3": {
		"icon": WEAPON_PATH + "Plague.png",
		"displayname": "Plague",
		"details": "Plague jumps to more enemies and the cooldown is reduced",
		"level": "Level: 3",
		"prerequisite": ["plague2"],
		"type": "weapon"
	},
	"plague4": {
		"icon": WEAPON_PATH + "Plague.png",
		"displayname": "Plague",
		"details": "Three plague projectiles are shot and the cooldown is greatly reduced",
		"level": "Level: 4",
		"prerequisite": ["plague3"],
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
		"leaf1": {
		"icon": WEAPON_PATH + "Leaf.png",
		"displayname": "Leaves",
		"details": "A ring of leaves protects you, damaging weak enemies that get close",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"leaf2": {
		"icon": WEAPON_PATH + "Leaf.png",
		"displayname": "Leaves",
		"details": "The leaves deal 2 more damage per pulse",
		"level": "Level: 2",
		"prerequisite": ["leaf1"],
		"type": "weapon"
	},
	"leaf3": {
		"icon": WEAPON_PATH + "Leaf.png",
		"displayname": "Leaves",
		"details": "The leaves pulse 0.3 seconds faster",
		"level": "Level: 3",
		"prerequisite": ["leaf2"],
		"type": "weapon"
	},
	"leaf4": {
		"icon": WEAPON_PATH + "Leaf.png",
		"displayname": "Leaves",
		"details": "Bigger area, leaves spin around you, 10% of pulses grow 30% wider",
		"level": "Level: 4",
		"prerequisite": ["leaf3"],
		"type": "weapon"
	},
	"roots1": {
		"icon": WEAPON_PATH + "Roots_icon2.png",
		"displayname": "Roots",
		"details": "Roots burst from the ground around you, crushing enemies caught in them",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"roots2": {
		"icon":  WEAPON_PATH + "Roots_icon2.png",
		"displayname": "Roots",
		"details": "2 more roots erupt each time",
		"level": "Level: 2",
		"prerequisite": ["roots1"],
		"type": "weapon"
	},
	"roots3": {
		"icon":  WEAPON_PATH + "Roots_icon2.png",
		"displayname": "Roots",
		"details": "Roots grow 40% larger",
		"level": "Level: 3",
		"prerequisite": ["roots2"],
		"type": "weapon"
	},
	"roots4": {
		"icon":  WEAPON_PATH + "Roots_icon2.png",
		"displayname": "Roots",
		"details": "3 more roots erupt each time",
		"level": "Level: 4",
		"prerequisite": ["roots3"],
		"type": "weapon"
	},
	"mycelium1": {
		"icon": WEAPON_PATH + "Mycelium.png",
		"displayname": "Mycelium Circle",
		"details": "A mushroom orbits you for 2 seconds every 5 seconds, damaging enemies it touches",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"mycelium2": {
		"icon": WEAPON_PATH + "Mycelium.png",
		"displayname": "Mycelium Circle",
		"details": "A second mushroom joins opposite the first and the circle lasts 3 seconds",
		"level": "Level: 2",
		"prerequisite": ["mycelium1"],
		"type": "weapon"
	},
	"mycelium3": {
		"icon": WEAPON_PATH + "Mycelium.png",
		"displayname": "Mycelium Circle",
		"details": "One more mushroom joins and the circle spins 20% faster",
		"level": "Level: 3",
		"prerequisite": ["mycelium2"],
		"type": "weapon"
	},
	"mycelium4": {
		"icon": WEAPON_PATH + "Mycelium.png",
		"displayname": "Mycelium Circle",
		"details": "Three more mushrooms fill the circle, it never stops and spins 10% faster",
		"level": "Level: 4",
		"prerequisite": ["mycelium3"],
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
		"details": "Your spells spawn 1 more attack (Claws swing again, Leaves grow 20% wider)",
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
