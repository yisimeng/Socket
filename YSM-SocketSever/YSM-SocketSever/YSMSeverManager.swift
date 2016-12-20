//
//  YSMSeverManager.swift
//  YSM-SocketSever
//
//  Created by 忆思梦 on 2016/12/13.
//  Copyright © 2016年 忆思梦. All rights reserved.
//

import Cocoa

class YSMSeverManager: NSObject {
    
    //tcp服务器
    fileprivate var severSocket : TCPServer
    fileprivate var isRunning : Bool = false
    fileprivate lazy var clients : [YSMClient] = [YSMClient]()
    
    //根据地址和端口号创建服务器
    init(address:String,port:Int32) {
        self.severSocket = TCPServer(address: address, port: port)
    }
}

// MARK: - operation
extension YSMSeverManager {
    //开启服务器
    func turnOnSever() {
        //开启服务器监听
        severSocket.listen()
        isRunning = true
        //开始接收客户端连接
        DispatchQueue.global().async {
            //只要服务器打开，就应该保证能一直接收消息
            while self.isRunning {
                //会阻塞当前线程直到有客户端连接
                if let client = self.severSocket.accept() {
                    //重新开启一个线程去监听该客户端
                    DispatchQueue.global().async {
                        self.listen(client: client)
                    }
                }
            }
        }
    }
    //关闭服务器
    func turnOffSever() {
        isRunning = false
        //关闭服务器
        severSocket.close()
    }
}

// MARK: - 内部函数
extension YSMSeverManager {
    //监听客户端消息
    fileprivate func listen(client : TCPClient) {
        //创建socket保持与客户端socket连接
        let ysmClient : YSMClient = YSMClient(client)
        ysmClient.delegate = self
        //判断客户端是否已经添加
        if (self.clients as NSArray).contains(ysmClient) {
            //获取原来的下标
            let index = (self.clients as NSArray).index(of: ysmClient)
            //将之前的客户端移除
            self.clients.remove(at: index)
        }
        //将客户端添加至客户端组中
        self.clients.append(ysmClient)
        print("客户端连接：\(ysmClient)")
        //开启监听
        ysmClient.listen()
    }
}

extension YSMSeverManager:YSMClientDelegate{
    //客户端失去连接，将其移除
    func disConnectClient(_ client:YSMClient){
        guard let index = clients.index(of: client) else {
            return
        }
        clients.remove(at: index)
    }
    //给客户端发送消息
    func sendMsgToClient(_ data: Data) {
        for client in clients {
            _ = client.clientSocket.send(data: data)
        }
    }
}
