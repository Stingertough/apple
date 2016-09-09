//
//  MainControllerOtherD.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import SafariServices
import JavaScriptCore
import DZNEmptyDataSet

extension MainController: LPTBarButtonItemDelegate, TableOfContentsDelegate, ZimMultiReaderDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate, UIWebViewDelegate, SFSafariViewControllerDelegate, UIScrollViewDelegate, UIViewControllerTransitioningDelegate {
    
    // MARK: - LPTBarButtonItemDelegate
    
    func barButtonTapped(sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        guard sender == bookmarkButton else {return}
        showBookmarkTBVC()
    }
    
    func barButtonLongPressedStart(sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        guard sender == bookmarkButton else {return}
        guard !webView.hidden else {return}
        guard let article = article else {return}
        
        article.isBookmarked = !article.isBookmarked
        if article.isBookmarked {article.bookmarkDate = NSDate()}
        if article.snippet == nil {article.snippet = getSnippet(webView)}
        
        let operation = UpdateWidgetDataSourceOperation()
        GlobalQueue.shared.addOperation(operation)
        
        let controller = ControllerRetainer.bookmarkStar
        controller.bookmarkAdded = article.isBookmarked
        controller.transitioningDelegate = self
        controller.modalPresentationStyle = .OverFullScreen
        presentViewController(controller, animated: true, completion: nil)
        configureBookmarkButton()
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BookmarkControllerAnimator(animateIn: true)
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BookmarkControllerAnimator(animateIn: false)
    }
    
    // MARK: - TableOfContentsDelegate
    
    func scrollTo(heading: HTMLHeading) {
        webView.stringByEvaluatingJavaScriptFromString(heading.scrollToJavaScript)
        if traitCollection.horizontalSizeClass == .Compact {
            animateOutTableOfContentsController()
        }
    }
    
    // MARK: - ZimMultiReaderDelegate
    
    func firstBookAdded() {
        guard let id = ZimMultiReader.sharedInstance.readers.keys.first else {return}
        loadMainPage(id)
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        showSearch(animated: true)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        hideSearch(animated: true)
        configureSearchBarPlaceHolder()
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        ControllerRetainer.search.startSearch(searchText, delayed: true)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        ControllerRetainer.search.searchResultTBVC?.selectFirstResultIfPossible()
    }
    
    // MARK: -  UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .None
    }
    
    // MARK: - UIWebViewDelegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.URL else {return true}
        if url.scheme == "kiwix" {
            return true
        } else {
            let svc = SFSafariViewController(URL: url)
            svc.delegate = self
            presentViewController(svc, animated: true, completion: nil)
            return false
        }
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        PacketAnalyzer.sharedInstance.startListening()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        guard let url = webView.request?.URL else {return}
        guard url.scheme!.caseInsensitiveCompare("Kiwix") == .OrderedSame else {return}
        
        let title = webView.stringByEvaluatingJavaScriptFromString("document.title")
        let managedObjectContext = UIApplication.appDelegate.managedObjectContext
        guard let bookID = url.host else {return}
        guard let book = Book.fetch(bookID, context: managedObjectContext) else {return}
        guard let article = Article.addOrUpdate(title, url: url, book: book, context: managedObjectContext) else {return}
        
        self.article = article
        if let image = PacketAnalyzer.sharedInstance.chooseImage() {
            article.thumbImageURL = image.url.absoluteString
        }
        
        configureSearchBarPlaceHolder()
        injectTableWrappingJavaScriptIfNeeded()
        adjustFontSizeIfNeeded()
        configureNavigationButtonTint()
        configureBookmarkButton()
        
        if traitCollection.horizontalSizeClass == .Regular && isShowingTableOfContents {
            tableOfContentsController?.headings = getTableOfContents(webView)
        }
        
        PacketAnalyzer.sharedInstance.stopListening()
    }
    
    // MARK: - Javascript
    
    func injectTableWrappingJavaScriptIfNeeded() {
        if Preference.webViewInjectJavascriptToAdjustPageLayout {
            if traitCollection.horizontalSizeClass == .Compact {
                guard let path = NSBundle.mainBundle().pathForResource("adjustlayoutiPhone", ofType: "js") else {return}
                guard let jString = try? String(contentsOfFile: path) else {return}
                webView.stringByEvaluatingJavaScriptFromString(jString)
            } else {
                guard let path = NSBundle.mainBundle().pathForResource("adjustlayoutiPad", ofType: "js") else {return}
                guard let jString = try? String(contentsOfFile: path) else {return}
                webView.stringByEvaluatingJavaScriptFromString(jString)
            }
        }
    }
    
    func adjustFontSizeIfNeeded() {
        let zoomScale = Preference.webViewZoomScale
        guard zoomScale != 100.0 else {return}
        let jString = String(format: "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%.0f%%'", zoomScale)
        webView.stringByEvaluatingJavaScriptFromString(jString)
    }
    
    func getTableOfContents(webView: UIWebView) -> [HTMLHeading] {
        guard let context = webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext,
            let path = NSBundle.mainBundle().pathForResource("getTableOfContents", ofType: "js"),
            let jString = try? String(contentsOfFile: path),
            let elements = context.evaluateScript(jString).toArray() as? [[String: String]] else {return [HTMLHeading]()}
        var headings = [HTMLHeading]()
        for element in elements {
            guard let heading = HTMLHeading(rawValue: element) else {continue}
            headings.append(heading)
        }
        return headings
    }
    
    func getSnippet(webView: UIWebView) -> String? {
        guard let context = webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext,
            let path = NSBundle.mainBundle().pathForResource("getSnippet", ofType: "js"),
            let jString = try? String(contentsOfFile: path),
            let snippet = context.evaluateScript(jString).toString() else {return nil}
        return snippet
    }
    
    
    
}
