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
   -> ロゴを配置
   -> 検索窓を配置
   -> 横スクロールのヘッダーナビを配置
   -> フッターナビを配置
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
import AVFoundation
import CoreMedia

// MARK:- 動画プレイヤーを配置したビューをAVPlayerLayerにするためのラッパークラス
// これをsuperViewにaddSubViewする
// これがないと動画再生できない
class AVPlayerView: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame) // frameのサイズを変えると動画プレイヤーのビューのサイズが変わる
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

class ViewController: UIViewController {
    
    // 再生用のアイテム
    var playerItem: AVPlayerItem! // 実際の動画内容を保存する変数
    
    // ビデオプレイヤー
    var videoPlayer: AVPlayer! // 動画の再生プレイヤーを保存する変数

    // ビデオプレイヤービューを貼り付けるためのバックグラウンドビュー
    var videoBackGroundView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        // 動画プレイヤーをviewに配置
        createMovieView()
    }
    
    // 動画プレイヤーを配置するメソッド
    private func createMovieView() {
        /*
         動画をビデオプレイヤーに表示しviewに貼り付ける処理
         */
        // 動画のファイル名と拡張子を変数に保存
        let fileName = "IMG_9333"
        let fileExtension = "MOV"
        
        // 他のプログラムから参照できるように動画ファイル名と拡張子をAppDelegateに保存
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.fileName = fileName
        appDelegate.fileExtension = fileExtension

        // パスからassetを生成
        let path = Bundle.main.path(forResource: fileName, ofType: fileExtension)
        let fileURL = URL(fileURLWithPath: path!)
        let avAsset = AVURLAsset(url: fileURL)
        
        //ビデオプレイヤーに再生させるアイテムを生成
        playerItem = AVPlayerItem(asset: avAsset)
        
        // 再生する動画を指定してビデオプレイヤーを生成
        videoPlayer = AVPlayer(playerItem: playerItem)
        
        // ビデオプレイヤーを配置するためのUIViewを生成 -> ここで動画プレイヤーのサイズを決める(撮影の段階から画角を決めるべきか?)
        videoBackGroundView = UIView(frame: self.view.bounds)
        self.view.addSubview(videoBackGroundView) // superViewにビデオプレイヤービューのためのバックグラウンドビューを貼り付け
        let videoPlayerView = AVPlayerView(frame: self.view.bounds) // frameのサイズを変えると動画プレイヤーのサイズが変わる

        // 動画の終了を監視してリピート再生するためのNotification設定
        NotificationCenter.default.addObserver(self, selector: #selector(self.handlePlayerItemDidReachEnd), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)

        // videoPlayerViewをAVPlayerLayerキャストし動画プレイヤーを配置する
        let layer = videoPlayerView.layer as! AVPlayerLayer
        layer.videoGravity = AVLayerVideoGravityResizeAspect // 縦横ともちょうどよく収まる
        layer.player = videoPlayer
        
        // 動画プレイヤーを配置したビューをバックグラウンドビューに追加する
        videoBackGroundView.layer.addSublayer(layer)
        
        // 動画をタップしたらモーダルを起動するようにviewにTapGestureRecognizerを設定
        let movieTap = UITapGestureRecognizer(target: self, action: #selector(handleDetailViewShow(sender:)))
        videoBackGroundView.addGestureRecognizer(movieTap)
    }
    
    // 画面が表示される直前に動作するメソッド
    override func viewDidAppear(_ animated: Bool) {
        // この画面が読み込まれたら動画を自動再生
        videoPlayer.play()
    }
    
    // 動画をタップした時にモーダルを立ち上げるメソッド
    func handleDetailViewShow(sender: UITapGestureRecognizer) {
        print("検知した！")
        videoPlayer.pause()
        let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "detail")
        self.present(detailViewController!, animated: true, completion: nil)
    }
    
    // 動画の終了を検知してリピート再生するメソッド
    func handlePlayerItemDidReachEnd(notification: Notification) -> Void {
        // 再生中の動画の総再生時間を取得
        let duration = CMTimeGetSeconds(self.videoPlayer.currentItem!.duration)
        
        // 再生終了時間をCMTime型で取得
        let endTime = CMTimeMake(Int64(0.5), Int32(duration))
        
        // 動画終了を検知したらまた再生
        videoPlayer.seek(to: endTime, completionHandler: {_ in 
            // 動画を再生
            self.videoPlayer.play()
        })
        return
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

