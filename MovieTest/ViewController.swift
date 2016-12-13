//
//  ViewController.swift
//  MovieTest
//
//  Created by Naohiro Segawa on 2016/12/09.
//  Copyright © 2016年 segayan3. All rights reserved.
//

/*
 実装したい機能
 (1)自動再生
   Done:-> アプリ立ち上げるとviewControllerで動画を自動再生
   Done:-> viewControllerの動画はリピート再生
 (2)(1)をタップしたらページ遷移して自動再生
   Done:-> viewControllerの動画をタップするとモーダルを開いて自動再生
   Done:-> 遷移先から元に戻るとまた自動再生
 (3)(2)に再生/停止を追加
   Done:-> 動画の再生/停止ボタンを実装
   Done:-> シークバーを移動させるとそこから再生
   Done:-> 再生中に動画をタップすると停止
   Done:-> もう一度タップすると再生
   Done:-> 終了後に動画をタップするとゼロから再生
   Done:-> 終了後は自動的にシークをゼロに戻す
 (4)(3)に再生経過時間を表示
   Done:-> シークバーの下に再生時間と経過時間を表示
 (5)viewControllerのレイアウトを作成
   Done:-> ロゴを配置
   Done:-> 検索窓を配置
   -> 横スクロールのヘッダーナビを配置
   Done:-> フッターナビを配置
   -> タブ切り替え時の各ページのデザインを作成
 (6)複数動画の読み込み
   -> CollectionViewLayoutを実装
   -> 各セルに動画を配置
   -> 一番上の動画のみ自動再生
   -> 他はタップするまで停止状態でタップしたらモーダル表示
 (7)detailViewControllerのレイアウトを作成
   -> ヘッダータイトルを配置
   -> モーダルを閉じるボタンを配置
   -> 動画を配置
   -> 再生/停止ボタンを配置
   -> シークバーを配置
   -> コンテンツタイトルと調理時間を配置
   -> レシピを配置
   -> 食べレポを配置
   -> フッターナビを配置
   -> 読み込みをもっと早くする工夫
 (8)Firebaseからの読み込み
   -> Firebaseにヘッダーナビのデータを保存
   -> Firebaseからヘッダーナビのデータを取得
   -> Firebaseに動画データを保存
   -> Firebaseから動画データを取得
   -> Firebaseにレシピデータを保存
   -> Firebaseからレシピデータを取得
 (9)(8)を動画多くてもクルクル回ってどんどん表示対応
   -> データ数を50ぐらいに増やす
   -> クルクル回って読み込む機能を実装
*/

import UIKit
import ESTabBarController

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
                
        // ESTabBarControllerでTabBarを作成
        setUpTab()
    }
    
    // ESTabBarControllerでTabBarを作成するメソッド
    func setUpTab() {
        // 画像ファイル名を指定してESTabBarControllerを作成する
        let tabBarController: ESTabBarController! = ESTabBarController(tabIconNames: ["home", "home", "home", "home"])
        
        // 背景色、選択時の色を設定する
        tabBarController.selectedColor = UIColor(red: 1.0, green: 0.44, blue: 0.11, alpha: 1)
        tabBarController.buttonsBackgroundColor = UIColor(red: 0.96, green: 0.91, blue: 0.87, alpha: 1)
        
        // 作成したESTabBarControllerをviewControllerに貼り付ける
        addChildViewController(tabBarController)
        self.view.addSubview(tabBarController.view)
        tabBarController.view.frame = CGRect(x: 0, y: 20 + 50 + 40, width: self.view.bounds.width, height: self.view.bounds.height - (20 + 50 + 40))
        tabBarController.didMove(toParentViewController: self)
        
        // タブをタップした時に表示するViewControllerを設定する
        let recipeViewController = storyboard?.instantiateViewController(withIdentifier: "Recipe")
        let searchViewController = storyboard?.instantiateViewController(withIdentifier: "Search")
        let likeViewController = storyboard?.instantiateViewController(withIdentifier: "Like")
        let myPageViewController = storyboard?.instantiateViewController(withIdentifier: "MyPage")
        
        tabBarController.setView(recipeViewController, at: 0)
        tabBarController.setView(searchViewController, at: 1)
        tabBarController.setView(likeViewController, at: 2)
        tabBarController.setView(myPageViewController, at: 3)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

