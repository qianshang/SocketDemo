//
//  SocketUtil.swift
//  SocketDemo
//
//  Created by mac on 2018/2/28.
//  Copyright © 2018年 mac. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

enum SocketConnectState {
    case connecting
    case connected
    case disabled
}

protocol SocketProtocol: class {
    func socketConnecteStateDidChanged(_ state: SocketConnectState)
    func socketDidReceivedMessage(_ message: String, from isService: Bool)
}
extension SocketProtocol {
    func socketConnecteStateDidChanged(_ state: SocketConnectState) {}
    func socketDidReceivedMessage(_ message: String, from isService: Bool) {}
}

final class SocketUtil: NSObject {
    static let `default`: SocketUtil = SocketUtil()
    
    weak var delegate: SocketProtocol?
    private var clientSocket: GCDAsyncSocket?
    
    func start() {
        let host: String = "172.16.15.86"
        let port: UInt16 = 12345
        
        delegate?.socketConnecteStateDidChanged(.connecting)
        clientSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
            try clientSocket?.connect(toHost: host, onPort: port)
        } catch {
            print(error)
            delegate?.socketConnecteStateDidChanged(.disabled)
        }
    }
    
    func sendMessage() {
        let msg: String = "这是一条来自端上的数据:\(arc4random() % 0xFFFFFF)\n"
        sendMessage(msg)
    }
    func sendMessage(_ msg: String) {
        if let data: Data = msg.data(using: .utf8) {
            clientSocket?.write(data, withTimeout: -1, tag: 0)
            
            delegate?.socketDidReceivedMessage(msg, from: false)
        }
    }
    
}

extension SocketUtil: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("连接成功<\(host)><\(port)>")
        delegate?.socketConnecteStateDidChanged(.connected)
    }
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("发送信息tag=\(tag)")
        sock.readData(withTimeout: -1, tag: tag)
    }
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        if let res: String = String(data: data, encoding: .utf8) {
            print("收到信息:\(res)")
            delegate?.socketDidReceivedMessage(res, from: true)
        }
        sock.readData(withTimeout: -1, tag: tag)
    }
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("断开连接")
        delegate?.socketConnecteStateDidChanged(.disabled)
        clientSocket?.delegate = nil
        clientSocket = nil
    }
    func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        print(trust)
    }
}
