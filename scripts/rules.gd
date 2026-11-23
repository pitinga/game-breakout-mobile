extends "res://scripts/rules_base.gd"

const COLS := 9
const ROWS := 5
# Área lógica de BOARD.grow(-10) em main.gd. Toda a colisão usa pixels
# deste mesmo espaço; o desenho projeta as formas normalizadas na tela.
const FIELD_SIZE := Vector2(632.0, 750.0)
const BALL_RADIUS := 13.0
const BRICK_GAP := 3.0
const PADDLE_WIDTH := 0.24
const PADDLE_HEIGHT := 18.0
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


func _brick_rect(col: int, row: int) -> Rect2:
	return Rect2(Vector2(float(col) / COLS + BRICK_GAP / FIELD_SIZE.x, 0.1 + row * 0.076),
		Vector2(1.0 / COLS - BRICK_GAP * 2.0 / FIELD_SIZE.x, 0.065))


func _paddle_rect() -> Rect2:
	return Rect2(Vector2(paddle - PADDLE_WIDTH * 0.5, 0.93),
		Vector2(PADDLE_WIDTH, PADDLE_HEIGHT / FIELD_SIZE.y))


func _ball_hits_rect(rect: Rect2) -> bool:
	var nearest := ball.clamp(rect.position, rect.end)
	var distance_pixels := (ball - nearest) * FIELD_SIZE
	return distance_pixels.length_squared() <= BALL_RADIUS * BALL_RADIUS


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
	if ball.x < BALL_RADIUS / FIELD_SIZE.x:
		ball.x = BALL_RADIUS / FIELD_SIZE.x
		velocity.x = absf(velocity.x)
	elif ball.x > 1.0 - BALL_RADIUS / FIELD_SIZE.x:
		ball.x = 1.0 - BALL_RADIUS / FIELD_SIZE.x
		velocity.x = -absf(velocity.x)
	if ball.y < BALL_RADIUS / FIELD_SIZE.y:
		ball.y = BALL_RADIUS / FIELD_SIZE.y
		velocity.y = absf(velocity.y)
	var paddle_rect := _paddle_rect()
	if velocity.y > 0 and ball.y <= paddle_rect.end.y + BALL_RADIUS / FIELD_SIZE.y \
			and _ball_hits_rect(paddle_rect):
		ball.y = paddle_rect.position.y - BALL_RADIUS / FIELD_SIZE.y
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
	if ball.y >= 0.1 - BALL_RADIUS / FIELD_SIZE.y and ball.y < 0.48 + BALL_RADIUS / FIELD_SIZE.y:
		var hit := false
		for row in range(ROWS):
			for col in range(COLS):
				var index := row * COLS + col
				if not bricks[index]:
					continue
				# Mesma geometria do desenho: não acertar o espaço entre tijolos.
				var brick := _brick_rect(col, row)
				if not _ball_hits_rect(brick):
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
				var model := _brick_rect(x, y)
				var r := Rect2(area.position + model.position * area.size, model.size * area.size)
				canvas.draw_rect(r, Color.from_hsv(float(y) / 9.0 + 0.02, 0.6, 0.92))
	var bar_model := _paddle_rect()
	var bar := Rect2(area.position + bar_model.position * area.size, bar_model.size * area.size)
	canvas.draw_rect(bar, ACCENT)
	canvas.draw_circle(area.position + ball * area.size, BALL_RADIUS * area.size.y / FIELD_SIZE.y, INK)
	label(canvas, "Vidas: %d" % lives, area.position + Vector2(area.size.x / 2.0, 0.55 * area.size.y), 26)
