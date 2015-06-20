//
// ZoomableListController.swift
// ZoomableListController
//
// Copyright (c) 2015 Daniele Margutti
//
// First release: June 3, 2015
// Web: http://www.danielemargutti.com
// Mail: me@danielemargutti.com
// Twitter: http://twitter.com/danielemargutti
//
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
import CircularScrollView

//MARK: ZoomableListControllerDatasource

/// This is the protocol you should implement to use ZoomableListController class
public protocol ZoomableListControllerDatasource:class {
	/**
	Return the number of rows to show inside the classic tabular list
	
	:param: table table
	
	:returns: number of rows
	*/
	func numberOfRowsInZoomableTable(table: ZoomableListController!)->Int!
	/**
	You should return a valid UICollectionViewCell subclass as nth row of the tabular representation
	You can register your custom class to the control using registerClass() or registerNib() methods
	and use dequeueCellWithIdentifier() to return a cached version of your cell.
	
	:param: table table
	:param: index index of the cell to return for tabular representation
	
	:returns: a valid UICollectionViewCell instance
	*/
	func zoomableTable(table: ZoomableListController!, cellAtIndex index: Int!)->UICollectionViewCell!
	/**
	Allows you to specify the height of the nth cell of the table
	
	:param: table table
	:param: index index of the cell
	
	:returns: height of the cell
	*/
	func zoomableTable(table: ZoomableListController!, cellHeightAtIndex index: Int!)->CGFloat!
	/**
	This method allows you to return a valid UIViewController instance to use when the user is moving from the
	tabular representation to the detailed scrollview page representation.
	
	:param: table table
	:param: index index of the row
	
	:returns: a valid UIViewController subclass
	*/
	func zoomableTable(table: ZoomableListController!, controllerAtIndex index: Int!)->UIViewController!
}

//MARK: ZoomableListControllerDelegate

/// This protocol allows you to receive notificastions about the class itself
@objc public protocol ZoomableListControllerDelegate:class {
	
	// METHODS CALLED FROM THE TABULAR REPRESENTATION
	
	/**
	This method is called when an user touch the cell to expand from tabular representation to the scrollview page representation
	
	:param: table table
	:param: index index of the touched row
	*/
	optional func zoomableTable(table: ZoomableListController!, didSelectRow index: Int)
	
	/**
	This method is called when the user use pinch gesture to expand a cell into the tabular representation
	
	:param: table table
	:param: index index of the cell
	*/
	optional func zoomableTable(table: ZoomableListController!, startExpandPinch index: Int)
	
	/**
	This method is called when the user end it's pinch gesture and tell to the delegate if the transition to the page scroll view representation
	will be applied or not
	
	:param: table      table
	:param: index      index of the cell
	:param: willExpand true if the transition to the page scroll mode will happens
	*/
	optional func zoomableTable(table: ZoomableListController!, endExpandPinch index: Int, willExpand: Bool)
	
	// METHODS CALLED FROM THE DETAIL PAGESCROLLVIEW REPRESENTATION
	/**
	This method is called when user scroll between pages. It's called continuously during the scroll.
	
	:param: scroll  target circular scroll view instance
	:param: forward true if scroll is forward, false if it's backward (backward/forward is calculated using the page indexes)
	:param: index   index of the current page (the predominant page rect)
	*/
	optional func zoomableTable(table: ZoomableListController!, willScrollForward forward: Bool, fromPage index: Int)
	
	/**
	This method is called when a scroll task is beginning and report the current page index
	
	:param: scroll    target circular scroll view instance
	:param: fromIndex current predominant page index
	*/
	optional func zoomableTable(table: ZoomableListController!, willScrollFromPage fromIndex : NSInteger)
	
	/**
	This method is called at the end of a scrolling task and report the new current page
	
	:param: scroll  target circular scroll view instance
	:param: toIndex current end page index
	*/
	optional func zoomableTable(table: ZoomableListController!, didScrollToPage toIndex: NSInteger)
	
	/**
	This method is called continuously during a scroll and report the offset of the scroll view
	
	:param: scroll target circular scroll view instance
	:param: offset offset of the scrollview (note: when number of pages > 1 scroll view has 2 more extra pages at start/end, with the relative offset)
	*/
	optional func zoomableTable(table: ZoomableListController!, didScroll offset: CGPoint)
}


/// This class is used as ghost cell to
public class GhostCell : UICollectionViewCell {
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.backgroundColor = UIColor.clearColor()
		self.opaque = false
	}

	required public init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}

//MARK: ZoomableListController

public class ZoomableListController: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, CircularScrollViewDataSource, CircularScrollViewDelegate {
	
	//MARK: Public Properties
	public weak var dataSource: ZoomableListControllerDatasource? {
		didSet {
			self.reloadData()
		}
	}
	public weak var delegate: ZoomableListControllerDelegate?
	
	//MARK: Private Properties
	private var tableView: UICollectionView!
	private var pageScrollView: CircularScrollView!
	private var isTabular: Bool!
	private var pageCount: Int!
	
	private var isPinching: Bool!
	private var pinchIndexPath: NSIndexPath?
	private var pinchInitialRowHeight: CGFloat?
	private var pinchCurrentRowHeight: CGFloat?
	private var pinchCell: UICollectionViewCell?
	private var pinchInitialOffset: CGPoint?
	private var pinchViewController: UIViewController?
	
	//MARK: Init
	
	override public init(frame: CGRect) {
		let bounds = CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))
		tableView = UICollectionView(frame: bounds, collectionViewLayout: UICollectionViewFlowLayout())
		pageScrollView = CircularScrollView(frame: bounds)
		isPinching = false
		pinchIndexPath = nil
		isTabular = true
		pageCount = 0
		super.init(frame: frame)
		
		tableView.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.FlexibleWidth.rawValue | UIViewAutoresizing.FlexibleHeight.rawValue)
		tableView.delegate = self
		tableView.dataSource = self
		tableView.registerClass(GhostCell.self, forCellWithReuseIdentifier: "ghost")
		self.addSubview(tableView)
		
		let pinch = UIPinchGestureRecognizer(target: self, action: "handlePinch:")
		self.addGestureRecognizer(pinch)
	}

	required public init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	//MARK: Tabular List Data Source
	
	public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return pageCount+1
	}

	public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		if indexPath.item == pageCount {
			let cell = tableView.dequeueReusableCellWithReuseIdentifier("ghost", forIndexPath: indexPath) as! UICollectionViewCell
			return cell
		}
		return dataSource!.zoomableTable(self, cellAtIndex: indexPath.row)
	}
	
	public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		if indexPath.item == pageCount {
			return CGSizeMake(CGRectGetWidth(collectionView.frame), CGRectGetHeight(self.bounds) / 3.0)
		}
		if pinchIndexPath != nil {
			if pinchIndexPath!.item == indexPath.row {
				return CGSizeMake(CGRectGetWidth(collectionView.frame), pinchCurrentRowHeight!)
			}
		}
		return CGSizeMake(CGRectGetWidth(collectionView.frame), self.dataSource!.zoomableTable(self, cellHeightAtIndex: indexPath.item))
	}
	
	public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		//if self.delegate?.zoomableTable(self, didSelectRow: indexPath.row) {
			self.switchToDetailList(indexPath.item, animated: true)
		//}
	}
	
	//MARK: Manage Pinch
	
	func handlePinch(recognizer: UIPinchGestureRecognizer) {
		switch recognizer.state {
		case UIGestureRecognizerState.Began:
			handlePinchBegan(recognizer)
		case UIGestureRecognizerState.Changed:
			handlePinchChanged(recognizer)
		case UIGestureRecognizerState.Ended:
			handlePinchEnded(recognizer)
		default:
			break
		}
	}
	
	private func handlePinchBegan(recognizer: UIPinchGestureRecognizer) {
		if isTabular == true {
			// Check if recognizer is under a valid cell view. If yes we can start our pinch action, otherwise
			// we reset our machine and ignore all.
			pinchIndexPath = tableView.indexPathForItemAtPoint(recognizer.locationInView(tableView))
			if pinchIndexPath != nil {
				isPinching = true
				// We are expading our cell so initial cell height is the height of the cell before any zoom pinch
				pinchInitialRowHeight = self.dataSource!.zoomableTable(self, cellHeightAtIndex: pinchIndexPath!.item)
				pinchInitialOffset = tableView.contentOffset
				self.delegate?.zoomableTable?(self, startExpandPinch: pinchIndexPath!.item)
			} else {
				resetPinchState()
			}
		} else {
			// Compress pinch from page scroller to tabular list should start from our current page.
			// So, first of all, we want to set the index path to the current visible page index
			pinchIndexPath = NSIndexPath(forItem: pageScrollView.currentPage(), inSection: 0)
			isPinching = true
			pinchCell = nil
			pinchInitialRowHeight = CGRectGetHeight(self.bounds) // initial row height is the height of the page scroller
			pinchCurrentRowHeight = pinchInitialRowHeight
			// Reload our tabular list collection view and scroll to set our cell at the top of the table itself
			tableView.reloadData()
			tableView.scrollToItemAtIndexPath(pinchIndexPath!, atScrollPosition: UICollectionViewScrollPosition.Top, animated: false)
			// Remove our page scroll view instance and replace it with the tabular list
			//self.addSubview(tableView)
			//pageScrollView.removeFromSuperview()
			self.insertSubview(tableView, belowSubview: pageScrollView)
			// Set the pinch cell and offset
			
			pinchInitialOffset = tableView.contentOffset
		}
	}
	
	private func handlePinchChanged(recognizer: UIPinchGestureRecognizer) {
		// We want to calculate the new height of the cell during any pinch gesture state
		// Anyway pinch row's height must be >= pinchInitialHeight and <= control's view bounds
		pinchCurrentRowHeight = pinchInitialRowHeight! * recognizer.scale
		
		if pinchCell == nil {
			
			pinchCell = tableView.cellForItemAtIndexPath(pinchIndexPath!)
			
				// We want to add the final view controller and fade in when pin
			pinchViewController = self.dataSource!.zoomableTable(self, controllerAtIndex: pinchIndexPath!.item)
			pinchViewController!.view.frame = pinchCell!.bounds
			
			var a = CGFloat(isTabular == true ? 0.0 : 1.0)
			pinchViewController!.view.alpha = a
			pinchCell!.addSubview(pinchViewController!.view)
			
			if isTabular == false {
				pageScrollView.removeFromSuperview()
			}
		}
		// Calculate diff between the old and new height of the cell. It will be used to calculate the new offset of the table
		let delta = fabs(pinchInitialRowHeight! - pinchCurrentRowHeight!) * (isTabular == true ? 1 : -1)
		
		// During pinch resize the cell view according to the new size
		var cellFrame = pinchCell!.frame
		cellFrame.size.height = pinchCurrentRowHeight!
		
		//	if isTabular == true {
		var alpha : CGFloat = 0.0
		if isTabular == true {
			alpha = (pinchCurrentRowHeight! - pinchInitialRowHeight! ) / (pinchInitialRowHeight! * 2)
		} else {
			let finalHeight = CGRectGetHeight(self.bounds) - self.dataSource!.zoomableTable(self, cellHeightAtIndex: pinchIndexPath!.item)
			alpha = 1 - (pinchInitialRowHeight! - pinchCurrentRowHeight! ) / (finalHeight)
		}
		
		pinchViewController?.view.alpha = alpha
		//	}
		UIView.setAnimationsEnabled(false)
		tableView.performBatchUpdates({ () -> Void in
			self.pinchCell!.frame = cellFrame
			// Also move the contentoffset in order to mimate a cell scale down near the center of the screen
			self.tableView.contentOffset = CGPointMake(self.pinchInitialOffset!.x, self.pinchInitialOffset!.y + (delta/2.0))
		}, completion: nil)
	}
	
	private func handlePinchEnded(recognizer: UIPinchGestureRecognizer) {
		var finalScrollPosition: UICollectionViewScrollPosition?
		if isTabular == true { // when expading final height will be the height of the control itself
			pinchCurrentRowHeight = CGRectGetHeight(self.bounds)
			finalScrollPosition = UICollectionViewScrollPosition.Top
		} else { // when shrinking the final height is the initial height of that cell
			pinchCurrentRowHeight = self.dataSource!.zoomableTable(self, cellHeightAtIndex: pinchIndexPath!.item)
			finalScrollPosition = UICollectionViewScrollPosition.CenteredVertically
		}
		
		var frame = pinchCell!.frame
		frame.size.height = pinchCurrentRowHeight!
		
		UIView.setAnimationsEnabled(true) // restore animations
		if isTabular == true {
			// at this time we don't support a min height which allow the control to expand. Maybe in a future I'll add it
			// so the willExpand parameter will be not a fixed value anymore
			self.delegate?.zoomableTable?(self, endExpandPinch: pinchIndexPath!.item, willExpand: true)
		}
		tableView.performBatchUpdates({ () -> Void in
			UIView.animateWithDuration(0.25, animations: { () -> Void in
				self.pinchViewController!.view.alpha = (self.isTabular == false ? 0.0 : 1.0)
				self.pinchCell!.frame = frame
				self.tableView .scrollToItemAtIndexPath(self.pinchIndexPath!, atScrollPosition: finalScrollPosition!, animated: true)
			}, completion: { (finished) -> Void in
					
			})
		}) { (finished) -> Void in
			if self.isTabular == true {
				self.switchToScrollMode(self.pinchIndexPath!.item)
			} else {
				self.pinchViewController!.view.removeFromSuperview()
			}
			self.isTabular = !self.isTabular
			self.resetPinchState()
		}
	}
	
	//MARK: Public Methods
	
	public func registerClass(cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
		tableView.registerClass(cellClass, forCellWithReuseIdentifier: identifier)
	}
	
	public func registerNib(nib: UINib?, forCellWithReuseIdentifier identifier: String) {
		tableView.registerNib(nib, forCellWithReuseIdentifier: identifier)
	}
	
	public func dequeueCellWithIdentifier(identifier: String!, index: Int!) -> UICollectionViewCell {
		return tableView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: NSIndexPath(forItem: index, inSection: 0)) as! UICollectionViewCell
	}
	
	public func reloadData() {
		pageCount = self.dataSource!.numberOfRowsInZoomableTable(self)
		if isTabular == true {
			tableView.reloadData()
		} else {
			pageScrollView.reloadData()
		}
	}
	
	public func switchToTabularList(animated: Bool!) {
		if animated == false {
			tableView.reloadData()
			pageScrollView.removeFromSuperview()
			self.addSubview(tableView)
			resetPinchState()
			isTabular = true
		} else {
			UIView.setAnimationsEnabled(true)
			self.pinchIndexPath = NSIndexPath(forItem: self.pageScrollView.currentPage(), inSection: 0)
			self.pinchInitialRowHeight = CGRectGetHeight(self.bounds)
			pageScrollView.removeFromSuperview()
			self.addSubview(tableView)
			
			self.pinchInitialOffset = self.tableView.contentOffset
			self.pinchCell = self.tableView.cellForItemAtIndexPath(self.pinchIndexPath!)
			self.pinchCurrentRowHeight = self.dataSource!.zoomableTable(self, cellHeightAtIndex: self.pinchIndexPath!.item)
			
			// We want to add the final view controller and fade in when pin
			pinchViewController = self.dataSource!.zoomableTable(self, controllerAtIndex: pinchIndexPath!.item)
			pinchViewController!.view.frame = pinchCell!.bounds
			pinchViewController!.view.alpha = 1.0
			pinchCell!.addSubview(pinchViewController!.view)
			
			UIView.animateWithDuration(0.25, animations: { () -> Void in
				self.tableView.performBatchUpdates({ () -> Void in
					// set the final cell size
					
					var frame = self.pinchCell!.frame
					self.tableView.setContentOffset(frame.origin, animated: false)
					
					frame.size.height = self.pinchCurrentRowHeight!
					self.pinchCell!.frame = frame
					self.pinchViewController!.view.alpha = 0.0
					self.tableView.contentOffset = CGPointMake(self.pinchInitialOffset!.x, frame.origin.y)
					
					}) { (finished) -> Void in
						self.isTabular = true
						self.resetPinchState()
				}
			})
			
		}
	}
	
	public func switchToDetailList(index: Int!, animated: Bool!) {
		if index < 0 && index >= pageCount {
			return
		}
		if animated == false {
			self.switchToScrollMode(index)
			isTabular = false
			self.resetPinchState()
		} else {
			pinchIndexPath = NSIndexPath(forItem: index, inSection: 0)
			pinchInitialRowHeight = self.dataSource!.zoomableTable(self, cellHeightAtIndex: index)
			pinchInitialOffset = tableView.contentOffset
			pinchCurrentRowHeight = CGRectGetHeight(self.bounds)
			if isRowVisible(index) == false {
				tableView.scrollToItemAtIndexPath(pinchIndexPath!, atScrollPosition: UICollectionViewScrollPosition.CenteredVertically, animated: true)
			}
			pinchCell = tableView.cellForItemAtIndexPath(pinchIndexPath!)
			
			// We want to add the final view controller and fade in when pin
			pinchViewController = self.dataSource!.zoomableTable(self, controllerAtIndex: pinchIndexPath!.item)
			pinchViewController!.view.frame = pinchCell!.bounds
			pinchViewController!.view.alpha = 0.0
			pinchCell!.addSubview(pinchViewController!.view)
			
			tableView.performBatchUpdates({ () -> Void in
				UIView.animateWithDuration(0.25, animations: { () -> Void in
					var frame = self.pinchCell!.frame
					frame.size.height = CGRectGetHeight(self.bounds)
					self.pinchCell!.frame = frame
					self.pinchViewController?.view.alpha = 1.0
					self.tableView.setContentOffset(frame.origin, animated: true)
				})
				}, completion: { finished in
					self.isTabular = false
					self.switchToScrollMode(index)
			})
		}
	}
	
	//MARK: Helper Methods
	
	private func resetPinchState() {
		isPinching = false
		pinchIndexPath = nil;
		pinchInitialRowHeight = nil
		pinchCurrentRowHeight = nil
		pinchCell = nil
		pinchInitialOffset = nil
		pinchViewController = nil
	}
	
	private func switchToScrollMode(pageIdx: Int!) {
		self.tableView.removeFromSuperview()
		pageScrollView.frame = self.bounds
		self.addSubview(pageScrollView)
		pageScrollView.dataSource = self
		pageScrollView.delegate = self
		pageScrollView.reloadData(moveToPage: pageIdx)
	}
	
	private func isRowVisible(index: Int!) -> Bool! {
		let visibleItems = tableView.indexPathsForVisibleItems()
		for path in visibleItems {
			if path.item == index {
				return true
			}
		}
		return false
	}
	
	//MARK: Circular ScrollView Delegate/DataSource
	
	public func circularScrollView(#scroll: CircularScrollView!, viewControllerAtIndex index: Int!) -> UIViewController! {
		return self.dataSource?.zoomableTable(self, controllerAtIndex: index)
	}
	
	public func numberOfPagesInCircularScrollView(#scroll: CircularScrollView!) -> Int! {
		return self.dataSource?.numberOfRowsInZoomableTable(self)
	}
	
	public func circularScrollView(#scroll: CircularScrollView?, willMoveForward forward: Bool, fromPage index: Int) {
		self.delegate?.zoomableTable?(self, willScrollForward: forward, fromPage: index)
	}
	
	public func circularScrollView(#scroll: CircularScrollView?, willScrollFromPage fromIndex : NSInteger) {
		self.delegate?.zoomableTable?(self, willScrollFromPage: fromIndex)
	}

	public func circularScrollView(#scroll: CircularScrollView?, didScrollToPage toIndex: NSInteger) {
		self.delegate?.zoomableTable?(self, didScrollToPage: toIndex)
	}
	
	public func circularScrollView(#scroll: CircularScrollView?, didScroll offset: CGPoint) {
		self.delegate?.zoomableTable?(self, didScroll: offset)
	}
}
