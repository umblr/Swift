//
//  GameOverScene.swift
//  Space
//
//  Created by UMBLR on 2014/12/21.
//  Copyright (c) 2014年 raus0. All rights reserved.
//

import UIKit
import SpriteKit

class GameOverScene: SKScene {
    
    init(size:CGSize, won:Bool){
        super.init(size: size)
        self.backgroundColor = SKColor.blackColor()
        var message:NSString = NSString()
        
        if (won){
            message = "You win!"
        }else{
            message = "Game Over"
        }
        
        var label:SKLabelNode = SKLabelNode(fontNamed: "DamascusBold")
        
        label.text = message
        label.fontColor = SKColor.whiteColor()
        label.position = CGPointMake(self.size.width/2, self.size.height/2)
        
        self.addChild(label)
        
        self.runAction(SKAction.sequence([SKAction.waitForDuration(3.0),
            SKAction.runBlock({
                var transtion:SKTransition = SKTransition.flipHorizontalWithDuration(0.5)
                var scene:SKScene = GameScene(size: self.size)
                self.view!.presentScene(scene, transition: transtion)
            })
            ]))
        
    };
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}