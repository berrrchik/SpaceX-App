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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        startRotationAnimation()
    }
    
    private func startRotationAnimation() {
        // Remove any existing animation to prevent duplicates
        rocketLabel.layer.removeAnimation(forKey: "rotationAnimation")
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.toValue = NSNumber(value: Double.pi * 2) // Full 360-degree rotation
        rotationAnimation.duration = 1 // Duration of one rotation
        rotationAnimation.repeatCount = .infinity // Repeat indefinitely
        rocketLabel.layer.add(rotationAnimation, forKey: "rotationAnimation")
        
        print("Animation started") // Debug log
    }
    
    func stopRotationAnimation() {
        rocketLabel.layer.removeAnimation(forKey: "rotationAnimation")
        print("Animation stopped") // Debug log
    }
}
