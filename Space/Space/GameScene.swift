//
//  GameScene.swift
//  Space
//
//  Created by UMBLR on 2014/12/17.
//  Copyright (c) 2014年 raus0. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player:SKSpriteNode = SKSpriteNode()
    var lastYieldTimeInterval:NSTimeInterval = NSTimeInterval()
    var lastUpdateTimerInterval:NSTimeInterval = NSTimeInterval()
    
    var aliens:NSMutableArray = NSMutableArray()
    var aliensDestroyed:Int = 0
    
    let alienCateory:UInt32 = 0x1 << 1
    let photonTorpedoCategory:UInt32 = 0x1 << 0
    
    override init(size:CGSize){
        super.init(size: size)
        self.backgroundColor = SKColor.blackColor()
        
        player = SKSpriteNode(imageNamed: "shuttle")
        player.position = CGPointMake(self.frame.size.width/2, player.size.height/2 + 20)
        
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        self.physicsWorld.contactDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addAlien(){
        
        // Create alien sprite
        var alien:SKSpriteNode = SKSpriteNode(imageNamed: "alien")
        alien.physicsBody = SKPhysicsBody(rectangleOfSize: alien.size)
        alien.physicsBody?.dynamic = true
        alien.physicsBody?.categoryBitMask = alienCateory
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        // Where to create aliens along the x-axis
        let minX = alien.size.width/2
        let maxX = self.frame.size.width - alien.size.width/2
        let rangeX = maxX-minX
        let position:CGFloat = CGFloat(arc4random()) % CGFloat(rangeX) + CGFloat(minX)
        
        // Bring aliens of screen
        alien.position = CGPointMake(position, self.frame.size.height+alien.size.height)
        
        self.addChild(alien)
        aliens.addObject(alien)
        
        // Alien Animation Duration        
        let minDuration = 2
        let maxDuration = 4
        let rangeDuration = maxDuration - minDuration
        let duration = UInt(arc4random()) % UInt(rangeDuration) + UInt(minDuration)
        
        // Create actions to animate
        var actionArray:NSMutableArray = NSMutableArray()
        
        actionArray.addObject(SKAction.moveTo(CGPointMake(position, -alien.size.height),duration: NSTimeInterval(duration)))
        actionArray.addObject(SKAction.runBlock({
            var transition:SKTransition = SKTransition.flipHorizontalWithDuration(0.5)
            var gameOverScene:SKScene = GameOverScene(size: self.size, won: false)
            self.view!.presentScene(gameOverScene, transition: transition)
        }))
        
        actionArray.addObject(SKAction.removeFromParent())
        
        alien.runAction(SKAction.sequence(actionArray))
        
    }
    
    func updateWithTimeSinceLastUpdate(timeSinceLastUpdate:CFTimeInterval){
        
        lastYieldTimeInterval += timeSinceLastUpdate
        if (lastYieldTimeInterval > 1){
            lastYieldTimeInterval = 0
            addAlien()
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        
        var timeSinceLastUpdate = currentTime - lastUpdateTimerInterval
        lastUpdateTimerInterval = currentTime
        
        if(timeSinceLastUpdate > 1){
            timeSinceLastUpdate = 1/60
            lastUpdateTimerInterval = currentTime
        }
        updateWithTimeSinceLastUpdate(timeSinceLastUpdate)
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent){
        self.runAction(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
    
        // chose one of the touches to work with
        var touch:UITouch = touches.anyObject() as UITouch
        var location:CGPoint = touch.locationInNode(self)
        
        // Set up initial location for torpedo
        var torpedo:SKSpriteNode = SKSpriteNode(imageNamed: "torpedo")
        torpedo.position = player.position
        torpedo.physicsBody = SKPhysicsBody(circleOfRadius: torpedo.size.width/2)
        torpedo.physicsBody?.dynamic = true
        
        // BOTH TIMES BIT MASK NECESSARY
        torpedo.physicsBody?.categoryBitMask = photonTorpedoCategory
        torpedo.physicsBody?.contactTestBitMask = alienCateory
        torpedo.physicsBody?.collisionBitMask = 0
        torpedo.physicsBody?.usesPreciseCollisionDetection = true
        
        // Determine offset of location to torpedo
        var offset:CGPoint = vecSub(location, b: torpedo.position)
        
        // dont add torpedo if shooting backwards
        if(offset.y < 0){
            return
        }
        
        self.addChild(torpedo)
        
        //Where to shoot?
        var direction:CGPoint = vecNomalize(offset)
        
        //Shoot off screen
        var shotLength:CGPoint = vecMult(direction, b: 1000)
        
        //Add length to current position
        var finalDestination:CGPoint = vecAdd(shotLength, b: torpedo.position)
        
        // create action
        let velocity = 568/1
        let moveDuration:Float = Float (self.size.width) / Float(velocity)
        
        var actionArray:NSMutableArray = NSMutableArray()
        actionArray.addObject(SKAction.moveTo(finalDestination, duration: NSTimeInterval(moveDuration)))
        actionArray.addObject(SKAction.removeFromParent())
        
        torpedo.runAction(SKAction.sequence(actionArray))
        
    }
    
    func didBeginContact(contact: SKPhysicsContact!){
        
        // Body1 and 2 depend on the categoryBitMask << 0 und << 1
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody
        
        if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask){
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        torpedoDidCollideWithAlien(contact.bodyA.node as SKSpriteNode, alien: contact.bodyB.node as SKSpriteNode)
    }
    
    func torpedoDidCollideWithAlien(torpedo:SKSpriteNode, alien:SKSpriteNode){
        println("Hit")
        torpedo.removeFromParent()
        alien.removeFromParent()
        aliensDestroyed++
        
        if (aliensDestroyed > 10){
            //Transition to GameOver or Success
            var transition:SKTransition = SKTransition.flipHorizontalWithDuration(0.5)
            var gameOverScene:SKScene = GameOverScene(size: self.size, won: true)
            self.view!.presentScene(gameOverScene, transition: transition)
        }
    }
    
    func vecAdd(a:CGPoint, b:CGPoint)->CGPoint{
        return CGPointMake(a.x + b.x, a.y + b.y)
    }
    
    func vecSub(a:CGPoint, b:CGPoint)->CGPoint{
        return CGPointMake(a.x - b.x, a.y - b.y)
    }
    
    func vecMult(a:CGPoint, b:CGFloat)->CGPoint{
        return CGPointMake(a.x * b, a.y * b)
    }
    
    func vecLength(a:CGPoint)->CGFloat{
        return CGFloat(sqrtf(CFloat(a.x)*CFloat(a.x)+CFloat(a.y)*CFloat(a.y)))
    }
    
    func vecNomalize(a:CGPoint)->CGPoint{
        var length:CGFloat = vecLength(a)
        return CGPointMake(a.x / length, a.y / length)
    }
}