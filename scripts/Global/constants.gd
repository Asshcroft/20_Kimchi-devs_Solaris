extends Node

enum GameScene {
	WORLD,
	ASTEROID
}

const SCENE_DATA: Dictionary = {
	GameScene.WORLD: {
		"path": "uid://26vmnqx6iwuy",
		"spawn": "Spawn_World_Main"
	},
	GameScene.ASTEROID: {
		"path": "uid://b3gq1ubenyotg",
		"spawn": "Spawn_Asteroid_Start"
	}
}
