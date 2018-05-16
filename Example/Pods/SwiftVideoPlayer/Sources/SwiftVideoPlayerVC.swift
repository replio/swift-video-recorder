//
//
//  Created by Максим Ефимов on 16.01.2018.
//

import UIKit
import AVKit

public struct Item {
    let videoURL: URL!
    let previewURL: URL?

    public init(videoURL: URL!, previewURL: URL?) {
        self.videoURL = videoURL
        self.previewURL = previewURL
    }
}

open class SwiftVideoPlayerVC: UIViewController {
    private static let assetKeysRequiredToPlay = [
        "playable",
        "hasProtectedContent"
    ]
    private var playerView: PlayerView = {
        var playerView = PlayerView()
        playerView.translatesAutoresizingMaskIntoConstraints = false
        return playerView
    }()
    private var previewView: UIImageView = {
        var view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var toggleButton: UIButton = {
        var button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        return button
    }()
    private var moveBackButton: UIButton = {
        var button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(moveBack), for: .touchUpInside)
        return button
    }()
    private var moveForwardButton: UIButton = {
        var button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(moveForward), for: .touchUpInside)
        return button
    }()
    private var topGradientView: UIView = {
        var view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var bottomGradientView: UIView = {
        var view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private (set) var player: AVQueuePlayer!
    private var playerLayer: AVPlayerLayer? {
        return playerView.playerLayer
    }
    private var MAX_COUNT = 14
    private var MIN_COUNT = 3
    private var items: [Item]!
    private (set) var currentIndex: Int = 0

    convenience init(_ url: Item, videoGravity: AVLayerVideoGravity = .resizeAspectFill){
        self.init([url], videoGravity: videoGravity)
    }
    
    public init(_ urls: [Item], startIndex: Int = 0, videoGravity: AVLayerVideoGravity = .resizeAspectFill){
        super.init(nibName: nil, bundle: nil)
        self.items = urls
        self.currentIndex = startIndex
        MAX_COUNT = min(urls.count, MAX_COUNT)
        MIN_COUNT = min(urls.count, MIN_COUNT)
        playerLayer!.videoGravity = videoGravity
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        print(#function, currentIndex, MAX_COUNT, items.count)

        player = AVQueuePlayer()
        playerView.player = player
        player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        
        for i in currentIndex..<min(items.count, currentIndex + MAX_COUNT) {
            addItem(items[i].videoURL)
        }

        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.3, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: DispatchQueue.main) { time in
            if self.player.currentItem != nil {
                self.timeAction(seconds: time.seconds, duration: self.player.currentItem!.duration.seconds)
            }
        }

        modalPresentationStyle = .overFullScreen
        
        providesPresentationContextTransitionStyle = true
        definesPresentationContext = true

        setupViews()
        itemDidChange()
    }

    func timeAction(seconds: Double, duration: Double) {
        self.previewView.isHidden = seconds > 0
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        UIApplication.shared.isStatusBarHidden = true
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player.pause()
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        UIApplication.shared.isStatusBarHidden = false
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    internal func setupViews(){
        view.backgroundColor = .black
        navigationItem.title = ""
        view.addSubview(playerView)
        playerView.addSubview(previewView)
        playerView.addSubview(topGradientView)
        playerView.addSubview(bottomGradientView)
        playerView.addSubview(moveBackButton)
        playerView.addSubview(moveForwardButton)
        playerView.addSubview(toggleButton)
        
        playerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        playerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        playerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        previewView.leadingAnchor.constraint(equalTo: playerView.leadingAnchor).isActive = true
        previewView.trailingAnchor.constraint(equalTo: playerView.trailingAnchor).isActive = true
        previewView.topAnchor.constraint(equalTo: playerView.topAnchor).isActive = true
        previewView.bottomAnchor.constraint(equalTo: playerView.bottomAnchor).isActive = true

        moveBackButton.topAnchor.constraint(equalTo: playerView.topAnchor).isActive = true
        moveBackButton.leftAnchor.constraint(equalTo: playerView.leftAnchor).isActive = true
        moveBackButton.widthAnchor.constraint(equalToConstant:50).isActive = true
        moveBackButton.bottomAnchor.constraint(equalTo: playerView.bottomAnchor).isActive = true
        
        moveForwardButton.rightAnchor.constraint(equalTo:playerView.rightAnchor).isActive = true
        moveForwardButton.widthAnchor.constraint(equalToConstant:50).isActive = true
        moveForwardButton.topAnchor.constraint(equalTo: playerView.topAnchor).isActive = true
        moveForwardButton.bottomAnchor.constraint(equalTo:playerView.bottomAnchor).isActive = true
        
        toggleButton.leftAnchor.constraint(equalTo: moveBackButton.rightAnchor).isActive = true
        toggleButton.rightAnchor.constraint(equalTo: moveForwardButton.leftAnchor).isActive = true
        toggleButton.topAnchor.constraint(equalTo: playerView.topAnchor).isActive = true
        toggleButton.bottomAnchor.constraint(equalTo:playerView.bottomAnchor).isActive = true

        topGradientView.leadingAnchor.constraint(equalTo: playerView.leadingAnchor).isActive = true
        topGradientView.trailingAnchor.constraint(equalTo: playerView.trailingAnchor).isActive = true
        topGradientView.topAnchor.constraint(equalTo: playerView.topAnchor).isActive = true
        topGradientView.heightAnchor.constraint(equalToConstant: 200).isActive = true

        bottomGradientView.leadingAnchor.constraint(equalTo: playerView.leadingAnchor).isActive = true
        bottomGradientView.trailingAnchor.constraint(equalTo: playerView.trailingAnchor).isActive = true
        bottomGradientView.bottomAnchor.constraint(equalTo: playerView.bottomAnchor).isActive = true
        bottomGradientView.heightAnchor.constraint(equalToConstant: 200).isActive = true
    }

    public func itemDidChange() {
        if let _: URL = items[self.currentIndex].previewURL {
            previewView.isHidden = false
            //previewView.load(url.absoluteString, contentMode: playerLayer!.videoGravity == .resizeAspectFill ? .scaleAspectFill : .scaleAspectFit )
        }
    }

    @objc public func itemDidEnd() {
        print(#function)
        if !moveForward() {
            self.dismiss(animated: true)
        }
    }


    @objc public func toggle() {
        if player.rate != 0 {
            player.pause()
        }
        else {
            player.play()
        }
    }

    //Добавляем текущий элемент после текущего элемента потом добавляем предыдущий элемент после текущего к переходим к нему
    @objc public func moveBack() {
        if currentIndex > 0 {
            addItem(items[currentIndex].videoURL, toBack: false)
            currentIndex-=1
            addItem(items[currentIndex].videoURL, toBack: false)
            player.advanceToNextItem()
            itemDidChange()
        }
    }
    
    @objc public func moveForward() -> Bool {
        if currentIndex < items.count - 1 {
            player.advanceToNextItem()

            let leftCount = player.items().count
            currentIndex += 1
            print(#function, leftCount)
            if(leftCount <= MIN_COUNT){
                let startIndex = currentIndex + leftCount
                let endIndex = min(startIndex + (MAX_COUNT - MIN_COUNT), items.count)
                print("can add new answers", startIndex, endIndex)
                for i in startIndex..<endIndex {
                    addItem(items[i].videoURL)
                }
            }
            itemDidChange()
            return true
        }
        return false
    }

    @objc func close(){
        clear()
        self.dismiss(animated: true)
    }

    private func addItem(_ url: URL, toBack: Bool = true){
        print(#function, url.absoluteString)
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: SwiftVideoPlayerVC.assetKeysRequiredToPlay)

        NotificationCenter.default.addObserver(self, selector: #selector(itemDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        player.insert(playerItem, after: toBack ? nil : player.items()[0])
    }

    private func clear(){
        if playerLayer != nil && playerLayer!.player != nil {
            print(#function)
            player.pause()
            player.removeAllItems()
            playerLayer!.player = nil
        }
    }

    deinit {
        print(#function)
        clear()
    }
}
