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
 (2)(1)をタップしたらページ遷移して自動再生
 (3)(2)に再生/停止を追加
 (4)(3)に再生経過時間を表示
 (5)複数動画の読み込み
 (6)(5)を一番上の動画のみ自動再生（他はタップするまで停止）
 (7)(6)をタップしたらページ遷移して自動再生
 (8)(7)をスクロールビューに配置
 (9)Firebaseへの動画保存
 (10)(9)を読み込んで表示
 (11)(10)をクルクル回ってどんどん表示対応
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
        //super.init(frame: CGRect(x: 0, y: 0, width: 120, height: 180)) // -> テスト済み
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
    
    // シークバー
    var seekBar: UISlider! // 動画の再生バーを保存する変数

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        /*
         動画をビデオプレイヤーに表示しviewに貼り付ける処理
        */
        // パスからassetを生成
        let path = Bundle.main.path(forResource: "IMG_9333", ofType: "MOV")
        let fileURL = URL(fileURLWithPath: path!)
        let avAsset = AVURLAsset(url: fileURL)
        
        //ビデオプレイヤーに再生させるアイテムを生成
        playerItem = AVPlayerItem(asset: avAsset)
        
        // 再生する動画を指定してビデオプレイヤーを生成
        videoPlayer = AVPlayer(playerItem: playerItem)
        
        // ビデオプレイヤーを配置するためのUIViewを生成
        let videoPlayerView = AVPlayerView(frame: self.view.bounds) // frameのサイズを変えると動画プレイヤーのサイズが変わる
        //let videoPlayerView = AVPlayerView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width / 2, height: self.view.bounds.height / 2)) // -> テスト済み
        
        // videoPlayerViewをAVPlayerLayerキャストし動画プレイヤーを配置する
        let layer = videoPlayerView.layer as! AVPlayerLayer
        layer.videoGravity = AVLayerVideoGravityResizeAspect // 縦横ともちょうどよく収まる
        layer.player = videoPlayer
        
        // 動画プレイヤーを配置したビューをsuperViewに追加する
        self.view.layer.addSublayer(layer) // layerパラメーターについて調査
        
        // 動画のシークバーとなるUISlderを生成
        seekBar = UISlider(frame: CGRect(x: 0, y: 0, width: self.view.bounds.maxX - 100, height: 50)) // スライダーオブジェクトを作っているだけなので、xとyの値が何でも変化はない
        seekBar.layer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.maxY - 100) // スライダーの配置場所を決定しているが、boundsを使っているのでローカルビューに対するposition
        seekBar.minimumValue = 0 // シークバーの最小値
        seekBar.maximumValue = Float(CMTimeGetSeconds(avAsset.duration)) // シークバーの最大値はビデオの再生時間
        seekBar.addTarget(self, action: #selector(onSliderValueChange(sender:)), for: UIControlEvents.valueChanged)
        self.view.addSubview(seekBar) // selfがなくても動く。理由はviewがsuperViewだからselfしてもしなくても同じなので。
        //view.addSubview(seekBar) // -> テスト済み
        
        /*
         シークバーを動画とシンクロさせる処理
        */
        // シークバーを0.5分割で動かすことができるようにインターバルを指定
        let interval: Double = Double(0.5 * seekBar.maximumValue) / Double(seekBar.bounds.maxX)
        
        // インターバル（秒）を動画用インターバル（フレーム/秒）に変換するため、CMTimeに変換する
        let time: CMTime = CMTimeMakeWithSeconds(interval, Int32(NSEC_PER_SEC)) // Int32(NSEC_PER_SEC)はタイムスケールと呼ばれ指定するとフレーム/秒にできる
        
        // time毎に呼び出されるクロージャー
        videoPlayer.addPeriodicTimeObserver(forInterval: time, queue: nil, using: { time in
            // 総再生時間を取得
            let duration = CMTimeGetSeconds(self.videoPlayer.currentItem!.duration)
            
            // 現在の時間を取得
            let time = CMTimeGetSeconds(self.videoPlayer.currentTime())
            
            // シークバーの位置を変更
            let value = Float(self.seekBar.maximumValue - self.seekBar.minimumValue) * Float(time) / Float(duration) + Float(self.seekBar.minimumValue)
            self.seekBar.value = value
        })
        
        // 動画の再生ボタンを生成
        let startButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50)) // ボタンオブジェクトを作っているだけなのでxとyの数値が何でも同じ
        startButton.layer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY - 50) // ボタンの位置を決めているが、boundsを使っているのでローカルビューに対するposition
        startButton.layer.masksToBounds = true // 角丸に合わせてマスクする
        startButton.layer.cornerRadius = 20.0
        startButton.backgroundColor = UIColor.orange
        startButton.setTitle("Start", for: UIControlState.normal) // normal:ボタン有効、highlighted:ボタン接触中、disabled:ボタン無効
        startButton.addTarget(self, action: #selector(onButtonClick(sender:)), for: UIControlEvents.touchUpInside)
        self.view.addSubview(startButton)
    }
    
    // Startボタンがタップされた時に呼ばれるメソッド
    func onButtonClick(sender: UIButton) {
        // 再生時間を最初に戻して再生
        videoPlayer.seek(to: CMTimeMakeWithSeconds(0, Int32(NSEC_PER_SEC)))
        videoPlayer.play()
    }
    
    // シークバーの値が変わった時に呼ばれるメソッド
    func onSliderValueChange(sender: UISlider) {
        // 動画の再生時間をシークバーとシンクロさせる
        videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(seekBar.value), Int32(NSEC_PER_SEC)))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

