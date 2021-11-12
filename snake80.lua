-- title:  Snake80
-- author: Aleksandr Hovhannisyan
-- desc:   Snake! Eat food to grow. Avoid colliding with your own body.
-- script: lua

-- Some of the logic was borrowed from the official TIC-80 Snake clone tutorial:
-- https://github.com/nesbox/TIC-80/wiki/Snake-Clone-tutorial

SCREEN={
  WIDTH=30,
  HEIGHT=17
}

SPRITE={
  SNAKE=256,
  FOOD=272
}

BUTTON={
  UP=0,
  DOWN=1,
  LEFT=2,
  RIGHT=3
}

SFX={
  EAT=2
}

COLOR={
  -- white
  BG=15,
  -- black
  FG=0
}

function init()
  Game={
    t=0,
    score=0,
    paused=false
  }
  Dirs={
    [BUTTON.UP]   = {x= 0, y=-1},
    [BUTTON.DOWN] = {x= 0, y= 1},
    [BUTTON.LEFT] = {x=-1, y= 0},
    [BUTTON.RIGHT]= {x= 1, y= 0}
  }
 Snake={
    -- initially moving left
    dirIndex = BUTTON.LEFT,
    dir      = Dirs[BUTTON.LEFT],
    body={
      {x=15,y=8},  -- tail
      {x=14,y=8},  -- mid
      {x=13,y=8}   -- head
    }
  }
  Food={
      x=0,
      y=0,
      sprite=SPRITE.FOOD
  }
  SpawnFood()
end

function GetSnakeBodyParts()
  return {
    head=Snake.body[#Snake.body],
    neck=Snake.body[#Snake.body-1],
    tail=Snake.body[1]
  }
end

-- Prints the player's score on screen
function DrawScoreboard()
  local offset=2
  local scoreMessage="Score: "..Game.score
  -- Compute pixel width of the score
  -- by printing it outside the screen
  local width = print(scoreMessage,0,-6)
  print(
    scoreMessage,
    -- Rightmost column, offset by width
    -- of the text and a fixed offset 
    8*SCREEN.WIDTH-width-offset,
    -- Fixed y offset
    offset,
    COLOR.FG
  )
end

-- Draws the entire game on each frame
function Draw()
  -- Clear previous paint
  cls(COLOR.BG)
  map(0,0,SCREEN.WIDTH,SCREEN.HEIGHT)
  -- Draw snake
  for i,segment in pairs(Snake.body) do
    if i==#Snake.body then
      spr(
        -- Render correct head sprite
        -- based on direction of movement
        SPRITE.SNAKE+1+Snake.dirIndex, 
        segment.x*8,
        segment.y*8,
        COLOR.BG
      )
    -- Render snake body
    else
      spr(
        SPRITE.SNAKE,
        segment.x*8,
        segment.y*8,
        COLOR.BG
      )
    end
 end
  -- Draw food
  spr(
    Food.sprite, 
    Food.x*8, 
    Food.y*8,
    COLOR.BG
  )
  -- Draw this last so it's always 
  -- painted above everything else
  DrawScoreboard()
end

function MoveSnake()  
  local body=GetSnakeBodyParts()
  local head=body.head
  local neck=body.neck
  local tail=body.tail
  
  -- Insert a new segment at the end of
  -- the snake body table. Effectively,
  -- this means the snake grew 1 unit
  -- and the head has advanced in the
  -- direction of the player's movement.
  table.insert(
    Snake.body,
    #Snake.body+1,
    {
      -- If player went off screen,
      -- cycle them back from the start
      x=(head.x+Snake.dir.x)%SCREEN.WIDTH,
      y=(head.y+Snake.dir.y)%SCREEN.HEIGHT
    }
  )
end

function SpawnFood()
  local foodIndex = math.random(0, 3)
  Food.x=math.random(0,SCREEN.WIDTH-1)
  Food.y=math.random(0,SCREEN.HEIGHT-1)
  Food.sprite=SPRITE.FOOD+foodIndex
end

function AteFood()
  local body=GetSnakeBodyParts()
  return body.head.x==Food.x and body.head.y==Food.y
end

function CollidedWithSelf()
  local head=GetSnakeBodyParts().head
  for i,segment in pairs(Snake.body) do
    -- If the index is not the head's but
    -- the head x/y and current x/y match, then we    
    -- collided with ourselves. Game over!
  if i~=#Snake.body and 
     segment.x==head.x and 
     segment.y==head.y 
  then
    return true
  end
 end
 return false
end

function SetSnakeDirection()
  local body=GetSnakeBodyParts()
  local head=body.head
  local neck=body.neck
  local tail=body.tail

  local prevDir=Snake.dir
  local prevDirIndex=Snake.dirIndex

  if btnp(BUTTON.UP)    then Snake.dirIndex=0 end
  if btnp(BUTTON.DOWN)  then Snake.dirIndex=1 end
  if btnp(BUTTON.LEFT)  then Snake.dirIndex=2 end
  if btnp(BUTTON.RIGHT) then Snake.dirIndex=3 end
  
  -- Set the direction of the player
  Snake.dir=Dirs[Snake.dirIndex]
  
  -- Prevent the player from reversing
  -- direction (i.e., turn left when
  -- already traveling right)
  if head.x+Snake.dir.x==neck.x and 
     head.y+Snake.dir.y==neck.y 
  then
    Snake.dir=prevDir
    Snake.dirIndex=prevDirIndex
  end
end

function ShouldUpdate()
  -- Make the game harder every 4 points.
  -- Fastest is a modifier of 4.
  local scoreLevel=math.floor(Game.score/4)
  local speedModifier=math.max(4,8-scoreLevel)
  return Game.t%speedModifier==0
end

-- Main update loop for the game
function Update()
  Game.t=Game.t+1

  if ShouldUpdate() then
    MoveSnake()
    
    -- Player ate food. Earn points
    -- and body grows on next paint 
    -- because of the code above that
    -- inserted a new segment.
    if AteFood() then
      Game.score=Game.score+1
      sfx(SFX.EAT)
      SpawnFood()
    else  
      -- Player didn't eat. Remove first
      -- segment (tail) to undo the growth
      -- from the code above.
      table.remove(Snake.body,1)
    end
    
    Draw()
  
    if CollidedWithSelf() then
      trace("Game Over!")
      trace("Score: "..Game.score)
      exit()
    end
  end
  -- Do this outside the slowed down
  -- bit above so input is immediate
  SetSnakeDirection()
end

-- executes once every 60 seconds
function TIC()
  Update()
end

-- Initialize some global variables
init()
