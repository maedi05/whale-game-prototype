extends Node

var game_controller : GameController

var total_coins: int= 0

func coin_collected(value: int):
	total_coins += value
	EventController.coin_collected.emit(total_coins)
