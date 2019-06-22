//
//  ViewController.swift
//  gaussian_calc_by_ssh
//
//  Created by 保泉拓也 on 2019/02/20.
//  Copyright © 2019 保泉拓也. All rights reserved.
//

import Cocoa
import NMSSH

class My_modifing_file_for_gauss {
    private var filename :String
    private var mail_address:String
    init(_ filename:String,mailAddress ma:String){
        self.filename = filename
        self.mail_address = ma
    }
    private func modify() -> String?{
        let filehandle = FileHandle(forReadingAtPath:self.filename)
        var output :[String] = []
        if filehandle != nil {
            let in_data = filehandle?.readDataToEndOfFile()
            filehandle?.closeFile()
            guard let in_da = in_data else {print("error in_data 6");return nil}
            let str = String(data: in_da, encoding: .utf8)
            guard let str1 = str else{print("errro str1 6");return nil}
            output.append(self.mail_address)
            output.append("%nprocshared=8")
            output.append("%mem=500MW")
            for line in str1.split(separator:"\r\n") {
                if String(line).pregMatche(pattern: "chk*") {
                    
                }
                else{
                    output.append(String(line))
                }
                
            }
            print("modify success")
            return output.joined(separator: "\r\n")
        }
        print("filehandle not working")
        return nil
    }
    public func undo_file(){
        let filehandle = FileHandle(forReadingAtPath:self.filename)
        var output :[String] = []
        if filehandle != nil {
            let in_data = filehandle?.readDataToEndOfFile()
            filehandle?.closeFile()
            guard let in_da = in_data else {print("error in_data 6");return;}
            let str = String(data: in_da, encoding: .utf8)
            guard let str1 = str else{print("errro str1 6");return;}
            
            for line in str1.split(separator:"\r\n") {
                if String(line).pregMatche(pattern: "chk*"){
                    
                }
                else if String(line).pregMatche(pattern: "%nprocshared") || String(line).pregMatche(pattern: "%mem") ||  String(line).pregMatche(pattern:"@") {
                    
                }else{
                    output.append(String(line))
                }
                
            }
            print("modify success")
            do{
                try output.joined(separator: "\r\n").write(toFile:self.filename, atomically: true, encoding: String.Encoding.utf8)
            }catch {
                print("over_write error")
            }
            
        }
    }
    public func over_write(){
        do{
            try self.modify()?.write(toFile:self.filename, atomically: true, encoding: String.Encoding.utf8)
        }catch {
            print("over_write error")
        }
    }
}
class My_SSH_Client{
    private var text_field: NSTextField!
    public let Session :NMSSHSession
    public func my_ssh_execute(_ execute_string: String) -> String{
        if(self.Session.isAuthorized){
            
            return self.Session.channel.execute(execute_string,error: nil)
        }
        return "ERROR"
    }
    public func upload_my_server(localpath:String,remotepath:String){
        //self.in_mac_mini(nil)
        //self.Session.channel.uploadFile(localpath, to: remotepath)
        //self.Session.sftp.connect()
        let _sftp = NMSFTP.connect(with: self.Session)
        //_sftp.writeFile(atPath: localpath, toFileAtPath: remotepath)
        //file open operation
        let file_data: FileHandle? = FileHandle(forReadingAtPath:localpath)
        if file_data != nil {
            let in_data = file_data?.readDataToEndOfFile()
            file_data?.closeFile()
            guard let in_data_unwrrup = in_data else {print("read error");return;}
            _sftp.writeContents(in_data_unwrrup,toFileAtPath:remotepath)
            _sftp.disconnect()
            
            let char:Character = "/"
            if let file_name = localpath.split(separator: char).last {
                let execute_str = "cp \"/home/hoitaku/application_file/tmp\" \"/home/hoitaku/application_file/" + file_name + "\""
                self.Session.channel.execute(execute_str, error: nil)
                print("upload success")
                self.transfer_file_to_server(String(file_name))
                
            }else{
                print("not found file name my error 3")
            }
        }
        else{
            print("error in file data")
        }
        
    }
    private func transfer_file_to_server(_ filename:String){ //only filename without path
        if(self.Session.isAuthorized){
            self.Session.channel.requestPty = true
            self.Session.channel.ptyTerminalType = NMSSHChannelPtyTerminal.ansi
            do{
                try self.Session.channel.startShell()
                sleep(3)
                //self.Session.channel.write("transfer_univ " + filename + " /home/arakawa/hoitaku/for_gaussian_app" + "\n",error: nil,timeout:10)
                
                self.Session.channel.write("ssh_univ_mac_mini\n",error: nil,timeout: 10)
                sleep(3)
                self.Session.channel.write("ishiilab_server\n",error: nil,timeout:10)
                sleep(3)
                self.Session.channel.write("bash /home/arakawa/hoitaku/transfer_.sh " + "hoitaku@27.120.126.72:/home/hoitaku/application_file/" + filename + " /home/arakawa/hoitaku/for_gaussian_app/" + "\n",error: nil,timeout:10)
                sleep(3)
                self.Session.channel.write("cd /home/arakawa/hoitaku/for_gaussian_app/\n", error: nil, timeout: 10)
                sleep(1)
                self.Session.channel.write("nohup bash application.sh " + filename + " &\n", error: nil, timeout: 10)
                let str = self.Session.channel.lastResponse ?? "ERROR"
                print("transfer_univ success\n" + str)
                let formatter = DateFormatter()
                formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMdkHms", options: 0, locale: Locale(identifier: "ja_JP"))
                self.text_field.stringValue = "Uploading Success " + formatter.string(from: Date())
                
            }
            catch{
                self.text_field.stringValue = "Cannot Upload\nbecause of not working network!?"
                print("error shell not working 5")
            }
        }
    }
    
    public func in_mac_mini(_ tex: NSTextField?){
        if(self.Session.isAuthorized){
            self.Session.channel.requestPty = true
            self.Session.channel.ptyTerminalType = NMSSHChannelPtyTerminal.ansi
            
            do {
                try self.Session.channel.startShell()   //tmp.dataをuniv_に送る
//                self.Session.channel.write("ssh_univ_mac_mini\n",error: nil,timeout: 10)
//                sleep(3)
//                self.Session.channel.write("ishiilab_server\n",error: nil,timeout:10)
//                sleep(5)
//                self.Session.channel.write("ls -l\n",error: nil,timeout:10)
//                sleep(3)
                
                tex?.stringValue = self.Session.channel.lastResponse ?? "ssh_univ_mac_mini_eneter_ERROR"
                
             }
            catch{
                print("ERROR SHELL")
                return;
            }
            //self.Session.channel.write("history\n", error: nil, timeout: 10)
        }
    }
    
    public func set_textbox(text :NSTextField){
        self.text_field = text
    }
    init(hostname:String,username:String,password:String){
        self.Session = NMSSHSession.init(host: hostname,andUsername :username)
        self.Session.connect()
        if(self.Session.isConnected){
            self.Session.authenticate(byPassword: password)
            
        }
    }
    
}

class ViewController: NSViewController {
    //#### instance variable ####
    
    @IBOutlet weak var mail_address: NSTextField!
    @IBOutlet weak var path_field_text: NSTextField!
    @IBOutlet weak var text_field: NSTextField!
    var ssh_session: My_SSH_Client!
    var connection_alive: Int = 0
    @IBAction func modify_button(_ sender: NSButton) {
         My_modifing_file_for_gauss(self.path_field_text.stringValue,mailAddress:self.mail_address.stringValue).undo_file()
    }
    
    @IBAction func Connect_button(_ sender: NSButton) {
        //we need judge if .gjf or not
        if let judge_str = self.path_field_text.stringValue.split(separator: "/").last {
            if String(judge_str).pregMatche(pattern: "gjf") {
                
            }
            else {
                self.text_field.stringValue = "You need to select ~.gjf file"
                return;
            }
        }
        //judge mail address
        if mail_address.stringValue.count == 0{
            self.text_field.stringValue = "Enter your mail address"
            return;
        }else if !(self.mail_address.stringValue.pregMatche(pattern: "@")){
            self.text_field.stringValue = "Entered incorrect mail address\nYou need correct mail address"
            return;
        }
        //modyfing file
        My_modifing_file_for_gauss(self.path_field_text.stringValue,mailAddress:self.mail_address.stringValue).over_write()
        
        if self.connection_alive >= 1 {
            self.connection_alive = 0
            self.ssh_session.Session.channel.closeShell()
            self.ssh_session.Session.disconnect()
            
        }
        if(self.ssh_session == nil){
            self.ssh_session = My_SSH_Client(hostname: "x.x.x.x",username: "hoitaku",password: "ho1130")
            self.ssh_session.set_textbox(text: self.text_field)
        }else {
            self.ssh_session.Session.connect()
            if(self.ssh_session.Session.isConnected){
                self.ssh_session.Session.authenticate(byPassword: "ho1130")
            }
        }
        self.connection_alive += 1
        self.ssh_session.upload_my_server(localpath: self.path_field_text.stringValue, remotepath: "/home/hoitaku/application_file/tmp")
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.path_field_text.isEnabled = false
        self.text_field.stringValue = "Status Message"
        
        // Do any additional setup after loading the view.
        
        let rect1_height = self.view.bounds.height/3
        let rect1 = FileDropView(frame:CGRect(x:0,y:self.view.bounds.height-rect1_height,width:self.view.bounds.width/2,height: rect1_height))
        rect1.wantsLayer = true
        rect1.layer?.backgroundColor = CGColor(red:0.5,green:0.0,blue:0.5,alpha:0.2)
        rect1.set_text_field_pointer(self.path_field_text)
        self.view.addSubview(rect1)
        
    }
    override func viewDidAppear(){
        super.viewDidAppear()
        self.view.window?.title = "Gaussian Calculator"
        self.view.window?.styleMask.remove(.resizable)
    }
    

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    class FileDropView: NSView {
        @IBOutlet weak var path_text: NSTextField!
        public var Path_data:[URL] = []
        public var text_field:NSTextField!
        override init(frame frameRect: NSRect){
            super.init(frame: frameRect)
            self.commonInit()
            
        }
        required init?(coder: NSCoder){
            super.init(coder:coder)
            commonInit()
        }
        private func commonInit(){
            self.registerForDraggedTypes([.fileURL])
            
        }
        override func draw(_ dirtyRect: NSRect){
            super.draw(dirtyRect)
            let mywidth:CGFloat = 80
            let myheight:CGFloat = 20
            "Drag & Drop".draw(in: NSMakeRect(self.bounds.width/2-mywidth/2, self.bounds.height/2-myheight/2, mywidth, myheight), withAttributes: nil)
        }
        func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
            let pboard = draggingInfo.draggingPasteboard
            if pboard.canReadObject(forClasses: [NSURL.self],options: nil){
                return true
            }
            return false
        }
        override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation{
            
//            return shouldAllowDrag(sender) ? [.copy] : []
            return NSDragOperation.copy
        }
        override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
            return shouldAllowDrag(sender)
        }
        override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
            let pboard = sender.draggingPasteboard
            if let urls = pboard.readObjects(forClasses: [NSURL.self],options: nil) as? [URL] {
                //for url in urls {
                if let url = urls.last {
                    print(url)
                    var modify_str = "\(url)"
                    if let mstr_range = modify_str.range(of: "file://"){
                        modify_str.replaceSubrange(mstr_range,with:"")
                    }
                    path_text.stringValue = "\(modify_str)"
                }
            }
            return true
        }
        public func set_text_field_pointer(_ text_field:NSTextField){
            self.path_text = text_field
        }
    }
    
}

extension String {
    //絵文字など(2文字分)も含めた文字数を返します
    var count:Int{
        let string_NS = self as NSString
        return string_NS.length
    }
    
    //正規表現の検索をします
    func pregMatche(pattern: String, options: NSRegularExpression.Options = []) -> Bool {
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        let matches = regex.matches(in: self, options: [], range: NSMakeRange(0, self.count))
        return matches.count > 0
    }
    
    //正規表現の検索結果を利用できます
    func pregMatche(pattern: String, options: NSRegularExpression.Options = [], matches: inout [String]) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return false
        }
        let targetStringRange = NSRange(location: 0, length: self.count)
        let results = regex.matches(in: self, options: [], range: targetStringRange)
        for i in 0 ..< results.count{
            for j in 0 ..< results[i].numberOfRanges{
                let range = results[i].range(at: j)
                matches.append((self as NSString).substring(with: range))
            }
        }
        return results.count > 0
    }
    
    //正規表現の置換をします
    func pregReplace(pattern: String, with: String, options: NSRegularExpression.Options = []) -> String {
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        return regex.stringByReplacingMatches(in: self, options: [], range: NSMakeRange(0, self.count), withTemplate: with)
    }
}

