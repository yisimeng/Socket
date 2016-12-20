//
//  ViewController.swift
//  YSM-SocketClient
//
//  Created by 忆思梦 on 2016/12/13.
//  Copyright © 2016年 忆思梦. All rights reserved.
//

import UIKit

let SeverAddress = "0.0.0.0"
let SeverPort = Int32(8080)

class ViewController: UIViewController {
    
    var clientManager :YSMClientManager = YSMClientManager(address: SeverAddress, port: SeverPort)
    
    @IBOutlet weak var messageTextField: UITextField!
    
    @IBOutlet weak var giftName: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        clientManager.delegate = self
    }
    
    @IBAction func connectSever(_ sender: Any) {
        //连接服务器
        if clientManager.connectServer() {
            print("服务器连接成功")
        }else{
            print("服务器连接失败")
        }
    }
    
    @IBAction func join(_ sender: Any) {
        clientManager.joinRoom()
    }
    
    @IBAction func sendText(_ sender: Any) {
        guard let text = messageTextField.text else {
            return
        }
        clientManager.send(text)
    }
    @IBAction func gift(_ sender: Any) {
        guard let gift = giftName.text else {
            return
        }
        clientManager.send(gift, "www.baidu.com", Int(arc4random_uniform(100)))
    }
    @IBAction func leave(_ sender: Any) {
        clientManager.leaveRoom()
    }
    
    @IBAction func disConnectSever(_ sender: Any) {
        clientManager.closeConnect()
    }
}

extension ViewController:YSMClientDelegate{
    //进入房间
    func clientManager(_ clientManager:YSMClientManager, joinRoomWith userInfo:UserInfo){
        print("\(userInfo.name) 来了")
    }
    //离开房间
    func clientManager(_ clientManager:YSMClientManager, leaveRoomWith userInfo:UserInfo){
        print("\(userInfo.name) 走了")
    }
    //发送聊天消息
    func clientManager(_ clientManager:YSMClientManager, sendChat message:ChatMessage){
        print("\(message.user.name) 说：\(message.text)")
    }
    //发送礼物
    func clientManager(_ clientManager:YSMClientManager, sendGift message:GiftMessage){
        print("\(message.user.name) 送了 \(message.giftcount)个\(message.giftname)")
    }
}
