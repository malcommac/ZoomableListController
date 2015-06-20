//
//  ViewController.swift
//  ZoomableListController
//
//  Created by daniele margutti on 06/20/2015.
//  Copyright (c) 06/20/2015 daniele margutti. All rights reserved.
//

import UIKit
import ZoomableListController

class CustomViewController: UIViewController {
	weak var zoomTable : ZoomableListController?
	var pageIndex: Int!
	init(table: ZoomableListController?,page: Int!) {
		zoomTable = table
		pageIndex = page
		super.init(nibName: nil, bundle: nil)
		
		let button = UIButton.buttonWithType( UIButtonType.Custom ) as! UIButton
		button.setTitle("Close", forState: UIControlState.Normal)
		button.frame = CGRectMake(0, 0, 100, 100)
		self.view.addSubview(button)
		button.addTarget(self, action: "click", forControlEvents: UIControlEvents.TouchUpInside)
	}
	
	func click() {
		//zoomTable!.compressPage()
		zoomTable!.switchToTabularList(true)
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class CellClass: UICollectionViewCell {
	var textLabel: UILabel!
	
	override init(frame: CGRect) {
		textLabel = UILabel(frame: CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame)))
		super.init(frame: frame)
		textLabel.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.FlexibleHeight.rawValue | UIViewAutoresizing.FlexibleWidth.rawValue)
		textLabel.textAlignment = NSTextAlignment.Center
		self.addSubview(textLabel)
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}

class ViewController: UIViewController, ZoomableListControllerDatasource {
	var table : ZoomableListController?
	private var colors : [UIColor]!
	private var controllersList: [CustomViewController]!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		table = ZoomableListController(frame: self.view.bounds)
		
		
		colors = [UIColor.yellowColor(),UIColor.orangeColor(),UIColor.redColor(),UIColor.purpleColor(),UIColor.blueColor(),UIColor.cyanColor(),UIColor.lightGrayColor(),UIColor.brownColor()]
		controllersList = []
		for (var x = 0;x < colors.count; x++) {
			let vc = CustomViewController(table: table, page:x)
			vc.view.backgroundColor = colors[x]
			vc.view.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.FlexibleHeight.rawValue | UIViewAutoresizing.FlexibleWidth.rawValue)
			
			let label = UILabel(frame: vc.view.bounds)
			label.text = "VC \(x)"
			label.textAlignment = NSTextAlignment.Center
			vc.view.addSubview(label)
			label.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.FlexibleHeight.rawValue | UIViewAutoresizing.FlexibleWidth.rawValue)
			controllersList.append(vc)
		}
		
		
		table?.dataSource = self
		table?.registerClass(CellClass.self, forCellWithReuseIdentifier: "cell")
		self.view.addSubview(table!)
		table?.reloadData()
	}
	
	func numberOfRowsInZoomableTable(table: ZoomableListController!) -> Int! {
		return colors.count
	}
	
	func zoomableTable(table: ZoomableListController!, cellAtIndex index: Int!) -> UICollectionViewCell! {
		let cell: CellClass = table.dequeueCellWithIdentifier("cell", index: index) as! CellClass
		cell.backgroundColor = colors[index]
		cell.textLabel?.text = "Row \(index)"
		cell.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.FlexibleWidth.rawValue | UIViewAutoresizing.FlexibleHeight.rawValue)
		return cell
	}
	
	func zoomableTable(table: ZoomableListController!, cellHeightAtIndex index: Int!) -> CGFloat! {
		return 90
	}
	
	func zoomableTable(table: ZoomableListController!, controllerAtIndex index: Int!) -> UIViewController! {
		return controllersList[index]
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
}


