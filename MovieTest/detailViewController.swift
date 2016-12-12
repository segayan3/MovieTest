//
//  detailViewController.swift
//  MovieTest
//
//  Created by Naohiro Segawa on 2016/12/10.
//  Copyright © 2016年 segayan3. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia

// MARK:- 動画プレイヤーを配置したビューをAVPlayerLayerにするためのラッパークラス
// これをsuperViewにaddSubViewする
// これがないと動画再生できない
class AVDetailPlayerView: UIView {
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

class detailViewController: UIViewController {
    
    // 再生する動画のファイル名
    var fileName: String!
    
    // 再生する動画の拡張子
    var fileExtension: String!
    
    
    // 再生用のアイテム
    var playerItem: AVPlayerItem! // 実際の動画内容を保存する変数
    
    // ビデオプレイヤー
    var videoPlayer: AVPlayer! // 動画の再生プレイヤーを保存する変数
    
    // ビデオプレイヤービューを貼り付けるためのバックグラウンドビュー
    var videoBackGroundView: UIView!
    
    // シークバー
    var seekBar: UISlider! // 動画の再生バーを保存する変数
    
    // 動画の再生時間に関する変数
    var elapsedTime: String! // 経過時間
    var durationTime: String! // 収録時間
    
    // 再生/停止ボタン
    var startAndStopButton: UIButton!

    // 動画の再生/停止ステータスフラグ
    var startAndStopButtonStatus = 0 // 0の時は再生中


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // AppDelegateを参照して動画ファイル名と拡張子を取得
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        fileName = appDelegate.fileName
        fileExtension = appDelegate.fileExtension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        createDetailView()
    }
    
    // 詳細画面を作成し表示
    private func createDetailView() {
        /*
         動画をビデオプレイヤーに表示しviewに貼り付ける処理
         */
        // パスからassetを生成
        let path = Bundle.main.path(forResource: fileName, ofType: fileExtension)
        let fileURL = URL(fileURLWithPath: path!)
        let avAsset = AVURLAsset(url: fileURL)
        
        //ビデオプレイヤーに再生させるアイテムを生成
        playerItem = AVPlayerItem(asset: avAsset)
        
        // 再生する動画を指定してビデオプレイヤーを生成
        videoPlayer = AVPlayer(playerItem: playerItem)
        
        /*
         現在設定している動画の再生時間を取得し再生時間ラベルに設定
        */
        /* CMTime構造体
         public struct CMTime {
         
         public var value: CMTimeValue // Int64
         public var timescale: CMTimeScale // Int32
         public var flags: CMTimeFlags // Valid等のフラグ(CMTimeFlags)
         public var epoch: CMTimeEpoch // Int64 同一時刻でもループしているなどで実際にはことなるものの違いを表す値として使う。
         }
         */
        let itemDuration = videoPlayer.currentItem?.asset.duration // 戻り値はCMTime構造体
        let itemDurationSec = itemDuration!.value / Int64(itemDuration!.timescale) // 秒はvalue/timescaleで算出できる
        
        // itemDurationSec(秒)を読みやすい形式に変換
        let hour = itemDurationSec / 3600
        let min = (itemDurationSec % 3600) / 60
        let sec = (itemDurationSec % 3600) % 60
        
        // 動画の収録時間を表示するUILabelを生成
        let durationTimeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 30))
        durationTimeLabel.layer.position = CGPoint(x: self.view.bounds.width - 50, y: 20 + 20 + 50 + self.view.bounds.height / 2)
        durationTimeLabel.font = UIFont(name: "Thonburi", size: 15)
        durationTimeLabel.textColor = UIColor.black
        
        if(hour != 0) {
            self.durationTime = String(hour) + ":" + String(min) + ":" + String(sec)
            durationTimeLabel.text = self.durationTime
        } else if(sec < 10) {
            let secString: String = "0" + String(sec)
            self.durationTime = String(min) + ":" + secString
            durationTimeLabel.text = self.durationTime
        } else {
            self.durationTime = String(min) + ":" + String(sec)
            durationTimeLabel.text = self.durationTime
        }
        
        self.view.addSubview(durationTimeLabel)
        
        // ビデオプレイヤーを配置するためのUIViewを生成 -> ここで動画プレイヤーのサイズを決める(撮影の段階から画角を決めるべき)
        videoBackGroundView = UIView(frame: CGRect(x: 0, y: 50, width: self.view.bounds.width, height: self.view.bounds.height / 2))
        self.view.addSubview(videoBackGroundView)
        let videoPlayerView = AVDetailPlayerView(frame: videoBackGroundView.bounds)
        
        // 動画が最後まで再生されたことを監視してシークバーを元に戻す
        NotificationCenter.default.addObserver(self, selector: #selector(handleDetailMovieDidEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        // videoPlayerViewをAVPlayerLayerキャストし動画プレイヤーを配置する
        let layer = videoPlayerView.layer as! AVPlayerLayer
        layer.videoGravity = AVLayerVideoGravityResizeAspect // 縦横ともちょうどよく収まる
        layer.player = videoPlayer
        
        // 動画プレイヤーを配置したビューをsuperViewに追加する
        videoBackGroundView.layer.addSublayer(layer) // layerパラメーターについて調査

        /*
         シークバーを動画とシンクロさせる処理
         */
        // 動画のシークバーとなるUISlderを生成
        seekBar = UISlider(frame: CGRect(x: 0, y: 0, width: self.view.bounds.maxX - 100, height: 50)) // スライダーオブジェクトを作っているだけなので、xとyの値が何でも変化はない
        seekBar.layer.position = CGPoint(x: self.view.bounds.width / 2, y: (20 + 50 + self.view.bounds.height / 2)) // スライダーの配置場所を決定しているが、boundsを使っているのでローカルビューに対するposition
        seekBar.minimumValue = 0 // シークバーの最小値
        seekBar.maximumValue = Float(CMTimeGetSeconds(avAsset.duration)) // シークバーの最大値はビデオの再生時間
        seekBar.addTarget(self, action: #selector(onSliderValueChange(sender:)), for: UIControlEvents.valueChanged)
        seekBar.addTarget(self, action: #selector(handleSeekBarValueChange(sender:)), for: UIControlEvents.touchDragInside)
        self.view.addSubview(seekBar) // selfがなくても動く。理由はviewがsuperViewだからselfしてもしなくても同じなので。
        
        // シークバーを0.5分割で動かすことができるようにインターバルを指定
        let interval: Double = Double(0.5 * seekBar.maximumValue) / Double(seekBar.bounds.maxX)
         
        // インターバル（秒）を動画用インターバル（フレーム/秒）に変換するため、CMTimeに変換する
        let time: CMTime = CMTimeMakeWithSeconds(interval, Int32(NSEC_PER_SEC)) // Int32(NSEC_PER_SEC)はタイムスケールと呼ばれ指定するとフレーム/秒にできる

        // 動画の経過時間を表示するUILabelの生成
        let elapsedTimeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 30))
        elapsedTimeLabel.layer.position = CGPoint(x: 75, y: 20 + 20 + 50 + self.view.bounds.height / 2)
        elapsedTimeLabel.font = UIFont(name: "Thonoburi", size: 15)
        elapsedTimeLabel.textColor = UIColor.black
        self.view.addSubview(elapsedTimeLabel)

        // time毎に呼び出されるクロージャー
        videoPlayer.addPeriodicTimeObserver(forInterval: time, queue: nil, using: { time in
            // 総再生時間を取得(秒で戻ってくる)
            let duration = CMTimeGetSeconds(self.videoPlayer.currentItem!.duration)
            
            // 現在の時間を取得(秒で戻ってくる)
            let time = CMTimeGetSeconds(self.videoPlayer.currentTime())
            
            // time(秒)を読みやすい形式に変換
            let timeFloor = floor(time) // 小数点以下は切り捨て
            let timeInt = Int(timeFloor)
            let tHour = timeInt / 3600
            let tMin = (timeInt % 3600) / 60
            let tSec = (timeInt % 3600) % 60
            
            if(tHour != 0) {
                self.elapsedTime = String(tHour) + ":" + String(tMin) + ":" + String(tSec)
                elapsedTimeLabel.text = self.elapsedTime
            } else if(tSec < 10) {
                let secString: String = "0" + String(tSec)
                self.elapsedTime = String(tMin) + ":" + secString
                elapsedTimeLabel.text = self.elapsedTime
            } else {
                self.elapsedTime = String(tMin) + ":" + String(tSec)
                elapsedTimeLabel.text = self.elapsedTime
            }
         
            // シークバーの位置を変更
            let value = Float(self.seekBar.maximumValue - self.seekBar.minimumValue) * Float(time) / Float(duration) + Float(self.seekBar.minimumValue)
            self.seekBar.value = value
        })
        
        /*
         動画をタップした時の処理
        */
        // 動画にTapGestureRecognizerを設定
        let detailMovieTap = UITapGestureRecognizer(target: self, action: #selector(handleDetailMovieAction(sender:)))
        videoBackGroundView.addGestureRecognizer(detailMovieTap)
        
        /*
         再生/停止ボタンを配置
        */
        startAndStopButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        startAndStopButton.layer.position = CGPoint(x: 25, y: 20 + 50 + self.view.bounds.height / 2)
        startAndStopButton.setTitleColor(UIColor.black, for: UIControlState.normal)
        startAndStopButton.setTitle("停止", for: UIControlState.normal)
        startAndStopButton.addTarget(self, action: #selector(handleStartAndStopButton(sender:)), for: UIControlEvents.touchUpInside)
        self.view.addSubview(startAndStopButton)
        
        /*
         モーダルを閉じるボタンを配置
        */
        let exitButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        exitButton.layer.position = CGPoint(x: 25, y: 40)
        exitButton.setTitleColor(UIColor.black, for: UIControlState.normal)
        exitButton.setTitle("×", for: UIControlState.normal)
        exitButton.addTarget(self, action: #selector(handleExitModalButton(sender:)), for: UIControlEvents.touchUpInside)
        self.view.addSubview(exitButton)
        
        
        // この画面が読み込まれたら動画を自動再生
        videoPlayer.play()
    }
    
    // 動画のシークバーを手動で動かした時に呼ばれるメソッド
    func handleSeekBarValueChange(sender: UIControlEvents) {
        videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(seekBar.value), Int32(NSEC_PER_SEC)), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        // -> toleranceBeforeとtoleranceAfterをkCMTimeZeroで設定しなければ１秒単位でしかシークされないので動きがカクカクする
        // -> kCMTimeZeroはCMTime型の0を表す
    }
    
    private func switchButton() {
        if(startAndStopButtonStatus == 0) {
            videoPlayer.pause()
            startAndStopButton.setTitle("再生", for: UIControlState.normal)
            startAndStopButtonStatus = 1
        } else {
            videoPlayer.play()
            startAndStopButton.setTitle("停止", for: UIControlState.normal)
            startAndStopButtonStatus = 0
        }
    }
    
    // 動画をタップした時のメソッド
    func handleDetailMovieAction(sender: UITapGestureRecognizer) {
        switchButton()
    }
    
    // 動画の再生/停止ボタンをタップした時のメソッド
    func handleStartAndStopButton(sender: UIButton) {
        switchButton()
    }
    
    // 動画を最後まで再生した時に呼ばれるメソッド
    func handleDetailMovieDidEnd(notification: Notification) {
        videoPlayer.seek(to: CMTimeMakeWithSeconds(0, Int32(NSEC_PER_SEC)))
        switchButton()
    }
    
    // 閉じるボタンをタップした時のメソッド
    func handleExitModalButton(sender: UIButton) {
        // アプリが重くなるのでモーダルの全要素を削除
        self.view.removeFromSuperview()
        
        // モーダルを閉じる
        dismiss(animated: true, completion: nil)
    }
    
     // シークバーの値が変わった時に呼ばれるメソッド
     func onSliderValueChange(sender: UISlider) {
        // 動画の再生時間をシークバーとシンクロさせる
        videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(seekBar.value), Int32(NSEC_PER_SEC)))
     }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
