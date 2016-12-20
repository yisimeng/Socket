//
//  YSMClient.swift
//  YSM-SocketSever
//
//  Created by 忆思梦 on 2016/12/13.
//  Copyright © 2016年 忆思梦. All rights reserved.
//

import Cocoa

protocol YSMClientDelegate :class{
    func disConnectClient(_ client:YSMClient)
    func sendMsgToClient(_ data:Data)
}

enum MessageType:Int {
    case joinRoom = 0
    case leaveRoom = 1
    case textMsg = 2
    case giftMsg = 3
    
    case heartbeat = 100
}

let headCount = 4
//类型长度
let typeCount = 2

class YSMClient: NSObject {
    weak var delegate:YSMClientDelegate?
    
    fileprivate var heartTimeCount : Int = 0
    
    var clientSocket : TCPClient
    
    fileprivate var isConnected : Bool = false
    
    init(_ client:TCPClient) {
        self.clientSocket = client
    }
}

extension YSMClient{
    //监听Client
    func listen() {
        isConnected = true
        
        startClientHeartbeatCheck()
        
        //持续监听客户端发送的消息
        while isConnected {
            //阻塞线程方法，直到读取到信息。‘4’是和客户端确定好的头部信息长度
            if let receiveBytes = clientSocket.read(headCount) {
                //只截取4位，获取头部信息,bytes:参数为指针，receiveData为指向'[Byte]'数组的指针
                let headData = Data(bytes: receiveBytes, count: headCount)
                //解析出真实数据的长度
                var length : Int = 0
                //将length地址传入，获取length的值
                (headData as NSData).getBytes(&length, length: headCount)
                
                //读取消息类型
                guard let typeBytes = clientSocket.read(typeCount) else {
                    return
                }
                //类型data
                let typeData = Data(bytes: typeBytes, count: typeCount)
                var type : Int = 0
                (typeData as NSData).getBytes(&type, length: typeCount)

                let messageType = MessageType(rawValue: type)!
                
                //读取真实数据
                guard let messageBytes = clientSocket.read(length) else {
                    return
                }
                // 将消息转换为data，然后在从data中取数据
                //真实消息的数据
                let messageData = Data(bytes: messageBytes, count: length)
                //解析信息
                //let message = String(data: messageData, encoding: .utf8)
                
                /*
                /*直接将bytes转换为string*/
                //解析信息
                let message = String.init(bytes: messageBytes, encoding: .utf8)
                */
                
                //如果是离开房间，通知服务器移除客户端
                if messageType == .leaveRoom {
                    clientSocket.close()
                    delegate?.disConnectClient(self)
                }else if messageType == .heartbeat {
                    heartTimeCount = 0
                    print("连接中。。。")
                    continue
                }
                let totalData = headData+typeData+messageData
                //收到客户端发送的消息，需要通知服务器发送给其他的客户端
                delegate?.sendMsgToClient(totalData)
            }else{
                //连接中断
                disConnected()
            }
        }
    }
}

extension YSMClient{
    fileprivate func startClientHeartbeatCheck(){
        let timer = Timer(fireAt: Date(), interval: 1, target: self, selector: #selector(checkHeartBeat), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .commonModes)
        timer.fire()
    }
    @objc fileprivate func checkHeartBeat() {
        heartTimeCount += 1
        if heartTimeCount >= 10 {
            self.disConnected()
        }
    }
    //失去连接
    fileprivate func disConnected() {
        isConnected = false
        //关闭socket，通知服务器移除
        clientSocket.close()
        delegate?.disConnectClient(self)
        print("客户端中断连接")
    }
    
}
