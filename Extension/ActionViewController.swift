//
//  ActionViewController.swift
//  Extension
//
//  Created by Luke Inger on 18/06/2020.
//  Copyright © 2020 Luke Inger. All rights reserved.
//

import UIKit
import MobileCoreServices

class ActionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
    var pageTile = ""
    var pageURL = ""
    var scripts = [Script]()
    var showTable: Bool = true {
        didSet{
            if (showTable){
                tableView.isHidden = false
                textView.isHidden = true
            } else {
                tableView.isHidden = true
                textView.isHidden = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //let buttonDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        let buttonSelect = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        let buttonAdd = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNew))
        navigationItem.setRightBarButtonItems([buttonAdd, buttonSelect], animated: true)
    
        //Hide the text view on first load and show the table
        showTable = true
        
        let notificationCentre = NotificationCenter.default
        notificationCentre.addObserver(self, selector: #selector(keyboardWillAdjust), name: UIResponder.keyboardDidHideNotification, object: nil)
        notificationCentre.addObserver(self, selector: #selector(keyboardWillAdjust), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = inputItem.attachments?.first {
                itemProvider.loadItem(forTypeIdentifier: kUTTypePropertyList as String) { [weak self] (dict, error) in
                    // do somthing
                    guard let itemDictionary = dict as? NSDictionary else { return }
                    guard let JavaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else { return }
                    
                    self?.pageTile = JavaScriptValues["Title"] as? String ?? ""
                    self?.pageURL = JavaScriptValues["Url"] as? String ?? ""
                    
                    DispatchQueue.main.async {
                        self?.title = self?.pageTile;
                    }
                }
            }
        }
    }
    
    @objc func save(){
        
        showTable = false
        
        let ac = UIAlertController(title: "Save Script?", message: "Enter a name for your script", preferredStyle: .alert)
        ac.addTextField()
        ac.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] action in
            self?.scripts.append(Script(name: (ac.textFields?[0].text) ?? "", script: (self?.textView.text) ?? ""))
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.showTable = true
             }
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { [weak self] void in self?.showTable = true}))
        
        present(ac, animated: true, completion: {
 
        })
    }
    
    @objc func addNew(){
        showTable = false
        textView.text = ""
    }

    @IBAction func done() {
        
        let item = NSExtensionItem()
        let argument: NSDictionary = ["customJavaScript": textView.text!]
        let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey : argument]
        let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: kUTTypePropertyList as String)
        item.attachments = [customJavaScript]
        extensionContext?.completeRequest(returningItems: [item])
    }
    
    @objc func picker(){
        
        let ac = UIAlertController(title: "Select a script", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Title", style: .default, handler: { [weak self] action in
            self?.textView.text = "alert(document.title);"
        }))
        ac.addAction(UIAlertAction(title: "Url", style: .default, handler: { [weak self] action in
            self?.textView.text = "alert(document.location);"
        }))
        present(ac, animated: true)
        
    }

    @objc func keyboardWillAdjust(notification: Notification){
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else { return }
        
        let keyboardEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardEndFrame, to: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            textView.contentInset = .zero
        } else {
            textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        textView.scrollIndicatorInsets = textView.contentInset
        
        let selectedRange = textView.selectedRange
        textView.scrollRangeToVisible(selectedRange)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scripts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "script", for: indexPath)
        cell.textLabel?.text = scripts[indexPath.row].Name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let script = scripts[indexPath.row]

        let item = NSExtensionItem()
        let argument: NSDictionary = ["customJavaScript": script.Script]
        let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey : argument]
        let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: kUTTypePropertyList as String)
        item.attachments = [customJavaScript]
        extensionContext?.completeRequest(returningItems: [item])
    }
}
