//
//  ViewController.swift
//  RainHttpManager
//
//  Created by rainedAllNight on 2018/5/10.
//  Copyright © 2018年 luowei. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //如何使用
        
        //1.json
        RainHttpManager.requestJSON(ApiTest.fetchTestJSON, success: { (response) in
            // json response
        }) { (error) in
            self.showErrorHUD(error.message)
        }
        
        //2.model
        RainHttpManager<ApiTest, TestModel>.requestModel(.fetchTestModel, success: { (model) in
            guard let model = model else {
                return
            }
            print("name: \(model.name)")
        }) { (error) in
            self.showErrorHUD(error.message)
        }
        
        //model list
        RainHttpManager<ApiTest, TestModel>.requestModelList(.fetchTestModelList(pageIndex: 0, pageSize: 10), authType: .basic, success: { (models) in
            guard let models = models else {
                return
            }
            print(models)
        }) { (error) in
            self.showErrorHUD(error.message)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

