//
//  ViewController.swift
//  SubredditViewer
//
//  Created by Joseph Petrich on 3/28/17.
//  Copyright © 2017 Joseph Petrich. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController, UISearchBarDelegate {

    var timer = Timer()
    var arrayIndex = 0
    var urlArray: Array<String> = Array.init()
    var headers: HTTPHeaders = [
        "Authorization": "",
        ]
    let apiUrl = "https://api.imgur.com/3/gallery/r/"
    
    var keys:NSDictionary = NSDictionary()

    @IBOutlet weak var mImageView: UIImageView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    func loadSubreddit(subreddit: String) {
        self.view.endEditing(true)
        self.timer.invalidate()
        urlArray.removeAll()
        let subredditUrl = apiUrl + subreddit
        if let path = Bundle.main.path(forResource: "keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)!
            let imgurAPIKey = keys["imgurAPIKey"]
            headers["Authorization"] = imgurAPIKey as! String?
        }
        Alamofire.request(subredditUrl, headers:headers).responseJSON{ response in
            //let json = response.result.value
            
            let responseDict = response.result.value as? [String: Any]
            if let data = responseDict?["data"] as? Array<[String: Any]>{
                for var i in 0..<data.count {
                    if let entry = data[i] as? [String: Any] {
                        if ((entry["link"] as! String).hasSuffix(".jpg")){
                            self.urlArray.append(entry["link"] as! String)
                        }
                    }
                    //print("\(data[i])")
                }
            }
            for var link in self.urlArray {
                print("\(link)")
            }
            if self.urlArray.count != 0{
                self.startTimer()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        mImageView.isUserInteractionEnabled = true
        mImageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
    }
    
    func imageTapped(tapGestureRecognizer: UITapGestureRecognizer){
        if (mImageView == tapGestureRecognizer.view as! UIImageView){
            if (self.timer.isValid){
                self.timer.invalidate()
            }
            else if (urlArray.count > 0){
                startTimer()
            }
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        print("Did Begin Editing text: \(searchBar.text)")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Search Button Clicked: \(searchBar.text)")
        loadSubreddit(subreddit: searchBar.text!)
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        print("End editing text: \(searchBar.text)")
    }
    
    func update() {
        let urlString = urlArray[arrayIndex % urlArray.count]
        print("Loading \(urlString)")
        let url = URL(string: urlString)
        if let data = try? Data(contentsOf: url!){ //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
            mImageView.image = UIImage(data: data)
        }
        arrayIndex += 1
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

