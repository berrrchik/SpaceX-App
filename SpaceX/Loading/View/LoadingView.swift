import UIKit
import SnapKit

final class LoadingView: UIView {
    
    private let loadingLabel = UILabel()
    private let rocketLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = AppColors.black
        
        rocketLabel.text = "🚀"
        rocketLabel.font = AppFonts.bold64
        rocketLabel.textAlignment = .center
        rocketLabel.textColor = AppColors.lightGray
        addSubview(rocketLabel)
        
        rocketLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
        }
        
        loadingLabel.text = "Загрузка данных..."
        loadingLabel.font = AppFonts.regular20
        loadingLabel.textAlignment = .center
        loadingLabel.textColor = AppColors.lightGray
        addSubview(loadingLabel)
        
        loadingLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(rocketLabel.snp.bottom).offset(16)
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window == nil {
            stopRotationAnimation()
        } else {
            startRotationAnimation()
        }
    }
    
    private func startRotationAnimation() {
        rocketLabel.layer.removeAnimation(forKey: "rotationAnimation")
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.toValue = NSNumber(value: Double.pi * 2)
        rotationAnimation.duration = 1
        rotationAnimation.repeatCount = .infinity
        rocketLabel.layer.add(rotationAnimation, forKey: "rotationAnimation")
    }
    
    func stopRotationAnimation() {
        rocketLabel.layer.removeAnimation(forKey: "rotationAnimation")
    }
}
