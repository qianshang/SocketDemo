//
//  ViewController.swift
//  SocketDemo
//
//  Created by mac on 2018/2/28.
//  Copyright © 2018年 mac. All rights reserved.
//

import UIKit

struct Message {
    let content: String
    let isMe: Bool
}

class ViewController: UIViewController {

    @IBOutlet weak var stateView: UIView!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var bottomBar: UIVisualEffectView!
    
    @IBOutlet weak var bottomViewBottomConstraint: NSLayoutConstraint!
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SocketUtil.default.delegate = self
        SocketUtil.default.start()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDismiss), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func onSendBtnClick() {
        guard let msg = textField.text, !msg.isEmpty else {
            return
        }
        textField.text = ""
        SocketUtil.default.sendMessage(msg)
    }
    
    @objc func keyboardWillShow(_ note: Notification) {
        print(note.userInfo ?? [])
        guard let keyboardHeight = (note.userInfo?["UIKeyboardBoundsUserInfoKey"] as? CGRect)?.height else {
            return
        }
        
        bottomViewBottomConstraint.constant = keyboardHeight
        self.view.setNeedsLayout()
    }
    @objc func keyboardDismiss() {
        
        bottomViewBottomConstraint.constant = 0
        self.view.setNeedsLayout()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textField.resignFirstResponder()
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let msg: Message = messages[indexPath.row]
        if msg.isMe {
            let cell: MessageForMeCell = tableView.dequeueReusableCell(withIdentifier: "SendCell", for: indexPath) as! MessageForMeCell
            
            cell.contentLabel.text = msg.content + ":C"
            
            return cell
        } else {
            let cell: MessageForServiceCell = tableView.dequeueReusableCell(withIdentifier: "ReceiveCell", for: indexPath) as! MessageForServiceCell
            
            cell.contentLabel.text = "S:" + msg.content
            
            return cell
        }
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        textField.resignFirstResponder()
    }
}

extension ViewController: SocketProtocol {
    func socketConnecteStateDidChanged(_ state: SocketConnectState) {
        switch state {
        case .connected:
            stateLabel.text = "连接成功"
            stateView.backgroundColor = .green
        case .connecting:
            stateLabel.text = "连接中..."
            stateView.backgroundColor = .yellow
        case .disabled:
            stateLabel.text = "断开连接"
            stateView.backgroundColor = .red
        }
    }
    func socketDidReceivedMessage(_ message: String, from isService: Bool) {
        let index: Int = messages.count
        messages.append(Message(content: message, isMe: !isService))
        
        let indexPath: IndexPath = IndexPath(row: index, section: 0)
        tableView.insertRows(at: [indexPath], with: .fade)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
}

class MessageForServiceCell: UITableViewCell {
    @IBOutlet weak var contentLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.backgroundColor = .clear
    }
}
class MessageForMeCell: UITableViewCell {
    @IBOutlet weak var contentLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.backgroundColor = .clear
    }
}

