//
//  SlideSwitchView.swift
//  MadeInChina
//
//  Created by sheng rong on 9/10/15.
//  Copyright © 2015 MICN. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol SRSlideSwitchViewDelegate{
    
    /*!
    * @method 顶部tab个数
    * @abstract
    * @discussion
    * @param 本控件
    * @result tab个数
    */
    func numberOfTab(view:SRSlideSwitchView) -> Int
    /*!
    * @method 每个tab所属的viewController
    * @abstract
    * @discussion
    * @param tab索引
    * @result viewController
    */
    func slideSwitchView(view:SRSlideSwitchView, viewOfTab:Int) -> UIViewController
    /*!
    * @method 滑动左边界时传递手势
    * @abstract
    * @discussion
    * @param   手势
    * @result
    */
    optional func slideSwitchView(view:SRSlideSwitchView, panLeftParam:UIPanGestureRecognizer)
    /*!
    * @method 滑动右边界时传递手势
    * @abstract
    * @discussion
    * @param   手势
    * @result
    */
    optional func slideSwitchView(view:SRSlideSwitchView, panRightParam:UIPanGestureRecognizer)
    /*!
    * @method 点击tab
    * @abstract
    * @discussion
    * @param tab索引
    * @result
    */
    optional func slideSwitchView(view:SRSlideSwitchView, didSelectTab:Int)
}

enum SRSlideViewStyle{
    case Default
    case Tabbar
}

@objc public class SRSlideSwitchView: UIView, UIScrollViewDelegate {

    var topScrollView : UIScrollView!
    var rootScrollView : UIScrollView!
    var userSelectedChannelID : Int
    var userContentOffsetX : CGFloat
    var viewArray : Array<AnyObject>
    var kHeightOfTopScrollView:CGFloat = 45.0
    public var slideSwitchViewDelegate : SRSlideSwitchViewDelegate!
    
    public var tabBarIsShow : Bool = true
    public var isLeftScroll : Bool = false                         //是否左滑动
    public var isRootScroll : Bool = false                         //是否主视图滑动
    public var isBuildUI : Bool = false                            //是否建立了ui
    
    public var shadowImageView : UIImageView?
    public var shadowImage : UIImage?
    public var tabItemNormalColor : UIColor?
    public var tabItemSelectedColor : UIColor?
    public var tabItemNormalBackgroundImage : UIImage?
    public var tabItemSelectedBackgroundImage : UIImage?
    
    public var rightSideButton : UIButton?{
        didSet {
            let button:UIButton? = self.viewWithTag(SRSlideSwitchView.kTagOfRightSideButton) as? UIButton
            button?.removeFromSuperview()
            rightSideButton!.tag = SRSlideSwitchView.kTagOfRightSideButton
            self.addSubview(rightSideButton!)
        }
    }
    
    static let kWidthOfButtonMargin : CGFloat = 15.0
    static let kFontSizeOfTabButton = 15.0
    static let kTagOfRightSideButton = 999
    static let buttonWidth : CGFloat = 85
    static let buttonHeight : CGFloat = 20
    static let marginTop : CGFloat = 5
    
    
    required public init?(coder aDecoder: NSCoder) {
        viewArray = []
        isBuildUI = false
        userSelectedChannelID = 100
        userContentOffsetX = 0
        super.init(coder: aDecoder)
        initUIValues()
    }
    
    func initValues(){
        viewArray = []
        isBuildUI = false
        userSelectedChannelID = 100
        userContentOffsetX = 0
    }
    
    func initUIValues(){
        if(self.tabBarIsShow){
            //创建顶部可滑动的tab
            topScrollView = UIScrollView(frame: CGRectMake(0, SRSlideSwitchView.marginTop, self.bounds.size.width, kHeightOfTopScrollView))
            topScrollView.delegate = self
            topScrollView.backgroundColor = UIColor.lightTextColor()
            topScrollView.pagingEnabled = false
            topScrollView.showsHorizontalScrollIndicator = false
            topScrollView.showsVerticalScrollIndicator = false
            topScrollView.autoresizingMask = UIViewAutoresizing.FlexibleWidth
            self.addSubview(topScrollView)
        }
        
        //创建主滚动视图
        rootScrollView = UIScrollView(frame: CGRectMake(0, kHeightOfTopScrollView + SRSlideSwitchView.marginTop, self.bounds.size.width, self.bounds.size.height - kHeightOfTopScrollView - SRSlideSwitchView.marginTop))
        rootScrollView.delegate = self
        rootScrollView.pagingEnabled = true
        rootScrollView.userInteractionEnabled = true
        rootScrollView.bounces = false;
        rootScrollView.showsHorizontalScrollIndicator = true
        rootScrollView.showsVerticalScrollIndicator = false
        rootScrollView.autoresizingMask = [.FlexibleWidth,.FlexibleBottomMargin,.FlexibleHeight]
        
        //        rootScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        
        rootScrollView.panGestureRecognizer.addTarget(self, action: "scrollHandlePan:")
        self.addSubview(rootScrollView)
    }
    
    func showTopTab(show:Bool)
    {
        self.tabBarIsShow = show;
        if(show){
            kHeightOfTopScrollView = 44.0;
        }else{
            kHeightOfTopScrollView = 0;
        }
    }
    
    //当横竖屏切换时可通过此方法调整布局
    override public func layoutSubviews()
    {
        //创建完子视图UI才需要调整布局
        if (isBuildUI) {
            if let rightSideButton = self.rightSideButton{
                //如果有设置右侧视图，缩小顶部滚动视图的宽度以适应按钮
                if (rightSideButton.bounds.size.width > 0) {
                    rightSideButton.frame = CGRectMake(self.bounds.size.width - rightSideButton.bounds.size.width, 0,
                        rightSideButton.bounds.size.width, topScrollView.bounds.size.height);
                    
                    topScrollView.frame = CGRectMake(0, SRSlideSwitchView.marginTop,
                        self.bounds.size.width - rightSideButton.bounds.size.width, kHeightOfTopScrollView);
                }
            }
    
            //更新主视图的总宽度
            rootScrollView.contentSize = CGSizeMake(self.bounds.size.width * CGFloat(viewArray.count), 0);
    
            //更新主视图各个子视图的宽度
            for (var i = 0; i < viewArray.count; i++) {
                let listVC:UIViewController = viewArray[i] as! UIViewController
                listVC.view.frame = CGRectMake(0+rootScrollView.bounds.size.width * CGFloat(i), 0,
                    rootScrollView.bounds.size.width, rootScrollView.bounds.size.height)
            }
    
            //滚动到选中的视图
            rootScrollView.setContentOffset(CGPointMake(CGFloat(userSelectedChannelID - 100) * self.bounds.size.width,0), animated: false)
    
            //调整顶部滚动视图选中按钮位置
            let button: UIButton = topScrollView.viewWithTag(userSelectedChannelID) as! UIButton
            adjustScrollViewContentX(button)
        }
    }
    
    /*!
    * @method 创建子视图UI
    * @abstract
    * @discussion
    * @param
    * @result
    */
    public func buildUI()
    {
        initValues()
        initUIValues()
        let number = slideSwitchViewDelegate.numberOfTab(self)
        for (var i=0; i < number; i++){
            let vc:UIViewController = self.slideSwitchViewDelegate.slideSwitchView(self, viewOfTab: i)
            viewArray.append(vc)
            rootScrollView.addSubview(vc.view)
        }
        if self.tabBarIsShow {
            self.createNameButtons()
        }
    
        //选中第一个view
        self.slideSwitchViewDelegate.slideSwitchView?(self, didSelectTab: self.userSelectedChannelID - 100)
    
        isBuildUI = true
    
        //创建完子视图UI才需要调整布局
        self.setNeedsLayout()
    }
    
    /*!
    * @method 初始化顶部tab的各个按钮
    * @abstract
    * @discussion
    * @param
    * @result
    */
    func createNameButtons()
    {
        if let shadowImage = self.shadowImage{
            shadowImageView = UIImageView(image: shadowImage)
            topScrollView.addSubview(shadowImageView!)
        }
    
        //顶部tabbar的总长度
        var topScrollViewContentWidth : CGFloat = CGFloat(SRSlideSwitchView.kWidthOfButtonMargin)
        var xOffset: CGFloat = CGFloat(SRSlideSwitchView.kWidthOfButtonMargin)
        
        //每个tab偏移量
        for (var i = 0; i < viewArray.count; i++) {
            let vc : UIViewController = viewArray[i] as! UIViewController
            let button:UIButton = UIButton(type: .Custom)
            
//            let attrs = [NSFontAttributeName : UIFont.systemFontOfSize(CGFloat(SlideSwitchView.kFontSizeOfTabButton))]
//            let attrString : NSAttributedString = NSAttributedString(string: vc.title!, attributes: attrs)
            
//            let textSize : CGSize = attrString.boundingRectWithSize(CGSizeMake(topScrollView.bounds.size.width, kHeightOfTopScrollView), options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil).size
            
            let textSize : CGSize = CGSizeMake(SRSlideSwitchView.buttonWidth, SRSlideSwitchView.buttonHeight)

            //累计每个tab文字的长度
            topScrollViewContentWidth += CGFloat(SRSlideSwitchView.kWidthOfButtonMargin) + textSize.width
            //设置按钮尺寸
            button.frame = CGRectMake(xOffset, 0, textSize.width, kHeightOfTopScrollView)
            //计算下一个tab的x偏移量
            xOffset += textSize.width + CGFloat(SRSlideSwitchView.kWidthOfButtonMargin)
            button.tag = i + 100
            button.setTitle(vc.title, forState: .Normal)
            button.titleLabel?.font = UIFont.systemFontOfSize(CGFloat(SRSlideSwitchView.kFontSizeOfTabButton))
            button.setTitleColor(tabItemNormalColor, forState: .Normal)
            button.setTitleColor(tabItemSelectedColor, forState: .Selected)
            button.setBackgroundImage(tabItemNormalBackgroundImage, forState: .Normal)
            button.setBackgroundImage(tabItemSelectedBackgroundImage, forState: .Selected)
            button.addTarget(self, action: "selectNameButton:", forControlEvents: .TouchUpInside)
            if i == 0 {
                if let shadowImageView = self.shadowImageView{
                    shadowImageView.frame = CGRectMake(CGFloat(SRSlideSwitchView.kWidthOfButtonMargin), 0, textSize.width, shadowImage!.size.height)
                    button.selected = true
                }
            }
            topScrollView.addSubview(button)
        }
    
        //设置顶部滚动视图的内容总尺寸
        topScrollView.contentSize = CGSizeMake(topScrollViewContentWidth, kHeightOfTopScrollView);
    }
    
    /*!
    * @method 选中tab时间
    * @abstract
    * @discussion
    * @param 按钮
    * @result
    */
    func selectNameButton(sender:UIButton)
    {
        //如果点击的tab文字显示不全，调整滚动视图x坐标使用使tab文字显示全
        self.adjustScrollViewContentX(sender)
        //如果更换按钮
        if sender.tag != userSelectedChannelID {
            //取之前的按钮
            let lastButton : UIButton = topScrollView.viewWithTag(userSelectedChannelID) as! UIButton
            lastButton.selected = false
            //赋值按钮ID
            userSelectedChannelID = sender.tag
        }
    
        //按钮选中状态
        if (!sender.selected) {
            sender.selected = true
            
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                if let shadowImageView = self.shadowImageView{
                    shadowImageView.frame = CGRectMake(sender.frame.origin.x, 0, sender.frame.size.width, self.shadowImage!.size.height)
                }
                
                }, completion: { (finished) -> Void in
                    if (finished) {
                        //设置新页出现
                        if !self.isRootScroll {
                            self.rootScrollView.setContentOffset(CGPointMake(CGFloat(sender.tag - 100) * self.bounds.size.width, 0), animated: true)
                        }
                        self.isRootScroll = false
                        self.slideSwitchViewDelegate.slideSwitchView?(self, didSelectTab: self.userSelectedChannelID - 100)
                    }
            })
        }
            //重复点击选中按钮
        else {
    
        }
    }
    
    /*!
    * @method 调整顶部滚动视图x位置
    * @abstract
    * @discussion
    * @param
    * @result
    */
    func adjustScrollViewContentX(sender:UIButton)
    {
        let nextButton : UIButton? = self.viewWithTag(sender.tag + 1) as? UIButton
        let lastButton : UIButton? = self.viewWithTag(sender.tag - 1) as? UIButton
        let screenWidth = UIScreen.mainScreen().bounds.width
        var buttonAbsX = sender.frame.origin.x - topScrollView.contentOffset.x
        var buttonWidth = sender.frame.width
        if buttonAbsX < 0 {
            topScrollView.setContentOffset(CGPointMake(buttonAbsX - SRSlideSwitchView.kWidthOfButtonMargin + topScrollView.contentOffset.x, 0), animated: true)
        }
        if buttonAbsX + sender.frame.width > screenWidth{
            topScrollView.setContentOffset(CGPointMake(buttonAbsX + buttonWidth - screenWidth + SRSlideSwitchView.kWidthOfButtonMargin, 0), animated: true)
        }
        if let nxtButton = nextButton {
            buttonWidth = nxtButton.frame.width
            buttonAbsX = nxtButton.frame.origin.x - topScrollView.contentOffset.x
            if buttonAbsX + nxtButton.frame.width > screenWidth {
                topScrollView.setContentOffset(CGPointMake(buttonAbsX + buttonWidth - screenWidth + SRSlideSwitchView.kWidthOfButtonMargin, 0), animated: true)
            }
        }
        
        if let lstButton = lastButton {
            buttonWidth = lstButton.frame.width
            buttonAbsX = lstButton.frame.origin.x - topScrollView.contentOffset.x
            if buttonAbsX < 0 {
                topScrollView.setContentOffset(CGPointMake(buttonAbsX - SRSlideSwitchView.kWidthOfButtonMargin + topScrollView.contentOffset.x, 0), animated: true)
            }
        }
    }
    
    //滚动视图开始时
    public func scrollViewWillBeginDragging(scrollView:UIScrollView)
    {
        if scrollView == rootScrollView {
            userContentOffsetX = scrollView.contentOffset.x
        }
    }
    
    //滚动视图结束
    public func scrollViewDidScroll(scrollView : UIScrollView)
    {
        if scrollView == rootScrollView {
            //判断用户是否左滚动还是右滚动
            if (userContentOffsetX < scrollView.contentOffset.x) {
                isLeftScroll = true
            }
            else {
                isLeftScroll = false
            }
        }
    }
    
    //滚动视图释放滚动
    public func scrollViewDidEndDecelerating(scrollView:UIScrollView)
    {
        if scrollView == rootScrollView {
            isRootScroll = true
            //调整顶部滑条按钮状态
            let tag = Int(scrollView.contentOffset.x / self.bounds.size.width) + 100;
            let button : UIButton = topScrollView.viewWithTag(Int(tag)) as! UIButton
            self.selectNameButton(button)
        }
    }
    
    //传递滑动事件给下一层
    func scrollHandlePan(panParam : UIPanGestureRecognizer)
    {
        //当滑道左边界时，传递滑动事件给代理
        if rootScrollView.contentOffset.x <= 0 {
            self.slideSwitchViewDelegate.slideSwitchView?(self, panLeftParam: panParam)
        } else if rootScrollView.contentOffset.x >= (rootScrollView.contentSize.width - rootScrollView.bounds.size.width) {
            self.slideSwitchViewDelegate.slideSwitchView?(self, panRightParam: panParam)
        }
    }
    
    /*!
    * @method 通过16进制计算颜色
    * @abstract
    * @discussion
    * @param 16机制
    * @result 颜色对象
    */
    static func colorFromHexRGB(inColorString:String) -> UIColor?
    {
        var result : UIColor? = nil
        var colorCode : UInt32 = 0
        let redByte : CUnsignedChar
        let greenByte : CUnsignedChar
        let blueByte : CUnsignedChar
    
        if inColorString != ""{
            let scanner : NSScanner = NSScanner(string: inColorString)
            scanner.scanHexInt(&colorCode) // ignore error
        }
        redByte = CUnsignedChar(colorCode >> 16)
        greenByte = CUnsignedChar(colorCode >> 8)
        blueByte = CUnsignedChar(colorCode) // masks off high bits
        result = UIColor(colorLiteralRed: Float(redByte), green: Float(greenByte), blue: Float(blueByte), alpha: 1.0)
        return result
    }
    
    func setTabBarStyle(style:SRSlideViewStyle)
    {
        switch (style) {
            case .Default: break
            case .Tabbar: break
        }
    }
}


