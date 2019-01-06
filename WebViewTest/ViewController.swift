//
//  ViewController.swift
//  WebViewTest
//
//  Created by Raymund Tong on 6/1/2019.
//  Copyright © 2019 Raymund. All rights reserved.
//

import UIKit
import WebKit
import Alamofire
import Zip

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    
    var webView: WKWebView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    let filePath: String = ""
    let tempZipFileName: String = "temp.zip"
    let tempHtmlDirectory: String = "temp"
    let deleteZipOnUnzip: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Init WebView
        let preference = WKPreferences()
        preference.javaScriptEnabled = true
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences = preference
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height/2), configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        self.view.addSubview(webView)
        
        //  Check local HTML exist
        let fm = FileManager.default
        let documentDirectoryURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first
        let contentBaseURL = documentDirectoryURL?.appendingPathComponent("temp", isDirectory: true)
        let htmlURL = contentBaseURL?.appendingPathComponent("index.html")

        //  If local HTML not exist, download, unzip and display
        if (!fm.fileExists(atPath: htmlURL!.path)) {
            downloadUnzipAndDisplay()
        }
        //  If local HTML exist, display directly
        else {
            print("Load HTML at: \(htmlURL!.absoluteString)")
            self.statusLabel.text = "Display local HTML"
            webView.loadFileURL(htmlURL!, allowingReadAccessTo: contentBaseURL!)
        }
    }
    
    //  Download, unzip and display the html in webview
    func downloadUnzipAndDisplay() {
        downloadFile(fileUrl: filePath, completionHandler: { url, error in
            if(url != nil) {
                let htmlURL = url?.appendingPathComponent("index.html")
                print("Load HTML at: \(htmlURL!.absoluteString)")
                self.statusLabel.text = "Display downloaded HTML"
                self.webView.loadFileURL(htmlURL!, allowingReadAccessTo: url!)
            } else if (error != nil) {
                print(error!)
            }
        })
    }
    
    //  Download a remote file
    func downloadFile(fileUrl: String, completionHandler: @escaping (URL?, Error?) -> ()) {
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationURL = documentDirectoryURL!.appendingPathComponent(self.tempZipFileName)
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        let downloadParameters : Parameters = ["":""]
        
        Alamofire.download(fileUrl, method: .get, parameters: downloadParameters, encoding: JSONEncoding.default, to: destination)
            .downloadProgress { progress in
                self.statusLabel.text = "Download Progress: \(progress.fractionCompleted)"
                print("Download Progress: \(progress.fractionCompleted)")
            }
            .response(completionHandler: { (DefaultDownloadResponse) in
                if DefaultDownloadResponse.response?.statusCode == 200 {
                    let fm = FileManager.default
                    if (fm.fileExists(atPath: destinationURL.path)) {
                        print("Download complete at: \(destinationURL.absoluteString)")
                        let unzipFileDirectory = documentDirectoryURL!.appendingPathComponent(self.tempHtmlDirectory, isDirectory: true)
                        self.unzip(filePath: destinationURL, outputDestination: unzipFileDirectory, deleteOnComplete: self.deleteZipOnUnzip, completionHandler: completionHandler)
                    }
                }
            })
    }
    
    //  Unzip a zip file
    func unzip(filePath: URL, outputDestination: URL, deleteOnComplete: Bool, completionHandler:(URL?, Error?) -> ()) -> () {
        do {
            try Zip.unzipFile(filePath, destination: outputDestination, overwrite: true, password: "", progress: { (progress) -> () in
                print("Unzip Progress: \(progress)")
                DispatchQueue.main.async {
                    self.statusLabel.text = "Unzip Progress: \(progress)"
                }
            })
            print("Unzip complete at: \(outputDestination.absoluteString)")
            if (deleteOnComplete) {
                try FileManager.default.removeItem(at: filePath)
                print("Delete zip file at: \(filePath.absoluteString)")
            }
            completionHandler(outputDestination, nil)
        }
        catch {
            print("Couldn't unzip")
            completionHandler(nil, error)
        }
    }
    
    @IBAction func downloadButtonDidTouch(_ sender: Any) {
        downloadUnzipAndDisplay()
    }

}

