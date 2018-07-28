//   Copyright 2018 Joseph Petrich
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//
//
//  ViewController.swift
//  SubredditViewer
//
//  Created by Joseph Petrich on 3/28/17.
//

import UIKit
import Alamofire

class ViewController: UIViewController, UISearchBarDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    var timer = Timer()
    var interval = 2
    var arrayIndex = 0
    var urlArray: Array<String> = Array.init()
    var headers: HTTPHeaders = [
        "Authorization": "",
        ]
    let apiUrl = "https://api.imgur.com/3/gallery/r/"
    
    var keys:NSDictionary = NSDictionary()
    
    let pickerData = ["1 second", "2 seconds", "3 seconds", "5 seconds", "10 seconds", "15 seconds", "30 seconds", "1 minute", "2 minutes"]
    let secondsData = [1, 2, 3, 5, 10, 15, 30, 60, 120]
    
    let sortPickerData = ["new", "day", "week", "month", "year", "all"]
    var sortString = "new"
    var currentSubreddit:String = ""
    
    @IBOutlet weak var mImageView: UIImageView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var intervalPicker: UIPickerView! = UIPickerView()
    @IBOutlet weak var intervalButton: UIBarButtonItem!
    @IBOutlet weak var sortButton: UIBarButtonItem!
    @IBOutlet weak var sortPicker: UIPickerView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        mImageView.isUserInteractionEnabled = true
        mImageView.addGestureRecognizer(tapGestureRecognizer)
        
        intervalPicker.isHidden = true
        intervalPicker.delegate = self
        intervalPicker.dataSource = self
        intervalButton.action = #selector(intervalButtonClicked(sender:))
        
        sortPicker.isHidden = true
        sortPicker.delegate = self
        sortPicker.dataSource = self
        sortButton.action = #selector(sortButtonClicked(sender:))
        
        indicatorView.stopAnimating()
        indicatorView.isHidden = true
    }
    
    func loadSubreddit(subreddit: String) {
        if (subreddit == ""){
            return
        }
        indicatorView.isHidden = false
        indicatorView.startAnimating()
        currentSubreddit = subreddit
        self.view.endEditing(true)
        self.timer.invalidate()
        urlArray.removeAll()
        let subredditUrl = apiUrl + subreddit + "/" + (sortString == "new" ? "time/" : "top/\(sortString)/")
        print(subredditUrl)
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
                self.update()
            }
        }
    }
    
    func intervalButtonClicked(sender: UIBarButtonItem){
        intervalPicker.isHidden = !intervalPicker.isHidden
        sortPicker.isHidden = true
    }
    
    func sortButtonClicked(sender: UIBarButtonItem){
        sortPicker.isHidden = !sortPicker.isHidden
        intervalPicker.isHidden = true
    }
    
    func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(interval), target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
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
        //print("Did Begin Editing text: \(searchBar.text)")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Search Button Clicked: \(searchBar.text ?? "no text entered")")
        loadSubreddit(subreddit: searchBar.text!)
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        //print("End editing text: \(searchBar.text)")
    }
    
    func update() {
        indicatorView.startAnimating()
        indicatorView.isHidden = false
        if (self.timer.isValid){
            self.timer.invalidate()
        }
        
        let urlString = urlArray[arrayIndex % urlArray.count]
        print("Loading \(urlString)")
        let url = URL(string: urlString)
        if let data = try? Data(contentsOf: url!){
            mImageView.image = UIImage(data: data)
        }
        arrayIndex += 1
        indicatorView.isHidden = true
        indicatorView.stopAnimating()
        
        self.startTimer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (pickerView == intervalPicker){
            return pickerData.count
        }
        else {
            return sortPickerData.count
        }
    }
    
    //MARK: Delegates
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if (pickerView == intervalPicker){
            return pickerData[row]
        }
        else{
            return sortPickerData[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (pickerView == intervalPicker){
            intervalPicker.isHidden = true
            interval = secondsData[row]
            if (timer.isValid && urlArray.count > 0){
                timer.invalidate()
                startTimer()
            }
        }
        else{
            sortPicker.isHidden = true
            if (sortPickerData[row] != sortString){
                sortString = sortPickerData[row]
                sortButton.title = sortString == "new" ? "Sort:new" : "Top:\(sortString)"
                loadSubreddit(subreddit: currentSubreddit)
            }
        }
    }


}

