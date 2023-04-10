//
//  PhotoViewerViewController.swift
//  Messenger
//
//  Created by Afraz Siddiqui on 6/6/20.
//  Copyright © 2020 ASN GROUP LLC. All rights reserved.
//

import UIKit

final class PhotoViewerViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    private let url: URL
    
    var hidden = false
    
    init(with url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.contentMode = .scaleAspectFit
        return scrollView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        scrollView.addSubview(imageView)
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
        view.addSubview(scrollView)
        scrollView.maximumZoomScale = 10
        scrollView.minimumZoomScale = 1
        imageView.image = UIImage(contentsOfFile: url.path())
        
        let btnShare = UIBarButtonItem(barButtonSystemItem:.action, target: self, action: #selector(self.share))
        self.navigationItem.rightBarButtonItem = btnShare
        
        self.navigationController?.hidesBarsOnTap = true
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.hidesBarsOnTap = true
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        imageView.frame = scrollView.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.hidesBarsOnTap = false
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1 {
            scrollView.isScrollEnabled = true
            if let image = imageView.image {
                let ratioW = imageView.frame.width / image.size.width
                let ratioH = imageView.frame.height / image.size.height
                let ratio = ratioW < ratioH ? ratioW : ratioH
                let newWidth = image.size.width * ratio
                let newHeight = image.size.height * ratio
                let conditionLeft = newWidth*scrollView.zoomScale > imageView.frame.width
                let left = 0.5 * (conditionLeft ? newWidth - imageView.frame.width : (scrollView.frame.width - scrollView.contentSize.width))
                let conditioTop = newHeight*scrollView.zoomScale > imageView.frame.width
                let top = 0.5 * (conditioTop ? newHeight - imageView.frame.height : (scrollView.frame.height - scrollView.contentSize.height))
                
                scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
            }
        }
        else {
            scrollView.contentInset = .zero
            scrollView.isScrollEnabled = false
            imageView.frame = scrollView.bounds
        }
    }
    
    @objc func share() {
        // image to share
        let image = imageView.image
        
        // set up activity view controller
        let imageToShare = [ image! ]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
    
}
