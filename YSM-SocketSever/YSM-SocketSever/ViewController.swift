//
//  ViewController.swift
//  YSM-SocketSever
//
//  Created by 忆思梦 on 2016/12/13.
//  Copyright © 2016年 忆思梦. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    //创建socket服务器:地址和端口号
    fileprivate var severSocket : YSMSeverManager = YSMSeverManager(address: "0.0.0.0", port: 8080)
    @IBOutlet weak var status: NSTextField!
    
    @IBOutlet weak var message: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //开始接收数据
    }

    //打开socket，开始接收客户端连接和收发数据
    @IBAction func openSocket(_ sender: Any) {
        //开启监听
        severSocket.turnOnSever()
        status.stringValue = "服务器运行中"
    }

    @IBAction func sendMessage(_ sender: NSButton) {
    }
    
    //关闭socket
    @IBAction func closeSocket(_ sender: Any) {
        severSocket.turnOffSever()
        status.stringValue += "\n服务器关闭"
    }
    
}

