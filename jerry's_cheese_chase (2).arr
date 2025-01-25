use context starter2024
import image as I
import reactors as R

#------------------------------------------------------------
# GAME CONSTANTS AND CONFIGURATIONS
#------------------------------------------------------------
# Screen dimensions
WIDTH = 800
HEIGHT = 500

# Movement and gameplay constants
KEY_DISTANCE = 20
ITEM-SPAWN-RATE = 0.1  # chance to spawn an item per tick
MAX_ITEMS = 6  # Maximum number of items allowed on screen

# Speed configurations for falling items
MIN-CHEESE-SPEED = 8
MAX-CHEESE-SPEED = 10
MIN-BOMB-SPEED = 10
MAX-BOMB-SPEED = 12

#------------------------------------------------------------
# IMAGE LOADING AND SCALING
#------------------------------------------------------------
# Load and scale kitchen background
kitchenn = image-url("https://code.pyret.org/shared-image-contents?sharedImageId=14wVZaWulTIbO3x0tYEWYuDHoteMhATGk")
kitchen = I.scale(0.65, kitchenn)
BACKGROUND = kitchen

# Load and scale Jerry character
jerryy = image-url("https://code.pyret.org/shared-image-contents?sharedImageId=1eDhaN2THNThJftJKqcKJAoFrlAAZwxwi")
jerry = I.scale(0.6, jerryy)

# Load and scale bomb obstacle
bombb = image-url("https://code.pyret.org/shared-image-contents?sharedImageId=1okFQ_RtIRTvPYKAng9o-ImyrE5Ali_DU")
bomb = I.scale(0.125, bombb)

# Load and scale cheese collectible
cheesee = image-url("https://code.pyret.org/shared-image-contents?sharedImageId=137j_szw2jHbVAfjxOyO4JbHPSTiUuexJ")
cheese = I.scale(0.13, cheesee)

explosionn = image-url("https://code.pyret.org/shared-image-contents?sharedImageId=1Ah3ZrDCXya_ysGPUS2ghnfHVe6fp8agg")
explosion = I.scale(0.55, explosionn)

#------------------------------------------------------------
# DATA DEFINITIONS
#------------------------------------------------------------
# Position data structure for tracking coordinates
data Posn:
  | posn(x, y)
end

# Structure for falling items (cheese and bombs)
data FallingItem:
  | falling-item(pos :: Posn, speed :: Number, kind :: String)
end

# Game world state structure
data World:
  | world(
      pos :: Posn,          # Jerry's position
      items :: List<FallingItem>,  # List of active falling items
      score :: Number,      # Current score
      is-game-over :: Boolean,  # Game over state
      is-start-screen :: Boolean,  # Start screen state
      exploded :: Boolean   # New field to track explosion state
    )
end

#------------------------------------------------------------
# ITEM GENERATION AND MANAGEMENT
#------------------------------------------------------------
# Calculate speed multiplier based on score for difficulty progression
fun calculate-speed-multiplier(score :: Number) -> Number:
  doc: "Increases game difficulty by returning a multiplier based on score"
  1 + (score / 20)  # Speed increases every 20 points
end

# Create new falling items (cheese or bombs)
fun create-item(score :: Number):
  doc: "Generates a new falling item with position, speed, and type based on current score"
  is-bomb = num-random(100) < (30 + (score / 10))  # Bomb probability increases with score
  speed-mult = calculate-speed-multiplier(score)
  
  if is-bomb:
    falling-item(
      posn(num-random(WIDTH), 0),
      (num-random(MAX-BOMB-SPEED - MIN-BOMB-SPEED) + MIN-BOMB-SPEED) * speed-mult,
      "bomb"
    )
  else:
    falling-item(
      posn(num-random(WIDTH), 0),
      (num-random(MAX-CHEESE-SPEED - MIN-CHEESE-SPEED) + MIN-CHEESE-SPEED) * speed-mult,
      "cheese"
    )
  end
end

#------------------------------------------------------------
# ITEM MOVEMENT AND UPDATES
#------------------------------------------------------------
# Update item position based on its speed
fun update-item(item :: FallingItem):
  doc: "Updates the position of a falling item based on its speed"
  falling-item(
    posn(item.pos.x, item.pos.y + item.speed),
    item.speed,
    item.kind
  )
end

# Check if item is still within game bounds
fun item-active(item :: FallingItem):
  doc: "Determines if an item is still within the game screen"
  item.pos.y < HEIGHT
end

# Generate new items if conditions are met
fun maybe-spawn-item(items :: List<FallingItem>, score :: Number):
  doc: "Potentially spawns a new item based on probability and maximum item limit"
  if (num-random(100) < (ITEM-SPAWN-RATE * 100)) and (items.length() < MAX_ITEMS):
    link(create-item(score), items)
  else:
    items
  end
end

# Update all active items
fun update-items(items :: List<FallingItem>):
  doc: "Updates positions of all active items and removes out-of-bounds items"
  filter(item-active, map(update-item, items))
end

#------------------------------------------------------------
# SCREEN DRAWING FUNCTIONS
#------------------------------------------------------------
# Draw the start screen
fun draw-start-screen(scene):
  doc: "Creates and draws the game's start screen with title and instructions"
  title-box = I.rectangle(600, 100, "solid", "lightyellow")
  title-text = I.text("JERRY'S CHEESE CHASE", 48, "red")
  play-button = I.rectangle(190, 60, "solid", "white")
  play-text = I.text("PLAY", 36, "black")
  instructions-text = I.text("Use LEFT and RIGHT arrows to move", 24, "black")
  
  # Layer all elements
  scene-with-title-box = I.place-image(title-box, WIDTH / 2, HEIGHT / 3, scene)
  scene-with-title = I.place-image(title-text, WIDTH / 2, HEIGHT / 3, scene-with-title-box)
  scene-with-button = I.place-image(play-button, WIDTH / 2, (HEIGHT / 2) + 25, scene-with-title)
  scene-with-play = I.place-image(play-text, WIDTH / 2, (HEIGHT / 2) + 25, scene-with-button)
  
  I.place-image(instructions-text, WIDTH / 2, (HEIGHT / 2) + 160, scene-with-play)
end

# Draw the game over screen
fun draw-game-over(scene, w :: World):
  doc: "Creates and draws the game over screen with final score"
  game-over-box = I.rectangle(400, 200, "solid", "white")
  game-over-text = I.text("GAME OVER", 48, "red")
  final-score-text = I.text("Final Score: " + num-to-string(w.score), 36, "black")
  
  scene-with-box = I.place-image(game-over-box, WIDTH / 2, HEIGHT / 2, scene)
  scene-with-text = I.place-image(game-over-text, WIDTH / 2, (HEIGHT / 2) - 30, scene-with-box)
  I.place-image(final-score-text, WIDTH / 2, (HEIGHT / 2) + 30, scene-with-text)
end

#------------------------------------------------------------
# MAIN DRAWING FUNCTION
#------------------------------------------------------------
# Place Jerry and all game elements on screen
fun place-jerry(w :: World):
  doc: "Main drawing function that handles all game states and elements"
  if w.is-start-screen:
    draw-start-screen(BACKGROUND)
  else:
    # Create and place score display
    score-box = I.rectangle(120, 40, "solid", "white")
    score-label = I.text("SCORE: " + num-to-string(w.score), 24, "black")
    scene-with-box = I.place-image(score-box, 80, 30, BACKGROUND)
    scene-with-score = I.place-image(score-label, 80, 30, scene-with-box)
    
    # Place Jerry or Explosion
    scene-with-character = 
      if w.exploded:
        I.place-image(explosion, w.pos.x, HEIGHT - 27, scene-with-score)
      else:
        I.place-image(jerry, w.pos.x, HEIGHT - 27, scene-with-score)
      end
    
    # Draw all falling items (except bombs when exploded)
    fun place-single-item(scene, item :: FallingItem):
      if w.exploded and (item.kind == "bomb"):
        scene  # Skip drawing bombs during explosion
      else:
        image-to-place = if item.kind == "bomb": bomb else: cheese end
        I.place-image(image-to-place, item.pos.x, item.pos.y, scene)
      end
    end
    
    scene-with-items = fold(place-single-item, scene-with-character, w.items)
    
    if w.is-game-over:
      draw-game-over(scene-with-items, w)
    else:
      scene-with-items
    end
  end
end

#------------------------------------------------------------
# COLLISION DETECTION
#------------------------------------------------------------
# Calculate distance between two positions
fun distance(pos1 :: Posn, pos2 :: Posn) -> Number:
  doc: "Calculates Euclidean distance between two positions"
  num-sqrt(num-sqr(pos1.x - pos2.x) + num-sqr(pos1.y - pos2.y))
end

# Check for collision between Jerry and an item
fun check-collision(jerry-pos :: Posn, item :: FallingItem) -> Boolean:
  doc: "Determines if Jerry has collided with a falling item"
  jerry-y = HEIGHT - 27
  distance(jerry-pos, posn(item.pos.x, item.pos.y)) < 30
end

#------------------------------------------------------------
# GAME UPDATE FUNCTIONS
#------------------------------------------------------------
# Update game world state
fun update-world(w :: World):
  doc: "Main game update function handling all game logic"
  if w.is-start-screen:
    w
  else if w.is-game-over:
    w
  else:
    jerry-pos = w.pos
    colliding-items = filter(
      lam(item): check-collision(jerry-pos, item) end,
      w.items
    )
    
    colliding-bombs = filter(
      lam(item): item.kind == "bomb" end,
      colliding-items
    )
    
    if not(is-empty(colliding-bombs)):
      world(w.pos, w.items, w.score, true, false, true)  # Set exploded to true
    else:
      collected = length(filter(lam(item): item.kind == "cheese" end, colliding-items))
      active-items = filter(
        lam(item): not(check-collision(jerry-pos, item)) end,
        w.items
      )
      
      world(
        w.pos,
        update-items(maybe-spawn-item(active-items, w.score)),
        w.score + collected,
        false,
        false,
        false
      )
    end
  end
end

#------------------------------------------------------------
# INPUT HANDLING
#------------------------------------------------------------
# Handle mouse input for start screen
fun handle-mouse(w :: World, x :: Number, y :: Number, event :: String):
  doc: "Handles mouse input, primarily for the start screen play button"
  if w.is-start-screen and (event == "button-down"):
    if (x >= ((WIDTH / 2) - 100)) and (x <= ((WIDTH / 2) + 100)) and
       (y >= ((HEIGHT / 2) - 40)) and (y <= ((HEIGHT / 2) + 40)):
      world(posn(WIDTH / 2, HEIGHT - 27), empty, 0, false, false, false)  # Start the game
    else:
      w
    end
  else:
    w
  end
end

# Handle keyboard input for Jerry's movement
fun alter-jerry-on-key(w :: World, key):
  doc: "Handles keyboard input for moving Jerry left and right"
  if w.is-start-screen or w.is-game-over:
    w
  else:
    ask:
      | key == "left" then:
        if (w.pos.x - KEY_DISTANCE) > 0:
          world(posn(w.pos.x - KEY_DISTANCE, w.pos.y), w.items, w.score, false, false, w.exploded)
        else:
          w
        end
      | key == "right" then:
        if (w.pos.x + KEY_DISTANCE) < WIDTH:
          world(posn(w.pos.x + KEY_DISTANCE, w.pos.y), w.items, w.score, false, false, w.exploded)
        else:
          w
        end
      | otherwise: w
    end
  end
end

#------------------------------------------------------------
# GAME INITIALIZATION AND SETUP
#------------------------------------------------------------
# Create and start the game reactor
anim = reactor:
  init: world(
    posn(WIDTH / 2, HEIGHT - 27),  # Start Jerry in the middle
    empty,                         # Start with no items
    0,                            # Initial score
    false,                        # Game not over
    true,                         # Start on start screen
    false                         # Not exploded initially
  ),
  on-tick: update-world,
  on-key: alter-jerry-on-key,
  on-mouse: handle-mouse,
  to-draw: place-jerry
end

# Start the game
R.interact(anim)