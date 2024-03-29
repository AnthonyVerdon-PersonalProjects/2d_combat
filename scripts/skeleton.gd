extends CharacterBody2D

const SPEED = 2500.0
const HEALTH_MAX = 100
const JUMP_HEIGHT: float  = 200
const JUMP_TIME_TO_PEAK: float = 0.4
const JUMP_TIME_TO_DESCENT: float = 0.5
const JUMP_VELOCITY: float = (2.0 * JUMP_HEIGHT) / JUMP_TIME_TO_PEAK * -1.0
const JUMP_GRAVITY: float = (-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_PEAK * JUMP_TIME_TO_PEAK) * -1.0
const FALL_GRAVITY: float = (-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_DESCENT * JUMP_TIME_TO_DESCENT) * -1.0

@onready var animatedSprite2D = $AnimatedSprite2D
@onready var hitbox = $CollisionShape2D
@onready var weaponHitBoxFrame6 = $weapon/hitBoxFrame6
@onready var weaponHitBoxFrame7 = $weapon/hitBoxFrame7
@onready var healthBar = $statisticsBars/healthBar

var playerInstance = null
var playerType
var health: int = HEALTH_MAX
var isDead: bool = false
var latestAnimationEnded : bool = true
var direction: int = 1
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var protected: bool = false

enum PLAYER{
  MELEE,
  RANGE
}

func _ready() -> void:
	healthBar.value = health

func _process(delta: float) -> void:
	if (isDead):
		return
	
	findPlayer()
	if (latestAnimationEnded):
		get_node("weapon/hitBoxFrame6").set_deferred("disabled", true)
		get_node("weapon/hitBoxFrame7").set_deferred("disabled", true)
		protected = false
		if (playerInstance == null || playerInstance.getIsDead()):
			chill(delta)
			return 
		var distanceToPlayer: float = calculateDistance(playerInstance.position, position);
		if (distanceToPlayer >= 350.0):
			chill(delta)
		else:
			attackPlayer(delta, distanceToPlayer)
	elif (animatedSprite2D.animation == "attack"):
		match animatedSprite2D.frame:
			6:
				get_node("weapon/hitBoxFrame6").set_deferred("disabled", false)
			7:
				get_node("weapon/hitBoxFrame6").set_deferred("disabled", true)
				get_node("weapon/hitBoxFrame7").set_deferred("disabled", false)
			_:
				get_node("weapon/hitBoxFrame6").set_deferred("disabled", true)
				get_node("weapon/hitBoxFrame7").set_deferred("disabled", true)

func findPlayer() -> void:
	if (playerInstance != null):
		return
	if (get_tree().root.has_node("Node2D/medevialWarrior")):
		playerInstance = get_tree().root.get_node("Node2D/medevialWarrior")
		playerType = PLAYER.MELEE
		return
	if (get_tree().root.has_node("Node2D/archer")):
		playerInstance = get_tree().root.get_node("Node2D/archer")
		playerType = PLAYER.RANGE
		return

func calculateDistance(positionA: Vector2, positionB: Vector2) -> float:
	return (sqrt(pow(positionB.x - positionA.x, 2) + pow(positionB.y - positionA.y, 2)))

func attackPlayer(delta: float, distanceToPlayer: float) -> void:
	if (distanceToPlayer > 100):
		move(delta)
	else:
		fightPlayer()
	
func move(delta: float) -> void:
	var newDirection: int
	if (position.x - playerInstance.position.x > 0):
		newDirection = -1
	else:
		newDirection = 1
	if (newDirection != direction):
			animatedSprite2D.flip_h = !animatedSprite2D.flip_h
			weaponHitBoxFrame6.scale.x = -weaponHitBoxFrame6.scale.x
			weaponHitBoxFrame7.scale.x = -weaponHitBoxFrame7.scale.x
			direction = newDirection
	animatedSprite2D.play("walk")
	velocity.x = direction * SPEED
	velocity.y = FALL_GRAVITY
	velocity = velocity * delta
	move_and_slide()

func fightPlayer() -> void:
	#idea : the lower the health of the enemy is, the slower he will take decision
	var random = rng.randi_range(0, 1)
	match random:
		0:
			attack()
		1:
			shield()

func attack() -> void:
	animatedSprite2D.play("attack")
	latestAnimationEnded = false;

func shield() -> void:
	animatedSprite2D.play("shield")
	protected = true;
	latestAnimationEnded = false;
	
func chill(delta: float) -> void:
	animatedSprite2D.play("idle")
	velocity.x = 0
	velocity.y = FALL_GRAVITY
	velocity = velocity * delta
	move_and_slide()
	
func takeDamage() -> void:
	#idea : add a parameter "attackDirection", and if the enemy is protected and face the good direction, he protect himself
	if (isDead || protected):
		return ;
	health -= 10;
	healthBar.value = health
	if (health <= 0):
		die();
	else:
		animatedSprite2D.play("takeDamage");
		latestAnimationEnded = false

func die() -> void:
	animatedSprite2D.play("death");
	isDead = true;
	get_node("CollisionShape2D").set_deferred("disabled", true)
	
func _on_animated_sprite_2d_animation_finished():
	latestAnimationEnded = true;


func _on_weapon_body_entered(body):
	if (body.is_in_group("player")):
		body.takeDamage()
