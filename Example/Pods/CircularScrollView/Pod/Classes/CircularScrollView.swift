//
//  CircularScrollView.swift
//  CircularScrollView
//
//  Created by Daniele Margutti on 24/05/15.
//  Copyright (c) 2015 Daniele Margutti http://www.danielemargutti.com. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

//MARK: CircularScrollViewDataSource Protocol

public protocol CircularScrollViewDataSource: class {
	/**
	Return the number of pages to show into the scroll view
	
	:param: scroll target circular scroll view instance
	
	:returns: number of pages to show
	*/
	func numberOfPagesInCircularScrollView(#scroll: CircularScrollView!)->Int!
	
	/**
	The view controller to use into given page index
	
	:param: scroll                target circular scroll view instance
	:param: viewControllerAtIndex view controller to show into given page
	
	:returns: view controller to show
	*/
	func circularScrollView(#scroll: CircularScrollView!, viewControllerAtIndex index: Int!)->UIViewController!
}

//MARK: Delegate Protocol
@objc public protocol CircularScrollViewDelegate: class {
	/**
	This method is called when user scroll between pages. It's called continuously during the scroll.
	
	:param: scroll  target circular scroll view instance
	:param: forward true if scroll is forward, false if it's backward (backward/forward is calculated using the page indexes)
	:param: index   index of the current page (the predominant page rect)
	*/
	optional func circularScrollView(#scroll: CircularScrollView?, willMoveForward forward: Bool, fromPage index: Int)
	
	/**
	This method is called when a scroll task is beginning and report the current page index
	
	:param: scroll    target circular scroll view instance
	:param: fromIndex current predominant page index
	*/
	optional func circularScrollView(#scroll: CircularScrollView?, willScrollFromPage fromIndex : NSInteger)
	
	/**
	This method is called at the end of a scrolling task and report the new current page
	
	:param: scroll  target circular scroll view instance
	:param: toIndex current end page index
	*/
	optional func circularScrollView(#scroll: CircularScrollView?, didScrollToPage toIndex: NSInteger)
	
	/**
	This method is called continuously during a scroll and report the offset of the scroll view
	
	:param: scroll target circular scroll view instance
	:param: offset offset of the scrollview (note: when number of pages > 1 scroll view has 2 more extra pages at start/end, with the relative offset)
	*/
	optional func circularScrollView(#scroll: CircularScrollView?, didScroll offset: CGPoint)
}

//MARK: CircularScrollView

public class CircularScrollView: UIView, UIScrollViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
	//MARK: Public Properties
	/// Delegate of the Circular ScrollView
	weak public var delegate : CircularScrollViewDelegate?
	/// Data Source of the Circular ScrollView
	weak public var dataSource : CircularScrollViewDataSource? {
		didSet {
			self.reloadData()
		}
	}
	/// Yes to enable pagination for circular scroll view, default is true
	public var isPaginated: Bool! {
		didSet {
			collectionView.pagingEnabled = isPaginated
		}
	}
	/// Yes to enable circular scroll direction horizontally, false to use vertical layout
	public var horizontalScroll: Bool! {
		didSet {
			if horizontalScroll == true {
				layout.scrollDirection = UICollectionViewScrollDirection.Horizontal
			} else {
				layout.scrollDirection = UICollectionViewScrollDirection.Vertical
			}
			collectionView.reloadData()
		}
	}

	//MARK: Private Variables
	private var collectionView: UICollectionView!
	private var layout: UICollectionViewFlowLayout!
	private(set) var numberOfPages: Int!
	private var isDecelerating: Bool?

	//MARK: Initialization
	override public init(frame: CGRect) {
		numberOfPages = 0
		layout = UICollectionViewFlowLayout()
		collectionView = UICollectionView(frame: CGRectMake(0.0, 0.0, CGRectGetWidth(frame),CGRectGetHeight(frame)), collectionViewLayout: layout)
		super.init(frame: frame)
		
		isDecelerating = false
		
		collectionView.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.FlexibleWidth.rawValue | UIViewAutoresizing.FlexibleHeight.rawValue)
		collectionView.showsVerticalScrollIndicator = false
		collectionView.showsHorizontalScrollIndicator = false
		collectionView.registerClass(CircularScrollViewCell.self, forCellWithReuseIdentifier: CircularScrollViewCell.identifier)
		collectionView.dataSource = self
		collectionView.delegate = self
		collectionView.backgroundColor = UIColor.clearColor()
		({ // Closure to invoke didSet()
			self.horizontalScroll = true
			self.isPaginated = true
		} as ()->() )()
		self.addSubview(collectionView)
	}

	required public init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}


	//MARK: Public Methods
	
	/**
	Reload data inside the circular scrollview. If not specified scrollview try to reposition to previously loaded page index. You can however
	specify your own start page by passing it. Invalid page bounds are ignored, initial page setup is not animated.
	
	:param: moveToPage optional starting page
	*/
	public func reloadData(moveToPage: Int?=nil) {
		if dataSource == nil {
			return
		}
		let currentPageIdx = self.currentPage()
		numberOfPages = self.dataSource!.numberOfPagesInCircularScrollView(scroll: self)
		collectionView.reloadData()
		if moveToPage != nil {
			self.moveToPage(moveToPage, animated: false)
		} else {
			self.moveToPage(currentPageIdx, animated: false)
		}
	}
	
	/**
	This function return a list of all (2) visible pages inside the scroll view.
	At index 0 you will find the current page (the page that occupies the largest area within the control).
	At index 1 you will find the other visible page (if any. it happends when you call this method during a scroll process)
	
	:returns: visible pages
	*/
	public func visiblePages() -> [Int] {
		if numberOfPages == nil {
			return []
		} else if numberOfPages == 1 {
			return [0]
		}
		var pages: [Int] = []
		let visibleRect = self.visibleRect()
		var maxArea : CGFloat?
		var idxMaxArea : Int?
		for (var k=0; k < (numberOfPages+2); k++) {
			let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: k, inSection: 0))
			if let cell = cell as? CircularScrollViewCell {
				let intersection = CGRectIntersection(cell.frame, visibleRect)
				if CGRectIsNull(intersection) == false {
					pages.append(self.adjustedIndexForIndex(k))
					let area = intersection.width * intersection.height
					if area > maxArea {
						idxMaxArea = pages.count-1
						maxArea = area
					}
				}
			}
		}
		
		if pages.count > 1 && idxMaxArea != nil {
			let value = pages[idxMaxArea!]
			pages.removeAtIndex(idxMaxArea!)
			pages.insert(value, atIndex: 0)
		}
		
		return pages
	}
	
	/**
	This method return the current page index
	
	:returns: current page index
	*/
	public func currentPage() -> Int! {
		let pages = self.visiblePages()
		if pages.count > 0 {
			return pages[0]
		} else {
			return nil
		}
	}
	
	/**
	This method return the visible rect of the circular scroll view. Keep in mind: circular scroll view has two extra pages,
	one before page 0 and another after the last page.
	
	:returns: visible rect inside the circular scrollview
	*/
	public func visibleRect() -> CGRect {
		let visibleRect = CGRectMake(collectionView.contentOffset.x, collectionView.contentOffset.y, CGRectGetWidth(collectionView.frame), CGRectGetHeight(collectionView.frame))
		return visibleRect
	}

	/**
	Use this method to move to a specified page of the control
	
	:param: index    index of the page
	:param: animated YES to animate the movement
	
	:returns: true if page is valid, false otherwise
	*/
	public func moveToPage(index: Int!, animated: Bool!)->Bool! {
		if numberOfPages == nil {
			return false
		}
		var finalPageIdx = (index == nil ? 0 : index)
		if finalPageIdx < 0 || finalPageIdx >= numberOfPages {
			return false
		}
		if numberOfPages > 1 {
			finalPageIdx = finalPageIdx+1
		}
		let indexPath = NSIndexPath(forItem: finalPageIdx, inSection: 0)
		let scrollPosition = (horizontalScroll == true ? UICollectionViewScrollPosition.Left : UICollectionViewScrollPosition.Top)
		collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: scrollPosition, animated: animated)
		return true
	}
	
	//MARK: Collection View Delegate & DataSource
	public func scrollViewDidScroll(scrollView: UIScrollView) {
		let pageSize = self.pageSize()
		let offset = self.currentOffset()
		
		if offset >= ( pageSize * CGFloat((numberOfPages+1)) ) {
			if horizontalScroll == true {
				scrollView.contentOffset = CGPointMake(pageSize, 0)
			} else {
				scrollView.contentOffset = CGPointMake(0, pageSize)
			}
		} else if offset <= 0 {
			let lastItemOffset = pageSize * CGFloat(numberOfPages)
			if horizontalScroll == true {
				scrollView.contentOffset = CGPointMake(lastItemOffset, 0)
			} else {
				scrollView.contentOffset = CGPointMake(0, lastItemOffset)
			}
		}
		
		self.delegate?.circularScrollView?(scroll: self, didScroll: collectionView.contentOffset)
		
		if isDecelerating == false {
			var visiblePages = self.visiblePages()
			if visiblePages.count == 2 {
				let isMovingForward = ( visiblePages[1] > visiblePages[0])
				self.delegate?.circularScrollView?(scroll: self, willMoveForward: isMovingForward, fromPage: visiblePages[0])
			}
		}
	}
	
	public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
		let currentPage = self.currentPage()
		isDecelerating = false
		self.delegate?.circularScrollView?(scroll: self, willScrollFromPage: NSInteger(currentPage))
	}
	
	public func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
		isDecelerating = true
	}
	
	public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		isDecelerating = false
		self.delegate?.circularScrollView?(scroll: self, didScrollToPage: self.currentPage())
	}
	
	public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch numberOfPages {
		case 0...1:
			return numberOfPages
		default:
			return numberOfPages+2
		}
	}
	
	public func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
		let idx = adjustedIndexForIndex(indexPath.item)
		let viewController = self.dataSource!.circularScrollView(scroll: self, viewControllerAtIndex: idx)
		viewController.view.frame = cell.contentView.bounds
		cell.contentView.addSubview(viewController.view)
	}
	
	public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CircularScrollViewCell.identifier, forIndexPath: indexPath) as! CircularScrollViewCell
		cell.index = self.adjustedIndexForIndex(indexPath.item)
		return cell
	}
	
	public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		return self.bounds.size
	}

	public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
		return 0
	}
	
	public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
		return 0
	}
	
	//MARK: Private Methods
	private func adjustedIndexForIndex(index: Int!) -> Int! {
		if numberOfPages == 1 {
			return index
		}
		switch index {
		case 0:
			return (numberOfPages-1)
		case (numberOfPages+1):
			return 0
		default:
			return index-1
		}
	}
	
	private func pageSize() -> CGFloat {
		let size: CGFloat = (horizontalScroll == true ? CGRectGetWidth(collectionView.bounds) : CGRectGetHeight(collectionView.bounds))
		return size
	}
	
	private func currentOffset() -> CGFloat {
		let offset: CGFloat = (horizontalScroll == true ? collectionView.contentOffset.x : collectionView.contentOffset.y)
		return offset
	}
}

// MARK: Helper Cell
class CircularScrollViewCell: UICollectionViewCell {
	static var identifier = "CircularScrollViewCell"
	var index: Int?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.FlexibleWidth.rawValue | UIViewAutoresizing.FlexibleHeight.rawValue)
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}
