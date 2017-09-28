//
//  JCWebProgressView.swift
//  JCWebDemo
//
//  Created by zhengjiacheng on 2017/4/11.
//

import UIKit
import pop
class JCWebProgressView: UIView {
    
    private var _progress: CGFloat = 0.0
    public var progress: CGFloat {
        set{
            _progress = newValue
            animateProgress(newValue)
        }
        get{
            return _progress
        }
    }
    
    var progressBarView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubViews()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupSubViews()
    }
    
    func setupSubViews(){
        
        self.isUserInteractionEnabled = false
        self.autoresizingMask = .flexibleWidth
        
        progressBarView = UIView(frame: self.bounds)
        progressBarView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.addSubview(progressBarView)
        getbackLayer()
    }
    
    func getbackLayer(){
        let gradientLayer = CAGradientLayer()
        var frame = UIScreen.main.bounds
        frame.size = CGSize(width: frame.size.width, height: 2)
        frame.origin = CGPoint(x: 0, y: 0)
        gradientLayer.frame = frame
        
        //将CAGradientlayer对象添加在我们要设置背景色的视图的layer层
        progressBarView.layer.addSublayer(gradientLayer)
        
        progressBarView.clipsToBounds = true
        
        //设置渐变区域的起始和终止位置（范围为0-1）
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        
        //设置颜色数组
        gradientLayer.colors = [UIColor.color(withHex: 0xef4949).cgColor,UIColor.color(withHex: 0xfd7d45).cgColor,UIColor.color(withHex: 0xef4949).cgColor]

        //设置颜色分割点（范围：0-1）
        gradientLayer.locations = [0.5, 1.0]
    }

    func animateProgress(_ progress: CGFloat){
        if progress < 0 || progress > 1 {
            return
        }
        
        var frame = progressBarView.frame
        frame.size.width = progress * (self.superview?.bounds.size.width ?? frame.size.width)
        
        if frame.size.width < progressBarView.frame.size.width {
            frame.size.width = progressBarView.frame.size.width
        }

        guard let scaleAnimation = POPSpringAnimation(propertyNamed: kPOPViewFrame) else {
            return
        }
        scaleAnimation.toValue = NSValue.init(cgRect: frame)
        scaleAnimation.springSpeed = 14
        scaleAnimation.springBounciness = 0
        progressBarView.pop_add(scaleAnimation, forKey: "progressViewFrame")
        
        scaleAnimation.completionBlock = { (pop, flag) in
            if flag, progress >= 1.0{
                UIView.animate(withDuration: 0.4, animations: {
                    self.progressBarView.alpha = 0.0
                }, completion: { (finished) in
                    var frame = self.progressBarView.frame
                    frame.size.width = 0
                    self.progressBarView.frame = frame
                })
            }else{
                self.progressBarView.alpha = 1.0;
            }
        }
        
    }

    
    
    
    
}
