extends "res://scripts/rules_base.gd"

const COLS := 9
const ROWS := 5
const BALL_RADIUS := 0.021
var bricks: Array[bool] = []
var ball := Vector2(0.5, 0.7)
var velocity := Vector2(0.37, -0.48)
var paddle := 0.5
var lives := 3


func _init() -> void:
	title = "Breakout"
	subtitle = "Destrua os blocos com a bola"


func reset() -> void:
	super.reset()
	bricks.resize(COLS * ROWS)
	bricks.fill(true)
	ball = Vector2(0.5, 0.7)
	velocity = Vector2(0.37, -0.48)
	paddle = 0.5
	lives = 3


func pointer(p: Vector2) -> void:
	paddle = clampf(p.x, 0.12, 0.88)


func tap(p: Vector2) -> void:
	pointer(p)


func swipe(_a: Vector2, b: Vector2) -> void:
	pointer(b)


func tick(delta: float) -> void:
	# Bounded substeps reduce tunnelling when frames are delayed.
	var count := maxi(1, int(ceil(delta / 0.008)))
	for i in range(count):
		_advance(delta / float(count))
		if ended:
			break


func _advance(dt: float) -> void:
	ball += velocity * dt
	if ball.x < 0.025:
		ball.x = 0.025
		velocity.x = absf(velocity.x)
	elif ball.x > 0.975:
		ball.x = 0.975
		velocity.x = -absf(velocity.x)
	if ball.y < 0.025:
		ball.y = 0.025
		velocity.y = absf(velocity.y)
	if velocity.y > 0 and ball.y >= 0.91 and ball.y < 0.95 and absf(ball.x - paddle) <= 0.14:
		ball.y = 0.91
		velocity.y = -absf(velocity.y)
		velocity.x = (ball.x - paddle) * 3.1
		velocity = velocity.normalized() * minf(0.97, 0.62 + score * 0.002)
	if ball.y > 1.02:
		lives -= 1
		ball = Vector2(0.5, 0.7)
		velocity = Vector2(0.32, -0.55)
		if lives <= 0:
			ended = true
			message = "Fim de jogo"
		return
	if ball.y >= 0.1 - BALL_RADIUS and ball.y < 0.48 + BALL_RADIUS:
		var hit := false
		for row in range(ROWS):
			for col in range(COLS):
				var index := row * COLS + col
				if not bricks[index]:
					continue
				# Mesma geometria do desenho: não acertar o espaço entre tijolos.
				var brick := Rect2(Vector2(float(col) / COLS + 3.0 / 632.0, 0.1 + row * 0.076), Vector2(1.0 / COLS - 6.0 / 632.0, 0.065))
				var nearest := ball.clamp(brick.position, brick.end)
				if ball.distance_squared_to(nearest) > BALL_RADIUS * BALL_RADIUS:
					continue
				bricks[index] = false
				score += 10
				if ball.x < brick.position.x or ball.x > brick.end.x:
					velocity.x = -velocity.x
				else:
					velocity.y = -velocity.y
				hit = true
				if not bricks.has(true):
					ended = true
					message = "Todos os blocos!"
				break
			if hit:
				break


func draw_game(canvas: CanvasItem, area: Rect2) -> void:
	canvas.draw_rect(area, Color("eaf2ff"))
	for y in range(ROWS):
		for x in range(COLS):
			if bricks[y * COLS + x]:
				var r := Rect2(area.position + Vector2(x * area.size.x / COLS + 3, area.size.y * (0.1 + y * 0.076)), Vector2(area.size.x / COLS - 6, area.size.y * 0.065))
				canvas.draw_rect(r, Color.from_hsv(float(y) / 9.0 + 0.02, 0.6, 0.92))
	var bar := Rect2(area.position + Vector2((paddle - 0.12) * area.size.x, 0.93 * area.size.y), Vector2(area.size.x * 0.24, 18))
	canvas.draw_rect(bar, ACCENT)
	canvas.draw_circle(area.position + ball * area.size, 13.0, INK)
	label(canvas, "Vidas: %d" % lives, area.position + Vector2(area.size.x / 2.0, 0.55 * area.size.y), 26)
