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
	game.reset()
	game.ball = Vector2(0.5, 0.07)
	game.velocity = Vector2.ZERO
	game._advance(0.0)
	check(game.bricks.count(false) == 0, "bola distante não destrói bloco")
	game.ball = Vector2(0.50, 0.09)
	game._advance(0.0)
	check(game.bricks.count(false) == 1, "borda da bola encosta no tijolo")
	# A geometria dos alvos vem das mesmas formas usadas no draw_game.
	var brick: Rect2 = game._brick_rect(4, 0)
	var half_y := brick.position.y + brick.size.y * 0.5
	game.ball = Vector2(brick.position.x - (game.BALL_RADIUS - 0.01) / game.FIELD_SIZE.x, half_y)
	check(game._ball_hits_rect(brick), "tangência lateral na face desenhada do tijolo")
	game.ball.x -= 0.2 / game.FIELD_SIZE.x
	check(not game._ball_hits_rect(brick), "0,2 px fora da face não acerta tijolo")
	game.ball = Vector2(brick.position.x + brick.size.x * 0.5, brick.position.y - (game.BALL_RADIUS - 0.01) / game.FIELD_SIZE.y)
	check(game._ball_hits_rect(brick), "tangência superior no tijolo respeita altura real")
	game.ball = brick.position - Vector2(9.3 / game.FIELD_SIZE.x, 9.3 / game.FIELD_SIZE.y)
	check(not game._ball_hits_rect(brick), "canto diagonal a 13,15 px não gera colisão prematura")
	game.ball = brick.position - Vector2(9.0 / game.FIELD_SIZE.x, 9.0 / game.FIELD_SIZE.y)
	check(game._ball_hits_rect(brick), "canto diagonal a 12,73 px entra no raio visível")
	game.paddle = 0.5
	var paddle_rect: Rect2 = game._paddle_rect()
	check(is_equal_approx(paddle_rect.position.y, 0.93) and is_equal_approx(paddle_rect.size.y * game.FIELD_SIZE.y, 18.0), "raquete compartilha posição e altura entre física e desenho")
	game.ball = Vector2(0.5, paddle_rect.position.y - game.BALL_RADIUS / game.FIELD_SIZE.y)
	check(game._ball_hits_rect(paddle_rect), "bola toca exatamente o topo visível da raquete")
	game.ball.y -= 0.2 / game.FIELD_SIZE.y
	check(not game._ball_hits_rect(paddle_rect), "espaço de 0,2 px acima da raquete não rebate")
	finish()


func finish() -> void:
	print("Breakout: %s" % ("OK" if failures == 0 else "%d falhas" % failures))
	quit(0 if failures == 0 else 1)
