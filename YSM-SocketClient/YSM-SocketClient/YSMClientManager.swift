//
//  YSMClientManager.swift
//  YSM-SocketClient
//
//  Created by 忆思梦 on 2016/12/13.
//  Copyright © 2016年 忆思梦. All rights reserved.
//

import UIKit
import SwiftSocket

//头部信息
//数据长度
let headCount = 4
//类型长度
let typeCount = 2


enum MessageType:Int {
    case joinRoom = 0
    case leaveRoom = 1
    case textMsg = 2
    case giftMsg = 3
    
    case heartbeat = 100
}

protocol YSMClientDelegate:class {
    //进入房间
    func clientManager(_ clientManager:YSMClientManager, joinRoomWith userInfo:UserInfo)
    //离开房间
    func clientManager(_ clientManager:YSMClientManager, leaveRoomWith userInfo:UserInfo)
    //发送聊天消息
    func clientManager(_ clientManager:YSMClientManager, sendChat message:ChatMessage)
    //发送礼物
    func clientManager(_ clientManager:YSMClientManager, sendGift message:GiftMessage)
}

class YSMClientManager: NSObject {
    
    weak var delegate : YSMClientDelegate?
    
    var heartbeatInterval:TimeInterval = 9
    
    fileprivate var clientSocket : TCPClient
    fileprivate var isConnected: Bool = false
    
    //心跳包计时器
    fileprivate var timer : Timer!
    
    //当前的用户信息
    fileprivate var userInfo : UserInfo.Builder = {
        let userInfo = UserInfo.Builder()
        userInfo.name = "忆思梦(arc4random_uniform(10)"
        userInfo.level = Int32(arc4random_uniform(10))
        userInfo.iconUrl = "icon\(arc4random_uniform(10))"
        return userInfo
    }()
    
    //根据地址和端口号创建服务器
    init(address:String,port:Int32) {
        self.clientSocket = TCPClient(address: address, port: port)
    }
}

extension YSMClientManager{
    
    /// 保持心跳
    fileprivate func keepHeartbeat(){
        timer = Timer(fireAt: Date(), interval: heartbeatInterval, target: self, selector: #selector(sendHeartbeatMsg), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .commonModes)
    }
    
    /// 接受消息
    fileprivate func startReceiveMessage() {
        //接收处理服务器消息
        //读取消息会阻塞线程
        isConnected = true
        DispatchQueue.global().async {
            while self.isConnected {
                //读取头部信息
                if let receiveBytes = self.clientSocket.read(headCount){
                    //将接受到的二进制数据转换为data
                    let receiveData = Data(bytes: receiveBytes, count: headCount)
                    //读取数据信息,获取真实信息的长度
                    var messageLength :Int = 0
                    (receiveData as NSData).getBytes(&messageLength, length: headCount)
                    
                    //读取消息类型
                    guard let typeBytes = self.clientSocket.read(typeCount) else {
                        return
                    }
                    //将数据转换为data
                    let typeData = Data(bytes: typeBytes, count: typeCount)
                    //开辟类型内存
                    var type : Int = 0
                    //将类型内存传入，赋值，获得类型
                    (typeData as NSData).getBytes(&type, length: typeCount)
                    //转化消息类型
                    let messageType = MessageType(rawValue: type)!
                    
                    //读取真实数据
                    guard let messageBytes = self.clientSocket.read(messageLength) else {
                        return
                    }
                    //将真实数据从二进制转换为data
                    let messageData = Data(bytes: messageBytes, count: messageLength)
                    //数据处理
                    self.handleMessage(messageData, type: messageType)
                }else{
                    print("服务器断开连接")
                    //服务断开连接,需要重新连接
                    self.closeConnect()
                }
            }
        }
    }
    
    /// 处理消息
    ///
    /// - Parameters:
    ///   - data: <#data description#>
    ///   - type: <#type description#>
    fileprivate func handleMessage(_ data:Data,type:MessageType){
        switch type {
        case .joinRoom:
            let user = try! UserInfo.parseFrom(data: data)
            delegate?.clientManager(self, joinRoomWith: user)
        case .leaveRoom:
            let user = try! UserInfo.parseFrom(data: data)
            delegate?.clientManager(self, leaveRoomWith: user)
        case .textMsg:
            let message = try! ChatMessage.parseFrom(data: data)
            delegate?.clientManager(self, sendChat: message)
        case .giftMsg:
            let gift = try! GiftMessage.parseFrom(data: data)
            delegate?.clientManager(self, sendGift: gift)
        default :
            print("未知类型")
        }
    }
    
    /// 发送消息
    ///
    /// - Parameters:
    ///   - data: <#data description#>
    ///   - type: <#type description#>
    /// - Returns: <#return value description#>
    @discardableResult
    fileprivate func send(data : Data, type:MessageType) -> Bool {
        /*
        ----------------------
        | 头部 |  真实数据信息  |
        ----------------------
         1、头部信息存放真实数据的长度，头部信息的长度跟后台确定
        */
        
        //组装data
        
        //获取data的长度
        var length : Int = data.count
        //组装头部data,bytes:传入指针，指针指向的内存将被拷贝，count：拷贝的字节数
        let headData = Data(bytes: &length, count: headCount)
        
        //消息类型
        var typeValue = type.rawValue
        let typeData = Data(bytes: &typeValue, count:typeCount)
        
        //拼接成完整的data
        let totalData = headData+typeData+data
        return clientSocket.send(data: totalData).isSuccess
    }
    
    
    /// 心跳包
    @objc fileprivate func sendHeartbeatMsg() {
        // 1.获取心跳包中的数据
        let heartString = "I am is heart beat;"
        let heartData = heartString.data(using: .utf8)!
        
        // 2.发送数据
        send(data: heartData, type: .heartbeat)
    }
}

// MARK: - 外部调用
extension YSMClientManager{
    func connectServer() ->Bool {
        //连接服务器
        let success = clientSocket.connect(timeout: 5).isSuccess
        startReceiveMessage()
        
        keepHeartbeat()
        return success
    }
    
    func joinRoom() {
        //加入房间消息
        let msgData = (try! userInfo.build()).data()
        send(data: msgData, type: .joinRoom)
    }
    
    func leaveRoom() {
        //离开房间
        let msgData = (try! userInfo.build()).data()
        send(data: msgData, type: .leaveRoom)
    }
    
    func send(_ text:String) {
        //发送文本消息
        let msg = ChatMessage.Builder()
        msg.text = text
        msg.user = try! userInfo.build()
        let msgData = (try! msg.build()).data()
        send(data: msgData, type: .textMsg)
    }
    func send(_ giftName:String,_ giftUrl:String,_ giftCount:Int) {
        //发送礼物
        let msg = GiftMessage.Builder()
        msg.user = try! userInfo.build()
        msg.giftname = giftName
        msg.giftUrl = giftUrl
        msg.giftcount = Int32(giftCount)
        let msgData = (try! msg.build()).data()
        send(data: msgData, type: .giftMsg)
    }
    
    //关闭连接
    func closeConnect(){
        self.isConnected = false
        clientSocket.close()
    }
}
