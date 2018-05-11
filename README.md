# RainHttpManager

## 使用 Moya + ObjectMapper/Codable/SwiftyJSON (三选一)封装的一个网络层

## 如何使用

```
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
    
    //3.model list
    RainHttpManager<ApiTest, TestModel>.requestModelList(.fetchTestModelList(pageIndex: 0, pageSize: 10), authType: .basic, success: { (models) in
        guard let models = models else {
            return
        }
        print(models)
    }) { (error) in
        self.showErrorHUD(error.message)
    }
}

```
