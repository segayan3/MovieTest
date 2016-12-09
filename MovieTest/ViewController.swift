//
//  ViewController.swift
//  MovieTest
//
//  Created by Naohiro Segawa on 2016/12/09.
//  Copyright © 2016年 segayan3. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia

// MARK:- レイヤーをAVPlayerLayerにするためのラッパークラス
// -> 何のためにクラスなのか自分でもよくわからない...
// -> もしかして、superViewの上にビデオ再生用のviewを用意するクラスかな？
class AVPlayerView: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame) // -> 大きさ変えたらどうなる？
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

class ViewController: UIViewController {
    
    // 再生用のアイテム
    var playerItem: AVPlayerItem!
    
    // ビデオプレイヤー
    var videoPlayer: AVPlayer!
    
    // シークバー
    var seekBar: UISlider!

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
        
        // ビデオプレイヤーを生成
        videoPlayer = AVPlayer(playerItem: playerItem)
        
        // Viewを生成
        let videoPlayerView = AVPlayerView(frame: self.view.bounds) // -> 大きさ変えてみたい
        
        // UIViewのレイヤーをAVPayerLayerにする
        let layer = videoPlayerView.layer as! AVPlayerLayer
        layer.videoGravity = AVLayerVideoGravityResizeAspect // 縦横ともちょうどよく収まる
        layer.player = videoPlayer
        
        // レイヤーを追加する
        self.view.layer.addSublayer(layer) // layerパラメーターについて調査
        
        // 動画のシークバーとなるUISlderを生成
        seekBar = UISlider(frame: CGRect(x: 0, y: 0, width: self.view.bounds.maxX - 100, height: 50)) // -> 大きさ変えてみたい
        seekBar.layer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.maxY - 100) // -> 大きさ変えてみたい
        seekBar.minimumValue = 0 // シークバーの最小値
        seekBar.maximumValue = Float(CMTimeGetSeconds(avAsset.duration)) // シークバーの最大値はビデオの再生時間
        seekBar.addTarget(self, action: #selector(onSliderValueChange(sender:)), for: UIControlEvents.valueChanged)
        self.view.addSubview(seekBar) // -> view.layer.addSubviewだったらどうなるのか調査
        
        /*
         シークバーを動画とシンクロさせる処理
        */
        // シークバーを0.5分割で動かすことができるようにインターバルを指定
        let interval: Double = Double(0.5 * seekBar.maximumValue) / Double(seekBar.bounds.maxX) // -> 数字変えて動作確認
        
        // CMTimeに変換する
        let time: CMTime = CMTimeMakeWithSeconds(interval, Int32(NSEC_PER_SEC)) // CMTimeとInt32(NSEC_PER_SEC)って何か調査
        
        // time毎に呼び出される
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
        let startButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50)) // -> サイズの調査
        startButton.layer.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY - 50) // -> 何に対するposition?
        startButton.layer.masksToBounds = true // -> 何をしているか？
        startButton.layer.cornerRadius = 20.0
        startButton.backgroundColor = UIColor.orange
        startButton.setTitle("Start", for: UIControlState.normal) // -> normal以外は何がある？
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

