//
//  ViewController.swift
//  NearbyChat
//
//  Created by mot on 1/1/16.
//  Copyright © 2016 mot. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewConstraintsHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    let GoogleAPIKey = "<Your API Key>"

    var texts = [String]()
    var isObserving = false
    var messageManager: GNSMessageManager?
    var publication: GNSPublication?
    var subscription: GNSSubscription?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        textView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        messageManager = GNSMessageManager(APIKey: GoogleAPIKey) { (params: GNSMessageManagerParams!) -> Void in
            params.microphonePermissionErrorHandler = { hasError in
                if(hasError){
                    print("Nearby works better if microphone use is allowed")
                }
            }
            params.bluetoothPermissionErrorHandler = { hasError in
                if (hasError) {
                    print("Nearby works better if Bluetooth use is allowed")
                }
            }
            params.bluetoothPowerErrorHandler = { hasError in
                if (hasError) {
                    print("Nearby works better if Bluetooth is turned on")
                }
            }
        }
        GNSPermission.setGranted(true)
        
        startSubscribe()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if(!isObserving){
            let notification = NSNotificationCenter.defaultCenter()
            notification.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
            notification.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
            
            isObserving = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if(isObserving){
            let notification = NSNotificationCenter.defaultCenter()
            notification.removeObserver(self, name: "keyboardWillShow:", object: nil)
            notification.removeObserver(self, name: "keyboardWillHide:", object: nil)

            isObserving = false
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let rect = notification.userInfo![UIKeyboardFrameEndUserInfoKey]?.CGRectValue
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey]?.doubleValue
        
        UIView.animateWithDuration(duration!) { () -> Void in
            let transform = CGAffineTransformMakeTranslation(0, -rect!.size.height);
            self.view.transform = transform;
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey]?.doubleValue
       
        UIView.animateWithDuration(duration!) { () -> Void in
            self.view.transform = CGAffineTransformIdentity
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        let maxHeight = 80.0 as Float
        if(Float(textView.frame.size.height) < maxHeight){
            let size = textView.sizeThatFits(textView.frame.size)
            textViewConstraintsHeight.constant = size.height
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        textView.scrollRangeToVisible(textView.selectedRange)
        return true
    }
    
    func insertNewObject(message: String) {
        texts.append(message)
        tableView.reloadData()
    }
    
    @IBAction func tapButton(sender: AnyObject) {
        if(textView.text != ""){
            insertNewObject(textView.text)
            startPublication(textView.text)
        }
        
        textView.text = nil
        let size = textView.sizeThatFits(textView.frame.size)
        textViewConstraintsHeight.constant = size.height
        
        textView.resignFirstResponder()
    }
    
    // 設定（列数）
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // 設定（行数）
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int {
            return texts.count
    }
    
    // 設定（セル）
    func tableView(tableView: UITableView, cellForRowAtIndexPath
        indexPath: NSIndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 
            
            let text = texts[indexPath.row]
            cell.textLabel!.text = text
            return cell
    }
    
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath
        indexPath: NSIndexPath) -> Bool {
            // Return false if you do not want the specified item to be editable.
            return false
    }
 
    func startPublication(message: String){
        let content = message.dataUsingEncoding(NSUTF8StringEncoding)
        let message = GNSMessage(content: content)
        publication = messageManager?.publicationWithMessage(message)
    }
    
    func startSubscribe(){
        subscription = messageManager?.subscriptionWithMessageFoundHandler({ (message: GNSMessage!) -> Void in
            print("subscribed: " + String(data: message.content, encoding: NSUTF8StringEncoding)!)
                self.insertNewObject(String(data: message.content, encoding: NSUTF8StringEncoding)!)
            }, messageLostHandler: { (message: GNSMessage!) -> Void in
                print("messageLostHandler: " + String(data: message.content, encoding: NSUTF8StringEncoding)!)
        })
    }

}
