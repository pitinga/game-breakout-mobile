extends SceneTree

const Rules := preload("res://scripts/rules.gd")
var failures := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)


func _initialize() -> void:
	var game = Rules.new()
	game.reset()
	check(game.bricks.size() == 45 and game.lives == 3, "45 blocos e 3 vidas")
	game.pointer(Vector2(-1, 0))
	check(game.paddle >= 0.12, "raquete limitada à esquerda")
	game.pointer(Vector2(2, 0))
	check(game.paddle <= 0.88, "raquete limitada à direita")
	game.paddle = 0.5
	game.ball = Vector2(0.5, 0.905)
	game.velocity = Vector2(0, 0.5)
	game._advance(0.02)
	check(game.velocity.y < 0, "colisão com raquete inverte vertical")
	game.ball = Vector2(0.5, 0.16)
	game.velocity = Vector2(0, -0.5)
	game._advance(0.01)
	check(game.score == 10 and game.bricks.count(false) == 1, "bloco destruído")
	game.ball = Vector2(0.9, 1.03)
	game.velocity = Vector2(0, 0.5)
	game._advance(0.02)
	check(game.lives == 2, "bola perdida remove vida")
	finish()


func finish() -> void:
	print("Breakout: %s" % ("OK" if failures == 0 else "%d falhas" % failures))
	quit(0 if failures == 0 else 1)
