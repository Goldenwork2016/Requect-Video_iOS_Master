//
//  CountriesViewController.swift
//  SharedSpirit
//
//  Created by NTechnosoft on 5/12/17.
//  Copyright © 2017 NTechnosoft. All rights reserved.
//

import UIKit

class CountriesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate{

    @IBOutlet weak var aTableView: UITableView!
    @IBOutlet weak var aSearchBar: UISearchBar!
    var countries: NSArray!
    var display: NSMutableArray!
    var selected:  NSDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //aTableView.tableHeaderView = aSearchBar
        self.countries = NSArray.init(contentsOfFile: Bundle.main.path(forResource: "country", ofType: "plist")!)
        display = NSMutableArray()
        filter()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func filter(){
        display.removeAllObjects()
        if (self.aSearchBar.text?.isEmpty == true) {
            display.addObjects(from: self.countries as! [Any])
        }else{
            let Predicate = NSPredicate(format: "name contains[c] %@",self.aSearchBar.text!)
            display.removeAllObjects()
            let result:NSArray = countries.filtered(using: Predicate) as NSArray
            print(result)
            display.addObjects(from: result as! [Any])
        }
        aTableView.reloadData()
    }

    
    @IBAction func Done(_ sender: UIButton) {
        if (selected != nil) {
            
            let nc:UINavigationController = self.presentingViewController as! UINavigationController
            let v:SignupViewController = nc.viewControllers.last as! SignupViewController
            v.CountryBTN.setTitle(selected.object(forKey: "name") as? String, for: UIControlState.normal)
            v.CountryLBL.text = String(format: "%@", (selected.object(forKey: "dial_code"))! as! CVarArg)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        self.perform(#selector(filter), with: nil, afterDelay: 0.2)
        return true
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return display.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        let d:NSDictionary = display.object(at: indexPath.row) as! NSDictionary
        cell.accessoryType = UITableViewCellAccessoryType.none
        cell.textLabel?.text = String(format: "%@", d.object(forKey: "name") as! String)
        if (selected != nil) {
            if (d.isEqual(to: selected as! [AnyHashable : Any])) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected = display.object(at: indexPath.row) as! NSDictionary
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
    }

}
